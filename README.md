# Get the Git [repository]

Lite tool to quick get the remote git repository with blackjack and package.json dancers.

Clone Git project to specified dir in shallow manner,
then show README, then install NPMs and start it if any.\n

Usage: gg <git_repo_url> [dest_dir] [options]

```
  Options:
    -i  install NPMs if package.json exists
    -y  install NPMs with Yarn if package.json exists
    -s  run npm start command if it present in package.json
    -r  run yarn start command if it present in package.json
    -d  DEEP copy, i.e. no --depth=1 param
```
