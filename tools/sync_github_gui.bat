@echo off
chcp 65001 >nul
setlocal
start "" /b powershell.exe -NoProfile -WindowStyle Hidden -STA -ExecutionPolicy Bypass -Command "$code = (Get-Content -Encoding UTF8 '%~f0' | Select-Object -Skip 6) -join [Environment]::NewLine; & ([ScriptBlock]::Create($code)) -ScriptDir '%~dp0'"
exit /b 0
:: --- POWERSHELL PAYLOAD BELOW ---
param(
    [string]$ScriptDir = (Get-Location).Path
)

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

# Resolve Git repo root from wherever this .bat was launched
Set-Location $ScriptDir
$RepoRoot = (git rev-parse --show-toplevel 2>$null)
if (-not $RepoRoot) {
    [System.Windows.MessageBox]::Show(
        "This folder is not inside a Git repository:`n$ScriptDir",
        "GitHub Sync - Error",
        [System.Windows.MessageBoxButton]::OK,
        [System.Windows.MessageBoxImage]::Error
    ) | Out-Null
    exit 1
}
Set-Location $RepoRoot
$ProjName  = Split-Path $RepoRoot -Leaf
$Branch    = (git branch --show-current 2>$null).Trim()
$RemoteUrl = (git remote get-url origin 2>$null)
if ($RemoteUrl) { $RemoteUrl = $RemoteUrl.Trim() -replace "\.git$", "" }

