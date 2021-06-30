# Get the Git [repository]

Clone remote Git project to specified dir in shallow manner,
then show README files, then install NPMs, and start it
if you're ask for that. Whants to be a friend for JS people :)

## Usage

  gg <Git_Repo_Url> [Dest_Dir] [Options]


1. URL must be placed before destination dir name
2. Dest_Dir name may be omitted
3. The placements of the other switches does not matter


Samples of valid git_repo_urls and source code links:

  https://github.com/SynCap/get-git.git
  git@github.com:SynCap/get-git.git

## Options for Powershell version

  `-InstallPackages`,
  `-i`  install NPMs if `package.json` exists

  `-RunScript`, `-Run`,
  `-r`  run npm run command if it present in `package.json`
      you may launch several commands sequentally: `-Run` `build,start`

  `-PackageManager`,
  `-m`  specify package manager to use: **yarn**, **npm**

  `-EraseExisting`,
  `-e` Erase target folder if exists

  `-Readme`, `-ShowReadme`, `-About`,
  `-a` **README** files will be launched otherway only search for them

  `-DeepCopy`,
  `-d` DEEP copy, i.e. no --depth=1 param when clone

  `-MaxReadmes`
      Maximum number of **README** files to be searched for and opened

  `-MaxReadmeSearchDepth`
      How deep to dig into directory structure when search for
      **README** files

## Options for BASH version

    -i  install NPMs if package.json exists
    -y  install NPMs with Yarn if package.json exists
    -s  run npm start command if it present in package.json
    -r  run yarn start command if it present in package.json
    -d  DEEP copy, i.e. no --depth=1 param

## Example

```powershell
gg https://github.com/SynCap/get-git.git -ShowReadme `
  '~Get The GIT' -e -i -r test,build -m npm
```
