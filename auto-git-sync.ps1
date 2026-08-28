$projectPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$trackedFiles = @('index.html', 'style.css', 'script.js')
$pendingChange = $false

function Sync-Changes {
    Set-Location $projectPath

    $changes = git status --short -- $trackedFiles
    if (-not $changes) {
        return
    }

    git add -- $trackedFiles
    $commitMessage = "Auto-sync website changes $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
    git commit -m $commitMessage
    if ($LASTEXITCODE -eq 0) {
        git push origin main
    }
}

$watcher = New-Object IO.FileSystemWatcher
$watcher.Path = $projectPath
$watcher.Filter = '*.*'
$watcher.IncludeSubdirectories = $false
$watcher.EnableRaisingEvents = $true

$action = {
    $script:pendingChange = $true
}

$createdSubscription = Register-ObjectEvent $watcher Created -Action $action
$changedSubscription = Register-ObjectEvent $watcher Changed -Action $action
$renamedSubscription = Register-ObjectEvent $watcher Renamed -Action $action

Write-Host 'GitHub auto-sync is running. Press Ctrl+C to stop.'
try {
    while ($true) {
        if ($pendingChange) {
            $pendingChange = $false
            Start-Sleep -Milliseconds 800
            Sync-Changes
        }
        Wait-Event -Timeout 2 | Out-Null
    }
}
finally {
    Unregister-Event -SourceIdentifier $createdSubscription.Name -ErrorAction SilentlyContinue
    Unregister-Event -SourceIdentifier $changedSubscription.Name -ErrorAction SilentlyContinue
    Unregister-Event -SourceIdentifier $renamedSubscription.Name -ErrorAction SilentlyContinue
    $watcher.Dispose()
}