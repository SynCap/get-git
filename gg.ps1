<#
.Description

	Clone remote Git project to specified dir in shallow manner (with
	--depth=1), then show README files, then install NPMs, and start it if
	you're ask for that. Whants to be a friend for JS people :)

.Example
	gg -e -i -r test,build -m npm

.Link
	https://github.com/SynCap/get-git.git

#>

[CmdletBinding(SupportsShouldProcess)]

Param (
	# Source repository URL
	[Parameter (Position = 0)]
	[ValidateNotNullOrEmpty()]
	[ValidatePattern("^(git@|https:).*\.git/?$")]
	[Alias('Source')]
	[string] $Url,

	# Destination directory name
	[Alias('Dest', 'Out', 'o')]
	[Parameter(Position = 1)]
	[string] $DestDir,

	# Show usage information, describes parameters and swithches
	[Alias('h', 'Help')]
	[Switch] $ShowUsage,

	# Turn off depth limitations. See `git help clone --depth`
	[Alias('d')]
	[Switch] $DeepCopy,

	# Forcibly erase destination folder if exists. Git itself do not clone project
	# into existing directories
	[Alias('e')]
	[Switch] $EraseExisting,

	# Install node packages if `package.json` file present at the root of newly
	# cloned project
	[Alias('i')]
	[Switch] $InstallPackages,

	# GG automatically opens README files from cloned project. This switch turns
	# off this behovoir
	[Alias('a', 'Readme', 'About')]
	[Switch] $ShowReadme,

	# Specify Node package manager to use for install and/or start the scripts.
	# Yarn specified by default. No checking for installed managers is provided.
	[Alias('m', 'Mgr')]
	[ValidateSet('Yarn', 'NPM')]
	[String] $PackageManager = "yarn",

	# If `package.json` in cloned project and `scripts` are specified in it the
	# GG can launch them. To do this specify all needed to launch scripts in
	# order to be launched.
	[Alias('r', 'Run', 'Script')]
	[String[]] $RunScripts,

	# Some projects can contains tons of README.md, README.txt, and so on. To
	# limit number of files that can be opened this parameter is.
	[int] $MaxReadmes = 3,

	# In some project there a tons of readme in deep subfolders. Often they are
	# not critical for quick start so limiting the depth of searching for README
	# is useful.
	[int] $MaxReadmeSearchDepth = 1
)

################## Color Constants

$RST = "`e[0m"
$DEF = "`e[37m"

$RED = "`e[31m"
$GRN = "`e[32m"
$YLW = "`e[33m"
$BLU = "`e[34m"
$PPL = "`e[35m"
$CYN = "`e[36m"
$WHT = "`e[97m"
$DGY = "`e[90m"

$RED_ = "`e[1;31m"
$GRN_ = "`e[1;32m"
$YLW_ = "`e[1;33m"
$CYN_ = "`e[96m"

$YLW_RED = "`e[1;33;41m"
$CYN_RED = "`e[1;96;41m"
$WHT_RED = "`e[1;37;41m"

################## Global Vars

$ggName = $MyInvocation.InvocationName
$StartDir = $PWD.Path
$NewDir = ($DestDir ? $DestDir : $Url.Split('/')[-1].Split('.')[0])
$HrLength = [Math]::Min( $Host.UI.RawUI.WindowSize.Width, $GitRunCmd.Length )

# $IsDebugging = $true

$Launch = @{
	yarn = @{
		Install = '';
		Run     = '{0}';
	};
	npm  = @{
		Install = 'install';
		Run     = 'run {0}';
	};
}

function hr($Ch = '-', $Cnt = 0 -bor [Console]::WindowWidth / 2) { $Ch * $Cnt }
function println([string[]]$s) { [Console]::WriteLine($s -join '') }

###################################### Banner (Logo)

"$GRN`nGet the Git $DEF[repo]$GRN (Powershell version)"
"©2018-2021, CLosk"
"https://github.com/syncap/get-git`n"

###################################### Functions

function Finish ([int]$ExitCode = 0) {
	################################### DEBUG
	################################### Real FINISH
	# Set-Location $StartDir
	$RST
	Exit $ExitCode
}

