param(
  [ValidateSet('day','week','month','quarter','year')][string]$Period = 'week',
  [switch]$Final,
  [datetime]$Anchor
)
$ErrorActionPreference = 'Stop'
$root = 'D:\StudyBrain'
$csv  = Join-Path $root 'data\sessions.csv'
$note = Join-Path $root 'data\notes.csv'
$outDir = Join-Path $root 'reports'
if (!(Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir | Out-Null }

$names = @{ math='数学压轴题'; english='背单词'; chinese='语文阅读'; history='历史'; politic='政治';
            writing='练字'; notes='整理笔记'; homework='学校作业'; errorfix='错题复盘';
            break='休息'; free='自由时间'; custom='专注'; physics='物理网课'; chemistry='化学网课' }

$all = @()
if (Test-Path $csv) {
  $all = Import-Csv $csv -Encoding UTF8 | ForEach-Object {
    $d = $null
    try { $d = [datetime]::ParseExact($_.日期, 'yyyy-MM-dd', $null) } catch { $d = $null }
    if ($d -eq $null) { $null } else {
      [pscustomobject]@{
        Date = $d
        Time = $_.时间
        Subject = $_.科目
        SubjectCN = $(if ($names.ContainsKey($_.科目)) { $names[$_.科目] } else { $_.科目 })
        Plan = [double]$_.计划分钟
        Actual = [double]$_.实际分钟
        Status = $_.状态
      }
    }
  } | Where-Object { $_ -ne $null }
}

$today = (Get-Date).Date
if ($Anchor -eq $null -or $Anchor -eq [datetime]::MinValue) { $Anchor = $today } else { $Anchor = $Anchor.Date }

switch ($Period) {
  'day' {
    $start = $Anchor
    $end = $Anchor
    $periodLabel = '日报'
  }
  'week' {
    $start = $Anchor.AddDays(-((( [int]$Anchor.DayOfWeek + 6) % 7)))
    $end = $start.AddDays(6)
    $periodLabel = '周报'
  }
  'month' {
    $start = Get-Date -Year $Anchor.Year -Month $Anchor.Month -Day 1
    $end = $start.AddMonths(1).AddDays(-1)
    $periodLabel = '月报'
  }
  'quarter' {
    $q = [math]::Floor(($Anchor.Month - 1) / 3)
    $start = Get-Date -Year $Anchor.Year -Month ([int]($q * 3 + 1)) -Day 1
    $end = $start.AddMonths(3).AddDays(-1)
    $periodLabel = '季报'
  }
  'year' {
    $start = Get-Date -Year $Anchor.Year -Month 1 -Day 1
    $end = $start.AddYears(1).AddDays(-1)
    $periodLabel = '年报'
  }
}
$daysTotal = ($end - $start).Days + 1
$elapsed = [math]::Min($daysTotal, [math]::Max(1, ($today - $start).Days + 1))
$isComplete = ($today -gt $end)

$week = $all | Where-Object { $_.Date -ge $start -and $_.Date -le $end }
$study = $week | Where-Object { $_.Subject -ne 'break' -and $_.Subject -ne 'free' }

$notes = @()
if (Test-Path $note) {
  $notes = Import-Csv $note -Encoding UTF8 | ForEach-Object {
    try { $d = [datetime]::ParseExact($_.日期, 'yyyy-MM-dd', $null) } catch { $d = $null }
    if ($d -ne $null -and $d -ge $start) {
      [pscustomobject]@{ Date = $d; Subject = $(if ($names.ContainsKey($_.科目)) { $names[$_.科目] } else { $_.科目 }); Text = $_.总结 }
    }
  }
}

$totalMin = [math]::Round((($study | Measure-Object Actual -Sum).Sum), 0)
if ($totalMin -eq $null) { $totalMin = 0 }
$sessCount = @($study).Count
$doneCount = @($study | Where-Object { $_.Status -eq '完成' }).Count
$doneRate = $(if ($sessCount -gt 0) { [math]::Round($doneCount * 100 / $sessCount, 0) } else { 0 })
$planSum = [math]::Round((($study | Measure-Object Plan -Sum).Sum), 0)
if ($planSum -eq $null) { $planSum = 0 }
$focusRate = $(if ($planSum -gt 0) { [math]::Round($totalMin * 100 / $planSum, 0) } else { 0 })

$bySubject = $study | Group-Object SubjectCN | ForEach-Object {
  [pscustomobject]@{
    Name = $_.Name
    Min = [math]::Round((($_.Group | Measure-Object Actual -Sum).Sum), 0)
    Count = $_.Count
  }
} | Sort-Object Min -Descending
$maxSub = $(if ($bySubject) { ($bySubject | Measure-Object Min -Maximum).Maximum } else { 1 })
if ($maxSub -le 0) { $maxSub = 1 }

$byDay = @()
if ($daysTotal -le 14) {
  for ($i = 0; $i -lt $daysTotal; $i++) {
    $d = $start.AddDays($i)
    $m = (($study | Where-Object { $_.Date -eq $d } | Measure-Object Actual -Sum).Sum)
    if ($m -eq $null) { $m = 0 }
    $byDay += [pscustomobject]@{ Date = $d; Min = [math]::Round($m, 0); Label = $d.ToString('MM-dd'); Sub = '周' + ('日','一','二','三','四','五','六')[[int]$d.DayOfWeek] }
  }
} elseif ($daysTotal -le 62) {
  for ($i = 0; $i -lt $daysTotal; $i++) {
    $d = $start.AddDays($i)
    $m = (($study | Where-Object { $_.Date -eq $d } | Measure-Object Actual -Sum).Sum)
    if ($m -eq $null) { $m = 0 }
    $byDay += [pscustomobject]@{ Date = $d; Min = [math]::Round($m, 0); Label = $d.Day.ToString(); Sub = ('日','一','二','三','四','五','六')[[int]$d.DayOfWeek] }
  }
} else {
  $cursor = $start
  while ($cursor -le $end) {
    $segEnd = $cursor.AddDays(6)
    if ($segEnd -gt $end) { $segEnd = $end }
    $m = (($study | Where-Object { $_.Date -ge $cursor -and $_.Date -le $segEnd } | Measure-Object Actual -Sum).Sum)
    if ($m -eq $null) { $m = 0 }
    $byDay += [pscustomobject]@{ Date = $cursor; Min = [math]::Round($m, 0); Label = $cursor.ToString('MM/dd'); Sub = '周' }
    $cursor = $segEnd.AddDays(1)
  }
}
$maxDay = ($byDay | Measure-Object Min -Maximum).Maximum
if ($maxDay -le 0) { $maxDay = 1 }

$subjRows = ''
foreach ($s in $bySubject) {
  $pct = [math]::Round($s.Min * 100 / $maxSub, 0)
  $subjRows += "<div class=""subj""><div class=""subjTop""><span class=""subjName"">$($s.Name)</span><span class=""subjMin"">$($s.Min)<i>min</i></span></div><div class=""track""><div class=""fill"" style=""width:$pct%""></div></div><div class=""subjMeta"">$($s.Count) 次</div></div>`n"
}

$dayBars = ''
foreach ($d in $byDay) {
  $h = $(if ($d.Min -gt 0) { [math]::Max([math]::Round($d.Min * 100 / $maxDay, 0), 6) } else { 2 })
  $cls = $(if ($d.Date -eq $today) { 'bar today' } else { 'bar' })
  $dayBars += "<div class=""dayCol""><div class=""barWrap""><div class=""$cls"" style=""height:$h%"" title=""$($d.Min) 分钟""></div></div><div class=""dayMin"">$($d.Min)</div><div class=""dayLbl"">$($d.Label)</div><div class=""dayWk"">$($d.Sub)</div></div>`n"
}

$rows = ''
foreach ($r in ($week | Sort-Object Date, Time -Descending)) {
  $st = $(if ($r.Status -eq '完成') { 'ok' } else { 'half' })
  $rows += "<tr><td class=""mono"">$($r.Date.ToString('MM-dd'))</td><td class=""mono dim"">$($r.Time)</td><td>$($r.SubjectCN)</td><td class=""mono"">$($r.Plan)</td><td class=""mono strong"">$([math]::Round($r.Actual,1))</td><td><span class=""tag $st"">$($r.Status)</span></td></tr>`n"
}
if ($rows -eq '') { $rows = '<tr><td colspan="6" class="empty">本周还没有记录</td></tr>' }

$noteHtml = ''
foreach ($n in ($notes | Sort-Object Date -Descending)) {
  $noteHtml += "<div class=""noteItem""><div class=""noteHead""><span class=""noteDate"">$($n.Date.ToString('MM-dd'))</span><span class=""noteSubj"">$($n.Subject)</span></div><p>$([System.Net.WebUtility]::HtmlEncode($n.Text))</p></div>`n"
}
if ($noteHtml -eq '') { $noteHtml = '<div class="empty">本周还没有总结记录。完成任务后把一句话总结告诉我，我会写进这里。</div>' }

$sumFilePath = Join-Path $root 'data\summary.md'
$sumHtml = ''
if (Test-Path $sumFilePath) {
  $raw = Get-Content $sumFilePath -Encoding UTF8 -Raw
  $blocks = [regex]::Split($raw, '(?m)^##\s*') | Where-Object { $_.Trim() -ne '' }
  foreach ($b in $blocks) {
    $lines = $b -split "`r?`n"
    $h = $lines[0].Trim()
    $body = ($lines | Select-Object -Skip 1) -join ' '
    $body = $body.Trim()
    if ($h -like '#*') { continue }
    $sumHtml += "<div class=""sumItem""><h4>$([System.Net.WebUtility]::HtmlEncode($h))</h4><p>$([System.Net.WebUtility]::HtmlEncode($body))</p></div>`n"
  }
}
if ($sumHtml -eq '') { $sumHtml = '<div class="empty">本周还没有学科小结。完成一周后告诉我，我按学科各写一段总结。</div>' }

$rangeText = "$($start.ToString('MM月dd日')) — $($end.ToString('MM月dd日'))"

$html = @"
<!DOCTYPE html>
<html lang="zh-CN">
<head>
<meta charset="utf-8">
<title>学习$periodLabel $rangeText</title>
<style>
:root{
  --bg:#0b0d12; --panel:rgba(255,255,255,.07); --line:rgba(255,255,255,.13);
  --txt:#eef1f7; --dim:#8b93a7; --acc:#6aa8ff; --acc2:#8f6aff; --ok:#3ddc97; --half:#ffb454;
}
*{box-sizing:border-box;margin:0;padding:0}
body{
  background:
    radial-gradient(900px 500px at 12% -8%, rgba(106,168,255,.24), transparent 60%),
    radial-gradient(760px 460px at 92% 4%, rgba(143,106,255,.20), transparent 60%),
    radial-gradient(700px 420px at 60% 108%, rgba(61,220,151,.12), transparent 62%),
    var(--bg);
  color:var(--txt); min-height:100vh; padding:52px 24px 72px;
  font-family:"Segoe UI Variable Display","Segoe UI",-apple-system,"PingFang SC","Microsoft YaHei",sans-serif;
  -webkit-font-smoothing:antialiased;
}
.wrap{max-width:1080px;margin:0 auto}
.head{display:flex;justify-content:space-between;align-items:flex-end;gap:24px;flex-wrap:wrap;margin-bottom:34px}
.kicker{font-size:12px;letter-spacing:.24em;color:var(--dim);text-transform:uppercase;margin-bottom:10px}
h1{font-size:40px;font-weight:650;letter-spacing:-.02em;line-height:1.12}
h1 em{font-style:normal;background:linear-gradient(100deg,var(--acc),var(--acc2));-webkit-background-clip:text;background-clip:text;color:transparent}
.sub{color:var(--dim);font-size:14px;margin-top:10px}
.card{background:linear-gradient(135deg,rgba(255,255,255,.11) 0%,rgba(255,255,255,.03) 40%,rgba(255,255,255,.07) 100%);border:1px solid rgba(255,255,255,.16);border-top-color:rgba(255,255,255,.32);border-left-color:rgba(255,255,255,.24);border-radius:22px;backdrop-filter:blur(40px) saturate(1.7);-webkit-backdrop-filter:blur(40px) saturate(1.7);box-shadow:0 24px 60px rgba(0,0,0,.35), inset 0 1px 0 rgba(255,255,255,.14), inset 0 -1px 0 rgba(255,255,255,.04)}
.hero{display:grid;grid-template-columns:repeat(4,1fr);gap:16px;margin-bottom:18px}
.kpi{padding:22px 22px 20px}
.kpi .lab{font-size:12px;color:var(--dim);letter-spacing:.08em;margin-bottom:12px}
.kpi .val{font-size:34px;font-weight:640;letter-spacing:-.03em}
.kpi .val i{font-size:14px;font-style:normal;color:var(--dim);margin-left:4px;font-weight:500}
.kpi .foot{font-size:12px;color:var(--dim);margin-top:8px}
.grid{display:grid;grid-template-columns:1.35fr 1fr;gap:18px;margin-bottom:18px}
.pad{padding:26px}
.title{font-size:15px;font-weight:600;margin-bottom:20px;display:flex;align-items:center;gap:9px}
.title:before{content:"";width:4px;height:15px;border-radius:2px;background:linear-gradient(180deg,var(--acc),var(--acc2))}
.subj{margin-bottom:17px}
.subjTop{display:flex;justify-content:space-between;align-items:baseline;margin-bottom:8px}
.subjName{font-size:13.5px}
.subjMin{font-size:14px;font-weight:600;color:#dfe6f5}
.subjMin i{font-size:10.5px;font-style:normal;color:var(--dim);margin-left:3px}
.subjMeta{font-size:11px;color:var(--dim);margin-top:6px}
.track{height:7px;border-radius:99px;background:rgba(255,255,255,.07);overflow:hidden}
.fill{height:100%;border-radius:99px;background:linear-gradient(90deg,var(--acc),var(--acc2));box-shadow:0 0 18px rgba(106,168,255,.45)}
.chart{display:flex;align-items:flex-end;gap:10px;height:192px;padding-top:8px}
.dayCol{flex:1;display:flex;flex-direction:column;align-items:center;height:100%;justify-content:flex-end;gap:7px}
.barWrap{flex:1;width:100%;display:flex;align-items:flex-end;justify-content:center}
.bar{width:60%;max-width:34px;border-radius:9px 9px 4px 4px;background:linear-gradient(180deg,rgba(106,168,255,.85),rgba(143,106,255,.35));transition:.3s}
.bar.today{background:linear-gradient(180deg,#7fbcff,#8f6aff);box-shadow:0 0 22px rgba(127,188,255,.55)}
.dayMin{font-size:11px;color:#c9d2e4;font-variant-numeric:tabular-nums}
.dayLbl{font-size:10.5px;color:var(--dim);font-variant-numeric:tabular-nums}
.dayWk{font-size:10px;color:rgba(139,147,167,.6)}
table{width:100%;border-collapse:collapse;font-size:13px}
th{text-align:left;font-size:11px;letter-spacing:.08em;color:var(--dim);font-weight:500;padding:0 12px 12px;border-bottom:1px solid var(--line)}
td{padding:12px;border-bottom:1px solid rgba(255,255,255,.045)}
tbody tr:last-child td{border-bottom:none}
tbody tr:hover td{background:rgba(255,255,255,.028)}
.mono{font-variant-numeric:tabular-nums}
.dim{color:var(--dim)} .strong{font-weight:600;color:#eaf0ff}
.center{text-align:center}
.tag{display:inline-block;padding:3px 10px;border-radius:99px;font-size:11px;border:1px solid transparent}
.tag.ok{color:#7ff0c0;background:rgba(61,220,151,.12);border-color:rgba(61,220,151,.28)}
.tag.half{color:#ffcb85;background:rgba(255,180,84,.12);border-color:rgba(255,180,84,.28)}
.notes{display:grid;gap:12px}
.noteItem{padding:16px 18px;border-radius:16px;background:rgba(255,255,255,.04);border:1px solid rgba(255,255,255,.07)}
.noteHead{display:flex;gap:10px;align-items:center;margin-bottom:8px}
.noteDate{font-size:11px;color:var(--dim);font-variant-numeric:tabular-nums}
.noteSubj{font-size:11px;padding:2px 8px;border-radius:99px;background:rgba(106,168,255,.14);color:#9cc6ff}
.noteItem p{font-size:13.5px;line-height:1.65;color:#dbe3f2}
.empty{font-size:13px;color:var(--dim);padding:6px 2px}
.sumGrid{display:grid;grid-template-columns:1fr 1fr;gap:14px}
.sumItem{padding:18px 20px;border-radius:16px;background:rgba(255,255,255,.04);border:1px solid rgba(255,255,255,.07)}
.sumItem h4{font-size:12.5px;font-weight:600;color:#9cc6ff;letter-spacing:.05em;margin-bottom:9px}
.sumItem p{font-size:13.5px;line-height:1.75;color:#dbe3f2}
.foot{margin-top:30px;text-align:center;font-size:11.5px;color:rgba(139,147,167,.62);letter-spacing:.04em}
@media(max-width:860px){.hero{grid-template-columns:repeat(2,1fr)}.grid{grid-template-columns:1fr}h1{font-size:30px}body{padding:32px 16px 56px}}
</style>
</head>
<body>
<div class="wrap">
  <div class="head">
    <div>
      <div class="kicker">Weekly Review</div>
      <h1>学习<em>$periodLabel</em></h1>
      <div class="sub">$rangeText · 共 $daysTotal 天 · 已过 $elapsed 天 · 生成于 $(Get-Date -Format 'yyyy-MM-dd HH:mm')</div>
    </div>
  </div>

  <div class="hero">
    <div class="card kpi"><div class="lab">专注总时长</div><div class="val">$totalMin<i>min</i></div><div class="foot">计划 $planSum 分钟</div></div>
    <div class="card kpi"><div class="lab">完成任务</div><div class="val">$doneCount<i>/ $sessCount</i></div><div class="foot">完成率 $doneRate%</div></div>
    <div class="card kpi"><div class="lab">计划达成</div><div class="val">$focusRate<i>%</i></div><div class="foot">实际 / 计划</div></div>
    <div class="card kpi"><div class="lab">日均专注</div><div class="val">$([math]::Round($totalMin / $elapsed, 0))<i>min</i></div><div class="foot">按已过 $elapsed 天</div></div>
  </div>

  <div class="grid">
    <div class="card pad">
      <div class="title">科目分布</div>
$subjRows
    </div>
    <div class="card pad">
      <div class="title">每日时长</div>
      <div class="chart">
$dayBars
      </div>
    </div>
  </div>

  <div class="card pad" style="margin-bottom:18px">
    <div class="title">学科小结</div>
    <div class="sumGrid">
$sumHtml
    </div>
  </div>

  <div class="card pad" style="margin-bottom:18px">
    <div class="title">全部记录</div>
    <table>
      <thead><tr><th>日期</th><th>时间</th><th>科目</th><th>计划</th><th>实际</th><th>状态</th></tr></thead>
      <tbody>
$rows
      </tbody>
    </table>
  </div>

  <div class="card pad">
    <div class="title">每日一句话</div>
    <div class="notes">
$noteHtml
    </div>
  </div>

  <div class="foot">由 daily-study-agenda 自动生成 · sessions.csv + notes.csv</div>
</div>
</body>
</html>
"@

if ($Final -and $isComplete) {
  $outFile = Join-Path $outDir ($periodLabel + '_' + $start.ToString('yyyyMMdd') + '_' + $end.ToString('yyyyMMdd') + '.html')
} else {
  $tempDir = Join-Path $outDir 'temp'
  if (!(Test-Path $tempDir)) { New-Item -ItemType Directory -Path $tempDir | Out-Null }
  $outFile = Join-Path $tempDir ($periodLabel + '_临时_' + $start.ToString('yyyyMMdd') + '_' + $end.ToString('yyyyMMdd') + '_' + (Get-Date -Format 'HHmm') + '.html')
}
$utf8 = New-Object System.Text.UTF8Encoding($true)
[System.IO.File]::WriteAllText($outFile, $html, $utf8)
Write-Output $outFile