[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="GitHub Sync - $ProjName"
        Height="610" Width="740" MinHeight="540" MinWidth="640"
        WindowStartupLocation="CenterScreen"
        Background="#0F172A" Foreground="#E2E8F0"
        FontFamily="Segoe UI">
    <Window.Resources>
        <Style x:Key="ActionBtn" TargetType="Button">
            <Setter Property="Foreground" Value="#FFFFFF"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="FontSize" Value="13"/>
            <Setter Property="Padding" Value="14,10"/>
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
    </Window.Resources>

    <Grid Margin="18">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="140"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
        </Grid.RowDefinitions>

        <!-- Header Card -->
        <Border Grid.Row="0" Background="#1E293B" CornerRadius="10" Padding="16,12" Margin="0,0,0,12">
            <Grid>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>
                <StackPanel Grid.Column="0">
                    <TextBlock x:Name="TxtProject" Text="$ProjName" FontSize="20" FontWeight="Bold" Foreground="#38BDF8"/>
                    <TextBlock x:Name="TxtPath" Text="$RepoRoot" FontSize="11.5" Foreground="#94A3B8" Margin="0,2,0,0"/>
                </StackPanel>
                <StackPanel Grid.Column="1" Orientation="Horizontal" VerticalAlignment="Center">
                    <Border Background="#0C4A6E" CornerRadius="6" Padding="10,5" Margin="0,0,8,0">
                        <TextBlock x:Name="TxtBranch" Text="branch: $Branch" FontSize="12" FontWeight="SemiBold" Foreground="#7DD3FC"/>
                    </Border>
                    <Border x:Name="BadgeStatus" Background="#14532D" CornerRadius="6" Padding="10,5">
                        <TextBlock x:Name="TxtStatusBadge" Text="Checking..." FontSize="12" FontWeight="SemiBold" Foreground="#86EFAC"/>
                    </Border>
                </StackPanel>
            </Grid>
        </Border>

        <!-- Changed Files Header -->
        <Grid Grid.Row="1" Margin="0,0,0,6">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="Auto"/>
            </Grid.ColumnDefinitions>
            <TextBlock Text="Modified &amp; Untracked Files" FontSize="12.5" FontWeight="SemiBold" Foreground="#CBD5E1" VerticalAlignment="Center"/>
            <Button x:Name="BtnRefresh" Grid.Column="1" Content="Refresh" Style="{StaticResource ActionBtn}" Background="#334155" Padding="12,4" FontSize="11.5"/>
        </Grid>

        <!-- Changed Files List -->
        <Border Grid.Row="2" Background="#0B1220" BorderBrush="#334155" BorderThickness="1" CornerRadius="8" Margin="0,0,0,12">
            <ListBox x:Name="LstFiles" Background="Transparent" BorderThickness="0" Foreground="#E2E8F0" FontFamily="Consolas" FontSize="12" Padding="6"/>
        </Border>

        <!-- Commit Message -->
        <StackPanel Grid.Row="3" Margin="0,0,0,12">
            <TextBlock Text="Commit Message (leave blank for automatic timestamp)" FontSize="12" Foreground="#94A3B8" Margin="0,0,0,5"/>
            <TextBox x:Name="TxtCommitMsg" Background="#1E293B" Foreground="#F8FAFC" BorderBrush="#334155" BorderThickness="1"
                     Padding="10,8" FontSize="13" CaretBrush="#38BDF8"/>
        </StackPanel>

        <!-- Action Buttons -->
        <UniformGrid Grid.Row="4" Columns="4" Margin="0,0,0,12">
            <Button x:Name="BtnSync"   Content="Sync Now (All)" Style="{StaticResource ActionBtn}" Background="#059669" Margin="0,0,6,0"/>
            <Button x:Name="BtnPull"   Content="Pull Only"      Style="{StaticResource ActionBtn}" Background="#0284C7" Margin="3,0,3,0"/>
            <Button x:Name="BtnPush"   Content="Push Only"      Style="{StaticResource ActionBtn}" Background="#7C3AED" Margin="3,0,3,0"/>
            <Button x:Name="BtnGitHub" Content="Open GitHub"    Style="{StaticResource ActionBtn}" Background="#334155" Margin="6,0,0,0"/>
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

$LstFiles       = $window.FindName("LstFiles")
$TxtCommitMsg   = $window.FindName("TxtCommitMsg")
$TxtLog         = $window.FindName("TxtLog")
$PrgSync        = $window.FindName("PrgSync")
$BadgeStatus    = $window.FindName("BadgeStatus")
$TxtStatusBadge = $window.FindName("TxtStatusBadge")
$BtnSync        = $window.FindName("BtnSync")
$BtnPull        = $window.FindName("BtnPull")
$BtnPush        = $window.FindName("BtnPush")
$BtnGitHub      = $window.FindName("BtnGitHub")
$BtnRefresh     = $window.FindName("BtnRefresh")

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

function Run-Git([string]$argsStr) {
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = "git"
    $psi.Arguments = $argsStr
    $psi.WorkingDirectory = $RepoRoot
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true
    $psi.StandardOutputEncoding = [System.Text.Encoding]::UTF8
    $psi.StandardErrorEncoding = [System.Text.Encoding]::UTF8
    $p = [System.Diagnostics.Process]::Start($psi)
    while (-not $p.HasExited) {
        Start-Sleep -Milliseconds 40
        Do-Events
    }
    return [PSCustomObject]@{
        ExitCode = $p.ExitCode
        Out      = $p.StandardOutput.ReadToEnd().Trim()
        Err      = $p.StandardError.ReadToEnd().Trim()
    }
}

function Set-ButtonsEnabled([bool]$enabled) {
    $BtnSync.IsEnabled    = $enabled
    $BtnPull.IsEnabled    = $enabled
    $BtnPush.IsEnabled    = $enabled
    $BtnRefresh.IsEnabled = $enabled
    Do-Events
}

function Refresh-Status {
    $LstFiles.Items.Clear()
    $res = Run-Git "status --porcelain"
    $lines = @()
    if ($res.Out) { $lines = $res.Out -split "`r?`n" | Where-Object { $_ -ne "" } }
    if ($lines.Count -eq 0) {
        $LstFiles.Items.Add("  Working tree is clean. Ready to sync.") | Out-Null
        $BadgeStatus.Background = "#14532D"
        $TxtStatusBadge.Foreground = "#86EFAC"
        $TxtStatusBadge.Text = "Clean"
    } else {
        foreach ($l in $lines) { $LstFiles.Items.Add("  $l") | Out-Null }
        $BadgeStatus.Background = "#78350F"
        $TxtStatusBadge.Foreground = "#FDE68A"
        $TxtStatusBadge.Text = "$($lines.Count) Changed"
    }
    Do-Events
}

$BtnRefresh.Add_Click({
    Add-Log "Refreshing repository status..."
    Refresh-Status
})

$BtnGitHub.Add_Click({
    if ($RemoteUrl -and $RemoteUrl.StartsWith("http")) {
        Start-Process $RemoteUrl
    } else {
        Add-Log "No HTTP remote URL configured for origin."
    }
})

$BtnPull.Add_Click({
    Set-ButtonsEnabled $false
    $PrgSync.Value = 30
    Add-Log "Pulling latest updates from origin/$Branch..."
    $r = Run-Git "pull --rebase --autostash origin $Branch"
    if ($r.ExitCode -eq 0) {
        $PrgSync.Value = 100
        Add-Log "OK: Pull completed. $($r.Out)"
    } else {
        $PrgSync.Value = 0
        Add-Log "ERROR: Pull failed. $($r.Err)"
    }
    Refresh-Status
    Set-ButtonsEnabled $true
})

$BtnPush.Add_Click({
    Set-ButtonsEnabled $false
    $PrgSync.Value = 40
    Add-Log "Pushing to origin/$Branch..."
    $r = Run-Git "push origin $Branch"
    if ($r.ExitCode -eq 0) {
        $PrgSync.Value = 100
        Add-Log "OK: Push completed."
    } else {
        $PrgSync.Value = 0
        Add-Log "ERROR: Push failed. $($r.Err)"
    }
    Refresh-Status
    Set-ButtonsEnabled $true
})

$BtnSync.Add_Click({
    Set-ButtonsEnabled $false
    $PrgSync.Value = 15
    Add-Log "Starting full two-way sync on branch '$Branch'..."

    $st = Run-Git "status --porcelain"
    if ($st.Out) {
        $ts = Get-Date -Format "yyyy-MM-dd HH:mm"
        $msg = if ([string]::IsNullOrWhiteSpace($TxtCommitMsg.Text)) { "chore(sync): workspace update $ts" } else { $TxtCommitMsg.Text.Trim() }
        Add-Log "Staging all local changes..."
        $a = Run-Git "add -A"
        if ($a.ExitCode -ne 0) { Add-Log "ERROR: git add failed: $($a.Err)"; $PrgSync.Value = 0; Set-ButtonsEnabled $true; return }
        $PrgSync.Value = 35

        Add-Log "Committing: $msg"
        $esc = $msg.Replace('"', '\"')
        $c = Run-Git "commit -m `"$esc`""
        if ($c.ExitCode -ne 0) { Add-Log "ERROR: git commit failed: $($c.Err)"; $PrgSync.Value = 0; Set-ButtonsEnabled $true; return }
        $TxtCommitMsg.Text = ""
    } else {
        Add-Log "No local changes to commit."
    }

    $PrgSync.Value = 60
    Add-Log "Pulling updates from origin/$Branch..."
    $pl = Run-Git "pull --rebase --autostash origin $Branch"
    if ($pl.ExitCode -ne 0) {
        Add-Log "ERROR: Pull/rebase failed: $($pl.Err)"
        $PrgSync.Value = 0
        Refresh-Status
        Set-ButtonsEnabled $true
        return
    }

    $PrgSync.Value = 82
    $ahead = Run-Git "rev-list --count origin/$Branch..HEAD"
    if ($ahead.Out -match "^\d+$" -and [int]$ahead.Out -gt 0) {
        Add-Log "Pushing $($ahead.Out) commit(s) to origin/$Branch..."
        $ps = Run-Git "push origin $Branch"
        if ($ps.ExitCode -ne 0) {
            Add-Log "ERROR: Push failed: $($ps.Err)"
            $PrgSync.Value = 0
            Refresh-Status
            Set-ButtonsEnabled $true
            return
        }
        Add-Log "OK: Pushed $($ahead.Out) commit(s) to GitHub."
    } else {
        Add-Log "Already up to date with origin/$Branch."
    }

    $PrgSync.Value = 100
    Add-Log "SYNC COMPLETED SUCCESSFULLY."
    try { [Console]::Beep(880, 100); [Console]::Beep(1175, 130) } catch {}
    Refresh-Status
    Set-ButtonsEnabled $true
})

$window.Add_Loaded({
    Add-Log "Connected to repository: $ProjName ($Branch)"
    Refresh-Status
})

$window.ShowDialog() | Out-Null
