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
    [string]$BaseDir = "",
    [switch]$Auto
)

$ErrorActionPreference = "Continue"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$Host.UI.RawUI.WindowTitle = "Multi-Project GitHub Sync Hub"

$ESC = [char]27
$C_RESET  = "$ESC[0m"
$C_BOLD   = "$ESC[1m"
$C_DIM    = "$ESC[90m"
$C_CYAN   = "$ESC[96m"
$C_GREEN  = "$ESC[92m"
$C_YELLOW = "$ESC[93m"
$C_RED    = "$ESC[91m"
$C_WHITE  = "$ESC[97m"

# Validate Git presence
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host "`n  ${C_RED}[X] Git is not installed or not in system PATH.${C_RESET}"
    Write-Host "      Please install Git for Windows (https://git-scm.com) and ensure 'git.exe' is in your PATH.`n"
    if (-not $Auto) { Read-Host "  Press Enter to exit" }
    exit 1
}

# Resolve script directory (default fallback: %~dp0 or current directory)
if ([string]::IsNullOrWhiteSpace($ScriptDir)) {
    $ScriptDir = if (-not [string]::IsNullOrWhiteSpace($BaseDir)) { $BaseDir } else { (Get-Location).Path }
}
$fallbackDir = (Resolve-Path -LiteralPath $ScriptDir -ErrorAction SilentlyContinue).Path
if (-not $fallbackDir) { $fallbackDir = $ScriptDir.TrimEnd('\', '/') }

$chosenDir = $null
# Priority 1: Check if a path argument is provided via command line
$candidate = if (-not [string]::IsNullOrWhiteSpace($TargetDir)) { $TargetDir } elseif (-not [string]::IsNullOrWhiteSpace($BaseDir) -and $BaseDir -ne $ScriptDir) { $BaseDir } else { $null }

if ($candidate) {
    if (Test-Path -LiteralPath $candidate) {
        $chosenDir = (Resolve-Path -LiteralPath $candidate -ErrorAction SilentlyContinue).Path
    } else {
        Write-Host "`n  ${C_YELLOW}[!] Warning: Specified directory does not exist: '$candidate'${C_RESET}"
        Write-Host "      ${C_DIM}Defaulting to script directory: '$fallbackDir'${C_RESET}`n"
    }
}

# Priority 3 (CLI fallback): %~dp0
if (-not $chosenDir) {
    $chosenDir = $fallbackDir
}
$BaseDir = $chosenDir.TrimEnd('\', '/')

function Invoke-GitProc {
    param([string]$RepoPath, [string]$Arguments, [string]$SpinMsg = "", [int]$TimeoutSec = 120)
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = "git"
    $psi.Arguments = $Arguments
    $psi.WorkingDirectory = $RepoPath
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
            if ($SpinMsg) { Write-Host -NoNewline "`r                                                                        `r" }
            return [PSCustomObject]@{ ExitCode = -1; Out = ""; Err = "Timed out after ${TimeoutSec}s" }
        }
        if ($SpinMsg) {
            $f = $frames[$idx % $frames.Length]
            Write-Host -NoNewline "`r    ${C_CYAN}$f${C_RESET} $SpinMsg...                    "
        }
        Start-Sleep -Milliseconds 60
        $idx++
    }
    if ($SpinMsg) {
        Write-Host -NoNewline "`r                                                                        `r"
    }
    $out = $outTask.GetAwaiter().GetResult().Trim()
    $err = $errTask.GetAwaiter().GetResult().Trim()
    return [PSCustomObject]@{ ExitCode = $proc.ExitCode; Out = $out; Err = $err }
}

function Show-Bar {
    param([int]$Done, [int]$Total, [string]$Label)
    $pct = if ($Total -gt 0) { [int][math]::Floor(($Done / $Total) * 100) } else { 100 }
    $w = 26
    $f = [int][math]::Floor(($pct / 100) * $w)
    $bar = ("█" * $f) + ("░" * ($w - $f))
    Write-Host ("  ${C_CYAN}[${C_GREEN}$bar${C_CYAN}] ${C_WHITE}{0,3}%${C_RESET}  ${C_DIM}$Label${C_RESET}" -f $pct)
}

function Discover-Repos {
    param([string]$RootDir)
    $RootDir = $RootDir.TrimEnd('\', '/')
    $found = @()

    # Check if RootDir itself is inside a Git repo
    $selfTop = (Invoke-GitProc -RepoPath $RootDir -Arguments "rev-parse --show-toplevel")
    if ($selfTop.ExitCode -eq 0 -and $selfTop.Out) {
        $found += $selfTop.Out
    } else {
        # Scan immediate subdirectories for .git
        Get-ChildItem -Path $RootDir -Directory -ErrorAction SilentlyContinue | Sort-Object Name | ForEach-Object {
            if (Test-Path (Join-Path $_.FullName ".git")) {
                $found += $_.FullName
            }
        }
    }

    $repos = @()
    $idx = 1
    $totalFound = $found.Count
    foreach ($p in $found) {
        $name   = Split-Path $p -Leaf
        Write-Host -NoNewline "`r  ${C_DIM}Scanning [$idx/$totalFound]: $name...                              ${C_RESET}"
        $br     = (Invoke-GitProc -RepoPath $p -Arguments "branch --show-current" -TimeoutSec 10).Out
        if (-not $br) { $br = "(detached)" }
        $rem    = (Invoke-GitProc -RepoPath $p -Arguments "remote get-url origin" -TimeoutSec 10).Out
        $st     = (Invoke-GitProc -RepoPath $p -Arguments "status --porcelain" -TimeoutSec 15).Out
        $chCnt  = if ($st) { @($st -split "`r?`n" | Where-Object { $_ -ne "" }).Count } else { 0 }
        $ahead  = 0
        if ($rem -and $br -ne "(detached)") {
            $ar = (Invoke-GitProc -RepoPath $p -Arguments "rev-list --count origin/$br..HEAD" -TimeoutSec 10).Out
            if ($ar -match "^\d+$") { $ahead = [int]$ar }
        }
        $repos += [PSCustomObject]@{
            Index     = $idx
            Name      = $name
            Path      = $p
            Branch    = $br
            HasRemote = [bool]$rem
            Changes   = $chCnt
            Ahead     = $ahead
        }
        $idx++
    }
    Write-Host -NoNewline "`r                                                                        `r"
    return $repos
}

Clear-Host

Write-Host ""
Write-Host "  ${C_CYAN}╔══════════════════════════════════════════════════════════════════════╗${C_RESET}"
Write-Host "  ${C_CYAN}║${C_RESET}  ${C_BOLD}${C_WHITE}MULTI-PROJECT GITHUB SYNC HUB${C_RESET}                                       ${C_CYAN}║${C_RESET}"
Write-Host ("  ${C_CYAN}║${C_RESET}  ${C_DIM}Workspace : {0,-56}${C_RESET}${C_CYAN}║${C_RESET}" -f ($BaseDir.Substring(0, [Math]::Min(56, $BaseDir.Length))))
Write-Host "  ${C_CYAN}╚══════════════════════════════════════════════════════════════════════╝${C_RESET}"
Write-Host ""
Write-Host "  ${C_DIM}Scanning for Git repositories...${C_RESET}"

$Repos = @(Discover-Repos -RootDir $BaseDir)
if ($Repos.Count -eq 0) {
    Write-Host "`n  ${C_YELLOW}╔══════════════════════════════════════════════════════════════════════╗${C_RESET}"
    Write-Host "  ${C_YELLOW}║${C_RESET}  ${C_BOLD}NO GIT REPOSITORIES FOUND${C_RESET}                                           ${C_YELLOW}║${C_RESET}"
    Write-Host "  ${C_YELLOW}╠══════════════════════════════════════════════════════════════════════╣${C_RESET}"
    Write-Host ("  ${C_YELLOW}║${C_RESET}  Workspace : {0,-56}${C_YELLOW}║${C_RESET}" -f ($BaseDir.Substring(0, [Math]::Min(56, $BaseDir.Length))))
    Write-Host "  ${C_YELLOW}║${C_RESET}                                                                      ${C_YELLOW}║${C_RESET}"
    Write-Host "  ${C_YELLOW}║${C_RESET}  No Git repositories (.git) were detected in this folder.             ${C_YELLOW}║${C_RESET}"
    Write-Host "  ${C_YELLOW}║${C_RESET}  Usage Tips:                                                         ${C_YELLOW}║${C_RESET}"
    Write-Host "  ${C_YELLOW}║${C_RESET}   - Pass a workspace path: Sync_All_Projects.bat `"C:\Projects`"        ${C_YELLOW}║${C_RESET}"
    Write-Host "  ${C_YELLOW}║${C_RESET}   - Or copy this script into your parent projects directory.         ${C_YELLOW}║${C_RESET}"
    Write-Host "  ${C_YELLOW}╚══════════════════════════════════════════════════════════════════════╝${C_RESET}`n"
    if (-not $Auto) { Read-Host "  Press Enter to exit" }
    exit 0
}

Write-Host ""
Write-Host ("  ${C_BOLD}${C_WHITE}{0,-4} {1,-26} {2,-12} {3,-12} {4,-12}${C_RESET}" -f "#", "Project", "Branch", "Local", "Remote")
Write-Host "  ${C_DIM}──────────────────────────────────────────────────────────────────────${C_RESET}"
foreach ($r in $Repos) {
    $locTxt = if ($r.Changes -gt 0) { "$($r.Changes) changed" } else { "Clean" }
    $locCol = if ($r.Changes -gt 0) { $C_YELLOW } else { $C_GREEN }
    $remTxt = if (-not $r.HasRemote) { "No remote" } elseif ($r.Ahead -gt 0) { "Ahead $($r.Ahead)" } else { "Synced" }
    $remCol = if (-not $r.HasRemote) { $C_DIM } elseif ($r.Ahead -gt 0) { $C_CYAN } else { $C_GREEN }
    $nShort = if ($r.Name.Length -gt 25) { $r.Name.Substring(0, 22) + "..." } else { $r.Name }
    $bShort = if ($r.Branch.Length -gt 11) { $r.Branch.Substring(0, 11) } else { $r.Branch }
    Write-Host ("  ${C_WHITE}{0,-4}${C_RESET} {1,-26} ${C_DIM}{2,-12}${C_RESET} ${locCol}{3,-12}${C_RESET} ${remCol}{4,-12}${C_RESET}" -f $r.Index, $nShort, $bShort, $locTxt, $remTxt)
}
Write-Host ""

$Action = "SYNC_ALL"
$Targets = $Repos

if (-not $Auto) {
    Write-Host "  ${C_CYAN}[1]${C_RESET} Sync ALL projects (Commit + Pull + Push)"
    Write-Host "  ${C_CYAN}[2]${C_RESET} Sync ONLY changed/ahead projects"
    Write-Host "  ${C_CYAN}[3]${C_RESET} Pull ALL projects (download latest updates)"
    Write-Host "  ${C_CYAN}[4]${C_RESET} Pick specific project numbers (e.g. 1,3)"
    Write-Host "  ${C_CYAN}[Q]${C_RESET} Quit"
    Write-Host ""
    $choice = (Read-Host "  Choose option [1/2/3/4/Q]").Trim().ToUpper()

    switch ($choice) {
        "1" { $Action = "SYNC_ALL"; $Targets = $Repos }
        "2" { $Action = "SYNC_ALL"; $Targets = @($Repos | Where-Object { $_.Changes -gt 0 -or $_.Ahead -gt 0 }) }
        "3" { $Action = "PULL_ONLY"; $Targets = $Repos }
        "4" {
            $nums = (Read-Host "  Enter project numbers separated by comma (e.g. 1,2)") -split "[,\s]+" | Where-Object { $_ -match "^\d+$" } | ForEach-Object { [int]$_ }
            $Targets = @($Repos | Where-Object { $nums -contains $_.Index })
            $Action = "SYNC_ALL"
        }
        default { exit 0 }
    }
}

if ($Targets.Count -eq 0) {
    Write-Host "`n  ${C_GREEN}[OK] No projects require syncing.${C_RESET}`n"
    if (-not $Auto) { Read-Host "  Press Enter to close" }
    exit 0
}

$Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm"
$DefaultMsg = "chore(sync): workspace update $Timestamp"
$CommitMsg = $DefaultMsg
if (-not $Auto -and $Action -eq "SYNC_ALL") {
    $hasAnyChange = (@($Targets | Where-Object { $_.Changes -gt 0 }).Count -gt 0)
    if ($hasAnyChange) {
        $uMsg = Read-Host "  Commit message [Enter = '$DefaultMsg']"
        if (-not [string]::IsNullOrWhiteSpace($uMsg)) { $CommitMsg = $uMsg.Trim() }
    }
}

Write-Host ""
$okCount = 0; $errCount = 0; $skipCount = 0; $step = 0

foreach ($r in $Targets) {
    $step++
    Show-Bar -Done ($step - 1) -Total $Targets.Count -Label "Processing $($r.Name) ($step/$($Targets.Count))"
    Write-Host "  ${C_BOLD}${C_CYAN}>>> $($r.Name)${C_RESET} ${C_DIM}[$($r.Branch)]${C_RESET}"

    if ($r.Branch -eq "(detached)") {
        Write-Host "    ${C_YELLOW}[SKIP] Detached HEAD.${C_RESET}"
        $skipCount++
        continue
    }

    $failed = $false

    if ($Action -eq "SYNC_ALL" -and $r.Changes -gt 0) {
        $a = Invoke-GitProc -RepoPath $r.Path -Arguments "add -A" -SpinMsg "Staging $($r.Changes) file(s)"
        if ($a.ExitCode -ne 0) {
            Write-Host "    ${C_RED}[X] git add failed: $($a.Err)${C_RESET}"
            $errCount++; continue
        }
        $escMsg = $CommitMsg.Replace('"', '\"')
        $c = Invoke-GitProc -RepoPath $r.Path -Arguments "commit -m `"$escMsg`"" -SpinMsg "Committing changes"
        if ($c.ExitCode -ne 0) {
            Write-Host "    ${C_RED}[X] git commit failed: $($c.Err)${C_RESET}"
            $errCount++; continue
        }
        Write-Host "    ${C_GREEN}[OK] Committed local changes.${C_RESET}"
    }

    if (-not $r.HasRemote) {
        Write-Host "    ${C_YELLOW}[NOTE] Local commit only (no remote 'origin' configured).${C_RESET}"
        $okCount++; continue
    }

    $pl = Invoke-GitProc -RepoPath $r.Path -Arguments "pull --rebase --autostash origin $($r.Branch)" -SpinMsg "Pulling origin/$($r.Branch)"
    if ($pl.ExitCode -ne 0) {
        Write-Host "    ${C_RED}[X] Pull failed: $($pl.Err)${C_RESET}"
        $errCount++; continue
    }
    Write-Host "    ${C_GREEN}[OK] Pulled origin/$($r.Branch).${C_RESET}"

    if ($Action -eq "SYNC_ALL") {
        $ah = (Invoke-GitProc -RepoPath $r.Path -Arguments "rev-list --count origin/$($r.Branch)..HEAD").Out
        if ($ah -match "^\d+$" -and [int]$ah -gt 0) {
            $ps = Invoke-GitProc -RepoPath $r.Path -Arguments "push origin $($r.Branch)" -SpinMsg "Pushing $ah commit(s)"
            if ($ps.ExitCode -ne 0) {
                Write-Host "    ${C_RED}[X] Push failed: $($ps.Err)${C_RESET}"
                $errCount++; continue
            }
            Write-Host "    ${C_GREEN}[OK] Pushed $ah commit(s) to GitHub.${C_RESET}"
        }
    }
    $okCount++
}

Show-Bar -Done $Targets.Count -Total $Targets.Count -Label "Finished!"
Write-Host ""
Write-Host "  ${C_GREEN}╔══════════════════════════════════════════════════════════════════════╗${C_RESET}"
Write-Host ("  ${C_GREEN}║${C_RESET}  ${C_BOLD}SUMMARY:${C_RESET}  ${C_GREEN}Synced: {0,-4}${C_RESET}  ${C_YELLOW}Skipped: {1,-4}${C_RESET}  ${C_RED}Errors: {2,-4}${C_RESET}                   ${C_GREEN}║${C_RESET}" -f $okCount, $skipCount, $errCount)
Write-Host "  ${C_GREEN}╚══════════════════════════════════════════════════════════════════════╝${C_RESET}"
if (-not $Auto) {
    try { [Console]::Beep(880, 100); [Console]::Beep(1175, 130) } catch {}
    Write-Host ""
    Read-Host "  Press Enter to close"
}
exit 0
