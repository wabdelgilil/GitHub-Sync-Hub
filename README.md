<div align="center">

  <img src="assets/logo.svg" width="96" height="96" alt="GitHub Sync Hub Logo" />

  # GitHub Sync Hub

  **Zero-dependency, single-file portable Windows utilities for automated two-way GitHub synchronization.**
  
  *Effortlessly pull, commit, and push across multi-project workspaces and single repositories with zero friction.*

  <br />

  <p align="center">
    <a href="#-quick-download-hub"><img src="https://img.shields.io/badge/Download-Single--Click_.bat-2ea043?style=for-the-badge&logo=windows&logoColor=white" alt="Download" /></a>
    <a href="#-gui-dashboard-overview"><img src="https://img.shields.io/badge/GUI-Dark_Mode_WPF-0284c7?style=for-the-badge&logo=windows11&logoColor=white" alt="GUI" /></a>
    <a href="#-terminal-hub-overview"><img src="https://img.shields.io/badge/CLI-ANSI_Terminal-7c3aed?style=for-the-badge&logo=powershell&logoColor=white" alt="CLI" /></a>
    <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-f59e0b?style=for-the-badge" alt="License" /></a>
  </p>

  <p align="center">
    <img src="https://img.shields.io/badge/Platform-Windows_10_%7C_11-0078D6?style=flat-square&logo=windows" alt="Platform" />
    <img src="https://img.shields.io/badge/Dependencies-Zero_External-brightgreen?style=flat-square" alt="Zero Dependencies" />
    <img src="https://img.shields.io/badge/Pipeline-Deadlock--Free_Async_I%2FO-38bdf8?style=flat-square" alt="Async IO" />
    <img src="https://img.shields.io/badge/Encoding-UTF--8_%2F_Arabic_Ready-10b981?style=flat-square" alt="UTF8" />
    <img src="https://img.shields.io/badge/Engine-Pull_%2B_Commit_%2B_Push-6366f1?style=flat-square" alt="Engine" />
  </p>

  <br />

  [ 📦 Quick Download ](#-quick-download-hub) •
  [ 🖥️ GUI Overview ](#-gui-dashboard-overview) •
  [ ⚡ Terminal Overview ](#-terminal-hub-overview) •
  [ ⚖️ Feature Comparison ](#-why-github-sync-hub) •
  [ ⏱️ Automation Guide ](#-windows-task-scheduler-automation)

</div>

---

## 🌟 Visual Overview

GitHub Sync Hub packages complete enterprise-grade synchronization into **100% portable, standalone `.bat` files** powered by native Windows PowerShell and WPF — requiring **no installation, no Python, and no Node.js**.

### 🖥️ GUI Dashboard Overview (`Sync_All_Projects_GUI.bat`)

Modern dark-mode dashboard tailored for multi-repo management with live status badges, individual repository checkboxes, dynamic workspace browsing, and seamless Windows System Tray integration:

```text
┌────────────────────────────────────────────────────────────────────────────────────────┐
│ 📁 Multi-Project GitHub Sync Hub                                         [ - ] [ X ]   │
├────────────────────────────────────────────────────────────────────────────────────────┤
│  Workspace: C:\Users\<username>\Projects   [ 📁 Browse Workspace... ]    12 Repos      │
│  [ 3 Pending Changes ]                                                   [ Synced ]    │
├────────────────────────────────────────────────────────────────────────────────────────┤
│  [✓] Project                 Branch        Local Status       Remote Status  Last Sync │
│  ────────────────────────────────────────────────────────────────────────────────────  │
│  [✓] frontend-web-app        main          2 Changed (M, ?)   Ahead 1        2 hrs ago │
│  [✓] backend-api-service     develop       1 Changed (M)      Synced         Just now  │
│  [ ] docs-knowledge-base     master        Clean              Synced         Yesterday │
│  [✓] cloud-infra-terraform   main          Clean              Ahead 2        3 days ago│
├────────────────────────────────────────────────────────────────────────────────────────┤
│  Commit Message: chore(sync): workspace update 2026-11-25 23:45                        │
│  [ ⚡ Sync Selected (All) ]  [ ⬇️ Pull Selected ]  [ ⬆️ Push Selected ]  [ 🌐 GitHub ]   │
├────────────────────────────────────────────────────────────────────────────────────────┤
│  Progress: [████████████████████████████████████████████████████████████████] 100%     │
│  [23:45:01] DONE: 3 succeeded | 0 error(s) | Minimized to System Tray (Hidden Icons)  │
└────────────────────────────────────────────────────────────────────────────────────────┘
```

### ⚡ Terminal Hub Overview (`Sync_All_Projects.bat`)

High-velocity keyboard-driven hub featuring ANSI-colored status matrices, animated progress spinners, and non-interactive `--auto` flags for automation:

```text
  ╔══════════════════════════════════════════════════════════════════════╗
  ║  MULTI-PROJECT GITHUB SYNC HUB                                       ║
  ║  Workspace : C:\Users\<username>\Projects                            ║
  ╚══════════════════════════════════════════════════════════════════════╝

  #    Project                    Branch       Local        Remote      
  ──────────────────────────────────────────────────────────────────────
  1    frontend-web-app           main         2 changed    Ahead 1     
  2    backend-api-service        develop      1 changed    Synced      
  3    cloud-infra-terraform      main         Clean        Ahead 2     

  [1] Sync ALL projects (Commit + Pull + Push)
  [2] Sync ONLY changed/ahead projects
  [3] Pull ALL projects (download latest updates)
  [4] Pick specific project numbers (e.g. 1,3)
  [Q] Quit

  Choose option [1/2/3/4/Q]: 1
  >>> Processing backend-api-service [develop]
      | Staging 1 file(s)...                          [OK]
      | Pulling origin/develop (rebase + autostash)... [OK]
      | Pushing 1 commit(s) to GitHub...               [OK]
```

---

## 📦 Quick Download Hub

No Git installation or cloning needed. Download individual `.bat` files directly:

### 1-Click Direct Download

| Tool | Interface | Quick Download | Best Suited For |
| :--- | :--- | :---: | :--- |
| **`Sync_All_Projects_GUI.bat`** | Modern Dark WPF + System Tray | [⬇️ **Download GUI**](https://raw.githubusercontent.com/wabdelgilil/GitHub-Sync-Hub/main/tools/Sync_All_Projects_GUI.bat) | Desktop workspace management, selective sync, live folder browser, and notifications |
| **`Sync_All_Projects.bat`** | ANSI Terminal + Spinners | [⬇️ **Download CLI**](https://raw.githubusercontent.com/wabdelgilil/GitHub-Sync-Hub/main/tools/Sync_All_Projects.bat) | Fast keyboard-driven bulk sync & automated Task Scheduler routines |
| **`sync_github_gui.bat`** | Compact Dark WPF | [⬇️ **Download Single-GUI**](https://raw.githubusercontent.com/wabdelgilil/GitHub-Sync-Hub/main/tools/sync_github_gui.bat) | Single-repository visual diff & quick push |
| **`sync_github.bat`** | Lightweight Terminal | [⬇️ **Download Single-CLI**](https://raw.githubusercontent.com/wabdelgilil/GitHub-Sync-Hub/main/tools/sync_github.bat) | Quick double-click commit & push for one project |

> 💡 **Browser Tip:** Right-click any **Download** link above and select **"Save link as..."** to place the `.bat` file directly into your projects folder.

### ⚡ Fast Terminal Download Commands

Open PowerShell in your projects directory (e.g., `%USERPROFILE%\Projects\`) and run:

```powershell
# Download Multi-Project GUI Dashboard
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/wabdelgilil/GitHub-Sync-Hub/main/tools/Sync_All_Projects_GUI.bat" -OutFile "Sync_All_Projects_GUI.bat"

# Download Multi-Project Terminal Hub
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/wabdelgilil/GitHub-Sync-Hub/main/tools/Sync_All_Projects.bat" -OutFile "Sync_All_Projects.bat"
```

Or using `curl.exe` from Command Prompt:

```cmd
curl.exe -fLo Sync_All_Projects_GUI.bat https://raw.githubusercontent.com/wabdelgilil/GitHub-Sync-Hub/main/tools/Sync_All_Projects_GUI.bat
```

---

## ⚖️ Why GitHub Sync Hub?

| Capability | Standard Git CLI | Generic Batch Scripts | 🌟 GitHub Sync Hub |
| :--- | :---: | :---: | :---: |
| **Unified 2-Way Sync** | ❌ 3+ manual commands | ⚠️ Fragile & error-prone | ✅ Single-click automated sync |
| **Pipe Deadlock Prevention** | N/A | ❌ Hangs on 4 KB Windows buffer | ✅ Asynchronous non-blocking I/O |
| **Safe Rebase & Autostash** | ⚠️ Manual stash needed | ❌ Force-pulls or breaks | ✅ `pull --rebase --autostash` |
| **Nested Workspace Discovery** | ❌ Single repo only | ❌ Hardcoded directory loops | ✅ Automatic `.git` subtree scan |
| **Desktop System Tray** | ❌ None | ❌ None | ✅ Minimized to tray with Quick Sync |
| **Dynamic Directory Picker** | ❌ None | ❌ None | ✅ Native `FolderBrowserDialog` |
| **Zero External Dependencies** | Git required | Git required | ✅ Pure Windows PowerShell & Git |
| **Unicode & Arabic Paths** | ⚠️ Encoding glitches | ❌ Corrupts Arabic paths | ✅ Native UTF-8 (`chcp 65001`) |

---

## 🏗️ Architecture & Resolution Engine

### 1. Dynamic Directory Resolution Priority Flow

Every tool resolves its target workspace via an adaptive three-tier priority hierarchy:

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

- **Runtime In-Memory Switcher:** In `Sync_All_Projects_GUI.bat`, click **Browse Workspace...** at any time. The application instantly re-scans all repositories without restarting or moving files.

### 2. Nested Repository Discovery Architecture

Point the script at any parent directory; it automatically discovers and catalogs all child repositories:

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

If launched inside an individual Git repository, the tools automatically detect single-repo mode via `git rev-parse --show-toplevel`.

---

## 🚀 Usage Guide

<details open>
<summary><b>Multi-Project Sync Hub (CLI)</b></summary>

```cmd
:: 1. Run in current script directory (%~dp0)
Sync_All_Projects.bat

:: 2. Target a specific workspace folder dynamically
Sync_All_Projects.bat "C:\Users\<username>\Projects"
Sync_All_Projects.bat --dir "%USERPROFILE%\Projects"

:: 3. Non-interactive automated execution (for scripts or Task Scheduler)
Sync_All_Projects.bat --auto
Sync_All_Projects.bat "%USERPROFILE%\Projects" --auto
```
</details>

<details>
<summary><b>Multi-Project GUI Dashboard</b></summary>

```cmd
:: 1. Launch with interactive folder picker (or fallback to script directory)
Sync_All_Projects_GUI.bat

:: 2. Launch focused on a specific workspace directly
Sync_All_Projects_GUI.bat "C:\Users\<username>\Projects"
```
</details>

<details>
<summary><b>Single Repository Utilities</b></summary>

```cmd
:: Drop inside any Git repository root or scripts/ folder:
sync_github.bat

:: Or specify the target repository path from anywhere:
sync_github.bat "C:\Users\<username>\Projects\MyProject"
```
</details>

---

## ⏱️ Windows Task Scheduler Automation

Keep all your local repositories synchronized automatically in the background:

1. Press `Win + R`, type `taskschd.msc`, and press **Enter**.
2. Click **Create Basic Task...**, enter `GitHub Workspace Auto-Sync`, and choose a trigger (e.g., *Daily* or *At log on*).
3. Under **Action**, select **Start a program**.
4. Configure the action:
   - **Program/script:** `cmd.exe`
   - **Add arguments:**
     ```cmd
     /c ""C:\Users\<username>\Projects\Sync_All_Projects.bat" --auto"
     ```
     *(Or with a dynamic workspace target: `/c ""C:\Tools\Sync_All_Projects.bat" "C:\Users\<username>\Projects" --auto"`)*
   - **Start in:** `C:\Users\<username>\Projects`
5. Click **Finish**. All repositories will sync silently with zero popups or interruptions.

---

## 🔗 Integrated Ecosystem

Looking for a modern web-based command center for GitHub?

Check out **[GitNavigator](https://github.com/wabdelgilil/gitnavigator)** — an open-source, local-first web dashboard with visual branch network graphs, code viewer, and deep native integration with **GitHub Sync Hub**!

---

## 📋 Requirements

- **Operating System:** Windows 10 or Windows 11
- **Git for Windows:** `git` installed and accessible in system `PATH`
- **GitHub Credentials:** Configured via Git Credential Manager, SSH, or GitHub CLI (`gh`)

---

## 📄 License

This project is open-source under the [MIT License](LICENSE).
