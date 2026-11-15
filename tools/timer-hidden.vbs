Dim sh, cmd, i
If WScript.Arguments.Count = 0 Then WScript.Quit 1
cmd = "powershell.exe -NoProfile -STA -ExecutionPolicy Bypass -File """ & WScript.Arguments(0) & """"
For i = 1 To WScript.Arguments.Count - 1
  cmd = cmd & " " & WScript.Arguments(i)
Next
Set sh = CreateObject("WScript.Shell")
sh.Run cmd, 0, False
