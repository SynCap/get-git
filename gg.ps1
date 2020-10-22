Param (
	[Parameter (Position=0)]
	[ValidateNotNullOrEmpty()]
	[ValidatePattern("^(git@|https:).*\.git/?$")]
	[Alias('Source')]
	[string]
	$Url,

	[Alias('Dest','o')]
	[Parameter(Position=1)]
	[string]
	$DestDir,

	[Alias('i')]
	[Switch]
	$InstallPackages,

	[Alias('r','Run','Script')]
	[String[]]
	$RunScripts,

	[Alias('m','Mgr')]
    [ValidateSet('Yarn','NPM')]
    [String]
	$PackageManager = "yarn",

	[Alias('h','help')]
	[Switch]
	$ShowUsage=$false,

	[Alias('e','Clean')]
	[Switch]
	$EraseExisting = $false,

	[Alias('n')]
	[Switch]
	$NoReadme=$false,

	[Alias('d')]
	[Switch]
	$DeepCopy,

	[int]
	$MaxReadmes = 5,
	[int]
	$MaxReadmeSearchDepth = 1
)

################## Color Constants

	$RST="`e[0m"
	$DEF="`e[37;40m"

	$RED="`e[31;40m"
	$GRN="`e[32;40m"
	$YLW="`e[33;40m"
	$BLU="`e[34;40m"
	$PPL="`e[35;40m"
	$CYN="`e[36;40m"
	$WHT="`e[97;40m"
	$DGY="`e[90;40m"

	$RED_="`e[1;31;40m"
	$GRN_="`e[1;32;40m"
	$YLW_="`e[1;33;40m"
	$CYN_="`e[96;40m"

	$YLW_RED="`e[1;33;41m"
	$CYN_RED="`e[1;96;41m"
	$WHT_RED="`e[1;37;41m"

################## Global Vars

	$ggName = $MyInvocation.InvocationName
	$StartDir = (pwd).Path
	$NewDir = ($DestDir ? $DestDir : $Url.Split('/')[-1].Split('.')[0])
	$HrLength = [Math]::Min( $Host.UI.RawUI.WindowSize.Width, $GitRunCmd.Length )

	$IsDebugging = $true

	$Launch = @{
		yarn = @{
			Install = '';
			Run = '{0}';
		};
		npm = @{
			Install = 'install';
			Run = 'run {0}';
		};
	}

###################################### Banner (Logo)

	"$GRN`nGet the Git $DEF[repo]$GRN (Powershell version)"
	"©2018-2020, CLosk`n"

###################################### Functions

function Finish ([int]$ExitCode = 0) {

	################################### DEBUG


	################################### Real FINISH

	cd $StartDir
	$RST
	Exit $ExitCode
}

function Show-Usage {
	"$GRN`nClone remote Git project to specified dir in shallow manner,"
	"then show$YLW README$GRN files, then install$YLW NPMs$GRN, and start it"
	"if you're ask for that. Whants to be a friend for JS people$YLW_ :)$GRN"

	"`nUsage: $YLW$((Get-Item $PSCommandPath).Basename)$WHT <git_repo_url>$GRN [dest_dir] [options]"

	"`nSamples of valid$WHT git_repo_url$($GRN)s and source code links:`n"

	"  https://github.com/SynCap/get-git.git"
	"  git@github.com:SynCap/get-git.git"

	"`nOptions:"

	"`n  -InstallPackages,"
	"  -i  install NPMs if$WHT package.json$GRN exists"

	"`n  -RunScript, -Run,"
	"  -r  run$YLW npm run$WHT command$GRN if it present in$YLW package.json$GRN"
	"      you may launch several commands sequentally:$YLW -Run build,start$grn"

	"`n  -PackageManager,"
	"  -m  specify package manager to use:$WHT yarn$grn,$wht npm$grn"

	"`n  -EraseExisting,"
	"  -e $wht Erase$GRN target folder if exists"
	"`n  -NoReadme,"
	"  -n $wht NO README$GRN will be shown but found"

	"`n  -DeepCopy,"
	"  -d $WHT DEEP$GRN copy, i.e. no$YLW --depth=1$GRN param $RST`n"

	# "$WHT! NOTE !$GRN For processing$YLW package.json$GRN file$WHT jq$GRN utility being used."
	# "Look for it at$YLW https://stedolan.github.io/jq"

	"$YLW`nExample:$CYN"
	"$WHT  $ggName$CYN_ https://github.com/SynCap/get-git.git$wht -NoReadme$CYN '~Get The GIT'$wht -e -i -r$dgy dev$wht -m$dgy yarn$RST`n"

	"$YLW  1.$GRN URL must be placed before destination dir name"
	"$YLW  2.$GRN New dir name may be omitted"
	"$YLW  3.$GRN The placements of the other switches does not matter$RST"
}

