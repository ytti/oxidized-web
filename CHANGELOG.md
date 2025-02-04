# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Added

### Changed
- Update datatables.net to 2.2.1 and datatables.net-buttons to 3.2.1 (@robertcheramy)

### Fixed


## [0.14.0 - 2024-06-28]

### Added
- CHANGELOG.md created (@robertchreamy)
- First minitest: get / (@robertchreamy)
- docs/development.md created (@robertchreamy)
- weblibs are maintained with npm (@robertchreamy)
- display Oxidized-web version in the footer (@robertcheramy)

### Changed
- gem dependencies updated (@robertchreamy)
- support for ruby 3.0 dropped (@robertchreamy)
- #215: weblibs (jQuery, bootstrap, datatables.net) updated (@robertchreamy)
- the web design follows where possible bootstrap without specific css (@robertchreamy)
- deprecating the RANCID migration page (@robertchreamy)

### Fixed
- #232: escape_once not supported in haml 6.0 (@robertchreamy)
- #253: deprecated sass dependency dropped (@robertchreamy)
- rubocop warnings fixed (@robertchreamy)
- #234: removed link to not working live demo (@robertchreamy)
- group name containing a '/' producing a Sinatra error (@robertcheramy)
