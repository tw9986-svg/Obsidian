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
    contents = @(
        @{
            role = "user"
            parts = @(@{ text = $prompt })
        }
    )
    generationConfig = @{
        temperature = 0.1
        responseMimeType = "text/plain"
    }
} | ConvertTo-Json -Depth 10

$uri = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$apiKey"
$response = Invoke-RestMethod -Method Post -Uri $uri -ContentType "application/json; charset=utf-8" -Body $body
$guidance = $response.candidates[0].content.parts[0].text
if ([string]::IsNullOrWhiteSpace($guidance)) {
    throw "Gemini returned an empty guidance document."
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
