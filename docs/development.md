# Index
1. [Run from git](#how-to-run--develop-oxidized-web-from-git)
2. [Update weblibs](#update-the-weblibs)
3. [Release](#how-to-release-a-new-version-of-oxidized-web)

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

## Parallel development between oxidized and oxidized-web
You may need to make some changes in oxidized **and** oxidized-web. For this,
git clone oxidized and oxidized-web in a common root directory.

Then you can link your oxidized-web with the oxidized, add the direct
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

Be careful when committing your work in oxidized *NOT* to include the changes to
Gemfile, as this is a local change for development. I (@robertcheramy) didn't
find a better way to do this, better ideas are welcome :-)

If your changes to oxidized **AND** oxidzed-web are dependent from another, make
sure you document this in the respective CHANGELOG.md, so that everyone is
informed at the next release.

Note: you can also add the dependency to oxidized in oxidized-web, in the same
fashion:
```shell
git clone git@github.com:ytti/oxidized-web.git
git clone git@github.com:ytti/oxidized.git
cd oxidized-web
bundle config set --local path 'vendor/bundle'
echo "gem 'oxidized', path: '../oxidized'" >> Gemfile
bundle install
bundle exec oxidized
```


# Update the weblibs
The weblibs are beeing downloaded and maintained by `npm`.

Run `npm install` to download the weblibs. They will be stored under
`node_modules`.
The file `package-lock.json` (wich is tracked in git) ensures that every
developer gets the same versions.

Run `npm outdated` to get a list of new releases:

```shell
oxidized-web$ npm outdated
Package             Current  Wanted  Latest  Location                         Depended by
datatables.net-bs5    2.0.7   2.0.8   2.0.8  node_modules/datatables.net-bs5  oxidized-web
```

Run `npm update` to get the latest releases. They still are not used
oxidzed-web. Run `rake weblibs` to sync `node_modules` with
`lib/oxidized/web/public/weblibs`.

Test, and commit the changes to the weblibs **and** package-lock.json. Don't
forget to document your changes in CHANGELOG.md.

# How to release a new version of Oxidized-web?

## Version numbering
Oxidized-web versions are numbered like major.minor.patch
- currently, the major version is 0.
- minor is incremented when releasing new features.
- patch is incremented when releasing fixes only.

## Review changes
Run `git diff 0.xx.yy..master` (where `0.xx.yy` is to be changed to the last
release) and review all the changes that have been done. Have a specific look
at changes you don't understand.

It is nicer to read in a GUI, so you can use something like
`git difftool --tool=kdiff3 -d 0.xx.yy..master` to see it in kdiff3.

## Update the gem dependencies to the latest versions
```
bundle outaded
bundle update
bundle outaded
```

Test again after updating!

## Update the weblibs to the latest versions
```
npm outdated
```

Test again after updating!

## Make sure the file permissions are correct
Run `bundle exec rake chmod`

## Create a release branch
Name the release branch `release/0.xx.yy`

Update CHANGELOG.md:
- review it
- add release notes
- set the new version (replace `[Unreleased]` with `[0.xx.yy – 202Y-MM-DD]`)

Change the version in `lib/oxidized/web/version.rb`

Upload the branch to github, make a Pull Request for it.

## Test!
Run `bundle exec rake` on the git repository to check the code against rubocop
and run the defined tests in `/spec`.

Run Oxidized-web from git against the latest Oxidized version `bundle exec oxdized`

When testing the web application, open the javascript console in the browser to
see any errors.

## Release
1. Merge the Pull Request into master with the commit message
   `chore(release): release version 0.xx.y`
2. `git pull` master
3. Tag the commit with `git tag -a 0.xx.yy -m "Release 0.xx.yy"` or `rake tag`
4. Build the gem with ‘rake build’
5. Run `git diff` to check if there have been more changes (there shouldn't)
6. Install an test the gem locally
```shell
gem install --user-install pkg/oxidized-web-0.xx.yy.gem
~/.local/share/gem/ruby/3.1.0/bin/oxidized
```

## Release in github
Push the tag to github:
```
git push origin 0.xx.yy
```

Make a release from the tag in github.
- Take the release notes frm CHANGELOG.md
- List new contributors (generated automatically)
- Keep the Full Changelog (generated automatically)

## Release in rubygems
Push the gem with ‘rake push’

You need an account at rubygems which is allowed to push oxidized

## Release in docker.io
In order to release in docker.io, oxidized be released to a new version,
as the container is build there.

## Update CHANGELOG.md for next release
Add
```
## [Unreleased]

### Added

### Changed

### Fixed

```
And push to github

