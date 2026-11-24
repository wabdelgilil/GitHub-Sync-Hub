# GitHub Sync Hub

Zero-dependency, single-file portable Windows utilities for two-way GitHub synchronization (Pull + Commit + Push) across both **individual Git repositories** and **multi-project parent workspaces**.

Built entirely with native Windows PowerShell, WPF, and System Tray APIs — no Node.js, Python, or third-party runtimes required.

---

## Included Tools (`tools/`)

| File | Mode | Interface | Best For |
| :--- | :--- | :--- | :--- |
| **`Sync_All_Projects_GUI.bat`** | Multi-Project & Single-Repo | Modern Dark Mode WPF + System Tray + Windows Notifications | Drop into a parent workspace folder (e.g. `D:\Programming\`) to monitor and sync all Git repos from one dashboard |
| **`Sync_All_Projects.bat`** | Multi-Project & Single-Repo | ANSI-Colored Terminal + Live Spinner + Progress Bar | Fast keyboard-driven bulk sync & `--auto` Task Scheduler automation |
| **`sync_github_gui.bat`** | Single Repository | Compact Dark Mode WPF Window | Drop directly into any individual Git repository |
| **`sync_github.bat`** | Single Repository | ANSI-Colored Terminal + Spinner + Progress Bar | Lightweight double-click or `--auto` single-repo sync |

---

## Key Features

- **100% Portable Single-File `.bat` Launchers:** Copy any `.bat` file into any folder and double-click. It automatically detects whether it sits inside a single Git repository or a parent directory containing multiple repositories.
- **Safe Two-Way Sync:** Commits local changes (with optional custom commit message or automatic Conventional Commit timestamp), pulls remote changes safely via `git pull --rebase --autostash`, and pushes only when local commits are ahead.
- **Non-Blocking Async Pipe I/O:** Drains `stdout`/`stderr` asynchronously (`ReadToEndAsync`) with per-command timeouts, preventing 4 KB pipe deadlocks even on repositories with hundreds of modified files.
- **Windows System Tray (Hidden Icons) & Notifications:** `Sync_All_Projects_GUI.bat` minimizes cleanly to the Windows taskbar notification area with a right-click quick-sync menu and native Windows toast/balloon notifications upon completion.
- **UTF-8 & Multilingual Path Support:** Full support for Arabic/Unicode file paths and filenames.

---

## Quick Start

1. Download or copy your preferred `.bat` launcher from `tools/`:
   - For a workspace containing multiple Git repos: copy **`Sync_All_Projects_GUI.bat`** or **`Sync_All_Projects.bat`** into your parent projects directory.
   - For a single Git repo: copy **`sync_github_gui.bat`** or **`sync_github.bat`** into the repository root or `scripts/` folder.
2. Double-click the `.bat` file.
3. *(Optional)* For unattended automation via Windows Task Scheduler:
   ```bat
   Sync_All_Projects.bat --auto
   ```

---

## Requirements

- Windows 10 or Windows 11
- Git for Windows (`git` available in `PATH`) with GitHub credentials configured (GCM / SSH / `gh`)

---

## License

MIT License — see [LICENSE](LICENSE) for details.
