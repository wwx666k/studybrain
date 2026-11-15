param(
  [string]$Project = 'learnrept',
  [switch]$Deploy,
  [switch]$Day,
  [datetime]$Anchor
)
$ErrorActionPreference = 'Stop'
$root = 'D:\StudyBrain'
$csv  = Join-Path $root 'data\sessions.csv'
$note = Join-Path $root 'data\notes.csv'
$site = Join-Path $root 'reports\site'
$dailyDir  = Join-Path $site 'daily'
$weekDir   = Join-Path $site 'reports\weekly'
$monthDir  = Join-Path $site 'reports\monthly'
$yearDir   = Join-Path $site 'reports\yearly'
$assetDir  = Join-Path $site 'assets'
foreach ($d in @($site, $dailyDir, $weekDir, $monthDir, $yearDir, $assetDir)) {
  if (!(Test-Path $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }
}

$names = @{ math='数学压轴题'; english='背单词'; chinese='语文阅读'; history='历史'; politic='政治';
            writing='练字'; notes='整理笔记'; homework='学校作业'; errorfix='错题复盘';
            physics='物理网课'; chemistry='化学网课'; custom='专注' }

$rows = @()
if (Test-Path $csv) {
  $rows = Import-Csv $csv -Encoding UTF8 | Where-Object { $_.科目 -ne 'break' -and $_.科目 -ne 'free' } | ForEach-Object {
    [pscustomobject]@{ Date = [datetime]::ParseExact($_.日期, 'yyyy-MM-dd', $null); Min = [double]$_.实际分钟 }
  }
}
$noteMap = @{}
if (Test-Path $note) {
  Import-Csv $note -Encoding UTF8 | ForEach-Object { if (!$noteMap.ContainsKey($_.日期)) { $noteMap[$_.日期] = @() }; $noteMap[$_.日期] += ($names[$_.科目] + '：' + $_.总结) }
}

# ---------- 把加载动画注入报告页 ----------
$loaderCss = '<style id="sb-loader-css">#sb-loader{position:fixed;inset:0;z-index:9999;display:flex;align-items:center;justify-content:center;background:rgba(11,13,18,.72);backdrop-filter:blur(14px);-webkit-backdrop-filter:blur(14px);transition:opacity .35s ease}#sb-loader.hide{opacity:0;pointer-events:none}#sb-loader .ring{width:34px;height:34px;border-radius:50%;border:2.5px solid rgba(106,168,255,.22);border-top-color:#6aa8ff;border-right-color:#8f6aff;animation:sbSpin .8s linear infinite;box-shadow:0 0 18px rgba(106,168,255,.35)}@keyframes sbSpin{to{transform:rotate(360deg)}}</style>'
$loaderHtml = '<div id="sb-loader"><div class="ring"></div></div><script>(function(){var l=document.getElementById("sb-loader");function hide(){setTimeout(function(){l.classList.add("hide")},220)}if(document.readyState==="complete")hide();else window.addEventListener("load",hide);document.addEventListener("click",function(e){var a=e.target.closest?e.target.closest("a"):null;if(a&&a.getAttribute("href")&&a.getAttribute("href").indexOf("#")!==0&&!a.target){l.classList.remove("hide")}})})();</script>'

function Add-Loader([string]$path) {
  if (!(Test-Path $path)) { return }
  $h = [System.IO.File]::ReadAllText($path, [System.Text.Encoding]::UTF8)
  if ($h -match 'sb-loader') { return }
  $h = $h -replace '</head>', ($loaderCss + '</head>')
  $h = $h -replace '</body>', ($loaderHtml + '</body>')
  [System.IO.File]::WriteAllText($path, $h, (New-Object System.Text.UTF8Encoding($false)))
}

function New-Report([string]$period, [datetime]$anchor, [string]$dest) {
  $f = & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $root 'tools\report-html.ps1') -Period $period -Anchor $anchor
  $f = ($f | Select-Object -Last 1).ToString().Trim()
  if (Test-Path $f) {
    Copy-Item $f $dest -Force
    Add-Loader $dest
  }
}

