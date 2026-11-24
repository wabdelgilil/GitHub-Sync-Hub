@echo off
chcp 65001 >nul
setlocal
set "AUTO_ARG="
if /I "%~1"=="--auto" set "AUTO_ARG=-Auto"
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$code = (Get-Content -Encoding UTF8 '%~f0' | Select-Object -Skip 8) -join [Environment]::NewLine; & ([ScriptBlock]::Create($code)) -ScriptDir '%~dp0' %AUTO_ARG%"
exit /b %ERRORLEVEL%
:: --- POWERSHELL PAYLOAD BELOW ---
param(
    [string]$ScriptDir = (Get-Location).Path,
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

function Show-Progress {
    param([int]$Percent, [string]$Label)
    $width = 28
    $filled = [math]::Floor(($Percent / 100) * $width)
    $empty = $width - $filled
    $bar = ("█" * $filled) + ("░" * $empty)
    Write-Host ("  ${C_CYAN}[${C_GREEN}$bar${C_CYAN}] ${C_WHITE}{0,3}%${C_RESET}  ${C_DIM}$Label${C_RESET}" -f $Percent)
}

function Invoke-GitWithSpinner {
    param([string]$Arguments, [string]$Message)
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

    $frames = @('|', '/', '-', '\')
    $idx = 0
    while (-not $proc.HasExited) {
        $f = $frames[$idx % $frames.Length]
        Write-Host -NoNewline "`r  ${C_CYAN}$f${C_RESET} $Message...   "
        Start-Sleep -Milliseconds 110
        $idx++
    }
    $stdout = $proc.StandardOutput.ReadToEnd()
    $stderr = $proc.StandardError.ReadToEnd()
    $proc.WaitForExit()
    Write-Host -NoNewline "`r                                                                      `r"
    return [PSCustomObject]@{
        ExitCode = $proc.ExitCode
        StdOut   = $stdout.Trim()
        StdErr   = $stderr.Trim()
    }
}

Clear-Host

# Locate Git & Repository Root
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host "`n  ${C_RED}[X] Git is not installed or not in PATH.${C_RESET}`n"
    if (-not $Auto) { Read-Host "  Press Enter to exit" }
    exit 1
}

Set-Location $ScriptDir
$RepoRoot = (git rev-parse --show-toplevel 2>$null)
if (-not $RepoRoot) {
    Write-Host "`n  ${C_RED}[X] This folder is not inside a Git repository:${C_RESET}"
    Write-Host "      ${C_DIM}$ScriptDir${C_RESET}`n"
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
Write-Host ("  ${C_CYAN}║${C_RESET}  ${C_BOLD}${C_WHITE}GITHUB TWO-WAY SYNC${C_RESET}  ${C_DIM}|${C_RESET}  ${C_GREEN}{0,-37}${C_RESET}${C_CYAN}║${C_RESET}" -f $ProjName)
Write-Host "  ${C_CYAN}╠══════════════════════════════════════════════════════════════╣${C_RESET}"
Write-Host ("  ${C_CYAN}║${C_RESET}  ${C_DIM}Branch :${C_RESET} ${C_YELLOW}{0,-50}${C_RESET}${C_CYAN}║${C_RESET}" -f $Branch)
Write-Host ("  ${C_CYAN}║${C_RESET}  ${C_DIM}Folder :${C_RESET} ${C_WHITE}{0,-50}${C_RESET}${C_CYAN}║${C_RESET}" -f ($RepoRoot.Substring(0, [Math]::Min(50, $RepoRoot.Length))))
if ($LastCommit) {
    $lcShort = if ($LastCommit.Length -gt 50) { $LastCommit.Substring(0, 47) + "..." } else { $LastCommit }
    Write-Host ("  ${C_CYAN}║${C_RESET}  ${C_DIM}Latest :${C_RESET} ${C_DIM}{0,-50}${C_RESET}${C_CYAN}║${C_RESET}" -f $lcShort)
}
Write-Host "  ${C_CYAN}╚══════════════════════════════════════════════════════════════╝${C_RESET}"
Write-Host ""

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

    $addRes = Invoke-GitWithSpinner -Arguments "add -A" -Message "Staging files"
    if ($addRes.ExitCode -ne 0) {
        Write-Host "  ${C_RED}[X] git add failed: $($addRes.StdErr)${C_RESET}"
        if (-not $Auto) { Read-Host "`n  Press Enter to exit" }
        exit 1
    }

    $escapedMsg = $CommitMsg.Replace('"', '\"')
    $comRes = Invoke-GitWithSpinner -Arguments "commit -m `"$escapedMsg`"" -Message "Committing changes"
    if ($comRes.ExitCode -ne 0) {
        Write-Host "  ${C_RED}[X] git commit failed: $($comRes.StdErr)${C_RESET}"
        if (-not $Auto) { Read-Host "`n  Press Enter to exit" }
        exit 1
    }
    Write-Host "  ${C_GREEN}[OK] Committed:${C_RESET} $CommitMsg"
} else {
    Write-Host "  ${C_DIM}[1/3] Working tree is clean - no local changes to commit.${C_RESET}"
}

Show-Progress -Percent 45 -Label "Pulling remote updates..."

# STEP 2: Pull with rebase
$pullRes = Invoke-GitWithSpinner -Arguments "pull --rebase --autostash origin $Branch" -Message "Pulling from origin/$Branch"
if ($pullRes.ExitCode -ne 0) {
    Write-Host ""
    Write-Host "  ${C_RED}[X] Pull/Rebase failed or conflict detected:${C_RESET}"
    if ($pullRes.StdErr) { Write-Host "      ${C_DIM}$($pullRes.StdErr)${C_RESET}" }
    Write-Host "  ${C_YELLOW}Tip: Resolve conflicts, then run 'git rebase --continue'.${C_RESET}"
    if (-not $Auto) { Read-Host "`n  Press Enter to exit" }
    exit 1
}
Write-Host "  ${C_GREEN}[OK] Pulled & synced with origin/$Branch.${C_RESET}"

Show-Progress -Percent 75 -Label "Checking commits to push..."

# STEP 3: Push if ahead
$aheadRaw = (git rev-list --count "origin/$Branch..HEAD" 2>$null)
$AheadCount = if ($aheadRaw -match "^\d+$") { [int]$aheadRaw } else { 0 }

if ($AheadCount -gt 0) {
    $pushRes = Invoke-GitWithSpinner -Arguments "push origin $Branch" -Message "Pushing $AheadCount commit(s) to GitHub"
    if ($pushRes.ExitCode -ne 0) {
        Write-Host "  ${C_RED}[X] Push failed:${C_RESET} $($pushRes.StdErr)"
        if (-not $Auto) { Read-Host "`n  Press Enter to exit" }
        exit 1
    }
    Write-Host "  ${C_GREEN}[OK] Pushed $AheadCount commit(s) to origin/$Branch.${C_RESET}"
} else {
    Write-Host "  ${C_DIM}[3/3] Already up to date with origin/$Branch.${C_RESET}"
}

Show-Progress -Percent 100 -Label "All operations complete!"
Write-Host ""
Write-Host "  ${C_GREEN}╔══════════════════════════════════════════════════════════════╗${C_RESET}"
Write-Host "  ${C_GREEN}║            SYNC COMPLETED SUCCESSFULLY                       ║${C_RESET}"
Write-Host "  ${C_GREEN}╚══════════════════════════════════════════════════════════════╝${C_RESET}"
if (-not $Auto) {
    try { [Console]::Beep(880, 110); [Console]::Beep(1175, 140) } catch {}
    Write-Host ""
    Read-Host "  Press Enter to close"
}
exit 0
