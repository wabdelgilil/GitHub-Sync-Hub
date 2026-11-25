@echo off
chcp 65001 >nul
setlocal

set "BATCH_PATH=%~f0"
set "SYNC_SCRIPT_DIR=%~dp0"
set "TARGET_DIR="
set "AUTO_ARG="

:parse_args
if "%~1"=="" goto done_args
if /I "%~1"=="--auto" (
    set "AUTO_ARG=-Auto"
    shift /1
    goto parse_args
)
if /I "%~1"=="--dir" (
    if not "%~2"=="" (
        set "TARGET_DIR=%~2"
        shift /1
    )
    shift /1
    goto parse_args
)
if not defined TARGET_DIR (
    set "TARGET_DIR=%~1"
    shift /1
    goto parse_args
)
shift /1
goto parse_args
:done_args

set "SYNC_TARGET_DIR=%TARGET_DIR%"

powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$code = (Get-Content -Encoding UTF8 $env:BATCH_PATH | Select-Object -Skip 38) -join [Environment]::NewLine; & ([ScriptBlock]::Create($code)) -ScriptDir $env:SYNC_SCRIPT_DIR -TargetDir $env:SYNC_TARGET_DIR %AUTO_ARG%"
exit /b %ERRORLEVEL%
:: --- POWERSHELL PAYLOAD BELOW ---
param(
    [string]$TargetDir = "",
    [string]$ScriptDir = "",
    [switch]$Auto
)

$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$Host.UI.RawUI.WindowTitle = "GitHub Two-Way Sync"

# Enable ANSI Virtual Terminal Sequences on Windows 10/11
$ESC = [char]27
$C_RESET  = "$ESC[0m"
$C_BOLD   = "$ESC[1m"
$C_DIM    = "$ESC[90m"
$C_CYAN   = "$ESC[96m"
$C_GREEN  = "$ESC[92m"
$C_YELLOW = "$ESC[93m"
$C_RED    = "$ESC[91m"
$C_MAG    = "$ESC[95m"
$C_WHITE  = "$ESC[97m"

# Early Git Check
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host "`n  ${C_RED}[X] Git is not installed or not in system PATH.${C_RESET}"
    Write-Host "      Please install Git for Windows (https://git-scm.com) and ensure 'git.exe' is in your PATH.`n"
    if (-not $Auto) { Read-Host "  Press Enter to exit" }
    exit 1
}

