# System Requirements Specification (SRS) — GitHub Sync Hub

## 1. Scope & Objectives
GitHub Sync Hub provides zero-dependency, single-file portable Windows utilities that automate safe two-way Git synchronization (`add` / `commit` / `pull --rebase --autostash` / `push`) across both individual repositories and multi-project parent directories.

## 2. Functional Requirements
1. **Dynamic Workspace Resolution & Discovery:**
   - Resolve target workspace via a deterministic three-tier priority hierarchy:
     1. Priority 1: Positional CLI argument (`%~1`) or `--dir "<path>"`.
     2. Priority 2: Interactive `System.Windows.Forms.FolderBrowserDialog` in GUI mode (`*_GUI.bat`) when launched without arguments.
     3. Priority 3: Fallback script directory location (`%~dp0`).
   - Auto-detect single-repository context via `git rev-parse --show-toplevel`.
   - When executed in a multi-project directory, scan immediate subdirectories for `.git` repositories.
   - Support dynamic runtime workspace directory switching in `Sync_All_Projects_GUI.bat` via a header folder picker.
2. **Two-Way Synchronization Engine:**
   - Stage and commit local modifications with either user-supplied messages or deterministic timestamped Conventional Commit messages (`chore(sync): workspace update YYYY-MM-DD HH:mm`).
   - Pull remote changes safely via `git pull --rebase --autostash` and halt cleanly on merge/rebase conflicts without destructive force operations.
   - Push only when local `HEAD` is ahead of `origin/<branch>`.
3. **Dual Interface Support:**
   - **Terminal Hub (`Sync_All_Projects.bat`, `sync_github.bat`):** ANSI-colored status tables, animated progress indicators, interactive menu, and non-interactive `--auto` CLI flag.
   - **Dark Mode GUI (`Sync_All_Projects_GUI.bat`, `sync_github_gui.bat`):** Native Windows WPF interface with live repository status table, selective checkboxes, activity log, System Tray (`NotifyIcon`) integration, and native Windows notifications.
4. **Resilience & Diagnostics:**
   - Proactive verification of Git CLI availability in system `PATH` before script execution, presenting actionable recovery instructions.
   - Display clear, informative summaries and usage hints when the selected directory contains zero Git repositories.
5. **Direct Download Distribution:**
   - Support single-click raw file downloads and lightweight PowerShell/curl one-line fetch commands directly from the GitHub repository without requiring full git cloning.

## 3. Non-Functional Requirements
- **Zero External Dependencies:** Rely exclusively on built-in Windows PowerShell, .NET WPF/WinForms, and Git CLI.
- **Deadlock Prevention:** All child `git` processes must drain `StandardOutput` and `StandardError` asynchronously (`ReadToEndAsync`) with enforced timeouts.
- **Encoding Integrity:** Enforce UTF-8 (`chcp 65001` and `Encoding.UTF8`) for full Unicode/Arabic filename compatibility.
- **Windows Batch Fidelity:** All `.bat` launchers must use CRLF (`\r\n`) line endings.

## 4. Architecture
Each utility is packaged as a self-contained hybrid `.bat` + embedded PowerShell payload under `tools/`, allowing direct copy-and-run portability without installation or path configuration.
