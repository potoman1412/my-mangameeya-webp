<#
create_and_push_repo.ps1
à¹ƒà¸Šà¹‰à¸ªà¸„à¸£à¸´à¸›à¸•à¹Œà¸™à¸µà¹‰à¹ƒà¸™à¹‚à¸Ÿà¸¥à¹€à¸”à¸­à¸£à¹Œà¹‚à¸›à¸£à¹€à¸ˆà¸„à¹€à¸žà¸·à¹ˆà¸­à¸ªà¸£à¹‰à¸²à¸‡ GitHub repo à¹à¸¥à¸° push à¹‚à¸„à¹‰à¸”
à¸•à¹‰à¸­à¸‡à¸à¸²à¸£: Git à¹à¸¥à¸° GitHub CLI (`gh`) à¸•à¸´à¸”à¸•à¸±à¹‰à¸‡à¹à¸¥à¹‰à¸§
#>

param(
    [string]$RepoName = "",
    [ValidateSet('public','private')][string]$Visibility = 'public'
)

function Abort($msg){ Write-Host "ERROR: $msg" -ForegroundColor Red; exit 1 }

# Check current dir
$cwd = Get-Location
Write-Host "Working directory: $cwd"

# Check git
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Abort "git not found. à¹‚à¸›à¸£à¸”à¸•à¸´à¸”à¸•à¸±à¹‰à¸‡ Git à¹à¸¥à¸°à¸£à¸±à¸™à¸ªà¸„à¸£à¸´à¸›à¸•à¹Œà¹ƒà¸«à¸¡à¹ˆ. https://git-scm.com/downloads"
}

# Check gh
if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    Write-Host "GitHub CLI (gh) not found. à¸ˆà¸°à¸žà¸¢à¸²à¸¢à¸²à¸¡à¹ƒà¸Šà¹‰ gh à¹à¸•à¹ˆà¸„à¸¸à¸“à¸ªà¸²à¸¡à¸²à¸£à¸–à¸•à¸´à¸”à¸•à¸±à¹‰à¸‡à¸”à¹‰à¸§à¸¢: winget install --id GitHub.cli" -ForegroundColor Yellow
    $useGH = Read-Host "à¸•à¹‰à¸­à¸‡à¸à¸²à¸£à¸•à¸´à¸”à¸•à¸±à¹‰à¸‡ GitHub CLI à¸­à¸±à¸•à¹‚à¸™à¸¡à¸±à¸•à¸´à¸•à¸­à¸™à¸™à¸µà¹‰? (y/n)"
    if ($useGH -eq 'y') {
        Write-Host "à¸•à¸´à¸”à¸•à¸±à¹‰à¸‡ gh..."; winget install --id GitHub.cli -e || Abort "à¸•à¸´à¸”à¸•à¸±à¹‰à¸‡ gh à¸¥à¹‰à¸¡à¹€à¸«à¸¥à¸§" }
    if (-not (Get-Command gh -ErrorAction SilentlyContinue)) { Abort "gh à¸¢à¸±à¸‡à¹„à¸¡à¹ˆà¸žà¸š à¸«à¸¥à¸±à¸‡à¸•à¸´à¸”à¸•à¸±à¹‰à¸‡ à¹ƒà¸«à¹‰à¸£à¸±à¸™à¸ªà¸„à¸£à¸´à¸›à¸•à¹Œà¹ƒà¸«à¸¡à¹ˆ" }
}

# Ask repo name
if ([string]::IsNullOrWhiteSpace($RepoName)) {
    $RepoName = Read-Host "à¸£à¸°à¸šà¸¸à¸Šà¸·à¹ˆà¸­ repo à¸—à¸µà¹ˆà¸•à¹‰à¸­à¸‡à¸à¸²à¸£ (à¸•à¸±à¸§à¸­à¸¢à¹ˆà¸²à¸‡: my-mangameeya-webp)"
}
if ([string]::IsNullOrWhiteSpace($RepoName)) { Abort "à¸Šà¸·à¹ˆà¸­ repo à¸§à¹ˆà¸²à¸‡" }

