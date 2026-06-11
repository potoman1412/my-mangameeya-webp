param(
  [ValidateSet('x64','x86')][string]$Platform = 'x64'
)
$ErrorActionPreference = 'Stop'
$root = Join-Path $PSScriptRoot 'third_party' 
$dest = Join-Path $root 'libwebp'
if (Test-Path $dest) {
    Write-Host "libwebp already present in $dest"
    exit 0
}

New-Item -ItemType Directory -Force -Path $dest | Out-Null

# Map platform to a release zip URL. If URL becomes invalid, edit this script.
$ver = '1.3.1'
if ($Platform -eq 'x64') {
    $zipUrl = "https://storage.googleapis.com/downloads.webmproject.org/releases/webp/libwebp-$ver-windows-x64.zip"
} else {
    $zipUrl = "https://storage.googleapis.com/downloads.webmproject.org/releases/webp/libwebp-$ver-windows-x86.zip"
}

$zipPath = Join-Path $env:TEMP ("libwebp-$ver-$Platform.zip")
Write-Host "Downloading libwebp from $zipUrl ..."
try {
    Invoke-WebRequest -Uri $zipUrl -OutFile $zipPath -UseBasicParsing -ErrorAction Stop
} catch {
    Write-Error "Failed to download $zipUrl. Please download libwebp manually and place it under third_party\libwebp"
    exit 1
}

Write-Host "Extracting to $dest ..."
try {
    Expand-Archive -Path $zipPath -DestinationPath $dest -Force
} catch {
    Write-Error "Failed to extract archive. You may need to extract manually."
    exit 1
}

Write-Host "libwebp fetched and extracted to $dest"
exit 0