function ConfirmEraseDest {
	$ask = "$YLW_RED Warning! $WHT_RED Folder $CYN_RED$NewDir$WHT_RED seems alive! `n$RST"
	$ask += "Are you sure you whant to erase existing folder? [$($YLW)y$RST/N]"
	Return [bool]( (read-host $ask) -eq 'y' )
}

function Check-DestDir {
	if ( Test-Path -LiteralPath "$NewDir" ) {
		if ($EraseExisting -or $( ConfirmEraseDest)) {
			rmr $NewDir
		} else {
			"User requested Exit"
			Finish -1
		}
	}
}

function Clone-Repo {
	"`n$RED■$YLW_ $NewDir$RST"
	draw (hr `') DarkYellow
	$RST

	# Collect all params to launch clone job
	$GitPath = 'git' # (Get-Command git).Source
	$GitRunParams = @(
		"clone",
		"-c core.symlinks=true"
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

	# Just shows command line as how it may composed manually
	$GitRunCmd = $GitPath,($GitRunParams -join ' ') -join ' '
	"$GitRunCmd`n"

	# Really launches the cloning
	& $GitPath $GitRunParams

	draw (hr `' $HrLength),`n DarkYellow
}

function Open-Readmes {
	"`n$RED■$YLW_ README files$RST"

	$readmeFiles = Get-ChildItem "readme*" -Recurse -Depth $MaxReadmeSearchDepth | select FullName -First $MaxReadmes
	$readmeFiles | % {
		draw $_.FullName,`n DarkCyan;
		if (!$NoReadme) {
			& $_.FullName
		}
	}

	draw (hr `'),`n DarkYellow
}

function Show-GitLog {

	git log --graph "--date=format:%d.%m.%Y %H:%M:%S" "--pretty=format:%C(auto)%h%d %C(bold blue)%an %Cgreen%ad  %Creset%s" *
}

################################### MAIN


if (!$Url) {
	if ($ShowUsage) {
		Show-Usage
	} else {
		"To get informed about the launch parameters please use:"
		"$wht> $ggName$dgy -Help$grn"
		"    or"
		"$wht> Get-Help$dgy $ggName$def`n"
	}
	Finish 1
}

# Check-DestDir
# Clone-Repo

if ( Test-Path -LiteralPath "$NewDir" ) {
	"Change dir to $WHT$NewDir$RST"
	pushd $NewDir
	Show-GitLog
	Open-Readmes

	if (Test-Path -LiteralPath 'package.json') {
		"Found$YLW package.json$RST"
	}
}

if (Test-Path 'package.json') {

	if ($InstallPackages) {
		"Asked for install"
		"Command line to be launched: $PackageManager $($Launch[$PackageManager].Install)"
		# & $PackageManager $($Launch[$PackageManager].Install)
	}

	if ($RunScripts.Count) {
		"Ordered to launch the $ scripts."

		$s = (Get-Content 'package.json' | ConvertFrom-Json).scripts

		$RunScripts.ForEach({
			echo "& $PackageManager $($Launch[$PackageManager].Run -f $_)"
			})
	}
}

################################### That's All Folsk!

Finish
