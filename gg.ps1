Param (
	[Parameter (Position=0)]
	[ValidateNotNullOrEmpty()]
	[ValidatePattern("^(git@|https:).*\.git/?$")]
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
	[Switch]
	$RunNpmStart,
	[Alias("r")]
	[Switch]
	$RunYarnStart,

	[Alias("h","help")]
	[Switch]
	$ShowUsage=$false,

	[Alias("d")]
	[Switch]
	$DeepCopy
)

$RST="`e[0m"
$DEF="`e[37;40m"

$RED="`e[31;40m"
$GRN="`e[32;40m"
$YLW="`e[33;40m"
$BLU="`e[34;40m"
$PPL="`e[35;40m"
$CYN="`e[36;40m"
$WHT="`e[97;40m"

$RED_="`e[1;31;40m"
$GRN_="`e[1;32;40m"
$YLW_="`e[1;33;40m"

$YLW_RED="`e[1;33;41m"
$WHT_RED="`e[1;37;41m"

$NewDir = ($DestDir ? $DestDir : $Url.Split('/')[-1].Split('.')[0])
$HrLength = [Math]::Min( (Get-Host).UI.RawUI.WindowSize.Width, $GitRunCmd.Length )

###################################### Banner (Logo)

"$rst`nGet the Git $GRN[repo]$DEF (Powershell version)"
"©2018-2020, CLosk`n"

###################################### Functions

function Show-Usage {
	"Clone Git project to specified dir in shallow manner,"
	"then show README, then install NPMs, and start it"
	"if you're ask for that."

	"`nUsage: $YLW$((Get-Item $PSCommandPath).Basename)$WHT <git_repo_url>$GRN [dest_dir] [options]"

	"`nSamples of valid$wht git_repo_url$($def)s and source code repository:`n"

	"  https://github.com/SynCap/get-git.git"
	"  git@github.com:SynCap/get-git.git"

	"`nOptions:"
	"  -i  install NPMs if$WHT package.json$GRN exists"
	"  -y  install NPMs with$YLW Yarn$GRN if$WHT package.json$GRN exists"
	"  -s  run$WHT npm start$GRN command if it present in$YLW package.json$GRN"
	"  -r  run$YLW yarn$WHT start$GRN command if it present in$YLW package.json$GRN"
	"  -d $WHT DEEP$GRN copy, i.e. no$YLW --depth=1$GRN param $RST`n"
}

function Clone-Repo {

	# !!!! ###########################
	rmr $NewDir

	"`n$RED■$YLW_ $NewDir $RED■$RST"
	draw (hr '■') DarkYellow
	$RST

	$GitPath = (Get-Command git).Source
	$GitRunParams = @(
		"clone",
		"--verbose",
		"--progress"
	)
	if (!$DeepCopy) {
		$GitRunParams += '--depth=1'
	}
	$GitRunParams += '--'
	$GitRunParams += $Url

	if ($DestDir) {
		$GitRunParams += $DestDir -Match ' ' ?
			"`"$DestDir`"" :
			$DestDir
	}

	$GitRunCmd = $GitPath,($GitRunParams -join ' ') -join ' '
	$GitRunCmd
	draw (hr `' $HrLength),`n DarkYellow

	& $GitPath $GitRunParams

	draw (hr `' $HrLength),`n DarkYellow
}

function Open-Readmes {
	"`n$RED■$YLW_ README files $RED■$RST"
	draw (hr `' 16),`n

	$readmeFiles = ls "readme*" -Recurse -Depth 1 | select FullName -First 5
	$readmeFiles | % {
		draw $_.FullName,`n DarkCyan;
		# & $_.FullName
	}

	draw (hr `' 16),`n
}

function Show-GitLog {
	git log --graph "--date=format:%d.%m.%Y %H:%M:%S" "--pretty=format:%C(auto)%h%d %C(bold blue)%an %Cgreen%ad  %Creset%s" *
}

################################### MAIN

if (!$URL -and $ShowUsage) {
	Show-Usage
}

if (!$Url) {
	Return
}

Clone-Repo

if (
	Test-Path -LiteralPath "$NewDir"
) {
	"Change dir to $WHT$NewDir$RST"
	pushd $NewDir
	Show-GitLog
	Open-Readmes
}

$RST
