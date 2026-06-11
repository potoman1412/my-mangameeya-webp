param(
  [ValidateSet('x64','x86')][string]$Platform = 'x64',
  [ValidateSet('Release','Debug')][string]$Configuration = 'Release'
)
$ErrorActionPreference = 'Stop'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Write-Host "Fetching libwebp (if needed) for $Platform"
& powershell -ExecutionPolicy Bypass -File (Join-Path $scriptDir 'fetch_libwebp.ps1') -Platform $Platform

# Determine MSBuild platform name
if ($Platform -eq 'x64') { $msPlat = 'x64' } else { $msPlat = 'Win32' }

Write-Host "Running msbuild webp_dll.vcxproj ($Configuration|$msPlat)"
$msbuild = 'msbuild'
$proj = Join-Path $scriptDir 'webp_dll.vcxproj'
$arguments = "$proj /p:Configuration=$Configuration;Platform=$msPlat"
$proc = Start-Process -FilePath $msbuild -ArgumentList $arguments -NoNewWindow -Wait -PassThru
if ($proc.ExitCode -ne 0) { throw "msbuild failed with exit code $($proc.ExitCode)" }
Write-Host "Build finished. See project output folder for webp.dll"
