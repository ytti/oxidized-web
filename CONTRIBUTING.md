# oxidized-web - Contributing Guide
You can contribute to [oxidized-web](https://github.com/ytti/oxidized-web/) in
many ways. First of all, we'd like to thank you for taking the time to improve
this project!

oxidized-web is the web user interface and RESTful API of
[Oxidized](https://github.com/ytti/oxidized/). It is maintained by the same
people, so the
[Oxidized Contributing Guide](https://github.com/ytti/oxidized/blob/master/CONTRIBUTING.md)
applies too, in particular if you want to help as a maintainer.

> ## Legal Notice
> When submitting content to this project, you must agree that you have authored 100%
> of the content, that you have the necessary rights to the content and that the
> content you contribute may be provided under the project license.
>
> If you are employed, you probably need the permission from your employer to
> contribute to open source projects.


## Contribute as a user
A great place for users to get involved is the
[GitHub issues](https://github.com/ytti/oxidized-web/issues). Through the
issues, you can interact with maintainers and other users. You can open an issue
if you need help, but you can also help other users by reviewing their issues
and commenting on them.

Before writing an issue, please read the Oxidized documentation on
[how to write good issues](https://github.com/ytti/oxidized/blob/master/docs/Issues.md).


## How to contribute content
Content can be code, but also documentation and other things. Contributions are
submitted through pull requests on GitHub.

### Using AI coding agents
Using AI coding assistants (Copilot, Claude, ChatGPT, ...) to help write your
contribution is fine. But whatever tool you use, **you remain the
author and are responsible for the code you submit**:

* A human must read, understand and be able to explain every line before it is
  submitted. If you don't understand what the code does, do not submit it.
* Test your contribution and make sure it actually works (see
  [Run tests](#run-tests)). Agents happily produce plausible-looking code that
  does not work.
* Keep the change focused and minimal — agents tend to add unrelated
  "improvements", verbose comments and dead code. Clean this up before opening
  a pull request.

Please do not open pull requests containing raw, unreviewed agent output.
oxidized-web is maintained by only a few volunteers, and every pull request is
reviewed carefully by a human. Reviewing code that the author has not read or
understood themselves is a lot of work and rather thankless — it shifts the
effort of understanding the change onto the maintainers. Respect their time by
submitting code you have genuinely reviewed and stand behind.

If you use an agent, the repository provides [AGENTS.md](AGENTS.md) with project
conventions the agent should follow.

### Fork and clone the repository
Fork this repository to your GitHub account by clicking the "Fork" button at
the top right, and clone your fork:
```bash
git clone git@github.com:YOUR_GITHUB_USERNAME/oxidized-web.git
cd oxidized-web
```

Create a new branch for your contribution. If your contribution refers to an
issue, you may prepend the number of the issue to the branch name.
```bash
git checkout -b 1234-your-branch-name
```

### Create a Ruby bundle
You need [Bundler](https://bundler.io/) to install Ruby dependencies locally.
On Debian, you can install it with `sudo apt install ruby-bundler`.

```bash
bundle config set --local path 'vendor/bundle'
bundle install
```

### Run your code
oxidized-web depends on oxidized, so the bundle includes oxidized and you can
run it with oxidized-web from git:
```bash
bundle exec oxidized
```

If you don't want to use the configuration under `~/.config/oxidized/`, set the
path to your configuration with the environment variable `OXIDIZED_HOME`.

See [docs/development.md](docs/development.md) for more details, for example
how to develop oxidized and oxidized-web in parallel, or how to update the web
libraries.

### Code like a Ruby professional
RuboCop will help you follow our coding conventions (which are Ruby coding
conventions).
```bash
bundle exec rubocop
```

### Run tests
oxidized-web has integrated tests, that should be run before submitting your
work. Please add or adapt tests for your changes.
```bash
bundle exec rake test
```

When you change the web interface, test it in a browser and keep an eye on the
JavaScript console for errors.

### Document your changes
Update the documentation in [docs/](docs/) if needed, and add user-visible
changes to [CHANGELOG.md](CHANGELOG.md) under `[Unreleased]`.

### Commit and push your work
The commits will be seen in the pull request, so be concise and remember that
someone will try to understand what you have done.
```bash
git add <changed files here>
git commit
git push -u origin 1234-your-branch-name
```

### Open a pull request
Go to your GitHub repository. GitHub will offer to create a pull request and
guide you through the process.

If something is not as it should be, a maintainer will probably ask you to
change it when reviewing the pull request. Don't be shy, submit your code ;-)

Note: if the GitHub CI checks fail on your pull request, fix the problems.
A pull request with failed CI checks won't be merged, so maintainers may only
review pull requests that have passed CI.

## One last word
Have fun, and don't forget to congratulate yourself for your great contribution
to [oxidized-web](https://github.com/ytti/oxidized-web/)!