# Resolve script directory (default fallback: %~dp0 or current directory)
if ([string]::IsNullOrWhiteSpace($ScriptDir)) {
    $ScriptDir = (Get-Location).Path
}
$fallbackDir = (Resolve-Path -LiteralPath $ScriptDir -ErrorAction SilentlyContinue).Path
if (-not $fallbackDir) { $fallbackDir = $ScriptDir.TrimEnd('\', '/') }

$chosenDir = $null
# Priority 1: Check if a path argument is provided via command line
if (-not [string]::IsNullOrWhiteSpace($TargetDir)) {
    if (Test-Path -LiteralPath $TargetDir) {
        $chosenDir = (Resolve-Path -LiteralPath $TargetDir -ErrorAction SilentlyContinue).Path
    } else {
        Write-Host "`n  ${C_YELLOW}[!] Warning: Specified directory not found: '$TargetDir'${C_RESET}"
        Write-Host "      ${C_DIM}Defaulting to script directory: '$fallbackDir'${C_RESET}`n"
    }
}
# Priority 3 (CLI fallback): %~dp0
if (-not $chosenDir) {
    $chosenDir = $fallbackDir
}
$WorkingDir = $chosenDir.TrimEnd('\', '/')

Set-Location $WorkingDir
$RepoRoot = (git rev-parse --show-toplevel 2>$null)
if (-not $RepoRoot) {
    Write-Host "`n  ${C_RED}╔══════════════════════════════════════════════════════════════╗${C_RESET}"
    Write-Host "  ${C_RED}║${C_RESET}  ${C_BOLD}NOT INSIDE A GIT REPOSITORY${C_RESET}                                 ${C_RED}║${C_RESET}"
    Write-Host "  ${C_RED}╠══════════════════════════════════════════════════════════════╣${C_RESET}"
    Write-Host ("  ${C_RED}║${C_RESET}  Directory : {0,-47}${C_RED}║${C_RESET}" -f ($WorkingDir.Substring(0, [Math]::Min(47, $WorkingDir.Length))))
    Write-Host "  ${C_RED}║${C_RESET}                                                              ${C_RED}║${C_RESET}"
    Write-Host "  ${C_RED}║${C_RESET}  This directory does not contain a .git repository.          ${C_RED}║${C_RESET}"
    Write-Host "  ${C_RED}║${C_RESET}  Usage Tips:                                                 ${C_RED}║${C_RESET}"
    Write-Host "  ${C_RED}║${C_RESET}   - Pass a repo path: sync_github.bat `"C:\MyRepo`"              ${C_RED}║${C_RESET}"
    Write-Host "  ${C_RED}║${C_RESET}   - Or drop this script into the root of a Git repository.   ${C_RED}║${C_RESET}"
    Write-Host "  ${C_RED}║${C_RESET}   - For multi-repo parent folders, use Sync_All_Projects.bat  ${C_RED}║${C_RESET}"
    Write-Host "  ${C_RED}╚══════════════════════════════════════════════════════════════╝${C_RESET}`n"
    if (-not $Auto) { Read-Host "  Press Enter to exit" }
    exit 1
}

Set-Location $RepoRoot
$ProjName = Split-Path $RepoRoot -Leaf
$Branch = (git branch --show-current 2>$null).Trim()
if ([string]::IsNullOrWhiteSpace($Branch)) {
    Write-Host "`n  ${C_RED}[X] Detached HEAD state detected. Checkout a branch first.${C_RESET}`n"
    if (-not $Auto) { Read-Host "  Press Enter to exit" }
    exit 1
}

$RemoteUrl = (git remote get-url origin 2>$null)
$LastCommit = (git log -1 --pretty=format:"%h - %s (%cr)" 2>$null)
$Host.UI.RawUI.WindowTitle = "GitHub Sync - $ProjName [$Branch]"

# Header Banner
Write-Host ""
Write-Host "  ${C_CYAN}╔══════════════════════════════════════════════════════════════╗${C_RESET}"
Write-Host ("  ${C_CYAN}║${C_RESET}  ${C_BOLD}${C_WHITE}GITHUB TWO-WAY SYNC${C_RESET}  ${C_DIM}|${C_RESET}  ${C_GREEN}{0,-37}${C_RESET}${C_CYAN}║${C_RESET}" -f ($ProjName.Substring(0, [Math]::Min(37, $ProjName.Length))))
Write-Host "  ${C_CYAN}╠══════════════════════════════════════════════════════════════╣${C_RESET}"
Write-Host ("  ${C_CYAN}║${C_RESET}  ${C_DIM}Branch :${C_RESET} ${C_YELLOW}{0,-50}${C_RESET}${C_CYAN}║${C_RESET}" -f ($Branch.Substring(0, [Math]::Min(50, $Branch.Length))))
Write-Host ("  ${C_CYAN}║${C_RESET}  ${C_DIM}Folder :${C_RESET} ${C_WHITE}{0,-50}${C_RESET}${C_CYAN}║${C_RESET}" -f ($RepoRoot.Substring(0, [Math]::Min(50, $RepoRoot.Length))))
if ($LastCommit) {
    $lcShort = if ($LastCommit.Length -gt 50) { $LastCommit.Substring(0, 47) + "..." } else { $LastCommit }
    Write-Host ("  ${C_CYAN}║${C_RESET}  ${C_DIM}Latest :${C_RESET} ${C_DIM}{0,-50}${C_RESET}${C_CYAN}║${C_RESET}" -f $lcShort)
}
Write-Host "  ${C_CYAN}╚══════════════════════════════════════════════════════════════╝${C_RESET}"
Write-Host ""

function Show-Progress {
    param([int]$Percent, [string]$Label)
    $width = 28
    $filled = [math]::Floor(($Percent / 100) * $width)
    $empty = $width - $filled
    $bar = ("█" * $filled) + ("░" * $empty)
    Write-Host ("  ${C_CYAN}[${C_GREEN}$bar${C_CYAN}] ${C_WHITE}{0,3}%${C_RESET}  ${C_DIM}$Label${C_RESET}" -f $Percent)
}

function Invoke-GitWithSpinner {
    param([string]$Arguments, [string]$Message, [int]$TimeoutSec = 120)
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = "git"
    $psi.Arguments = $Arguments
    $psi.WorkingDirectory = (Get-Location).Path
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true
    $psi.StandardOutputEncoding = [System.Text.Encoding]::UTF8
    $psi.StandardErrorEncoding = [System.Text.Encoding]::UTF8

    $proc = New-Object System.Diagnostics.Process
    $proc.StartInfo = $psi
    [void]$proc.Start()

    # Drain stdout/stderr asynchronously to prevent Windows 4KB pipe buffer deadlocks
    $outTask = $proc.StandardOutput.ReadToEndAsync()
    $errTask = $proc.StandardError.ReadToEndAsync()

    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $frames = @('|', '/', '-', '\')
    $idx = 0
    while (-not $proc.HasExited) {
        if ($sw.Elapsed.TotalSeconds -gt $TimeoutSec) {
            try { $proc.Kill() } catch {}
            Write-Host -NoNewline "`r                                                                      `r"
            return [PSCustomObject]@{ ExitCode = -1; StdOut = ""; StdErr = "Timed out after ${TimeoutSec}s" }
        }
        $f = $frames[$idx % $frames.Length]
        Write-Host -NoNewline "`r  ${C_CYAN}$f${C_RESET} $Message...   "
        Start-Sleep -Milliseconds 60
        $idx++
    }
    Write-Host -NoNewline "`r                                                                      `r"
    $stdout = $outTask.GetAwaiter().GetResult().Trim()
    $stderr = $errTask.GetAwaiter().GetResult().Trim()
    return [PSCustomObject]@{
        ExitCode = $proc.ExitCode
        StdOut   = $stdout
        StdErr   = $stderr
    }
}

Show-Progress -Percent 10 -Label "Scanning workspace changes..."

# STEP 1: Check and commit local changes
$StatusLines = @(git status --porcelain)
if ($StatusLines.Count -gt 0) {
    Write-Host ""
    Write-Host "  ${C_YELLOW}[1/3] Detected $($StatusLines.Count) local change(s):${C_RESET}"
    $shown = 0
    foreach ($line in $StatusLines) {
        if ($shown -lt 12) {
            $code = $line.Substring(0, 2)
            $file = $line.Substring(3)
            $col = if ($code -match "\?") { $C_GREEN } elseif ($code -match "D") { $C_RED } else { $C_YELLOW }
            Write-Host "        ${col}$code${C_RESET} $file"
        }
        $shown++
    }
    if ($StatusLines.Count -gt 12) {
        Write-Host "        ${C_DIM}... and $($StatusLines.Count - 12) more file(s)${C_RESET}"
    }
    Write-Host ""

    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm"
    $DefaultMsg = "chore(sync): workspace update $Timestamp"

    if ($Auto) {
        $CommitMsg = $DefaultMsg
    } else {
        Write-Host -NoNewline "  ${C_CYAN}Commit message${C_RESET} ${C_DIM}[Enter = '$DefaultMsg']${C_RESET}: "
        $UserInput = Read-Host
        $CommitMsg = if ([string]::IsNullOrWhiteSpace($UserInput)) { $DefaultMsg } else { $UserInput.Trim() }
    }

    Show-Progress -Percent 25 -Label "Staging all changes..."
    $res = Invoke-GitWithSpinner -Arguments "add -A" -Message "Staging files (git add -A)"
    if ($res.ExitCode -ne 0) {
        Write-Host "`n  ${C_RED}[X] git add failed:${C_RESET} $($res.StdErr)"
        if (-not $Auto) { Read-Host "  Press Enter to exit" }
        exit 1
    }

    Show-Progress -Percent 40 -Label "Committing changes..."
    $escMsg = $CommitMsg.Replace('"', '\"')
    $res = Invoke-GitWithSpinner -Arguments "commit -m `"$escMsg`"" -Message "Creating commit"
    if ($res.ExitCode -ne 0) {
        Write-Host "`n  ${C_RED}[X] git commit failed:${C_RESET} $($res.StdErr)"
        if (-not $Auto) { Read-Host "  Press Enter to exit" }
        exit 1
    }
    Write-Host "  ${C_GREEN}[OK] Local changes committed:${C_RESET} $CommitMsg"
} else {
    Write-Host "  ${C_GREEN}[1/3] Working tree clean (nothing to commit).${C_RESET}"
    Show-Progress -Percent 40 -Label "Working tree clean"
}

# STEP 2: Pull latest changes from remote
Write-Host ""
if (-not $RemoteUrl) {
    Write-Host "  ${C_YELLOW}[2/3] No remote 'origin' configured. Skipping pull.${C_RESET}"
    Show-Progress -Percent 70 -Label "No remote configured"
} else {
    Write-Host "  ${C_CYAN}[2/3] Pulling latest changes from origin/$Branch...${C_RESET}"
    Show-Progress -Percent 55 -Label "Pulling from origin/$Branch..."
    $res = Invoke-GitWithSpinner -Arguments "pull --rebase --autostash origin $Branch" -Message "Pulling updates (rebase + autostash)"
    if ($res.ExitCode -ne 0) {
        Write-Host "`n  ${C_RED}[X] Pull failed with conflicts or network error:${C_RESET}"
        Write-Host "      $($res.StdErr)"
        Write-Host "`n  ${C_YELLOW}Resolve merge conflicts manually, then re-run.${C_RESET}"
        if (-not $Auto) { Read-Host "  Press Enter to exit" }
        exit 1
    }
    Write-Host "  ${C_GREEN}[OK] Remote changes pulled successfully.${C_RESET}"
    Show-Progress -Percent 70 -Label "Pull completed"
}

# STEP 3: Push local commits to remote
Write-Host ""
if (-not $RemoteUrl) {
    Write-Host "  ${C_YELLOW}[3/3] No remote 'origin' configured. Skipping push.${C_RESET}"
    Show-Progress -Percent 100 -Label "Complete (Local repo only)"
} else {
    Write-Host "  ${C_CYAN}[3/3] Checking for outgoing commits...${C_RESET}"
    $AheadCount = (git rev-list --count origin/$Branch..HEAD 2>$null)
    if ($AheadCount -match "^\d+$" -and [int]$AheadCount -gt 0) {
        Write-Host "        Detected $AheadCount commit(s) ahead of origin/$Branch."
        Show-Progress -Percent 85 -Label "Pushing $AheadCount commit(s) to origin/$Branch..."
        $res = Invoke-GitWithSpinner -Arguments "push origin $Branch" -Message "Pushing commits to GitHub"
        if ($res.ExitCode -ne 0) {
            Write-Host "`n  ${C_RED}[X] Push failed:${C_RESET} $($res.StdErr)"
            if (-not $Auto) { Read-Host "  Press Enter to exit" }
            exit 1
        }
        Write-Host "  ${C_GREEN}[OK] Successfully pushed $AheadCount commit(s) to GitHub!${C_RESET}"
        Show-Progress -Percent 100 -Label "Sync complete!"
    } else {
        Write-Host "  ${C_GREEN}[OK] Already up to date with origin/$Branch (0 outgoing commits).${C_RESET}"
        Show-Progress -Percent 100 -Label "Everything up to date!"
    }
}

# Completion Summary
Write-Host ""
Write-Host "  ${C_GREEN}╔══════════════════════════════════════════════════════════════╗${C_RESET}"
Write-Host "  ${C_GREEN}║${C_RESET}  ${C_BOLD}${C_GREEN}TWO-WAY SYNC COMPLETED SUCCESSFULLY${C_RESET}                        ${C_GREEN}║${C_RESET}"
Write-Host "  ${C_GREEN}╚══════════════════════════════════════════════════════════════╝${C_RESET}"
Write-Host ""

if (-not $Auto) {
    try { [Console]::Beep(880, 100); [Console]::Beep(1175, 130) } catch {}
    Read-Host "  Press Enter to close"
}
exit 0
