Param (
	[Parameter (Position=0)]
	[ValidateNotNullOrEmpty()]
	[string]
	$Url,

	[Parameter(Position=1)]
	[string]
	$DestDir,

	[Alias("i")]
	[Switch]
	$InstallNPM,
	[Alias("y")]
	[Switch]
	$InstallYarn,

	[Alias("s")]
	[string]
	$RunNpmStart,
	[Alias("r")]
	[string]
	$RunYarnStart,

	[Alias("h")]
	[string]
	$Help,

	[Alias("d")]
	[Switch]
	$DeepCopy
)

# $E=""
$E="`e"

$RST="$E[0m"
$DEF="`e[37;40m"

$RED="$E[31;40m"
$GRN="$E[32;40m"
$YLW="$E[33;40m"
$BLU="$E[34;40m"
$PPL="$E[35;40m"
$CYN="$E[36;40m"
$WHT="$E[97;40m"

$RED_="$E[1;31;40m"
$GRN_="$E[1;32;40m"
$YLW_="$E[1;33;40m"

$YLW_RED="$E[1;33;41m"
$WHT_RED="$E[1;37;41m"

"`nGet the Git [repo] (Powershell version)"
'©2018-2020, CLosk'

# https://github.com/SynCap/num-ranges-js.git
# git@github.com:SynCap/num-ranges-js.git
# cat "c:\Program Files\ConEmu\ConEmu\Addons\AnsiColors16t.ans"

function Show-Usage {
	echo "`nClone Git project to specified dir in shallow manner,"
	echo "then show README, then install NPMs and start it if any.\n"
	echo "`nUsage: $YLW$((Get-Item $PSCommandPath).Basename)$WHT <git_repo_url>$GRN [dest_dir] [options]"
	echo "Options:"
	echo "  -i  install NPMs if$WHT package.json$GRN exists"
	echo "  -y  install NPMs with$YLW Yarn$GRN if$WHT package.json$GRN exists"
	echo "  -s  run$WHT npm start$GRN command if it present in$YLW package.json$GRN"
	echo "  -r  run$YLW yarn$WHT start$GRN command if it present in$YLW package.json$GRN"
	echo '  -d  '$WHT'DEEP'$GRN" copy, i.e. no $YLW--depth=1$GRN param $RST"

	Return
}

Show-Usage
