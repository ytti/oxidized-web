# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
## [Unreleased]

### Added

### Changed
- the table preferences (pagelength, column visibility) are stored in the local browser cache (@robertcheramy)

### Fixed
- Allow connection to any virtual hosts + prepare extended configuration to specify which vhosts to accept. Fixes #298 (@robertcheramy)


## [0.15.1 – 2025-02-20]
This minor release fixes javascript errors.

### Fixed
- Fix javascript not working (@robertcheramy)

## [0.15.0 – 2025-02-17]
This release fixes a security issue on the RANCID migration page.
A non-authenticated user could gain control over the Linux user running
oxidized-web. The RANCID migration page was already deprecated in version
0.14.0, so it has been completely removed in this new version.
Thank you to Jon O'Reilly and Jamie Riden from NetSPI for discovering and
reporting this security issue!

### Changed
- Update datatables.net to 2.2.2 and datatables.net-buttons to 3.2.2 (@robertcheramy)
- remove the RANCID migration page (@robertchreamy)
- dependency on oxidized 0.31  (@robertchreamy)
- Update datatables.net to 2.2.1 and datatables.net-buttons to 3.2.1 (@robertcheramy)

### Fixed
- #302: group name containing a '/' produced a Sinatra error (@robertcheramy)


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
