# Redesign test results

Execution date: 2026-10-22. All checks below ran against synthetic/local data; no live network device was contacted.

## Executed checks

| Check | Result | Evidence |
|---|---|---|
| Ruby suite (`bundle exec rake test`) | Passed | 59 runs, 253 assertions, 0 failures, 0 errors, 0 skips. This repository uses Minitest, not RSpec. SimpleCov line coverage: 94.94% (638/672). |
| RuboCop (`bundle exec rake rubocop`) | Passed | 16 files inspected, no offenses detected. |
| Ruby syntax | Passed | All Ruby files under lib and spec compiled with RubyVM::InstructionSequence. |
| Haml compilation | Passed | All 10 templates compiled through Haml::Engine, then RubyVM::InstructionSequence in a render method (to support layout yield). |
| Node tests (`npm test`) | Passed | 8 tests, 0 failures; sidebar state/focus/dismissal and theme persistence/storage fallback. |
| JavaScript syntax | Passed | node --check for app-shell.js and theme-toggle.js. |
| Whitespace (`git diff --check`) | Passed | No whitespace errors; Windows line-ending normalization warnings only. |
| Chrome browser regression | Passed | Headless installed Chrome, Playwright, local Puma fixture on 127.0.0.1:9299. Both DataTables filtered 3 rows to 1 and reset to 3. Column chooser hid/restored Group and Total Failures. |
| Responsive navigation | Passed | 1440x1000 desktop and 390x844 mobile. Open/Escape/close, focus restoration, inert state, final sidebar position, no document horizontal overflow. |
| Dark/light theme | Passed | Both themes at desktop/mobile sizes, dark state retained after reload. |
| History/configuration/diff | Passed | Fixture requests returned 200; both diff panes displayed their respective old/new contents. No browser JavaScript page errors. |

## Runtime setup and corrections

With user approval, installed RubyInstaller 3.2.11 and its MSYS2 toolkit outside the repository, then installed project gems. Native build prerequisites were ICU, libyaml, and CMake; toolkit-local ICU import-library aliases accommodate charlock_holmes' Unix library names. No production source, credentials, or global PATH configuration was changed. Gemfile.lock and coverage output remain ignored.

The first Ruby test run found four duplicate Mocha fixture expectations and an assertion that required expanded HTML boolean attributes. Changed the default list fixture to a stub and accepted both valid selected-attribute forms. RuboCop found one method-chain indentation offense; it was corrected. The subsequent full suites passed as recorded above.

## Reproducing browser verification

The optional fixture and browser check are retained under `.cortex/verification/`. In an environment with the project's Ruby bundle, Chrome, Node, and Playwright available:

1. Run `bundle exec ruby .cortex/verification/browser_fixture.rb` from the repository root.
2. Run `node .cortex/verification/browser-check.cjs` in another terminal. If Playwright is not in normal Node module resolution, set PLAYWRIGHT_MODULE to its installed module path for this process.
3. Stop the fixture server after testing.

Five screenshots are saved under `docs/redesign/screenshots/`: inventory desktop/mobile in light/dark themes, plus desktop diff. Screenshots use synthetic device names, addresses, and configurations.

## Independent audit and limits

The independent Cortex fallback audit reviewed the test changes and runtime evidence. This is a synthetic application regression run, not a test of device connectivity, production storage, or other browser engines. No claim of live backup execution is made.

The documentation-claim validator previously found one existing placeholder-path issue in docs/development.md; the final validation result is recorded in REVIEW-RESULTS.md.

