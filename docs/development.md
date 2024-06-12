# How to run / develop oxidized-web from git
## Using the latest oxidized package
When you develop oxidized-web, it is quite simple to run it from git. As it depends on oxidized,
oxidized will be included in `bundle install`, and you just have to run `bundle exec oxidized`.
You need bundler, if not installed yet. On debian-based systems, you can run `sudo apt install ruby-bundler` to install it.

All steps in one to copy & pase:
```shell
git clone git@github.com:ytti/oxidized-web.git
cd oxidized-web
bundle config set --local path 'vendor/bundle'
bundle install
bundle exec oxidized
```

Changes to haml templates are reloaded on the fly. For changes to the ruby
scripts, you have to stop an restart `bundle exec oxidized`.

## Paralell development between oxidized and oxidized-web
You may need to make some changes in oxidized **and** oxidized-web. For this,
git clone oxidized and oxidized-web in a common root directory, add the direct
dependency to ../oxidized-web in oxidized and run oxidized from the oxidized
repo:

```shell
git clone git@github.com:ytti/oxidized-web.git
git clone git@github.com:ytti/oxidized.git
cd oxidized
bundle config set --local path 'vendor/bundle'
echo "gem 'oxidized-web', path: '../oxidized-web'" >> Gemfile
bundle install
bundle exec bin/oxidized
```

Be careful when commiting your work in oxidized *NOT* to include the changes to
Gemfile, as this is a local change for development. I (@robertcheramy) didn't
find a better way to do this, better ideas are welcome :-)

If your changes to oxidized **AND** oxidzed-web are dependent from another, make
sure you document this in the respectives CHANGELOG.md, so that everyone is
informed at the next release.
