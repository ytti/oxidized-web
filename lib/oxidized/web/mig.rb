module Oxidized
  module API
    class Mig
      def initialize(hash_router_db, cloginrc, path_new_router)
        @hash_router_db = hash_router_db
        @cloginrc = cloginrc
        @path_new_router = path_new_router
      end
      
      #read cloginrc and return a hash with node name, which a hash value which contains user, password, eventually enable
      def cloginrc clogin_file
        close_file = clogin_file
        file = close_file.read
        file = file.gsub("add", '')
        
        hash = {}
        file.each_line do |line|
          
          
          #stock all device name, and password and enable if there is one
          line = line.split(" ")
          for i in 0..line.length
            if line[i] == "user"
              #add the equipment and user if not exist
              unless hash[line[i + 1]]
                hash[line[i + 1]] = {:user=>line[i + 2]}
              end
            #if the equipment exist, add password and enable password
            elsif line[i] == "password"
              if hash[line[i + 1]]
                if line.length > i + 2
                  h = hash[line[i + 1]]
                  h[:password] = line[i + 2]
                  if /\s*/.match(line[i + 3])
                    h[:enable] = line[i + 3]
                  end
                  hash[line[i + 1]] = h
                elsif line.length = i + 2
                  h = hash[line[i + 1]]
                  h[:password] = line[i + 2]
                  hash[line[i + 1]] = h
                end
              end
            end
          end
        end
        close_file.close
        hash
      end
      def model_dico model
        dico = {"cisco"=>"ios", "foundry"=>"ironware"}
        model = model.gsub("\n", "")
        if dico[model]
          model = dico[model]
        end
        model
      end
      
      #add node and group for an equipment (take a list of router.db)
      def rancid_group router_db_list
        model = {}
        hash = cloginrc @cloginrc
        router_db_list.each do |router_db|
          group = router_db[:group]
          file_close = router_db[:file]
          file = file_close.read
          file = file.gsub(":up", '')
          file.gsub(" ", '')
          
          file.each_line do |line|
            line = line.split(":")
            node = line[0]
            if hash[node]
              h = hash[node]
              model = model_dico line[1].to_s
              h[:model] = model
              h[:group] = group
            end
          end
          file_close.close
        end
        hash
      end
      
      #write a router.db conf, need the hash and the path of the file we whish create
      def write_router_db hash
        router_db = File.new(@path_new_router, "w")
        hash.each do |key, value|
          line = key.to_s
          line += ":" + value[:model].to_s
          line += ":" + value[:user].to_s
          line += ":" + value[:password].to_s
          line += ":" + value[:group].to_s
          if value[:enable]
            line += ":" + value[:enable].to_s
          end
          router_db.puts(line)
        end
        router_db.close
      end
      
      def edit_conf_file path_conf, router_db_path
        file_close = File.open(path_conf, "r")
        file = file_close
        file = file.read
        source_reached = false
        new_file = []
        file.each_line do |line|
          if source_reached
            unless /^\w/.match(line)
              next
            end
            source_reached = false
          end
          new_file.push(line)
          if /source:/.match(line)
            source_reached = true
            new_file.push("  default: csv\n")
            new_file.push("  csv:\n")
            new_file.push("    file: " + router_db_path + "\n")
            new_file.push("    delimiter: !ruby/regexp /:/\n")
            new_file.push("    map:\n")
            new_file.push("      name: 0\n")
            new_file.push("      model: 1\n")
            new_file.push("      username: 2\n")
            new_file.push("      password: 3\n")
            new_file.push("      group: 4\n")
            new_file.push("    vars_map:\n")
            new_file.push("      enable: 5\n")
            next
          end
        end
        file_close.close
        
        new_conf = File.new(path_conf, "w")
        new_file.each do |line|
          new_conf.puts(line)
        end
        new_conf.close
      end
      
      def go_rancid_migration
        hash = rancid_group @hash_router_db
        write_router_db hash
        edit_conf_file "#{ENV['HOME']}/.config/oxidized/config", @path_new_router
      end
    end
  end
end
