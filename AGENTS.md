# AGENTS.md

Guidance for AI coding agents working in the oxidized-web repository. Human
contributors should read [CONTRIBUTING.md](CONTRIBUTING.md) and the [docs/](docs/)
folder.

## Project overview

oxidized-web is the web user interface and RESTful API for
[Oxidized](https://github.com/ytti/oxidized), a network device configuration
backup tool. It is not useful on its own: it is loaded by oxidized as an
extension and configured in the oxidized configuration under
`extensions.oxidized-web` (see [docs/configuration.md](docs/configuration.md)).

- [lib/oxidized/web.rb](lib/oxidized/web.rb) – configuration parsing and the
  puma server.
- [lib/oxidized/web/webapp.rb](lib/oxidized/web/webapp.rb) – the Sinatra
  application (routes for the web UI and the JSON API).
- [lib/oxidized/web/views/](lib/oxidized/web/views/) – ERB templates, rendered
  by Erubi.
- [lib/oxidized/web/public/](lib/oxidized/web/public/) – CSS, JavaScript and
  images. `public/weblibs/` contains third-party web libraries copied from
  `node_modules` by `rake weblibs`; do not edit them by hand.

## Environment & common commands

Dependencies are managed with Bundler into `vendor/bundle`. Prefix commands with
`bundle exec`.

```bash
bundle config set --local path 'vendor/bundle'
bundle install

bundle exec rake              # default task (rubocop + minitest)
bundle exec rake test         # run the whole test suite (minitest)
bundle exec rubocop           # lint / style
bundle exec oxidized          # run oxidized with oxidized-web from git
```

Use `OXIDIZED_HOME` to point at a custom config directory instead of
`~/.config/oxidized/`. See [docs/development.md](docs/development.md) for
developing oxidized and oxidized-web in parallel, and for updating the web
libraries.

## Communication

- Respond to the user in the language they write in.
- **All code, identifiers, comments, commit messages and documentation must be
  in English.**

## Coding conventions

- Target Ruby `>= 3.0` (see [oxidized-web.gemspec](oxidized-web.gemspec)). Do
  not use syntax or stdlib features newer than 3.0, or guard them (e.g. the
  regexp timeout of the config search, which needs Ruby >= 3.2).
- Follow RuboCop; the config lives in [.rubocop.yml](.rubocop.yml). Run
  `bundle exec rubocop` before finishing and fix offenses instead of disabling
  cops, unless a disable is clearly justified.
- Strings: prefer `"double quotes"`; use `'single quotes'` to signal that string
  interpolation is intentionally not wanted (not enforced by RuboCop).
- Max line length is 120.
- ERB templates escape HTML globally (`escape_html`): `<%= %>` escapes,
  `<%== %>` outputs raw HTML. Only use `<%== %>` for HTML that is already
  escaped (e.g. rendered templates or helpers like `snippet_html`), never for
  user-controlled data (node names, groups, models, URL parameters, device
  configurations); keep the XSS regression tests in
  [spec/web/xss_spec.rb](spec/web/xss_spec.rb) passing.
- **Comments should be sparse and concise.** Only comment when the code is not
  self-evident. Do not add comments, docstrings, or type annotations to code
  you did not change.
- Keep changes focused and minimal. Do not refactor or "clean up" unrelated code
  as part of an unrelated fix.

## Testing conventions

Tests live in `spec/**/*_spec.rb` (minitest + mocha + rack-test) and are run by
`rake test`. Oxidized objects such as `nodes` are mocked; see existing specs
under [spec/web/](spec/web/) for the patterns.

## Deprecations

When deprecating a feature, configuration option or platform:

- Keep it working and log a warning with `logger.warn` that names the
  replacement.
- Add it to [docs/deprecated.md](docs/deprecated.md) (table and a section),
  with `unreleased` in the column "Since"; the release process replaces it with
  the version.
- Mention it in [CHANGELOG.md](CHANGELOG.md) under `### Deprecated`.
- Check whether the deprecation must be coordinated with oxidized (e.g.
  supported Ruby versions, configuration handled by oxidized).

When removing a deprecated feature, remove it from docs/deprecated.md too.

## Contribution workflow

- Document user-visible changes in [CHANGELOG.md](CHANGELOG.md) under
  `[Unreleased]`.
- Keep commits small and messages descriptive; they appear in the pull request.
- Before opening a PR: `bundle exec rubocop` and `bundle exec rake test` must
  pass (CI blocks merges otherwise).
