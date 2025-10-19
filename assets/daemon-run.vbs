Set fso = CreateObject("Scripting.FileSystemObject")
Set WshShell = CreateObject("WScript.Shell")
scriptDir = fso.GetParentFolderName(WScript.ScriptFullName)
daemon = fso.BuildPath(scriptDir, "daemon.cmd")
logDir = fso.BuildPath(scriptDir, "logs")
If Not fso.FolderExists(logDir) Then fso.CreateFolder(logDir)
logFile = fso.BuildPath(logDir, "daemon-run.log")
If fso.FileExists(daemon) Then
  On Error Resume Next
  WshShell.Run Chr(34) & daemon & Chr(34), 0, False
  If Err.Number <> 0 Then
    Set log = fso.OpenTextFile(logFile, 8, True)
    log.WriteLine Now & " [ERROR] failed to run daemon: " & Err.Number & " " & Err.Description
    log.Close
  Else
    Set log = fso.OpenTextFile(logFile, 8, True)
    log.WriteLine Now & " [INFO] daemon started via VBS"
    log.Close
  End If
End If
Set WshShell = CreateObject("WScript.Shell")
WshShell.Run """C:\talitania\daemon.bat""", 0, False