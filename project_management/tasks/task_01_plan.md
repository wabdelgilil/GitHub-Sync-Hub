# Task 01 Plan: Dynamic Path Resolution Architecture & Portability Refinement

## 1. Scope & Objective
Refactor the path resolution architecture of all utilities in `tools/` and update project documentation to ensure 100% portability with zero hardcoded path assumptions:
- Multi-project utilities: `Sync_All_Projects.bat`, `Sync_All_Projects_GUI.bat`.
- Single-repo utilities: `sync_github.bat`, `sync_github_gui.bat`.
- Documentation: `README.md` and `SRS.md`.

## 2. Technical Requirements
1. **Dynamic CLI Directory Resolution:**
   - Support optional workspace target via positional argument (`%~1`) or named flag (`--dir "<path>"`).
   - Ensure `--auto` and `--dir` can be supplied in any order.
   - Batch wrapper passes normalized directory argument and script directory to PowerShell payload.
   - PowerShell payload validates target path with `Test-Path`. If omitted or invalid, cleanly fall back to `%~dp0` (the directory hosting the script).
2. **WPF GUI Dynamic Workspace Picker (`Sync_All_Projects_GUI.bat`):**
   - Add a styled "Browse Workspace..." button in the header card next to workspace path display.
   - Use `System.Windows.Forms.FolderBrowserDialog` to select a folder at runtime.
   - Update `$script:BaseDir` and `$TxtBase` text, triggering `Scan-Repositories` immediately without restart.
   - Maintain async non-blocking execution throughout scanning and syncing.
3. **Documentation Hygiene:**
   - Remove hardcoded `D:\Programming\` references in `README.md`.
   - Provide standard placeholders: `%USERPROFILE%\Projects\` or `C:\Users\<username>\Projects\`.
   - Explicitly document folder portability, CLI directory flags, and runtime workspace switching.
   - Update `SRS.md` with dynamic workspace resolution specifications.

## 3. Verification Criteria
- Batch argument combinations: no args (falls back to `%~dp0`), positional path, `--dir <path>`, `--dir <path> --auto`, `--auto --dir <path>`.
- Invalid path provided falls back to `%~dp0` with informative warning.
- Folder browser dialog triggers and refreshes repository list dynamically.
- Clean encoding (UTF-8) and CRLF line endings.
