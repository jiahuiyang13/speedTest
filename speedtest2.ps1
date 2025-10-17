# -------------------------------------------------------------
# Simple Fast.com speed test
# Auto-installs Node.js (via winget) and fast-cli if missing
# -------------------------------------------------------------

Write-Host "`nChecking for Node.js..." -ForegroundColor Cyan
$node = Get-Command node -ErrorAction SilentlyContinue
if (-not $node) {
    Write-Host "Node.js not found — installing via winget..." -ForegroundColor Yellow
    try {
        winget install --id OpenJS.NodeJS.LTS -e --accept-package-agreements --accept-source-agreements -h
    } catch {
        Write-Host "❌ Could not install Node.js automatically. Please install manually from https://nodejs.org" -ForegroundColor Red
        Pause
        exit 1
    }
} else {
    Write-Host "✅ Node.js is already installed." -ForegroundColor Green
}

Write-Host "`nChecking for fast-cli..." -ForegroundColor Cyan
$fast = Get-Command fast -ErrorAction SilentlyContinue
if (-not $fast) {
    Write-Host "fast-cli not found — installing globally..." -ForegroundColor Yellow
    try {
        npm install -g fast-cli | Out-Null
    } catch {
        Write-Host "❌ Failed to install fast-cli. Try running PowerShell as Administrator." -ForegroundColor Red
        Pause
        exit 1
    }
} else {
    Write-Host "✅ fast-cli is already installed." -ForegroundColor Green
}

Write-Host "`nRunning Fast.com speed test..." -ForegroundColor Cyan
try {
    fast
} catch {
    Write-Host "❌ Error running fast-cli: $($_.Exception.Message)" -ForegroundColor Red
}

Pause