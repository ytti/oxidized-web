# Deprecations
This page lists features, configuration options and platforms that are
deprecated in oxidized-web and will be removed in a future release.
Please migrate to the replacement before the planned removal.

| Deprecated                                    | Since      | Planned removal | Replacement               |
|-----------------------------------------------|------------|-----------------|---------------------------|
| [Ruby 3.0 and Ruby 3.1](#ruby-30-and-ruby-31) | unreleased | June 2028       | Ruby >= 3.2               |
| [Configuration `rest`](#configuration-rest)   | 0.16.0     | April 2027      | `extensions.oxidized-web` |

## Ruby 3.0 and Ruby 3.1
Ruby 3.0 and 3.1 have reached their end of life (3.0 in April 2024, 3.1 in
March 2025) and no longer receive security fixes.

oxidized-web still runs on them, but without some protections:
- **No timeout for the config search:** Ruby 3.2 introduced regular
  expression timeouts. On Ruby >= 3.2, the config search aborts when a
  regular expression takes longer than one second on a configuration. On
  Ruby 3.0 and 3.1 there is no timeout, and a malicious or badly written
  regular expression (ReDoS) can keep a web server thread busy for a very
  long time.

Please upgrade to Ruby 3.2 or newer.

Support for Ruby 3.0 and 3.1 is planned to be removed in June 2028, when
Debian LTS for Debian 12 ends. By then, none of the LTS distributions below
is supported any more without paid extended support.

### LTS distributions without Ruby >= 3.2
oxidized tries to support the Ruby versions of the LTS releases of common
Linux distributions. These still ship Ruby 3.0 or 3.1 as their system Ruby
(as of November 2026):

| Distribution      | System Ruby | End of support            | Extended support |
|-------------------|-------------|---------------------------|------------------|
| Ubuntu 22.04 LTS  | 3.0         | June 2027 (standard)      | April 2032 (ESM) |
| Debian 12         | 3.1         | June 2028 (Debian LTS)    | June 2033 (ELTS) |
| RHEL 9 and clones | 3.0         | May 2027 (full support)   | May 2032         |

Notes:
- Ubuntu 24.04 (Ruby 3.2), Ubuntu 26.04 and Debian 13 (Ruby 3.3) are not
  affected.
- RHEL 8 and 9 provide newer Ruby versions as AppStream module streams
  (e.g. `ruby:3.3`), so they can run Ruby >= 3.2 without the system Ruby.
- On any distribution, a newer Ruby can be installed with a Ruby version
  manager (rbenv, ruby-install, ...) or oxidized can be run from the
  [docker image](https://github.com/ytti/oxidized/blob/master/docs/Docker.md).

### Removal must be coordinated with oxidized
Raising `required_ruby_version` in oxidized-web must be coordinated with
[oxidized](https://github.com/ytti/oxidized):
- oxidized-web depends on oxidized, and oxidized has oxidized-web as a
  development dependency. Both CIs install the other gem and test the
  same Ruby versions (3.0 and 3.1 on `ubuntu-24.04`, 3.2 and newer on
  `ubuntu-latest`).
- If only one of them drops Ruby 3.0 and 3.1, the CI of the other one
  breaks on those versions, or bundler silently resolves an older release
  of the gem that still supports them, so the tests no longer run against
  the current code.
- Both gems should therefore raise `required_ruby_version` and remove
  Ruby 3.0 and 3.1 from `.github/workflows/ruby.yml` in releases that are
  published together.

### Development dependencies held back
Some development dependencies have dropped Ruby 3.0 and 3.1, so their version
constraints in `oxidized-web.gemspec` are kept loose enough for bundler to
resolve an older version on these Rubies:

| Gem       | Constraint | Ruby 3.0 and 3.1 | Newer versions need             |
|-----------|------------|------------------|---------------------------------|
| simplecov | `>= 0.22`  | 0.22             | Ruby >= 3.2 (1.0), >= 3.3 (1.3) |

When Ruby 3.0 and 3.1 are removed, tighten these constraints again (e.g.
simplecov `~> 1.0`; versions >= 1.3 also drop Ruby 3.2).

## Configuration `rest`
The old syntax `rest: 127.0.0.1:8888/prefix` to configure oxidized-web has been
replaced by `extensions.oxidized-web` in oxidized-web 0.16.0. The old syntax
still works, but oxidized logs a warning and ignores `extensions.oxidized-web`
when `rest` is configured. The new syntax also supports options that are not
available with `rest`, such as `vhosts` and `hide_node_vars`.

See [Configuration](configuration.md).

oxidized deprecated `rest` in version 0.33.0 and plans to remove it in April
2027. oxidized-web will drop its support for `rest` (the method
`parse_legacy_configuration` in `lib/oxidized/web.rb`) after oxidized has
removed it, and raise its dependency to that oxidized version.
