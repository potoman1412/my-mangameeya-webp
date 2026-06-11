param([string]$Path)
if (-not (Test-Path $Path)) { Write-Error "File not found: $Path"; exit 1 }
[byte[]]$data = [System.IO.File]::ReadAllBytes($Path)
$minLen = 4
$current = New-Object System.Text.StringBuilder
$results = @()
for ($i=0;$i -lt $data.Length; $i++) {
    $b = $data[$i]
    if ($b -ge 32 -and $b -lt 127) {
        $current.Append([char]$b) | Out-Null
    } else {
        if ($current.Length -ge $minLen) { $results += $current.ToString() }
        $current.Clear() | Out-Null
    }
}
if ($current.Length -ge $minLen) { $results += $current.ToString() }

# filter candidates that look like function names
$regex = '^[A-Za-z_@\?\$\-][A-Za-z0-9_@\?\$\-]{2,}$'
$unique = $results | Where-Object { $_ -match $regex } | Sort-Object -Unique
$unique | ForEach-Object { Write-Output $_ }
