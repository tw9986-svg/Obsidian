$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$status = git -C $repoRoot status --porcelain

if ([string]::IsNullOrWhiteSpace(($status -join "`n"))) {
    exit 0
}

git -C $repoRoot add -A

$staged = git -C $repoRoot diff --cached --name-only
if ([string]::IsNullOrWhiteSpace(($staged -join "`n"))) {
    exit 0
}

$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$message = "Auto-commit Research changes ($timestamp)"
git -C $repoRoot commit -m $message -m "Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
git -C $repoRoot push origin main
