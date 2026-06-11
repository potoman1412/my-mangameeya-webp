param(
    [string]$RepoName = "",
    [ValidateSet('public','private')][string]$Visibility = 'public'
)

function Abort([string]$msg){ Write-Host "ERROR: $msg" -ForegroundColor Red; exit 1 }

Write-Host "Working directory: " (Get-Location)

if (-not (Get-Command git -ErrorAction SilentlyContinue)) { Abort "git not found. Install Git and try again: https://git-scm.com/downloads" }
if (-not (Get-Command gh -ErrorAction SilentlyContinue)) { Write-Host "gh (GitHub CLI) not found. Please install: https://github.com/cli/cli" -ForegroundColor Yellow }

if ([string]::IsNullOrWhiteSpace($RepoName)) { $RepoName = Read-Host "Enter repository name (example: my-mangameeya-webp)" }
if ([string]::IsNullOrWhiteSpace($RepoName)) { Abort "Repository name is required" }

# Initialize git repo if needed
if (-not (Test-Path .git)) {
    Write-Host "Initializing local git repository..."
    git init 2>&1 | Write-Host
}

git add -A
try {
    $null = git rev-parse --verify HEAD 2>$null
    $hasCommit = $true
} catch {
    $hasCommit = $false
}
if (-not $hasCommit) {
    git commit -m "Initial commit: add project" 2>&1 | Write-Host
} else { Write-Host "Repository already has commits" }

Write-Host "Checking gh authentication..."
if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    Write-Host "gh not available; will attempt to create repo via git remote (you must have a remote URL)" -ForegroundColor Yellow
} else {
    $status = gh auth status 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "You are not logged in to gh. Please follow the interactive login." -ForegroundColor Yellow
        gh auth login || Abort "gh auth login failed"
    } else { Write-Host "gh authenticated" }
}

Write-Host "Creating repository on GitHub: $RepoName ($Visibility)"
if (Get-Command gh -ErrorAction SilentlyContinue) {
    gh repo create $RepoName --$Visibility --source=. --remote=origin --push || Abort "Failed to create repo or push via gh"
} else {
    Abort "gh is not installed; cannot create remote repo automatically. Install gh or create repo on GitHub and add remote manually."
}

$url = gh repo view $RepoName --json url -q .url
Write-Host "Repository created: $url" -ForegroundColor Green
Write-Host "Open Actions on GitHub to run the workflow or push a tag to trigger the release." -ForegroundColor Cyan
