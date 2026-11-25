# GitHub Sync Hub

Zero-dependency, single-file portable Windows utilities for automated two-way GitHub synchronization (Pull + Commit + Push) across both **multi-project parent workspaces** and **individual Git repositories**.

Built entirely with native Windows PowerShell, WPF, and System Tray APIs — no Node.js, Python, or third-party runtimes required.

---

## Direct Download (1-Click & Terminal)

You do **not** need to clone this repository. You can download individual standalone `.bat` utilities directly:

### 1-Click Browser Download

| Utility | Interface | Direct Download Link | Best For |
| :--- | :--- | :--- | :--- |
| **`Sync_All_Projects_GUI.bat`** | Modern Dark Mode WPF + Tray | [⬇️ Download `Sync_All_Projects_GUI.bat`](https://raw.githubusercontent.com/wabdelgilil/GitHub-Sync-Hub/main/tools/Sync_All_Projects_GUI.bat) | Multi-repo dashboard with live checkboxes, runtime folder browser, and Windows notifications |
| **`Sync_All_Projects.bat`** | ANSI Terminal + Spinners | [⬇️ Download `Sync_All_Projects.bat`](https://raw.githubusercontent.com/wabdelgilil/GitHub-Sync-Hub/main/tools/Sync_All_Projects.bat) | Keyboard-driven bulk sync & unattended `--auto` Task Scheduler automation |
| **`sync_github_gui.bat`** | Compact Dark Mode WPF | [⬇️ Download `sync_github_gui.bat`](https://raw.githubusercontent.com/wabdelgilil/GitHub-Sync-Hub/main/tools/sync_github_gui.bat) | Visual single-repo sync with file diff overview |
| **`sync_github.bat`** | Lightweight Terminal | [⬇️ Download `sync_github.bat`](https://raw.githubusercontent.com/wabdelgilil/GitHub-Sync-Hub/main/tools/sync_github.bat) | Double-click or automated single-repo sync |

> **Browser Download Tip:** Right-click the download link above and select **Save link as...** (or click the link, then press `Ctrl + S`).

### Fast PowerShell Download Commands

Open PowerShell in your projects folder (`%USERPROFILE%\Projects\`) and run either command to download instantly:

```powershell
# Download the Multi-Project GUI Dashboard
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/wabdelgilil/GitHub-Sync-Hub/main/tools/Sync_All_Projects_GUI.bat" -OutFile "Sync_All_Projects_GUI.bat"

# Download the Multi-Project Terminal Hub
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/wabdelgilil/GitHub-Sync-Hub/main/tools/Sync_All_Projects.bat" -OutFile "Sync_All_Projects.bat"
```

Or using `curl.exe` from Command Prompt:

```cmd
curl.exe -fLo Sync_All_Projects_GUI.bat https://raw.githubusercontent.com/wabdelgilil/GitHub-Sync-Hub/main/tools/Sync_All_Projects_GUI.bat
```

---

## Architecture & Directory Resolution

The utilities are **100% portable**. They require zero configuration and contain zero hardcoded directory paths.

### 1. Dynamic Resolution Priority Flow

When executed, every tool resolves its target working directory using a strict three-tier priority chain:

```text
  Directory Resolution Priority Flow:
  ┌────────────────────────────────────────────────────────┐
  │ Priority 1: Command-line Argument                      │
  │   Sync_All_Projects.bat "C:\Users\<user>\Projects"     │
  │   Sync_All_Projects.bat --dir "%USERPROFILE%\Projects" │
  └───────────────────────────┬────────────────────────────┘
                              │ (If argument omitted)
                              ▼
  ┌────────────────────────────────────────────────────────┐
  │ Priority 2: Native Folder Browser Dialog               │
  │   (GUI mode: prompts user with FolderBrowserDialog)    │
  └───────────────────────────┬────────────────────────────┘
                              │ (If cancelled or CLI mode)
                              ▼
  ┌────────────────────────────────────────────────────────┐
  │ Priority 3: Fallback Script Location (%~dp0)           │
  │   Self-contained directory hosting the .bat file       │
  └────────────────────────────────────────────────────────┘
```

- **Runtime Workspace Switching:** In `Sync_All_Projects_GUI.bat`, click **Browse Workspace...** at any time to point the dashboard to another directory. It re-scans all repositories dynamically without restarting.

### 2. Nested Repository Discovery Architecture

When pointed at any parent workspace, the discovery engine scans all immediate child folders for Git repositories:

```text
  Target Workspace Directory / (e.g. %USERPROFILE%\Projects\)
  ├── Project-Alpha/
  │   └── .git/               --> [DETECTED] Syncs branch origin/main
  ├── Project-Beta/
  │   └── .git/               --> [DETECTED] Syncs branch origin/dev
  ├── Documentation/          --> [SKIPPED]  No .git folder
  ├── Project-Gamma/
  │   └── .git/               --> [DETECTED] Syncs branch origin/main
  └── Sync_All_Projects_GUI.bat
```

If dropped directly inside a single Git repository, the tools automatically detect the single-repo context via `git rev-parse --show-toplevel`.

---

## Usage Guide

### Multi-Project Sync Hub (`Sync_All_Projects.bat`)

```cmd
:: 1. Default: Run in the folder where the script is located (%~dp0)
Sync_All_Projects.bat

:: 2. Target a specific workspace folder
Sync_All_Projects.bat "C:\Users\<username>\Projects"
Sync_All_Projects.bat --dir "%USERPROFILE%\Projects"

:: 3. Non-interactive automated sync (ideal for Task Scheduler)
Sync_All_Projects.bat --auto
Sync_All_Projects.bat "%USERPROFILE%\Projects" --auto
```

### Multi-Project GUI Dashboard (`Sync_All_Projects_GUI.bat`)

```cmd
:: 1. Launch with interactive folder picker (or fallback to script directory)
Sync_All_Projects_GUI.bat

:: 2. Launch directly focused on a specific workspace
Sync_All_Projects_GUI.bat "C:\Users\<username>\Projects"
```

### Single Repository Utilities (`sync_github.bat`, `sync_github_gui.bat`)

```cmd
:: Drop inside any Git repository root or scripts/ folder and run:
sync_github.bat

:: Or specify the target repository path from anywhere:
sync_github.bat "C:\Users\<username>\Projects\MyProject"
```

---

## Windows Task Scheduler Automation

You can schedule automated background synchronization across all your repositories:

1. Open **Task Scheduler** (`taskschd.msc`).
2. Click **Create Basic Task...**, name it `GitHub Workspace Auto-Sync`, and choose your trigger (e.g., *Daily at 18:00* or *At log on*).
3. Under **Action**, select **Start a program**.
4. Configure the program settings:
   - **Program/script:**
     ```cmd
     cmd.exe
     ```
   - **Add arguments:**
     ```cmd
     /c ""C:\Users\<username>\Projects\Sync_All_Projects.bat" --auto"
     ```
     *(Or pass a dynamic workspace target: `/c ""C:\Tools\Sync_All_Projects.bat" "C:\Users\<username>\Projects" --auto"`)*
   - **Start in:**
     ```cmd
     C:\Users\<username>\Projects
     ```
5. Click **Finish**. Your repositories will stay continuously synchronized without interrupting your workflow.

---

## Key Features & Safety Mechanisms

- **Safe Two-Way Sync:** Staging (`git add -A`), commits with optional custom message or automatic Conventional Commit timestamp (`chore(sync): workspace update YYYY-MM-DD HH:mm`), pulls remote changes safely via `git pull --rebase --autostash`, and pushes only when local commits are ahead.
- **Deadlock-Free Asynchronous Pipe I/O:** Child Git processes drain `StandardOutput` and `StandardError` asynchronously (`ReadToEndAsync`) with enforced timeouts, eliminating Windows 4 KB pipe buffer lockups.
- **System Tray & Toast Notifications:** `Sync_All_Projects_GUI.bat` minimizes cleanly to Windows Hidden Icons with right-click Quick Sync and native Windows balloon notifications.
- **Unicode & Arabic Support:** Full support for non-Latin paths, filenames, and commit messages (`chcp 65001` UTF-8).
- **Environment Validation:** Proactively verifies Git CLI availability in system `PATH` and presents actionable diagnostics when no repositories are detected.

---

## Requirements

- Windows 10 or Windows 11
- Git for Windows (`git` installed and available in `PATH`)
- GitHub authentication configured (Git Credential Manager, SSH, or GitHub CLI `gh`)

---

## License

MIT License — see [LICENSE](LICENSE) for details.
