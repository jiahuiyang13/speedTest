# installer.ps1 — Fast.com prerequisites installer (Node LTS + fast-cli)
# Uses npm.cmd (not npm.ps1) to avoid execution policy issues.
# --- Auto-elevate to Administrator ---
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltinRole] "Administrator"
)) {
    Write-Host "Restarting script with Administrator privileges..." -ForegroundColor Yellow
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = "powershell.exe"
    $psi.Arguments = "-ExecutionPolicy Bypass -File `"$PSCommandPath`""
    $psi.Verb = "runas"
    try {
        [System.Diagnostics.Process]::Start($psi) | Out-Null
    } catch {
        Write-Host "❌ Administrator privileges are required. Exiting." -ForegroundColor Red
    }
    exit
}
Write-Host "Installing prerequisites..." -ForegroundColor Cyan

# --- Node.js ---
$node = Get-Command node -ErrorAction SilentlyContinue
if (-not $node) {
  Write-Host "Installing Node.js (LTS) via winget..." -ForegroundColor Yellow
  try {
    Start-Process winget `
      -ArgumentList 'install --id OpenJS.NodeJS.LTS -e --accept-package-agreements --accept-source-agreements -h' `
      -Wait -NoNewWindow
  } catch {
    Write-Host "❌ Node.js install failed: $($_.Exception.Message)" -ForegroundColor Red
    Pause; exit 1
  }

  # Make node/npm immediately visible in this session
  $nodePath = Join-Path $env:ProgramFiles 'nodejs'
  if ((Test-Path -Path $nodePath) -and ($env:Path -notlike "*$nodePath*")) {
    $env:Path += ";$nodePath"
  }
  Write-Host "✅ Node.js installed." -ForegroundColor Green
} else {
  Write-Host "✅ Node.js already installed." -ForegroundColor Green
}

# Resolve npm.cmd explicitly (bypasses npm.ps1 execution-policy block)
function Get-NpmCmdPath {
  $npmCmd = (Get-Command npm.cmd -ErrorAction SilentlyContinue).Source
  if ($npmCmd) { return $npmCmd }

  $candidates = @()
  if ($env:ProgramFiles) { $candidates += (Join-Path $env:ProgramFiles 'nodejs\npm.cmd') }
  if (${env:ProgramFiles(x86)}) { $candidates += (Join-Path ${env:ProgramFiles(x86)} 'nodejs\npm.cmd') }

  foreach ($c in $candidates) {
    if ((Test-Path -Path $c)) { return $c }
  }
  return $null
}

# --- fast-cli ---
$fast = Get-Command fast -ErrorAction SilentlyContinue
if (-not $fast) {
  Write-Host "Installing fast-cli globally via npm..." -ForegroundColor Yellow
  $npmCmd = Get-NpmCmdPath
  if (-not $npmCmd) {
    Write-Host "❌ Couldn't find npm.cmd. Open a new PowerShell window and re-run this installer." -ForegroundColor Red
    Pause; exit 1
  }

  try {
    $p = Start-Process -FilePath $npmCmd -ArgumentList 'install -g fast-cli' -Wait -PassThru -NoNewWindow
    if ($p.ExitCode -ne 0) {
      throw "npm exited with code $($p.ExitCode)"
    }
  } catch {
    Write-Host "❌ fast-cli install failed: $($_.Exception.Message)" -ForegroundColor Red
    Pause; exit 1
  }

  # Ensure current session can find global npm binaries (fast.cmd / fast.exe)
  $npmBin = "$env:APPDATA\npm"
  if ((Test-Path -Path $npmBin) -and ($env:Path -notlike "*$npmBin*")) {
    $env:Path += ";$npmBin"
  }

  Write-Host "✅ fast-cli installed." -ForegroundColor Green
} else {
  Write-Host "✅ fast-cli already installed." -ForegroundColor Green
}

Write-Host "All prerequisites are ready." -ForegroundColor Green




Write-Host "`nRunning Fast.com speed test..." -ForegroundColor Cyan
try {
    fast
} catch {
    Write-Host "❌ Error running fast-cli: $($_.Exception.Message)" -ForegroundColor Red
}

Pause
