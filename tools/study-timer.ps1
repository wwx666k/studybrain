param(
  [string]$Task = 'custom',
  [string]$Title = '',
  [int]$Minutes = 25,
  [string]$At = '',
  [string]$Next = 'none',
  [string]$NextTitle = ''
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$names = @{
  math     = '数学压轴题'
  english  = '背单词'
  chinese  = '语文阅读'
  history  = '历史复习'
  politic  = '政治背诵'
  writing  = '练字'
  notes    = '整理笔记'
  homework = '学校作业'
  errorfix = '错题复盘'
  physics  = '物理网课'
  chemistry= '化学网课'
  break    = '休息'
  free     = '自由时间'
  custom   = '专注'
  none     = ''
}

function Get-TaskName([string]$key, [string]$t) {
  if ($t -ne '') { return $t }
  $n = $names[$key]
  if ($n -ne $null -and $n -ne '') { return $n }
  return '专注'
}

$taskName = Get-TaskName $Task $Title
if ($Next -eq 'none' -or $Next -eq '') { $nextName = '' } else { $nextName = Get-TaskName $Next $NextTitle }

if ($At -ne '') {
  $parsed = [datetime]::ParseExact($At, 'HH:mm', $null)
  $now = Get-Date
  $target = $now.Date.AddHours($parsed.Hour).AddMinutes($parsed.Minute)
  if ($target -le $now) { $target = $target.AddDays(1) }
  $totalSeconds = [int][math]::Ceiling(($target - $now).TotalSeconds)
} else {
  $totalSeconds = $Minutes * 60
}
if ($totalSeconds -lt 1) { $totalSeconds = 1 }

$dataDir = Join-Path (Split-Path $PSScriptRoot -Parent) 'data'
if (-not (Test-Path $dataDir)) { New-Item -ItemType Directory -Path $dataDir -Force | Out-Null }
$logPath = Join-Path $dataDir 'sessions.csv'

$script:taskKey    = $Task
$script:remaining  = $totalSeconds
$script:budget     = $totalSeconds
$script:plannedSec = $totalSeconds
$script:paused     = $false
$script:dragging   = $false
$script:logged     = $false
$script:offset     = New-Object System.Drawing.Point(0, 0)
$script:taskName   = $taskName
$script:nextName   = $nextName
$script:finish     = $false
$script:finishMenu = $null

function Write-SessionLog([string]$status) {
  if ($script:logged) { return }
  $script:logged = $true
  $actualSec = $script:budget - $script:remaining
  if ($actualSec -lt 0) { $actualSec = 0 }
  $plannedMin = [math]::Round($script:plannedSec / 60, 1)
  $actualMin  = [math]::Round($actualSec / 60, 1)
  if (-not (Test-Path $logPath)) {
    '日期,时间,科目,计划分钟,实际分钟,状态' | Out-File -FilePath $logPath -Encoding UTF8
  }
  $line = '{0},{1},{2},{3},{4},{5}' -f (Get-Date -Format 'yyyy-MM-dd'), (Get-Date -Format 'HH:mm'), $script:taskKey, $plannedMin, $actualMin, $status
  Add-Content -Path $logPath -Value $line -Encoding UTF8
}

# ---------------- 结束后把 Trae 窗口拉到前台 ----------------
function Show-TraeWindow {
  try {
    $proc = Get-Process | Where-Object { $_.ProcessName -like 'Trae*' -and $_.MainWindowHandle -ne 0 } | Select-Object -First 1
    if ($proc -eq $null) { return }
    $ws = New-Object -ComObject WScript.Shell
    $null = $ws.AppActivate($proc.Id)
    Start-Sleep -Milliseconds 150
    [GlassWin]::ShowWindow($proc.MainWindowHandle, 9) | Out-Null
    [GlassWin]::SetForegroundWindow($proc.MainWindowHandle) | Out-Null
  } catch {}
}

# ---------------- 分层窗口（逐像素透明 / 毛玻璃质感） ----------------
Add-Type -TypeDefinition @'
using System;
using System.Drawing;
using System.Runtime.InteropServices;

public class GlassWin {
  [StructLayout(LayoutKind.Sequential)] public struct POINT { public int X, Y; }
  [StructLayout(LayoutKind.Sequential)] public struct SIZE { public int cx, cy; }
  [StructLayout(LayoutKind.Sequential, Pack = 1)]
  public struct BLENDFUNCTION { public byte BlendOp, BlendFlags, SourceConstantAlpha, AlphaFormat; }

  [DllImport("user32.dll", SetLastError = true)]
  public static extern bool UpdateLayeredWindow(IntPtr hwnd, IntPtr hdcDst, ref POINT pptDst,
      ref SIZE psize, IntPtr hdcSrc, ref POINT pptSrc, int crKey, ref BLENDFUNCTION pblend, int dwFlags);
  [DllImport("user32.dll")] public static extern IntPtr GetDC(IntPtr hWnd);
  [DllImport("user32.dll")] public static extern int ReleaseDC(IntPtr hWnd, IntPtr hDC);
  [DllImport("user32.dll")] public static extern int GetWindowLong(IntPtr hWnd, int nIndex);
  [DllImport("user32.dll")] public static extern int SetWindowLong(IntPtr hWnd, int nIndex, int dwNewLong);
  [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
  [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hWnd);
  [DllImport("gdi32.dll")] public static extern IntPtr CreateCompatibleDC(IntPtr hdc);
  [DllImport("gdi32.dll")] public static extern IntPtr SelectObject(IntPtr hdc, IntPtr h);
  [DllImport("gdi32.dll")] public static extern bool DeleteObject(IntPtr h);
  [DllImport("gdi32.dll")] public static extern bool DeleteDC(IntPtr hdc);
  [DllImport("dwmapi.dll")] public static extern int DwmSetWindowAttribute(IntPtr hwnd, int attr, ref int val, int size);

  [StructLayout(LayoutKind.Sequential)]
  public struct ACCENTPOLICY { public int AccentState; public int AccentFlags; public int GradientColor; public int AnimationId; }
  [StructLayout(LayoutKind.Sequential)]
  public struct WINDATA { public int Attrib; public IntPtr pvData; public int cbData; }
  [DllImport("user32.dll")]
  public static extern int SetWindowCompositionAttribute(IntPtr hwnd, ref WINDATA data);

  // 真·毛玻璃（DWM Acrylic），tint 为 AABBGGRR 白色 20%
  public static void EnableAcrylic(IntPtr hwnd, int tint) {
    ACCENTPOLICY accent = new ACCENTPOLICY();
    accent.AccentState = 3;      // ACCENT_ENABLE_BLURBEHIND（只模糊，不上色）
    accent.AccentFlags = 2;
    accent.GradientColor = 0;
    accent.AnimationId = 0;
    WINDATA data = new WINDATA();
    data.Attrib = 19;            // WCA_ACCENT_POLICY
    data.cbData = Marshal.SizeOf(accent);
    IntPtr ptr = Marshal.AllocHGlobal(data.cbData);
    try {
      Marshal.StructureToPtr(accent, ptr, false);
      data.pvData = ptr;
      SetWindowCompositionAttribute(hwnd, ref data);
    } finally { Marshal.FreeHGlobal(ptr); }
  }

  public static void MakeLayered(IntPtr hwnd) {
    int ex = GetWindowLong(hwnd, -20);
    SetWindowLong(hwnd, -20, ex | 0x00080000 | 0x00000008); // LAYERED | TOPMOST
    int pref = 1; // DWMWCP_DONOTROUND：圆角由我们自己画，避免系统再切一刀造成四角发灰
    try { DwmSetWindowAttribute(hwnd, 33, ref pref, sizeof(int)); } catch {}
    // 注意：layered 窗口 + blur-behind 会静止时变黑，故不启用
  }

  public static void Render(IntPtr hwnd, IntPtr hBitmap, int x, int y, int w, int h) {
    IntPtr screenDc = GetDC(IntPtr.Zero);
    IntPtr memDc = CreateCompatibleDC(screenDc);
    IntPtr oldBmp = SelectObject(memDc, hBitmap);
    POINT src = new POINT(); src.X = 0; src.Y = 0;
    POINT dst = new POINT(); dst.X = x; dst.Y = y;
    SIZE sz = new SIZE(); sz.cx = w; sz.cy = h;
    BLENDFUNCTION bf = new BLENDFUNCTION();
    bf.BlendOp = 0; bf.BlendFlags = 0; bf.SourceConstantAlpha = 255; bf.AlphaFormat = 1;
    UpdateLayeredWindow(hwnd, screenDc, ref dst, ref sz, memDc, ref src, 0, ref bf, 2);
    SelectObject(memDc, oldBmp);
    DeleteDC(memDc);
    ReleaseDC(IntPtr.Zero, screenDc);
  }
}
'@ -ReferencedAssemblies System.Drawing

$W = 200
$H = 84
$R = 30

$form = New-Object System.Windows.Forms.Form
$form.FormBorderStyle = 'None'
$form.StartPosition   = 'Manual'
$form.ShowInTaskbar   = $false
$form.TopMost         = $true
$form.Size            = New-Object System.Drawing.Size($W, $H)
$form.BackColor       = [System.Drawing.Color]::Black
$form.Text            = "$taskName 计时"

$wa = [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea
$form.Location = New-Object System.Drawing.Point(($wa.Right - $W - 28), ($wa.Bottom - $H - 28))

# 圆角路径
function New-RoundPath([single]$x, [single]$y, [single]$w, [single]$h, [single]$r) {
  $p = New-Object System.Drawing.Drawing2D.GraphicsPath
  $d = $r * 2
  $p.AddArc($x, $y, $d, $d, 180, 90)
  $p.AddArc($x + $w - $d, $y, $d, $d, 270, 90)
  $p.AddArc($x + $w - $d, $y + $h - $d, $d, $d, 0, 90)
  $p.AddArc($x, $y + $h - $d, $d, $d, 90, 90)
  $p.CloseFigure()
  return $p
}

$fgMain  = [System.Drawing.Color]::FromArgb(240, 18, 22, 28)
$fgTask  = [System.Drawing.Color]::FromArgb(150, 40, 46, 56)
$fgPause = [System.Drawing.Color]::FromArgb(130, 40, 46, 56)
$fgWarn  = [System.Drawing.Color]::FromArgb(235, 214, 60, 62)
$accent  = [System.Drawing.Color]::FromArgb(215, 10, 132, 255)
if ($Task -eq 'break' -or $Task -eq 'free') {
  $accent = [System.Drawing.Color]::FromArgb(215, 40, 172, 108)
}

$fontTask  = New-Object System.Drawing.Font('Microsoft YaHei UI', 8.5)
$fontTime  = New-Object System.Drawing.Font('Segoe UI Semibold', 23)
$fontSmall = New-Object System.Drawing.Font('Microsoft YaHei UI', 11, [System.Drawing.FontStyle]::Bold)
$fmtLeft   = New-Object System.Drawing.StringFormat
$fmtRight  = New-Object System.Drawing.StringFormat
$fmtRight.Alignment = 'Far'

function Update-Glass {
  $bmp = New-Object System.Drawing.Bitmap($W, $H, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.SmoothingMode = 'AntiAlias'
  $g.TextRenderingHint = 'AntiAliasGridFit'
  $g.Clear([System.Drawing.Color]::Transparent)

  $path = New-RoundPath 0.5 0.5 ($W - 1) ($H - 1) $R

  # 厚磨砂白层（约 80%），背后内容基本糊掉
  $brMain = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(205, 255, 255, 255))
  $g.FillPath($brMain, $path)

  # 文案
  if ($script:finish) {
    $g.DrawString('时间到', $fontSmall, (New-Object System.Drawing.SolidBrush($fgWarn)), 16, 32)
    $g.DrawString('右键', $fontTask, (New-Object System.Drawing.SolidBrush($fgTask)), 92, 40)
  } else {
    $g.DrawString($script:taskName, $fontTask, (New-Object System.Drawing.SolidBrush($fgTask)), 16, 12)
    $m = [int][math]::Floor([math]::Max($script:remaining, 0) / 60)
    $s = [math]::Max($script:remaining, 0) % 60
    $timeTxt = '{0:D2}:{1:D2}' -f $m, $s
    $col = $fgMain
    if ($script:paused) { $col = $fgPause }
    $g.DrawString($timeTxt, $fontTime, (New-Object System.Drawing.SolidBrush($col)), 14, 26)

    $ratio = 1.0
    if ($script:budget -gt 0) { $ratio = $script:remaining / $script:budget }
    if ($ratio -lt 0) { $ratio = 0 }
    $bx = 16.0
    $bw = ($W - 44) * $ratio
    if ($bw -lt 1) { $bw = 1 }
    $by = $H - 14
    $penBar = New-Object System.Drawing.Pen($accent, 3)
    $penBar.StartCap = 'Round'
    $penBar.EndCap = 'Round'
    $g.DrawLine($penBar, $bx, $by, ($bx + $bw), $by)
  }

  # 关闭 ×
  $g.DrawString('×', $fontSmall, (New-Object System.Drawing.SolidBrush($fgTask)), 178, 8)

  $g.Dispose()
  $hb = $bmp.GetHbitmap([System.Drawing.Color]::FromArgb(0, 0, 0, 0))
  [GlassWin]::Render($form.Handle, $hb, $form.Left, $form.Top, $W, $H)
  [GlassWin]::DeleteObject($hb)
  $bmp.Dispose()
}

$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 1000

$showFinish = {
  $script:finish = $true
  $timer.Stop()
  Update-Glass
  $menu = New-Object System.Windows.Forms.ContextMenuStrip
  $miDone = $menu.Items.Add('完成')
  $mi5    = $menu.Items.Add('延迟 5 分钟')
  $mi10   = $menu.Items.Add('延迟 10 分钟')
  $script:finishMenu = $menu
  $miDone.Add_Click({ Write-SessionLog '完成'; Show-TraeWindow; $form.Close() })
  $mi5.Add_Click({ $script:finishMenu = $null; & $startWith 300 })
  $mi10.Add_Click({ $script:finishMenu = $null; & $startWith 600 })
  for ($i = 0; $i -lt 4; $i++) {
    [System.Media.SystemSounds]::Exclamation.Play()
    Start-Sleep -Milliseconds 250
  }
}

$startWith = {
  param($seconds)
  $script:finish     = $false
  $script:remaining  = $seconds
  $script:budget     = $seconds
  $script:paused     = $false
  Update-Glass
  $timer.Start()
}

$timer.Add_Tick({
  if ($script:paused) { return }
  if ($script:remaining -le 0) { return }
  $script:remaining = $script:remaining - 1
  Update-Glass
  if ($script:remaining -le 0) { & $showFinish }
})

# ---- 鼠标交互 ----
$form.Add_MouseDown({
  if ($_.Button -eq [System.Windows.Forms.MouseButtons]::Left) {
    $script:offset = $_.Location
    $script:dragging = $true
  }
})
$form.Add_MouseMove({
  if ($script:dragging) {
    $p = $form.PointToScreen($_.Location)
    $form.Location = New-Object System.Drawing.Point(($p.X - $script:offset.X), ($p.Y - $script:offset.Y))
    Update-Glass
  }
})
$form.Add_MouseUp({ $script:dragging = $false })

$form.Add_MouseDoubleClick({
  if ($script:finish) { return }
  $script:paused = -not $script:paused
  Update-Glass
})

$menu = New-Object System.Windows.Forms.ContextMenuStrip
$miPause = $menu.Items.Add('暂停')
$miReset = $menu.Items.Add('重置')
$miEarly = $menu.Items.Add('提前结束')
$menu.Items.Add('-') | Out-Null
$miClose = $menu.Items.Add('关闭（记中断）')

$miPause.Add_Click({
  $script:paused = -not $script:paused
  $miPause.Text = $(if ($script:paused) { '继续' } else { '暂停' })
  Update-Glass
})
$miReset.Add_Click({ & $startWith $script:plannedSec })
$miEarly.Add_Click({ Write-SessionLog '提前结束'; Show-TraeWindow; $form.Close() })
$miClose.Add_Click({ Write-SessionLog '中断'; $form.Close() })

$form.Add_MouseClick({
  if ($_.Button -eq [System.Windows.Forms.MouseButtons]::Right) {
    if ($script:finishMenu -ne $null) { $script:finishMenu.Show([System.Windows.Forms.Cursor]::Position) }
    else { $menu.Show([System.Windows.Forms.Cursor]::Position) }
  }
  elseif ($_.Button -eq [System.Windows.Forms.MouseButtons]::Left) {
    if ($_.X -ge 172 -and $_.Y -le 28) {
      Write-SessionLog '中断'
      $form.Close()
    }
  }
})

$form.Add_Shown({
  [GlassWin]::MakeLayered($form.Handle)
  Update-Glass
  $timer.Start()
})

[System.Windows.Forms.Application]::Run($form)
