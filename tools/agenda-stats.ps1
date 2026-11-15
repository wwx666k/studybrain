param(
  [string]$Task = '',
  [int]$Last = 5
)

$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$logPath = Join-Path $root 'data\sessions.csv'

$bounds = @{
  math    = @(40, 50, 45)
  english = @(15, 25, 20)
  chinese = @(20, 20, 20)
  history = @(30, 45, 35)
  politic = @(15, 15, 15)
  writing = @(10, 10, 10)
  break   = @(5, 5, 5)
  free    = @(60, 60, 60)
  custom  = @(10, 60, 25)
}

$rows = @()
if (Test-Path $logPath) {
  $rows = @(Import-Csv $logPath | Where-Object { $_.状态 -ne '中断' })
}

$result = @()
foreach ($key in $bounds.Keys) {
  $mine = @($rows | Where-Object { $_.科目 -eq $key } | Select-Object -Last $Last)
  $lo = $bounds[$key][0]
  $hi = $bounds[$key][1]
  $def = $bounds[$key][2]
  if ($mine.Count -ge 2) {
    $avg = ($mine | Measure-Object -Property 实际分钟 -Average).Average
    $sug = [int][math]::Round($avg)
    if ($sug -lt $lo) { $sug = $lo }
    if ($sug -gt $hi) { $sug = $hi }
    $result += [pscustomobject]@{
      科目     = $key
      建议分钟 = $sug
      样本数   = $mine.Count
      平均分钟 = [math]::Round($avg, 1)
      范围     = "$lo-$hi"
      依据     = '历史平均'
    }
  } else {
    $result += [pscustomobject]@{
      科目     = $key
      建议分钟 = $def
      样本数   = $mine.Count
      平均分钟 = 0
      范围     = "$lo-$hi"
      依据     = '默认值'
    }
  }
}

if ($Task -ne '') {
  $one = $result | Where-Object { $_.科目 -eq $Task }
  if ($one -ne $null) {
    'SUGGEST|{0}|{1}|{2}|{3}' -f $one.科目, $one.建议分钟, $one.样本数, $one.平均分钟
  } else {
    'SUGGEST|{0}|25|0|0' -f $Task
  }
} else {
  $result | Sort-Object 科目 | Format-Table -AutoSize | Out-String -Width 200
}
