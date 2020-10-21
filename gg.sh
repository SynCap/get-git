#!/bin/bash

# Shallow clone the Git repository to specified folder and launch showing
# README files. Optimized to use under Windows
#
# Optionally:
# - Deep clone
# - install NPM depedancy with NPM or Yarn
# - launch `start` script from `package.json`
#
# (C)2015-2019, Constantin Losk (SynCap)
#
# Licence: MIT

set +v # I forgot what this is, but it's important

RST="\E[0m"

RED="\E[31;40m"
GRN="\E[32;40m"
YLW="\E[33;40m"
BLU="\E[34;40m"
PPL="\E[35;40m"
CYN="\E[36;40m"
WHT="\E[37;40m"

RED_="\E[1;31;40m"
GRN_="\E[1;32;40m"
YLW_="\E[1;33;40m"

YLW_RED="\E[1;33;41m"
WHT_RED="\E[1;37;41m"

# alias echo='echo -e'

SOURCE="$1"
TARGET="$2"
# README='README.MD'

# check params: if no params
if [[ $# -lt 1 ]];then
	echo -e $GRN
	echo -e "Get the Git [repo] (BASH version)"
	echo -e "(c)2018-2019,$YLW CLosk$GRN\n"
	echo -e "Clone Git project to specified dir in shallow manner,"
	echo -e "then show README, then install NPMs and start it if any.\n"
	echo -e "Usage: $0 <git_repo> [dest_dir] [options]"
	echo -e "\n    Options:"
	echo -e "        -i    install NPMs if$WHT package.json$GRN exists"
	echo -e "        -y    install NPMs with$YLW Yarn$GRN if$WHT package.json$GRN exists"
	echo -e "        -s    run$WHT npm start$GRN command if it present in$YLW package.json$GRN"
	echo -e "        -r    run$YLW yarn$WHT start$GRN command if it present in$YLW package.json$GRN"
	echo -e '        -d    '$WHT'DEEP'$GRN" copy, i.e. no $YLW--depth=1$GRN param"
	echo -e $RST
	exit;
fi

# check params: if $2 is ommitted or it is a switch - take the dest dir name as `git clone` do
if [[ -z "$2" ]] || [[ ${2:0:1} == "-" ]];then
	DNAME="${SOURCE##*/}"
	TARGET="${DNAME%.git}"
fi

# check params:  search for switches
while [[ $# -gt 0 ]];
do
	opt="$1";
	shift; #expose next argument
	if [[ ${opt:0:1} == "-" ]];then
		case "$opt" in
			"-i") INSTALL='yes';;
			"-y") YARNINI='yes';;
			"-s") STARTUP='yes';;
			"-D") DEEPCPY='yes';;
		esac
	fi
done

echo -e $GRN_
echo -e "$RED■$YLW" $TARGET "$RED■"
echo -e "$YLW■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■"
# echo -e "$YLW──────────────────────────────────────────────────────────────────────────────"
echo -e "$GRN"


GIT_CMD='git clone'
if [ -z $DEEPCPY ];then
	GIT_CMD=$GIT_CMD' --depth 1'
fi

# This is IT!!
GIT_RUN_CMD="$GIT_CMD $SOURCE $TARGET"
echo -e $CYN'Command: '$GRN_$GIT_RUN_CMD$RST
$GIT_RUN_CMD

echo -e "\n"$CYN"PushD: "$GRN$(pushd "$TARGET")$RST

CMD_WIN_START='start' # cmd //c start "${@//&/^&}"

if [[ $OS == 'Windows_NT' ]];then CMD_SHOW_README=$CMD_WIN_START;else CMD_SHOW_README='less'; fi

README_SRCH_PRMS="-maxdepth 2 -type f -iname "readme*" -print"
README_FILES=$(find $TARGET'/' $README_SRCH_PRMS -exec $CMD_SHOW_README {} \;)

if [[ $(echo $README_FILES | wc -w) ]];then
	echo -e $YLW_$README_FILES"\n";
	else echo -e "${YLW_RED} Files ${WHT_RED}README${YLW_RED} not found! ";
fi
echo -e $GRN

pushd $TARGET

PKG_JSON=$TARGET'\package.json'
# `-s` -- проверяем размер > 0,
# а не просто существование `-e`
# можно еще `-r` -- читаемость
if [[ -r $PKG_JSON ]];then

	if [[ .$YARNINI = .'yes' ]];then
		echo -e "${YLW}Installing... $CYN $(pwd)/node_modules$GRN using Yarn"
		yarn
	fi

	if [[ .$INSTALL = .'yes' ]];then
		echo -e "${YLW}Installing... $CYN $(pwd)/node_modules$GRN"
		npm install
	fi

	if [[ .$STARTUP = .'yes' ]];then
		STRT_CMD="$(jq .scripts.start < $PKG_JSON)"
		if [[ $STRT_CMD != "null" ]];then
			echo -e "${YLW} Launching... ${GRN}npm start $CYN$STRT_CMD $GRN"
			npm start
		else
			echo -e "${YLW_RED} Starting script is not specified in $WHT_RED $PKG_JSON $GRN"
		fi
	fi
else
	echo -e " ${WHT_RED}package.json${YLW_RED} not found $GRN"
fi

echo -e "$RST"
