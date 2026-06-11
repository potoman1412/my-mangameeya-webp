param([string]$Path)
if (-not (Test-Path $Path)) { Write-Error "File not found: $Path"; exit 1 }
$fs = [System.IO.File]::Open($Path, 'Open', 'Read', 'Read')
$br = New-Object System.IO.BinaryReader($fs)
try {
    $fs.Seek(0, 'Begin') | Out-Null
    $e_magic = $br.ReadUInt16()
    if ($e_magic -ne 0x5A4D) { Write-Error "Not a PE file"; exit 1 }
    $fs.Seek(0x3C, 'Begin') | Out-Null
    $peHeaderOffset = $br.ReadUInt32()
    $fs.Seek($peHeaderOffset, 'Begin') | Out-Null
    $peSig = $br.ReadUInt32()
    if ($peSig -ne 0x4550) { Write-Error "Invalid PE signature"; exit 1 }
    # Skip FileHeader (20 bytes)
    $fs.Seek(20, 'Current') | Out-Null
    $optionalHeaderMagic = $br.ReadUInt16()
    $isPE32Plus = ($optionalHeaderMagic -eq 0x20b)
    # Seek to DataDirectory[0] (Export Table). In Optional Header, DataDirectory starts at offset 96 for PE32, 112 for PE32+
    if ($isPE32Plus) {
        $dataDirOffset = $peHeaderOffset + 24 + 112
    } else {
        $dataDirOffset = $peHeaderOffset + 24 + 96
    }
    $fs.Seek($dataDirOffset, 'Begin') | Out-Null
    $exportRVA = $br.ReadUInt32()
    $exportSize = $br.ReadUInt32()
    if ($exportRVA -eq 0) { Write-Host "No export table"; exit 0 }
    # Read Section Headers to map RVA -> file offset
    $fs.Seek($peHeaderOffset + 6, 'Begin') | Out-Null
    $numSections = $br.ReadUInt16()
    $fs.Seek($peHeaderOffset + 20, 'Begin') | Out-Null
    $sizeOptionalHeader = $br.ReadUInt16()
    $sectionTableOffset = $peHeaderOffset + 24 + $sizeOptionalHeader
    $sections = @()
    $fs.Seek($sectionTableOffset, 'Begin') | Out-Null
    for ($i=0; $i -lt $numSections; $i++) {
        $nameBytes = $br.ReadBytes(8)
        $name = ([System.Text.Encoding]::ASCII.GetString($nameBytes)).Trim([char]0)
        $virtualSize = $br.ReadUInt32()
        $virtualAddress = $br.ReadUInt32()
        $sizeOfRawData = $br.ReadUInt32()
        $pointerToRawData = $br.ReadUInt32()
        # skip the rest of section header (16 bytes)
        $br.ReadBytes(16) | Out-Null
        $sections += @{Name=$name; VA=$virtualAddress; VS=$virtualSize; RawSize=$sizeOfRawData; RawPtr=$pointerToRawData}
    }
    function RvaToOffset($rva) {
        foreach ($s in $sections) {
            if ($rva -ge $s.VA -and $rva -lt ($s.VA + $s.RawSize)) {
                return ($s.RawPtr + ($rva - $s.VA))
            }
        }
        return $null
    }
    $expOffset = RvaToOffset $exportRVA
    if ($expOffset -eq $null) { Write-Error "Cannot map export RVA"; exit 1 }
    $fs.Seek($expOffset, 'Begin') | Out-Null
    $Characteristics = $br.ReadUInt32()
    $TimeDateStamp = $br.ReadUInt32()
    $MajorVersion = $br.ReadUInt16(); $MinorVersion = $br.ReadUInt16()
    $NameRVA = $br.ReadUInt32()
    $OrdinalBase = $br.ReadUInt32()
    $NumberOfFunctions = $br.ReadUInt32()
    $NumberOfNames = $br.ReadUInt32()
    $AddressOfFunctions = $br.ReadUInt32()
    $AddressOfNames = $br.ReadUInt32()
    $AddressOfNameOrdinals = $br.ReadUInt32()
    $names = @()
    for ($i=0; $i -lt $NumberOfNames; $i++) {
        $nameRVAOffset = RvaToOffset ($AddressOfNames + 4 * $i)
        $fs.Seek($nameRVAOffset, 'Begin') | Out-Null
        $nameRVA = $br.ReadUInt32()
        $nameOffset = RvaToOffset $nameRVA
        if ($nameOffset -ne $null) {
            $fs.Seek($nameOffset, 'Begin') | Out-Null
            $sb = New-Object System.Text.StringBuilder
            while ($true) {
                $b = $br.ReadByte()
                if ($b -eq 0) { break }
                $sb.Append([char]$b) | Out-Null
            }
            $names += $sb.ToString()
        }
    }
    $names | Sort-Object | Get-Unique | ForEach-Object { Write-Output $_ }
} finally {
    $br.Close(); $fs.Close()
}
