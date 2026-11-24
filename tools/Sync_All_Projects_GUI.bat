@echo off
chcp 65001 >nul
setlocal
start "" /b powershell.exe -NoProfile -WindowStyle Hidden -STA -ExecutionPolicy Bypass -Command "$code = (Get-Content -Encoding UTF8 '%~f0' | Select-Object -Skip 6) -join [Environment]::NewLine; & ([ScriptBlock]::Create($code)) -BaseDir '%~dp0'"
exit /b 0
:: --- POWERSHELL PAYLOAD BELOW ---
param(
    [string]$BaseDir = (Get-Location).Path
)

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms, System.Drawing
$BaseDir = $BaseDir.TrimEnd('\', '/')

[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Multi-Project GitHub Sync Hub"
        Height="680" Width="900" MinHeight="580" MinWidth="760"
        WindowStartupLocation="CenterScreen"
        Background="#0F172A" Foreground="#E2E8F0"
        FontFamily="Segoe UI">
    <Window.Resources>
        <Style x:Key="Btn" TargetType="Button">
            <Setter Property="Foreground" Value="#FFFFFF"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="FontSize" Value="13"/>
            <Setter Property="Padding" Value="14,9"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="bg" Background="{TemplateBinding Background}" CornerRadius="8" Padding="{TemplateBinding Padding}">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="bg" Property="Opacity" Value="0.88"/>
                            </Trigger>
                            <Trigger Property="IsEnabled" Value="False">
                                <Setter TargetName="bg" Property="Opacity" Value="0.45"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
        <Style x:Key="SmallBtn" TargetType="Button" BasedOn="{StaticResource Btn}">
            <Setter Property="FontSize" Value="11.5"/>
            <Setter Property="Padding" Value="10,5"/>
            <Setter Property="Background" Value="#334155"/>
        </Style>
    </Window.Resources>

    <Grid Margin="18">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="240"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
        </Grid.RowDefinitions>

        <!-- Header -->
        <Border Grid.Row="0" Background="#1E293B" CornerRadius="10" Padding="16,12" Margin="0,0,0,12">
            <Grid>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>
                <StackPanel Grid.Column="0">
                    <TextBlock Text="Multi-Project GitHub Sync Hub" FontSize="20" FontWeight="Bold" Foreground="#38BDF8"/>
                    <TextBlock x:Name="TxtBase" Text="$BaseDir" FontSize="11.5" Foreground="#94A3B8" Margin="0,2,0,0"/>
                </StackPanel>
                <StackPanel Grid.Column="1" Orientation="Horizontal" VerticalAlignment="Center">
                    <Border Background="#0C4A6E" CornerRadius="6" Padding="10,5" Margin="0,0,8,0">
                        <TextBlock x:Name="TxtRepoCount" Text="Scanning..." FontSize="12" FontWeight="SemiBold" Foreground="#7DD3FC"/>
                    </Border>
                    <Border x:Name="BadgeChanged" Background="#14532D" CornerRadius="6" Padding="10,5">
                        <TextBlock x:Name="TxtChangedCount" Text="0 Changed" FontSize="12" FontWeight="SemiBold" Foreground="#86EFAC"/>
                    </Border>
                </StackPanel>
            </Grid>
        </Border>

        <!-- Toolbar -->
        <Grid Grid.Row="1" Margin="0,0,0,8">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="Auto"/>
            </Grid.ColumnDefinitions>
            <StackPanel Orientation="Horizontal">
                <Button x:Name="BtnSelAll"     Content="Select All"     Style="{StaticResource SmallBtn}" Margin="0,0,6,0"/>
                <Button x:Name="BtnSelChanged" Content="Changed Only"   Style="{StaticResource SmallBtn}" Margin="0,0,6,0"/>
                <Button x:Name="BtnSelNone"    Content="Select None"    Style="{StaticResource SmallBtn}"/>
            </StackPanel>
            <Button x:Name="BtnRefresh" Grid.Column="1" Content="Refresh All" Style="{StaticResource SmallBtn}" Background="#0369A1"/>
        </Grid>

        <!-- Projects DataGrid -->
        <Border Grid.Row="2" Background="#0B1220" BorderBrush="#334155" BorderThickness="1" CornerRadius="8" Margin="0,0,0,12">
            <DataGrid x:Name="GridRepos" AutoGenerateColumns="False" CanUserAddRows="False" CanUserDeleteRows="False"
                      Background="Transparent" Foreground="#E2E8F0" RowBackground="#0F172A" AlternatingRowBackground="#131F35"
                      GridLinesVisibility="Horizontal" HorizontalGridLinesBrush="#1E293B" HeadersVisibility="Column"
                      BorderThickness="0" FontSize="12.5" RowHeight="32" SelectionMode="Single">
                <DataGrid.ColumnHeaderStyle>
                    <Style TargetType="DataGridColumnHeader">
                        <Setter Property="Background" Value="#1E293B"/>
                        <Setter Property="Foreground" Value="#94A3B8"/>
                        <Setter Property="FontWeight" Value="SemiBold"/>
                        <Setter Property="Padding" Value="10,7"/>
                        <Setter Property="BorderThickness" Value="0,0,0,1"/>
                        <Setter Property="BorderBrush" Value="#334155"/>
                    </Style>
                </DataGrid.ColumnHeaderStyle>
                <DataGrid.Columns>
                    <DataGridCheckBoxColumn Header="" Binding="{Binding Selected, UpdateSourceTrigger=PropertyChanged}" Width="40"/>
                    <DataGridTextColumn Header="Project" Binding="{Binding Name}" IsReadOnly="True" Width="200"/>
                    <DataGridTextColumn Header="Branch" Binding="{Binding Branch}" IsReadOnly="True" Width="95"/>
                    <DataGridTextColumn Header="Local Status" Binding="{Binding LocalStatus}" IsReadOnly="True" Width="115"/>
                    <DataGridTextColumn Header="Remote Status" Binding="{Binding RemoteStatus}" IsReadOnly="True" Width="125"/>
                    <DataGridTextColumn Header="Last Commit" Binding="{Binding LastCommit}" IsReadOnly="True" Width="*"/>
                </DataGrid.Columns>
            </DataGrid>
        </Border>

        <!-- Commit Message -->
        <StackPanel Grid.Row="3" Margin="0,0,0,12">
            <TextBlock Text="Commit Message for Changed Projects (leave blank for automatic timestamp)" FontSize="12" Foreground="#94A3B8" Margin="0,0,0,5"/>
            <TextBox x:Name="TxtCommitMsg" Background="#1E293B" Foreground="#F8FAFC" BorderBrush="#334155" BorderThickness="1"
                     Padding="10,8" FontSize="13" CaretBrush="#38BDF8"/>
        </StackPanel>

        <!-- Action Buttons -->
        <UniformGrid Grid.Row="4" Columns="4" Margin="0,0,0,12">
            <Button x:Name="BtnSync"   Content="Sync Selected (All)" Style="{StaticResource Btn}" Background="#059669" Margin="0,0,6,0"/>
            <Button x:Name="BtnPull"   Content="Pull Selected"       Style="{StaticResource Btn}" Background="#0284C7" Margin="3,0,3,0"/>
            <Button x:Name="BtnPush"   Content="Push Selected"       Style="{StaticResource Btn}" Background="#7C3AED" Margin="3,0,3,0"/>
            <Button x:Name="BtnGitHub" Content="Open on GitHub"      Style="{StaticResource Btn}" Background="#334155" Margin="6,0,0,0"/>
        </UniformGrid>

        <!-- Progress Bar -->
        <ProgressBar x:Name="PrgSync" Grid.Row="5" Height="8" Minimum="0" Maximum="100" Value="0"
                     Background="#1E293B" Foreground="#38BDF8" BorderThickness="0" Margin="0,0,0,10"/>

        <!-- Live Activity Log -->
        <Border Grid.Row="6" Background="#0B1220" BorderBrush="#334155" BorderThickness="1" CornerRadius="8">
            <TextBox x:Name="TxtLog" IsReadOnly="True" VerticalScrollBarVisibility="Auto" TextWrapping="Wrap"
                     Background="Transparent" BorderThickness="0" Foreground="#A7F3D0" FontFamily="Consolas" FontSize="11.5" Padding="10"/>
        </Border>
    </Grid>
</Window>
"@

$reader = New-Object System.Xml.XmlNodeReader $xaml
$window = [Windows.Markup.XamlReader]::Load($reader)

$GridRepos       = $window.FindName("GridRepos")
$TxtRepoCount    = $window.FindName("TxtRepoCount")
$TxtChangedCount = $window.FindName("TxtChangedCount")
$BadgeChanged    = $window.FindName("BadgeChanged")
$TxtCommitMsg    = $window.FindName("TxtCommitMsg")
$TxtLog          = $window.FindName("TxtLog")
$PrgSync         = $window.FindName("PrgSync")
$BtnSelAll       = $window.FindName("BtnSelAll")
$BtnSelChanged   = $window.FindName("BtnSelChanged")
$BtnSelNone      = $window.FindName("BtnSelNone")
$BtnRefresh      = $window.FindName("BtnRefresh")
$BtnSync         = $window.FindName("BtnSync")
$BtnPull         = $window.FindName("BtnPull")
$BtnPush         = $window.FindName("BtnPush")
$BtnGitHub       = $window.FindName("BtnGitHub")

$script:RepoItems = New-Object System.Collections.ObjectModel.ObservableCollection[Object]
$GridRepos.ItemsSource = $script:RepoItems

function Do-Events {
    $frame = New-Object System.Windows.Threading.DispatcherFrame
    [System.Windows.Threading.Dispatcher]::CurrentDispatcher.BeginInvoke(
        [System.Windows.Threading.DispatcherPriority]::Background,
        [System.Windows.Threading.DispatcherOperationCallback]{ param($f) $f.Continue = $false; $null },
        $frame
    ) | Out-Null
    [System.Windows.Threading.Dispatcher]::PushFrame($frame)
}

function Add-Log([string]$msg) {
    $ts = Get-Date -Format "HH:mm:ss"
    $TxtLog.AppendText("[$ts] $msg`r`n")
    $TxtLog.ScrollToEnd()
    Do-Events
}

function Run-Git([string]$repoPath, [string]$argsStr, [int]$timeoutSec = 120) {
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = "git"
    $psi.Arguments = $argsStr
    $psi.WorkingDirectory = $repoPath
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true
    $psi.StandardOutputEncoding = [System.Text.Encoding]::UTF8
    $psi.StandardErrorEncoding = [System.Text.Encoding]::UTF8
    $p = [System.Diagnostics.Process]::Start($psi)
    # Async drain prevents 4KB Windows pipe buffer deadlocks on large repos
    $outTask = $p.StandardOutput.ReadToEndAsync()
    $errTask = $p.StandardError.ReadToEndAsync()
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    while (-not $p.HasExited) {
        if ($sw.Elapsed.TotalSeconds -gt $timeoutSec) {
            try { $p.Kill() } catch {}
            return [PSCustomObject]@{ ExitCode = -1; Out = ""; Err = "Timed out after ${timeoutSec}s" }
        }
        Start-Sleep -Milliseconds 25
        Do-Events
    }
    return [PSCustomObject]@{
        ExitCode = $p.ExitCode
        Out      = $outTask.GetAwaiter().GetResult().Trim()
        Err      = $errTask.GetAwaiter().GetResult().Trim()
    }
}

function Set-Busy([bool]$busy) {
    $en = -not $busy
    $BtnSync.IsEnabled       = $en
    $BtnPull.IsEnabled       = $en
    $BtnPush.IsEnabled       = $en
    $BtnRefresh.IsEnabled    = $en
    $BtnSelAll.IsEnabled     = $en
    $BtnSelChanged.IsEnabled = $en
    $BtnSelNone.IsEnabled    = $en
    Do-Events
}

function Scan-Repositories {
    Set-Busy $true
    $script:RepoItems.Clear()
    $paths = @()

    $selfCheck = Run-Git $BaseDir "rev-parse --show-toplevel"
    if ($selfCheck.ExitCode -eq 0 -and $selfCheck.Out) {
        $paths += $selfCheck.Out
    } else {
        Get-ChildItem -Path $BaseDir -Directory -ErrorAction SilentlyContinue | Sort-Object Name | ForEach-Object {
            if (Test-Path (Join-Path $_.FullName ".git")) { $paths += $_.FullName }
        }
    }

    $changedTotal = 0
    $scanIdx = 0
    $scanTotal = $paths.Count
    foreach ($p in $paths) {
        $scanIdx++
        $name   = Split-Path $p -Leaf
        $TxtRepoCount.Text = "Scanning $scanIdx/$scanTotal..."
        $PrgSync.Value = [int](($scanIdx / [Math]::Max(1, $scanTotal)) * 100)
        Do-Events

        $br     = (Run-Git $p "branch --show-current" 10).Out
        if (-not $br) { $br = "(detached)" }
        $rem    = (Run-Git $p "remote get-url origin" 10).Out
        $remUrl = if ($rem) { ($rem.Trim() -replace "\.git$", "") } else { "" }
        $st     = (Run-Git $p "status --porcelain" 15).Out
        $chCnt  = if ($st) { @($st -split "`r?`n" | Where-Object { $_ -ne "" }).Count } else { 0 }
        $ahead  = 0
        if ($rem -and $br -ne "(detached)") {
            $ar = (Run-Git $p "rev-list --count origin/$br..HEAD" 10).Out
            if ($ar -match "^\d+$") { $ahead = [int]$ar }
        }
        $lc = (Run-Git $p "log -1 --pretty=format:%cr" 10).Out
        if (-not $lc) { $lc = "-" }

        if ($chCnt -gt 0 -or $ahead -gt 0) { $changedTotal++ }

        $item = [PSCustomObject]@{
            Selected     = ($chCnt -gt 0 -or $ahead -gt 0 -or $paths.Count -le 5)
            Name         = $name
            Path         = $p
            Branch       = $br
            Changes      = $chCnt
            Ahead        = $ahead
            RemoteUrl    = $remUrl
            HasRemote    = [bool]$rem
            LocalStatus  = if ($chCnt -gt 0) { "$chCnt Changed" } else { "Clean" }
            RemoteStatus = if (-not $rem) { "No Remote" } elseif ($ahead -gt 0) { "Ahead $ahead" } else { "Synced" }
            LastCommit   = $lc
        }
        $script:RepoItems.Add($item)
        Do-Events
    }
    $PrgSync.Value = 0

    $TxtRepoCount.Text = "$($script:RepoItems.Count) Repo(s)"
    $TxtChangedCount.Text = "$changedTotal Pending"
    if ($changedTotal -gt 0) {
        $BadgeChanged.Background = "#78350F"
        $TxtChangedCount.Foreground = "#FDE68A"
    } else {
        $BadgeChanged.Background = "#14532D"
        $TxtChangedCount.Foreground = "#86EFAC"
    }
    Add-Log "Scanned $BaseDir -> Found $($script:RepoItems.Count) Git repository(s), $changedTotal with pending changes."
    Set-Busy $false
}

$BtnRefresh.Add_Click({ Scan-Repositories })

$BtnSelAll.Add_Click({
    foreach ($it in $script:RepoItems) { $it.Selected = $true }
    $GridRepos.Items.Refresh()
})
$BtnSelNone.Add_Click({
    foreach ($it in $script:RepoItems) { $it.Selected = $false }
    $GridRepos.Items.Refresh()
})
$BtnSelChanged.Add_Click({
    foreach ($it in $script:RepoItems) { $it.Selected = ($it.Changes -gt 0 -or $it.Ahead -gt 0) }
    $GridRepos.Items.Refresh()
})

$BtnGitHub.Add_Click({
    $sel = $GridRepos.SelectedItem
    if (-not $sel) { $sel = ($script:RepoItems | Where-Object { $_.Selected } | Select-Object -First 1) }
    if ($sel -and $sel.RemoteUrl -and $sel.RemoteUrl.StartsWith("http")) {
        Start-Process $sel.RemoteUrl
        Add-Log "Opened $($sel.Name) on GitHub."
    } else {
        Add-Log "Select a project with an HTTP GitHub remote first."
    }
})

function Run-BatchAction([string]$mode) {
    $targets = @($script:RepoItems | Where-Object { $_.Selected })
    if ($targets.Count -eq 0) {
        Add-Log "No repositories selected. Check at least one project."
        return
    }
    Set-Busy $true
    $PrgSync.Value = 5
    $ok = 0; $err = 0; $idx = 0
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm"
    $msg = if ([string]::IsNullOrWhiteSpace($TxtCommitMsg.Text)) { "chore(sync): workspace update $ts" } else { $TxtCommitMsg.Text.Trim() }

    foreach ($r in $targets) {
        $idx++
        Add-Log "=== [$idx/$($targets.Count)] $($r.Name) ($($r.Branch)) ==="
        if ($r.Branch -eq "(detached)") {
            Add-Log "  SKIP: Detached HEAD."
            continue
        }

        if ($mode -eq "SYNC" -and $r.Changes -gt 0) {
            $a = Run-Git $r.Path "add -A"
            if ($a.ExitCode -ne 0) { Add-Log "  ERROR git add: $($a.Err)"; $err++; continue }
            $esc = $msg.Replace('"', '\"')
            $c = Run-Git $r.Path "commit -m `"$esc`""
            if ($c.ExitCode -ne 0) { Add-Log "  ERROR git commit: $($c.Err)"; $err++; continue }
            Add-Log "  OK: Committed local changes."
        }

        if (-not $r.HasRemote) {
            Add-Log "  NOTE: No remote 'origin' configured (local only)."
            $ok++
            $PrgSync.Value = [int](($idx / $targets.Count) * 100)
            continue
        }

        if ($mode -eq "SYNC" -or $mode -eq "PULL") {
            $pl = Run-Git $r.Path "pull --rebase --autostash origin $($r.Branch)"
            if ($pl.ExitCode -ne 0) { Add-Log "  ERROR pull: $($pl.Err)"; $err++; continue }
            Add-Log "  OK: Pulled origin/$($r.Branch)."
        }

        if ($mode -eq "SYNC" -or $mode -eq "PUSH") {
            $ah = (Run-Git $r.Path "rev-list --count origin/$($r.Branch)..HEAD").Out
            if ($ah -match "^\d+$" -and [int]$ah -gt 0) {
                $ps = Run-Git $r.Path "push origin $($r.Branch)"
                if ($ps.ExitCode -ne 0) { Add-Log "  ERROR push: $($ps.Err)"; $err++; continue }
                Add-Log "  OK: Pushed $ah commit(s) to GitHub."
            } else {
                Add-Log "  OK: Already up to date with origin/$($r.Branch)."
            }
        }

        $ok++
        $PrgSync.Value = [int](($idx / $targets.Count) * 100)
    }

    $TxtCommitMsg.Text = ""
    Add-Log "DONE: $ok succeeded | $err error(s)."
    try { [Console]::Beep(880, 100); [Console]::Beep(1175, 130) } catch {}
    if ($err -eq 0) {
        Show-TrayNotify "GitHub Sync Completed" "$ok project(s) synchronized successfully." "Info"
    } else {
        Show-TrayNotify "GitHub Sync Finished with Errors" "$ok succeeded, $err error(s). Open Hub to review log." "Warning"
    }
    Scan-Repositories
}

# ============================================================================
# SYSTEM TRAY (HIDDEN ICONS) + WINDOWS NOTIFICATIONS
# ============================================================================
function New-SyncTrayIcon {
    $bmp = New-Object System.Drawing.Bitmap 32, 32
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.Clear([System.Drawing.Color]::Transparent)
    $bgBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 14, 165, 233))
    $g.FillEllipse($bgBrush, 2, 2, 28, 28)
    $pen = New-Object System.Drawing.Pen ([System.Drawing.Color]::White), 3
    $g.DrawArc($pen, 8, 8, 16, 16, 30, 130)
    $g.DrawArc($pen, 8, 8, 16, 16, 210, 130)
    $g.Dispose(); $bgBrush.Dispose(); $pen.Dispose()
    $hIcon = $bmp.GetHicon()
    $icon = [System.Drawing.Icon]::FromHandle($hIcon)
    return $icon
}

$script:AllowExit = $false
$script:NotifiedHide = $false
$script:TrayIcon = New-Object System.Windows.Forms.NotifyIcon
$script:TrayIcon.Icon = New-SyncTrayIcon
$script:TrayIcon.Text = "GitHub Sync Hub"
$script:TrayIcon.Visible = $true

function Show-TrayNotify([string]$title, [string]$body, [string]$kind = "Info") {
    $script:TrayIcon.BalloonTipTitle = $title
    $script:TrayIcon.BalloonTipText  = $body
    $script:TrayIcon.BalloonTipIcon  = switch ($kind) {
        "Warning" { [System.Windows.Forms.ToolTipIcon]::Warning }
        "Error"   { [System.Windows.Forms.ToolTipIcon]::Error }
        default   { [System.Windows.Forms.ToolTipIcon]::Info }
    }
    $script:TrayIcon.ShowBalloonTip(4000)
}

function Restore-MainWindow {
    $window.Show()
    $window.WindowState = [System.Windows.WindowState]::Normal
    $window.Activate() | Out-Null
    $window.Topmost = $true
    $window.Topmost = $false
}

$trayMenu = New-Object System.Windows.Forms.ContextMenuStrip
$miOpen = $trayMenu.Items.Add("Open Dashboard")
$miQuick = $trayMenu.Items.Add("Quick Sync Changed Projects")
$miRef = $trayMenu.Items.Add("Refresh Status")
[void]$trayMenu.Items.Add("-")
$miExit = $trayMenu.Items.Add("Exit")

$miOpen.Add_Click({ Restore-MainWindow })
$miRef.Add_Click({
    Scan-Repositories
    $pending = @($script:RepoItems | Where-Object { $_.Changes -gt 0 -or $_.Ahead -gt 0 }).Count
    Show-TrayNotify "GitHub Sync Hub" "Refreshed $($script:RepoItems.Count) repo(s). $pending pending." "Info"
})
$miQuick.Add_Click({
    foreach ($it in $script:RepoItems) { $it.Selected = ($it.Changes -gt 0 -or $it.Ahead -gt 0) }
    $GridRepos.Items.Refresh()
    $pending = @($script:RepoItems | Where-Object { $_.Selected }).Count
    if ($pending -eq 0) {
        Show-TrayNotify "GitHub Sync Hub" "All projects are already clean and up to date." "Info"
    } else {
        Run-BatchAction "SYNC"
    }
})
$miExit.Add_Click({
    $script:AllowExit = $true
    $script:TrayIcon.Visible = $false
    $script:TrayIcon.Dispose()
    $window.Close()
})

$script:TrayIcon.ContextMenuStrip = $trayMenu
$script:TrayIcon.Add_DoubleClick({ Restore-MainWindow })

$window.Add_StateChanged({
    if ($window.WindowState -eq [System.Windows.WindowState]::Minimized) {
        $window.Hide()
        if (-not $script:NotifiedHide) {
            $script:NotifiedHide = $true
            Show-TrayNotify "GitHub Sync Hub" "Minimized to Hidden Icons. Double-click to open or right-click to Exit." "Info"
        }
    }
})

$window.Add_Closing({
    param($s, $e)
    if (-not $script:AllowExit) {
        $e.Cancel = $true
        $window.Hide()
        if (-not $script:NotifiedHide) {
            $script:NotifiedHide = $true
            Show-TrayNotify "GitHub Sync Hub" "Running in Hidden Icons. Double-click icon to reopen, or right-click -> Exit." "Info"
        }
    } else {
        $script:TrayIcon.Visible = $false
        $script:TrayIcon.Dispose()
    }
})

$BtnSync.Add_Click({ Run-BatchAction "SYNC" })
$BtnPull.Add_Click({ Run-BatchAction "PULL" })
$BtnPush.Add_Click({ Run-BatchAction "PUSH" })

$window.Add_ContentRendered({ Scan-Repositories })
$window.ShowDialog() | Out-Null