# Ensure git repo
$gitDir = Join-Path $cwd '.git'
if (-not (Test-Path $gitDir)) {
    Write-Host "à¸à¸³à¸¥à¸±à¸‡à¸ªà¸£à¹‰à¸²à¸‡ git repo..."
    git init || Abort "git init failed"
} else {
    Write-Host "à¸žà¸š .git à¸­à¸¢à¸¹à¹ˆà¹à¸¥à¹‰à¸§"
}

# Add and commit
git add -A
$hasCommit = (git rev-parse --verify HEAD 2>$null) -ne $null
if (-not $hasCommit) {
    git commit -m "Initial commit: add project" || Write-Host "à¹„à¸¡à¹ˆà¸¡à¸µà¸à¸²à¸£ commit (à¸­à¸²à¸ˆà¹„à¸¡à¹ˆà¸¡à¸µà¸à¸²à¸£à¹€à¸›à¸¥à¸µà¹ˆà¸¢à¸™à¹à¸›à¸¥à¸‡)" -ForegroundColor Yellow
} else {
    Write-Host "à¸¡à¸µ commit à¸­à¸¢à¸¹à¹ˆà¹à¸¥à¹‰à¸§" -ForegroundColor Green
}

# Authenticate gh
Write-Host "à¸•à¸£à¸§à¸ˆà¸ªà¸­à¸šà¸à¸²à¸£à¸¥à¹‡à¸­à¸à¸­à¸´à¸™ gh..."
$who = gh auth status 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "à¸¢à¸±à¸‡à¹„à¸¡à¹ˆà¹„à¸”à¹‰à¸¥à¹‡à¸­à¸à¸­à¸´à¸™ gh â€” à¸ˆà¸°à¹€à¸£à¸µà¸¢à¸ gh auth login à¹à¸šà¸š interactive" -ForegroundColor Yellow
    gh auth login || Abort "gh auth login à¸¥à¹‰à¸¡à¹€à¸«à¸¥à¸§"
} else {
    Write-Host "gh auth OK"
}

# Create repo and push
Write-Host "à¸ªà¸£à¹‰à¸²à¸‡ repository à¸šà¸™ GitHub: $RepoName ($Visibility)"
# Use --source . --push to push current repo
$createCmd = "gh repo create $RepoName --$Visibility --source=. --remote=origin --push"
Write-Host "Running: $createCmd"
Invoke-Expression $createCmd
if ($LASTEXITCODE -ne 0) { Abort "à¸ªà¸£à¹‰à¸²à¸‡ repo à¸«à¸£à¸·à¸­ push à¸¥à¹‰à¸¡à¹€à¸«à¸¥à¸§" }

# Show repo URL
$repoUrl = gh repo view $RepoName --json url -q .url
Write-Host "à¸ªà¸³à¹€à¸£à¹‡à¸ˆ: Repo created at $repoUrl" -ForegroundColor Green
Write-Host "à¹„à¸›à¸—à¸µà¹ˆ Actions à¸šà¸™ GitHub à¹€à¸žà¸·à¹ˆà¸­à¸£à¸±à¸™ workflow à¸«à¸£à¸·à¸­à¸ªà¸£à¹‰à¸²à¸‡ tag à¹€à¸žà¸·à¹ˆà¸­ trigger release." -ForegroundColor Cyan

Write-Host "à¸–à¹‰à¸²à¸•à¹‰à¸­à¸‡à¸à¸²à¸£à¹ƒà¸«à¹‰à¸œà¸¡à¸•à¸£à¸§à¸ˆ workflow logs à¹ƒà¸«à¹‰ à¸ªà¹ˆà¸‡à¸¥à¸´à¸‡à¸à¹Œ repo à¸«à¸£à¸·à¸­ run id à¸¡à¸²à¹„à¸”à¹‰à¹€à¸¥à¸¢." -ForegroundColor Cyan