# ---------- 日报 ----------
$dayGroups = $rows | Group-Object { $_.Date.ToString('yyyy-MM-dd') } | Sort-Object Name -Descending
foreach ($g in $dayGroups) {
  $d = [datetime]::ParseExact($g.Name, 'yyyy-MM-dd', $null)
  New-Report 'day' $d (Join-Path $dailyDir ($g.Name + '.html'))
}

# ---------- 周报 / 月报 / 年报 ----------
$weekGroups = $rows | Group-Object { $s = $_.Date.AddDays(-((([int]$_.Date.DayOfWeek) + 6) % 7)); $s.ToString('yyyy-MM-dd') } | Sort-Object Name -Descending
foreach ($g in $weekGroups) {
  $s = [datetime]::ParseExact($g.Name, 'yyyy-MM-dd', $null)
  $e = $s.AddDays(6)
  New-Report 'week' $s.AddDays(3) (Join-Path $weekDir ($s.ToString('yyyyMMdd') + '_' + $e.ToString('yyyyMMdd') + '.html'))
}
$monthGroups = $rows | Group-Object { $_.Date.ToString('yyyy-MM') } | Sort-Object Name -Descending
foreach ($g in $monthGroups) {
  $d = [datetime]::ParseExact($g.Name + '-15', 'yyyy-MM-dd', $null)
  New-Report 'month' $d (Join-Path $monthDir ($g.Name + '.html'))
}
$yearGroups = $rows | Group-Object { $_.Date.ToString('yyyy') } | Sort-Object Name -Descending
foreach ($g in $yearGroups) {
  $d = [datetime]::ParseExact($g.Name + '-07-01', 'yyyy-MM-dd', $null)
  New-Report 'year' $d (Join-Path $yearDir ($g.Name + '.html'))
}

