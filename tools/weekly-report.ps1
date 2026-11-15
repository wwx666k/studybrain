param(
  [int]$Days = 7
)

$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$logPath = Join-Path $root 'data\sessions.csv'
$reportDir = Join-Path $root 'reports'
if (-not (Test-Path $reportDir)) { New-Item -ItemType Directory -Path $reportDir -Force | Out-Null }

$names = @{
  math    = '数学压轴题'
  english = '背单词'
  chinese = '语文阅读'
  history = '历史复习'
  politic = '政治背诵'
  writing = '练字'
  break   = '休息'
  free    = '自由时间'
  custom  = '专注'
}

$today = Get-Date
$from = $today.Date.AddDays(-($Days - 1))

$all = @()
if (Test-Path $logPath) {
  $all = @(Import-Csv $logPath)
}

$rows = @($all | Where-Object {
    $d = [datetime]::ParseExact($_.日期, 'yyyy-MM-dd', $null)
    $d -ge $from
  })

$file = Join-Path $reportDir ('周报_{0}.md' -f $today.ToString('yyyyMMdd'))
$sb = New-Object System.Text.StringBuilder

[void]$sb.AppendLine("# 学习周报（$($from.ToString('MM-dd')) ~ $($today.ToString('MM-dd'))）")
[void]$sb.AppendLine('')

if ($rows.Count -eq 0) {
  [void]$sb.AppendLine('本周还没有任何计时记录。')
} else {
  $totalMin = ($rows | Measure-Object -Property 实际分钟 -Sum).Sum
  $days = @($rows | ForEach-Object { $_.日期 } | Sort-Object -Unique)
  [void]$sb.AppendLine("## 总览")
  [void]$sb.AppendLine('')
  [void]$sb.AppendLine("- 记录条数：$($rows.Count) 条")
  [void]$sb.AppendLine("- 累计学习：$([math]::Round($totalMin, 0)) 分钟（约 $([math]::Round($totalMin/60, 1)) 小时）")
  [void]$sb.AppendLine("- 有效天数：$($days.Count) 天")
  [void]$sb.AppendLine('')

  [void]$sb.AppendLine("## 分科统计")
  [void]$sb.AppendLine('')
  [void]$sb.AppendLine('| 科目 | 次数 | 累计分钟 | 平均分钟 |')
  [void]$sb.AppendLine('|---|---|---|---|')
  $grouped = $rows | Group-Object 科目 | Sort-Object { ($_.Group | Measure-Object -Property 实际分钟 -Sum).Sum } -Descending
  foreach ($g in $grouped) {
    $n = $g.Count
    $sum = ($g.Group | Measure-Object -Property 实际分钟 -Sum).Sum
    $avg = ($g.Group | Measure-Object -Property 实际分钟 -Average).Average
    $label = $names[$g.Name]
    if ($label -eq $null) { $label = $g.Name }
    [void]$sb.AppendLine("| $label | $n | $([math]::Round($sum,0)) | $([math]::Round($avg,1)) |")
  }
  [void]$sb.AppendLine('')

  [void]$sb.AppendLine("## 每日分布")
  [void]$sb.AppendLine('')
  [void]$sb.AppendLine('| 日期 | 记录数 | 分钟 |')
  [void]$sb.AppendLine('|---|---|---|')
  foreach ($d in $days) {
    $dr = @($rows | Where-Object { $_.日期 -eq $d })
    $dm = ($dr | Measure-Object -Property 实际分钟 -Sum).Sum
    [void]$sb.AppendLine("| $d | $($dr.Count) | $([math]::Round($dm,0)) |")
  }
  [void]$sb.AppendLine('')

  $top = $grouped | Select-Object -First 1
  if ($top -ne $null) {
    $topLabel = $names[$top.Name]
    if ($topLabel -eq $null) { $topLabel = $top.Name }
    $topSum = ($top.Group | Measure-Object -Property 实际分钟 -Sum).Sum
    [void]$sb.AppendLine("## 一句话结论")
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine("- 本周最花时间：$topLabel（$([math]::Round($topSum,0)) 分钟）")
    $early = @($rows | Where-Object { $_.状态 -eq '提前结束' })
    if ($early.Count -gt 0) {
      [void]$sb.AppendLine("- 有 $($early.Count) 次提前结束，说明部分任务预估偏长，下周按历史均值调低。")
    } else {
      [void]$sb.AppendLine("- 所有任务都按计划完成，预估合理。")
    }
  }
}

[void]$sb.AppendLine('')
[void]$sb.AppendLine("> 生成时间：$($today.ToString('yyyy-MM-dd HH:mm'))")

$sb.ToString() | Out-File -FilePath $file -Encoding UTF8
Write-Output $file
