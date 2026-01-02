# Pranjal OM1 Node Setup (Windows 10/11)
$ErrorActionPreference = "Stop"

Write-Host "Pranjal OM1 Node setup starting..."
Start-Sleep -Seconds 1

function Has-Cmd($name) {
  return [bool](Get-Command $name -ErrorAction SilentlyContinue)
}

function Refresh-Path {
  $machine = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
  $user = [System.Environment]::GetEnvironmentVariable("Path", "User")
  $env:Path = "$machine;$user"
}

function Ensure-Winget {
  if (-not (Has-Cmd "winget")) {
    Write-Host ""
    Write-Host "winget not found."
    Write-Host "Install 'App Installer' from Microsoft Store, then rerun the same one-liner."
    Write-Host ""
    throw "winget missing"
  }
}

function Ensure-Python {
  if (Has-Cmd "python") { return }
  Ensure-Winget
  Write-Host "Python not found. Installing Python 3.11..."
  winget install --id Python.Python.3.11 --silent --accept-package-agreements --accept-source-agreements
  Refresh-Path
  if (-not (Has-Cmd "python")) {
    throw "Python installed but not visible yet. Close PowerShell, open it again, rerun the same one-liner."
  }
}

function Ensure-Git {
  if (Has-Cmd "git") { return }
  Ensure-Winget
  Write-Host "Git not found. Installing Git..."
  winget install --id Git.Git --silent --accept-package-agreements --accept-source-agreements
  Refresh-Path
  if (-not (Has-Cmd "git")) {
    throw "Git installed but not visible yet. Close PowerShell, open it again, rerun the same one-liner."
  }
}

function Ensure-FFmpeg {
  if (Has-Cmd "ffmpeg") { return }
  Ensure-Winget
  Write-Host "ffmpeg not found. Installing ffmpeg..."
  winget install --id Gyan.FFmpeg --silent --accept-package-agreements --accept-source-agreements
  Refresh-Path
}

Ensure-Python
Ensure-Git
Ensure-FFmpeg

$baseDir = Join-Path $HOME "pranjal-om1"

if (-not (Test-Path $baseDir)) {
  Write-Host "Cloning OM1..."
  git clone https://github.com/openmind/OM1.git $baseDir
}

Set-Location $baseDir
git submodule update --init

if (-not (Test-Path ".venv")) {
  Write-Host "Creating virtual environment..."
  python -m venv .venv
}

Write-Host "Activating environment..."
. .\.venv\Scripts\Activate.ps1

Write-Host "Upgrading pip..."
python -m pip install --upgrade pip -q

Write-Host "Installing uv..."
python -m pip install uv -q

Write-Host ""
$apiKey = Read-Host "Enter your OpenMind API key"
while ([string]::IsNullOrWhiteSpace($apiKey)) {
  $apiKey = Read-Host "API key cannot be empty. Enter your OpenMind API key"
}

if (-not (Test-Path ".env")) {
  Copy-Item "env.example" ".env"
}

$envLines = Get-Content ".env" -ErrorAction SilentlyContinue
if ($null -eq $envLines) { $envLines = @() }

$found = $false
for ($i = 0; $i -lt $envLines.Count; $i++) {
  if ($envLines[$i] -match '^\s*OM_API_KEY=') {
    $envLines[$i] = "OM_API_KEY=$apiKey"
    $found = $true
  }
}
if (-not $found) {
  $envLines += ""
  $envLines += "OM_API_KEY=$apiKey"
}

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllLines((Join-Path (Get-Location) ".env"), $envLines, $utf8NoBom)

Write-Host ""
Write-Host "API key saved ✅"
Write-Host "Starting OM1 node..."
Start-Sleep -Seconds 1

uv run src\run.py conversation
