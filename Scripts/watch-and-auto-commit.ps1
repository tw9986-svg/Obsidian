$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$quietPeriodSeconds = 10
$pollSeconds = 2
$lastChangeAt = $null

Write-Host "Watching $repoRoot for Research changes. Press Ctrl+C to stop."

while ($true) {
    $status = @(git -C $repoRoot status --porcelain)
    $relevantStatus = @($status | Where-Object {
        $_ -and $_ -notmatch "^\s*[MADRCU?!]{1,2}\s+\.obsidian/workspace\.json$"
    })

    if ($relevantStatus.Count -gt 0) {
        if ($null -eq $lastChangeAt) {
            $lastChangeAt = Get-Date
        }

        $elapsed = ((Get-Date) - $lastChangeAt).TotalSeconds
        if ($elapsed -ge $quietPeriodSeconds) {
            & powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "auto-commit.ps1")
            if ($LASTEXITCODE -ne 0) {
                throw "Automatic commit failed with exit code $LASTEXITCODE."
            }
            $lastChangeAt = $null
        }
    }
    else {
        $lastChangeAt = $null
    }

    Start-Sleep -Seconds $pollSeconds
}
