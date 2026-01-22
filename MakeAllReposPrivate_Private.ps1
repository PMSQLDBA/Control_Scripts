# ==============================================
# GitHub Bulk Repository Visibility Changer
# Author: Praveen Madupu (PMSQLDBA)
# Purpose: Change all repositories to PRIVATE mode
# Date: (auto-logged below)
# ==============================================

# ---- Configuration ----
$OrgName = "PMSQLDBA"
$LogFile = "D:\Scripts\GitHub_Private_Change_Log_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"

# ---- Start Logging ----
Add-Content $LogFile "=== Starting GitHub Repo Visibility Change ==="
Add-Content $LogFile "Date: $(Get-Date)"
Add-Content $LogFile "----------------------------------------------"

# ---- Validate GitHub CLI ----
if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    Write-Host "GitHub CLI not found. Please install it from https://cli.github.com/" -ForegroundColor Red
    exit
}

# ---- Verify Auth Status ----
$AuthStatus = gh auth status 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "Please authenticate first using: gh auth login --scopes 'repo,admin:repo_hook'" -ForegroundColor Red
    exit
}

# ---- Fetch All Repositories ----
$repos = gh repo list $OrgName --limit 200 --json name,visibility --jq ".[] | [.name, .visibility] | @tsv"

foreach ($line in $repos) {
    $parts = $line -split "`t"
    $repoName = $parts[0]
    $currentVisibility = $parts[1]

    if ($currentVisibility -eq "private") {
        Add-Content $LogFile "$OrgName/$repoName already private"
        continue
    }

    # ---- Attempt to Change Visibility ----
    Write-Host "Changing $repoName to private..." -ForegroundColor Cyan
    gh repo edit "$OrgName/$repoName" --visibility private --accept-visibility-change-consequences 2>&1 | Out-Null

    if ($LASTEXITCODE -eq 0) {
        Add-Content $LogFile "$OrgName/$repoName changed to private"
        Write-Host "$repoName → Private" -ForegroundColor Green
    } else {
        Add-Content $LogFile "$OrgName/$repoName failed to change"
        Write-Host "$repoName → Failed" -ForegroundColor Red
    }
}

Add-Content $LogFile "----------------------------------------------"
Add-Content $LogFile "Script completed at $(Get-Date)"
Write-Host "`Completed. Log file saved at: $LogFile" -ForegroundColor Yellow
