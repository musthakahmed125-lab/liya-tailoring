$projectPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$pendingChange = $false

$gitExe = $null
$gitCandidates = @(
    'C:\Program Files\Git\cmd\git.exe',
    'C:\Program Files\Git\bin\git.exe'
)

foreach ($candidate in $gitCandidates) {
    if (Test-Path $candidate) {
        $gitExe = $candidate
        break
    }
}

if (-not $gitExe) {
    try {
        $gitExe = (Get-Command git -ErrorAction Stop).Source
    }
    catch {
        throw "Git is not installed or not available on PATH. Please install Git for Windows and restart VS Code."
    }
}

function Sync-Changes {
    Set-Location $projectPath

    $changes = & $gitExe status --porcelain
    if (-not $changes) {
        return
    }

    & $gitExe add --all
    $commitMessage = "Auto-sync website changes $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
    & $gitExe commit -m $commitMessage
    if ($LASTEXITCODE -eq 0) {
        & $gitExe push origin main
    }
}

# Sync changes that existed before the watcher started.
Sync-Changes

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