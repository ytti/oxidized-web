require 'erb'

module Oxidized
  module API
    module Helpers
      # Building of URLs with node names, groups and models
      module Url
        private

        # URL-encode +value+ for a path or a query string. "/" stays readable,
        # as it separates the group from the node name and is allowed in
        # query strings.
        def url_escape(value)
          ERB::Util.url_encode(value.to_s).gsub('%2F', '/')
        end

        # query string with URL-encoded values from a hash
        def url_query(params)
          params.map { |key, value| "#{key}=#{url_escape(value)}" }.join('&')
        end
      end
    end
  end
end