function ShowUsage {
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
	"`n  -Readme, -ShowReadme, -About,"
	"  -a $wht NO README$GRN will be shown but found"
	"`n  -DeepCopy,"
	"  -d $WHT DEEP$GRN copy, i.e. no$YLW --depth=1$GRN param $RST`n"
	"$YLW`nExample:$CYN"
	"$WHT  $ggName$CYN_ https://github.com/SynCap/get-git.git$wht -NoReadme$CYN ``"
	"      '~Get The GIT'$wht -e -i -r$dgy test,build$wht -m$dgy npm$RST`n"
	"$YLW  1.$GRN URL must be placed before destination dir name"
	"$YLW  2.$GRN New dir name may be omitted"
	"$YLW  3.$GRN The placements of the other switches does not matter$RST"
}

function hrConfirmEraseDest {
	$ask = "$YLW_RED Warning! $WHT_RED Folder $CYN_RED$NewDir$WHT_RED seems alive! `n$RST"
	$ask += "Are you sure you whant to erase existing folder? [$($YLW)y$RST/N]"
	Return [bool]( (Read-Host $ask) -eq 'y' )
}

function CheckDestDir {
	if ( Test-Path -LiteralPath "$NewDir" ) {
		if ($EraseExisting -or $( ConfirmEraseDest)) {
			rmr $NewDir
		}
		else {
			"User requested Exit"
			Finish -1
		}
	}
}

function CloneRepo {
	"`n$RED■$YLW_ $NewDir$RST"
	println $YLW, (hr `')
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
	$GitRunCmd = $GitPath, ($GitRunParams -join ' ') -join ' '
	"$GitRunCmd`n"
	# Really launches the cloning
	& $GitPath $GitRunParams
	println $YLW, (hr `' $HrLength)
}

function OpenReadmes {
	"`n$RED■$YLW_ README files$RST"
	$readmeFiles = Get-ChildItem "readme*" -Recurse -Depth $MaxReadmeSearchDepth | Select-Object FullName -First $MaxReadmes
	$readmeFiles | ForEach-Object {
		println $CYN, $_.FullName
		if ($ShowReadme) {
			& $_.FullName
		}
	}
	println $YLW, (hr `')
}

function ShowGitLog {
	$dateFormat = '%d.%m.%Y %H:%M:%S'
	$prettyString = '%C(auto)%h%d %C(bold blue)%an %Cgreen%ad  %Creset%s'
	git log --graph "--date=format:$dateFormat" "--pretty=format:$prettyString" *
}

################################### MAIN

if (!$Url) {
	if ($ShowUsage) {
		ShowUsage
	}
 else {
		"To get informed about the launch parameters please use:"
		"$wht> $ggName$dgy -Help$grn"
		"    or"
		"$wht> Get-Help$dgy $ggName$def`n"
	}
	Finish 1
}

CheckDestDir
CloneRepo

if ( Test-Path -LiteralPath "$NewDir" ) {
	"Change dir to $WHT$NewDir$RST"
	Push-Location $NewDir
	ShowGitLog
	OpenReadmes
	if (Test-Path -LiteralPath 'package.json') {
		"Found$YLW package.json$RST"
	}
}

if (Test-Path 'package.json') {
	if ($InstallPackages) {
		"`nInstallation was requested. Prepare:$WHT $PackageManager$YLW $($Launch[$PackageManager].Install)$RST"
		& $PackageManager $($Launch[$PackageManager].Install)
		"$YLW$(hr `')$RST"
	}
	if ($RunScripts.Count) {
		"Ordered to launch the$wht $($RunScripts.Count)$rst scripts."
		$PkgScripts = (Get-Content 'package.json' | ConvertFrom-Json -AsHashtable).scripts
		$RunScripts.ForEach( {
				"`n$RED■$WHT $PackageManager$YLW $($Launch[$PackageManager].Run -f $_)$RST"
				"$YLW$(hr `')$RST"
				if (!$PkgScripts[$_]) {
					"$YLW_RED $_$WHT_RED not found in$YLW_RED package.json $RST"
				}
				else {
					& $PackageManager ($Launch[$PackageManager].Run -f $_).Split(' ')
				}
			})
	}
}

################################### That's All Folsk!

Finish
