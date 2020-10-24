Function Register-Watcher {
    param (
        $Path = './',
        $Filter = '*.*',
        [scriptblock]
        $Handler,
        $WatchEvents = @("Created","Changed","Deleted","Renamed")
    )

    $watcher = New-Object IO.FileSystemWatcher $folder, $filter -Property @{
        IncludeSubdirectories = $false
        EnableRaisingEvents = $true
    }

    # $changeAction = [scriptblock]::Create('
    #     # This is the code which will be executed every time a file change is detected
    #     $path = $Event.SourceEventArgs.FullPath
    #     $name = $Event.SourceEventArgs.Name
    #     $changeType = $Event.SourceEventArgs.ChangeType
    #     $timeStamp = $Event.TimeGenerated
    #     Write-Host "The file $name was $changeType at $timeStamp"
    # ')

    foreach ($e in $WatchEvents) {
        Register-ObjectEvent $Watcher -EventName $e -Action $Handler
    }
}

Register-Watcher "."
