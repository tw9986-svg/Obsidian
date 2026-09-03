$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$inbox = Join-Path $repoRoot "00_Inbox"
$stateDirectory = Join-Path $repoRoot ".claude\state"
$statePath = Join-Path $stateDirectory "inbox-ingest.json"
$pollSeconds = 5
$quietPeriodSeconds = 10

if ($null -eq (Get-Command claude.cmd -ErrorAction SilentlyContinue)) {
    throw "Claude Code CLI is not installed or is not available on PATH. Install it before starting the inbox pipeline."
}

New-Item -ItemType Directory -Force -Path $stateDirectory | Out-Null
$processed = @{}
if (Test-Path -LiteralPath $statePath) {
    $saved = Get-Content -LiteralPath $statePath -Raw | ConvertFrom-Json
    $saved.PSObject.Properties | ForEach-Object { $processed[$_.Name] = $_.Value }
}

function Save-State {
    $processed | ConvertTo-Json | Set-Content -LiteralPath $statePath -Encoding UTF8
}

Write-Host "Watching $inbox for files to ingest. Press Ctrl+C to stop."

while ($true) {
    $candidates = Get-ChildItem -LiteralPath $inbox -File -Recurse |
        Where-Object { $_.FullName -notmatch "\\(_duplicates|_nonresearch)\\" } |
        Where-Object { $_.Name -ne "README.md" -and $_.Extension -in @(".md", ".pdf", ".csv", ".py", ".mo", ".zip") }

    foreach ($file in $candidates) {
        $relativePath = $file.FullName.Substring($repoRoot.Length + 1)
        $hash = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash
        if ($processed[$relativePath] -eq $hash) {
            continue
        }

        $age = ((Get-Date) - $file.LastWriteTime).TotalSeconds
        if ($age -lt $quietPeriodSeconds) {
            continue
        }

        $prompt = @"
Process exactly one source with the /wiki-ingest procedure from .claude/skills/wiki-ingest/SKILL.md.
Target file: $relativePath
Read CLAUDE.md first. Preserve 01_Raw files, do not estimate unknown values, update all required Wiki/Data/index/log links, and report UNKNOWN or conflicting values.
"@

        & claude.cmd -p $prompt --allowedTools "Read,Edit,Bash" --output-format json
        if ($LASTEXITCODE -ne 0) {
            throw "Claude Code ingest failed for $relativePath with exit code $LASTEXITCODE."
        }

        $processed[$relativePath] = $hash
        Save-State
    }

    Start-Sleep -Seconds $pollSeconds
}
