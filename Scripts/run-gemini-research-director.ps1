$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$apiKey = [Environment]::GetEnvironmentVariable("GEMINI_API_KEY", "User")
if ([string]::IsNullOrWhiteSpace($apiKey)) {
    throw "GEMINI_API_KEY is not set for the current user."
}

$inputFiles = @(
    "CLAUDE.md",
    "index.md",
    "02_Wiki/overview.md",
    "04_Projects/msre-transform-status.md",
    "04_Projects/gemini-research-director.md",
    "03_Data/registry.md"
)

$parts = foreach ($relativePath in $inputFiles) {
    $path = Join-Path $repoRoot $relativePath
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Required Gemini input file is missing: $relativePath"
    }
    "### FILE: $relativePath`n" + (Get-Content -LiteralPath $path -Raw)
}

$prompt = @"
You are Gemini acting only as Research Director for the nuclear thermal-hydraulics knowledge base.
Read the supplied files and produce a Korean Markdown research guidance document.
Do not invent numerical values or citations. Mark unsupported values UNKNOWN.
Do not edit, move, delete, or create any vault file; return guidance text only.

Required sections:
## 우선순위 연구 질문
## 추가로 필요한 문헌
## 수치 검증 항목
## 검증 방법과 합격 기준
## provenance가 UNKNOWN 또는 conflicting인 항목
## GPT 자료 수집 요청
## Claude 편입 요청

For every requested number, include variable, unit, source/page or figure, provenance,
confidence, comparison target, tolerance, and verification status when available.

$($parts -join "`n`n")
"@

$body = @{
    agent = "deep-research-preview-04-2026"
    input = $prompt
    background = $true
    agentConfig = @{
        type = "deep-research"
        thinkingSummaries = "auto"
    }
} | ConvertTo-Json -Depth 10

$createUri = "https://generativelanguage.googleapis.com/v1beta/interactions?key=$apiKey"
$interaction = Invoke-RestMethod -Method Post -Uri $createUri -ContentType "application/json; charset=utf-8" -Body $body
$interactionId = $interaction.id
if ([string]::IsNullOrWhiteSpace($interactionId)) {
    throw "Gemini Deep Research did not return an interaction ID."
}

$guidance = $null
for ($attempt = 1; $attempt -le 60; $attempt++) {
    Start-Sleep -Seconds 10
    $pollUri = "https://generativelanguage.googleapis.com/v1beta/interactions/$interactionId`?key=$apiKey"
    $result = Invoke-RestMethod -Method Get -Uri $pollUri
    if ($result.status -eq "completed") {
        $lastOutput = @($result.outputs) | Select-Object -Last 1
        if ($null -ne $lastOutput.content.text) {
            $guidance = $lastOutput.content.text
        }
        break
    }
    if ($result.status -in @("failed", "cancelled")) {
        throw "Gemini Deep Research ended with status: $($result.status)"
    }
}

if ([string]::IsNullOrWhiteSpace($guidance)) {
    throw "Gemini Deep Research timed out or returned an empty guidance document."
}

$date = Get-Date -Format "yyyy-MM-dd"
$outputPath = Join-Path $repoRoot "04_Projects\gemini-guidance-$date.md"
$header = @"
---
type: gemini-guidance
reactor_system: [msre]
simulation_code: [transform-dymola, mars, sam]
created: $date
source_inputs:
$($inputFiles | ForEach-Object { "  - $_" } | Out-String)
---

"@
Set-Content -LiteralPath $outputPath -Value ($header + $guidance.Trim() + "`n") -Encoding UTF8
Write-Host "Gemini guidance written to $outputPath"
