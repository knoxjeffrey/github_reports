# GitHub Reports

A skeleton application for building custom reports with the GitHub API.

## Requirements

A working Ruby 2.1.5 installation. If you are using a different version of Ruby, update Gemfile accordingly.

## Getting Started

Fork this repository and clone it into your development environment.
Run bundle to install all dependencies.
You should be able to run the following commands:

`bin/reports` to run the program code. It should print out something like this:

```
$ bin/reports
Commands:
  reports activity USERNAME      # Summarize the activity of GitHub user USERNAME
  reports console                # Open an RB session with all dependencies loaded.
  reports help [COMMAND]         # Describe available commands or one specific command
  reports repositories USERNAME  # Load the repo stats for USERNAME
```

You can use `reports help` to get more information on a command:

```
$ bin/reports help repositories
Usage:
  reports repositories USERNAME

Options:
  [--forks], [--no-forks]  # Include forks in repo stats
  [--proxy], [--no-proxy]  # Use an HTTP proxy running at localhost:8080

Load the repo stats for USERNAME
```

`bundle exec rake spec` to run local tests.


&copy; Tealeaf Academy
