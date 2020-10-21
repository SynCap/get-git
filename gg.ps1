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
	$DeepCopy,

	[int]
	$MaxReadmes = 5,
	[int]
	$MaxReadmeSearchDepth = 1
)

################## Constants

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
	$CYN_RED="`e[1;96;41m"
	$WHT_RED="`e[1;37;41m"

################## Global Vars

	$NewDir = ($DestDir ? $DestDir : $Url.Split('/')[-1].Split('.')[0])
	$HrLength = [Math]::Min( $Host.UI.RawUI.WindowSize.Width, $GitRunCmd.Length )

###################################### Banner (Logo)

"$GRN`nGet the Git $DEF[repo]$GRN (Powershell version)"
"©2018-2020, CLosk`n"

###################################### Functions

function Show-Usage {
	"Clone Git project to specified dir in shallow manner,"
	"then show README files, then install NPMs, and start it"
	"if you're ask for that. Whants to be a friend for JS people :)"

	"`nUsage: $YLW$((Get-Item $PSCommandPath).Basename)$WHT <git_repo_url>$GRN [dest_dir] [options]"

	"`nSamples of valid$wht git_repo_url$($grn)s and source code repository:`n"

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
	if ( Test-Path -LiteralPath "$NewDir" ) {
		"$YLW_RED Warning! $WHT_RED Folder $CYN_RED$NewDir$WHT_RED exists $RST"
		$ConfirmEarse = read-host "Are you sure you whant to erase existing folder? [$($YLW)y$RST/N]"
		if ($ConfirmEarse -like 'y') {
			rmr $NewDir
		} else {
			$RST
			exit -1
		}
	}

	"`n$RED■$YLW_ $NewDir $RED■$RST"
	draw (hr '■') DarkYellow
	$RST

	$GitPath = (Get-Command git).Source
	$GitRunParams = @(
		"clone"
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
	draw (hr `'),`n DarkYellow

	$readmeFiles = ls "readme*" -Recurse -Depth $MaxReadmeSearchDepth | select FullName -First $MaxReadmes
	$readmeFiles | % {
		draw $_.FullName,`n DarkCyan;
		# & $_.FullName
	}

	draw (hr `'),`n DarkYellow
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

if ( Test-Path -LiteralPath "$NewDir" ) {
	"Change dir to $WHT$NewDir$RST"
	pushd $NewDir
	Show-GitLog
	Open-Readmes
}

$RST