# ---------- 站点 CSS ----------
$css = @'
*{box-sizing:border-box;-webkit-tap-highlight-color:transparent}
body{margin:0;min-height:100vh;overflow-x:hidden;font-family:'Segoe UI','Poppins','Roboto','Noto Sans',system-ui,-apple-system,BlinkMacSystemFont,'Helvetica Neue',sans-serif;background:radial-gradient(900px 500px at 12% -8%,rgba(106,168,255,.24),transparent 60%),radial-gradient(760px 460px at 92% 4%,rgba(143,106,255,.20),transparent 60%),radial-gradient(700px 420px at 60% 108%,rgba(61,220,151,.12),transparent 62%),#0b0d12;color:rgba(238,241,247,.92)}
.orb{position:fixed;border-radius:50%;filter:blur(90px);will-change:transform;z-index:0;pointer-events:none;opacity:.5;animation:orbit 22s ease-in-out infinite alternate}
.orb.o1{width:360px;height:360px;background:#6aa8ff;top:-100px;left:-80px}
.orb.o2{width:300px;height:300px;background:#8f6aff;bottom:-90px;right:-70px;animation-delay:-7s}
.orb.o3{width:220px;height:220px;background:#5b8cff;top:38%;right:12%;opacity:.35;animation-delay:-13s}
@keyframes orbit{from{transform:translate3d(0,0,0) scale(1)}to{transform:translate3d(44px,34px,0) scale(1.18)}}
.page{position:relative;z-index:1;max-width:1080px;margin:0 auto;padding:20px 16px 44px}
.glass{position:relative;overflow:hidden;background:linear-gradient(135deg,rgba(255,255,255,.12) 0%,rgba(255,255,255,.04) 40%,rgba(255,255,255,.08) 100%);backdrop-filter:blur(40px) saturate(1.8) brightness(1.1);-webkit-backdrop-filter:blur(40px) saturate(1.8) brightness(1.1);border:1px solid rgba(255,255,255,.18);border-top-color:rgba(255,255,255,.35);border-left-color:rgba(255,255,255,.25);border-radius:24px;box-shadow:0 8px 32px rgba(0,0,0,.2),inset 0 1px 0 rgba(255,255,255,.15),inset 0 -1px 0 rgba(255,255,255,.05)}
.hero{display:flex;align-items:center;gap:18px;padding:26px;margin-bottom:26px;animation:heroIn .6s cubic-bezier(.25,.8,.3,1) both}
.hero .logo{width:60px;height:60px;flex:none;border-radius:18px;display:flex;align-items:center;justify-content:center;font-size:28px;font-weight:800;color:#fff;background:linear-gradient(160deg,rgba(255,255,255,.24) 0%,rgba(255,255,255,.06) 100%);backdrop-filter:blur(20px);border:1px solid rgba(255,255,255,.3);box-shadow:0 6px 20px rgba(0,0,0,.25),inset 0 1px 0 rgba(255,255,255,.3);animation:logoFloat 4s ease-in-out infinite}
.hero-text h1{font-size:24px;letter-spacing:1px;margin:0}
.hero-text p{margin:4px 0 0;opacity:.75;font-size:13.5px}
.crumb{margin:0 0 16px;font-size:12.5px;opacity:.6}
.crumb a{color:#a9c8ff;text-decoration:none}
.crumb a:hover{text-decoration:underline}
.grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(230px,1fr));gap:18px}
.card{position:relative;display:flex;flex-direction:column;min-height:172px;padding:18px 16px 16px;text-decoration:none;color:inherit;background:linear-gradient(135deg,rgba(255,255,255,.13) 0%,rgba(255,255,255,.05) 40%,rgba(255,255,255,.09) 100%);backdrop-filter:blur(40px) saturate(1.8) brightness(1.1);-webkit-backdrop-filter:blur(40px) saturate(1.8) brightness(1.1);border:1px solid rgba(255,255,255,.2);border-top-color:rgba(255,255,255,.38);border-left-color:rgba(255,255,255,.28);border-radius:24px;box-shadow:0 10px 34px rgba(0,0,0,.28),inset 0 1px 0 rgba(255,255,255,.15),inset 0 -1px 0 rgba(255,255,255,.05);overflow:hidden;transition:transform .32s cubic-bezier(.2,.75,.3,1.25),border-color .32s;animation:cardIn .5s cubic-bezier(.2,.7,.3,1.15) both;will-change:transform,opacity}
.card::before{content:'';position:absolute;top:0;left:0;right:0;height:46%;background:linear-gradient(180deg,rgba(255,255,255,.10) 0%,transparent 100%);pointer-events:none}
.card::after{content:'';position:absolute;inset:0;border-radius:24px;pointer-events:none;box-shadow:0 20px 42px rgba(0,0,0,.36),0 0 0 1px rgba(106,168,255,.22),inset 0 0 30px rgba(143,106,255,.08);opacity:0;transition:opacity .34s ease}
.card:hover{transform:translateY(-6px) scale(1.015);border-color:rgba(106,168,255,.55)}
.card:hover::after{opacity:1}
.card .icon{width:48px;height:48px;border-radius:15px;margin-bottom:14px;display:flex;align-items:center;justify-content:center;font-size:20px;font-weight:800;color:#fff;background:linear-gradient(160deg,rgba(255,255,255,.24) 0%,rgba(255,255,255,.06) 100%);border:1px solid rgba(255,255,255,.3);box-shadow:inset 0 1px 0 rgba(255,255,255,.28),0 4px 12px rgba(0,0,0,.2);animation:idleFloat 4s ease-in-out infinite}
.card .name{font-size:16.5px;font-weight:700;letter-spacing:.5px}
.card .desc{font-size:12.5px;opacity:.72;margin-top:5px}
.snippet{font-size:12px;opacity:.55;margin-top:9px;line-height:1.5;display:-webkit-box;-webkit-line-clamp:3;-webkit-box-orient:vertical;overflow:hidden;padding-right:34px}
.badge{position:absolute;top:16px;right:16px;font-size:11px;padding:3px 11px;border-radius:20px;font-weight:600;letter-spacing:.3px}
.badge.open{background:linear-gradient(180deg,rgba(106,168,255,.30) 0%,rgba(143,106,255,.16) 100%);border:1px solid rgba(106,168,255,.5);border-top-color:rgba(160,200,255,.65);color:#d8e8ff;box-shadow:0 0 14px rgba(106,168,255,.28)}
.go{position:absolute;bottom:14px;right:16px;width:26px;height:26px;border-radius:9px;display:flex;align-items:center;justify-content:center;font-size:14px;color:#0b0d12;font-weight:800;background:linear-gradient(180deg,#c8ddff 0%,#6aa8ff 100%);box-shadow:0 4px 12px rgba(106,168,255,.45);animation:btnPulse 2.4s ease-in-out infinite}
.empty{opacity:.6;font-size:13px;padding:20px}
.foot{text-align:center;margin-top:30px;font-size:12px;opacity:.5;position:relative;z-index:1}
@keyframes heroIn{from{opacity:0;transform:translateY(-14px)}}
@keyframes cardIn{from{opacity:0;transform:translateY(24px) scale(.97)}}
@keyframes logoFloat{0%,100%{transform:translateY(0)}50%{transform:translateY(-4px)}}
@keyframes idleFloat{0%,100%{transform:translateY(0)}50%{transform:translateY(-3px)}}
@keyframes btnPulse{0%,100%{transform:scale(1)}50%{transform:scale(1.1)}}
#sb-loader{position:fixed;inset:0;z-index:9999;display:flex;align-items:center;justify-content:center;background:rgba(11,13,18,.72);backdrop-filter:blur(14px);-webkit-backdrop-filter:blur(14px);transition:opacity .35s ease}
#sb-loader.hide{opacity:0;pointer-events:none}
#sb-loader .ring{width:34px;height:34px;border-radius:50%;border:2.5px solid rgba(106,168,255,.22);border-top-color:#6aa8ff;border-right-color:#8f6aff;animation:sbSpin .8s linear infinite;box-shadow:0 0 18px rgba(106,168,255,.35)}
@keyframes sbSpin{to{transform:rotate(360deg)}}
@media (prefers-reduced-motion:reduce){.orb,.hero .logo,.card .icon,.go{animation:none!important}.card,.hero{animation-duration:.3s!important}}
@media (max-width:560px){.grid{grid-template-columns:repeat(2,1fr);gap:12px}.card{min-height:150px;padding:15px 13px 14px}.hero{padding:20px 18px}.hero .logo{width:52px;height:52px;font-size:24px}.hero-text h1{font-size:19px}.snippet{-webkit-line-clamp:2;font-size:11.5px}}
'@
[System.IO.File]::WriteAllText((Join-Path $assetDir 'style.css'), $css, (New-Object System.Text.UTF8Encoding($false)))
$loaderJs = '<script>(function(){var l=document.getElementById("sb-loader");function hide(){setTimeout(function(){l.classList.add("hide")},220)}if(document.readyState==="complete")hide();else window.addEventListener("load",hide);document.addEventListener("click",function(e){var a=e.target.closest?e.target.closest("a"):null;if(a&&a.getAttribute("href")&&a.getAttribute("href").indexOf("#")!==0&&!a.target){l.classList.remove("hide")}})})();</script>'

function New-SitePage([string]$file, [string]$title, [string]$logo, [string]$heading, [string]$sub, [string]$crumb, [string]$body) {
  $html = @"
<!DOCTYPE html>
<html lang="zh-CN">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>$title</title>
<link rel="stylesheet" href="assets/style.css">
</head>
<body>
<div class="orb o1"></div><div class="orb o2"></div><div class="orb o3"></div>
<div id="sb-loader"><div class="ring"></div></div>
<div class="page">
  <header class="hero glass">
    <div class="logo">$logo</div>
    <div class="hero-text"><h1>$heading</h1><p>$sub</p></div>
  </header>
  <div class="crumb">$crumb</div>
  <main class="grid">
$body
  </main>
  <footer class="foot">数据托管于 Cloudflare · <span style="display:inline-block;width:8px;height:8px;border-radius:50%;background:#6aa8ff;"></span> 持续更新</footer>
</div>
$loaderJs
</body>
</html>
"@
  $html = $html -replace 'href="([^"]+)\.html"', 'href="$1"'
  $html = $html -replace 'href="index"', 'href="/"'
  [System.IO.File]::WriteAllText((Join-Path $site $file), $html, (New-Object System.Text.UTF8Encoding($false)))
}

# ---------- 一级：选择报表类型 ----------
$lastWeekLabel = '暂无'
if ($weekGroups.Count -gt 0) { $lastWeekLabel = ([datetime]::ParseExact($weekGroups[0].Name, 'yyyy-MM-dd', $null)).ToString('MM-dd') + ' 起' }
$latestSub = '周报 · 月报 · 年报'
$typeCards = @"
<a class="card open" href="weeks.html" style="animation-delay:.05s">
      <div class="icon">周</div>
      <div class="name">周报</div>
      <div class="desc">按月份找到每一周</div>
      <div class="snippet">最近一周：$lastWeekLabel</div>
      <div class="go">→</div>
    </a>
    <a class="card open" href="months.html" style="animation-delay:.10s">
      <div class="icon">月</div>
      <div class="name">月报</div>
      <div class="desc">按年份找到每个月</div>
      <div class="snippet">共 $(@($monthGroups).Count) 个月有记录</div>
      <div class="go">→</div>
    </a>
    <a class="card open" href="years.html" style="animation-delay:.15s">
      <div class="icon">年</div>
      <div class="name">年报</div>
      <div class="desc">整年总览</div>
      <div class="snippet">共 $(@($yearGroups).Count) 年有记录</div>
      <div class="go">→</div>
    </a>
"@
New-SitePage 'index.html' '学习报告 · 选择类型' '报' '学习报告' '周报 / 月报 / 年报 · 按时间查看' '' $typeCards

# ---------- 周报：年份 → 月份 → 周 ----------
$weekYears = $weekGroups | Group-Object { ([datetime]::ParseExact($_.Name,'yyyy-MM-dd',$null)).Year } | Sort-Object Name -Descending
$yCards = ''
$i = 0
foreach ($y in $weekYears) {
  $yCards += @"
<a class="card open" href="weeks-$($y.Name).html" style="animation-delay:$(0.05*($i+1))s">
      <div class="icon">$($y.Name)</div>
      <div class="name">$($y.Name) 年周报</div>
      <div class="desc">选择月份 → 选择那一周</div>
      <div class="snippet">$(@($y.Group).Count) 周有记录</div>
      <div class="go">→</div>
    </a>

"@
  $i++
}
if ($yCards -eq '') { $yCards = '<div class="empty">还没有周报</div>' }
New-SitePage 'weeks.html' '周报 · 选择年份' '周' '周报' '先选年份，再选月份，最后选那一周' '<a href="index.html">报告首页</a> / 周报' $yCards

foreach ($y in $weekYears) {
  $mCards = ''
  $i = 0
  for ($m = 1; $m -le 12; $m++) {
    $wk = @($y.Group | Where-Object { ([datetime]::ParseExact($_.Name,'yyyy-MM-dd',$null)).Month -eq $m })
    if ($wk.Count -eq 0) { continue }
    $i++
    $mCards += @"
<a class="card open" href="weeks-$($y.Name)-$('{0:D2}' -f $m).html" style="animation-delay:$(0.05*$i)s">
      <div class="icon">$m</div>
      <div class="name">$($m) 月</div>
      <div class="desc">$($wk.Count) 周有记录</div>
      <div class="go">→</div>
    </a>

"@
  }
  New-SitePage "weeks-$($y.Name).html" "$($y.Name) 年周报 · 选择月份" "$($y.Name)" "$($y.Name) 年周报" '选择月份' "<a href=`"index.html`">报告首页</a> / <a href=`"weeks.html`">周报</a> / $($y.Name) 年" $mCards

  for ($m = 1; $m -le 12; $m++) {
    $wk = @($y.Group | Where-Object { ([datetime]::ParseExact($_.Name,'yyyy-MM-dd',$null)).Month -eq $m } | Sort-Object Name -Descending)
    if ($wk.Count -eq 0) { continue }
    $wCards = ''
    $j = 0
    foreach ($w in $wk) {
      $s = [datetime]::ParseExact($w.Name, 'yyyy-MM-dd', $null)
      $e = $s.AddDays(6)
      $min = [math]::Round((($rows | Where-Object { $_.Date -ge $s -and $_.Date -le $e } | ForEach-Object { $_.Min } | Measure-Object -Sum).Sum), 0)
      $j++
      $wCards += @"
<a class="card open" href="reports/weekly/$($s.ToString('yyyyMMdd'))_$($e.ToString('yyyyMMdd')).html" style="animation-delay:$(0.05*$j)s">
      <div class="icon">$($s.Day)</div>
      <div class="name">$($s.ToString('MM-dd')) — $($e.ToString('MM-dd'))</div>
      <div class="desc">$min 分钟专注</div>
      <div class="go">→</div>
    </a>

"@
    }
    New-SitePage "weeks-$($y.Name)-$('{0:D2}' -f $m).html" "$($y.Name) 年 $($m) 月 · 周报" "$m" "$($m) 月周报" "$($y.Name) 年 $($m) 月 · 选择某一周" "<a href=`"index.html`">报告首页</a> / <a href=`"weeks.html`">周报</a> / <a href=`"weeks-$($y.Name).html`">$($y.Name) 年</a> / $($m) 月" $wCards
  }
}

# ---------- 月报：年份 → 月份 ----------
$monthYears = $monthGroups | Group-Object { ([datetime]::ParseExact($_.Name + '-15','yyyy-MM-dd',$null)).Year } | Sort-Object Name -Descending
$yCards = ''
$i = 0
foreach ($y in $monthYears) {
  $i++
  $yCards += @"
<a class="card open" href="months-$($y.Name).html" style="animation-delay:$(0.05*$i)s">
      <div class="icon">$($y.Name)</div>
      <div class="name">$($y.Name) 年月报</div>
      <div class="desc">选择月份</div>
      <div class="snippet">$(@($y.Group).Count) 个月有记录</div>
      <div class="go">→</div>
    </a>

"@
}
if ($yCards -eq '') { $yCards = '<div class="empty">还没有月报</div>' }
New-SitePage 'months.html' '月报 · 选择年份' '月' '月报' '先选年份，再选月份' '<a href="index.html">报告首页</a> / 月报' $yCards

foreach ($y in $monthYears) {
  $mCards = ''
  $i = 0
  for ($m = 1; $m -le 12; $m++) {
    $g = @($y.Group | Where-Object { $_.Name -eq ('{0}-{1:D2}' -f $y.Name, $m) })
    if ($g.Count -eq 0) { continue }
    $mm = [datetime]::ParseExact($g[0].Name + '-15','yyyy-MM-dd',$null)
    $min = [math]::Round((($rows | Where-Object { $_.Date.ToString('yyyy-MM') -eq $g[0].Name } | ForEach-Object { $_.Min } | Measure-Object -Sum).Sum), 0)
    $i++
    $mCards += @"
<a class="card open" href="reports/monthly/$($g[0].Name).html" style="animation-delay:$(0.05*$i)s">
      <div class="icon">$m</div>
      <div class="name">$($m) 月</div>
      <div class="desc">$min 分钟专注</div>
      <div class="go">→</div>
    </a>

"@
  }
  New-SitePage "months-$($y.Name).html" "$($y.Name) 年月报" "$($y.Name)" "$($y.Name) 年月报" '选择月份' "<a href=`"index.html`">报告首页</a> / <a href=`"months.html`">月报</a> / $($y.Name) 年" $mCards
}

# ---------- 年报 ----------
$yCards = ''
$i = 0
foreach ($y in $yearGroups) {
  $min = [math]::Round((($rows | Where-Object { $_.Date.Year -eq [int]$y.Name } | ForEach-Object { $_.Min } | Measure-Object -Sum).Sum), 0)
  $i++
  $yCards += @"
<a class="card open" href="reports/yearly/$($y.Name).html" style="animation-delay:$(0.05*$i)s">
      <div class="icon">$($y.Name)</div>
      <div class="name">$($y.Name) 年</div>
      <div class="desc">$min 分钟专注</div>
      <div class="go">→</div>
    </a>

"@
}
if ($yCards -eq '') { $yCards = '<div class="empty">还没有年报</div>' }
New-SitePage 'years.html' '年报' '年' '年报' '整年总览' '<a href="index.html">报告首页</a> / 年报' $yCards

Write-Output ("SITE|" + $site + "|days=" + @($dayGroups).Count + " weeks=" + @($weekGroups).Count + " months=" + @($monthGroups).Count)

if ($Deploy) {
  $nodepath = 'C:\Users\lr\AppData\Local\nodejs\node-v26.13.1-win-x64'
  $env:Path = $nodepath + ';' + $env:Path
  $out = & wrangler pages deploy $site --project-name $Project --commit-dirty=true 2>&1
  $out | Write-Output
}
