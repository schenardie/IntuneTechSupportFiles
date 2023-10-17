	Try {
    #region variables
    #define log path
    $logPath = "$env:ProgramData\WULogs"
    #define log file
    $logFile = "$logPath\CopyLogs.log"
    #define export destination
    $exportdest = "C:\Windows\Temp"
    #endregion
    #region Logging
    #if log path does not exist, create it
    if (!(Test-Path -Path $logPath)) {
        New-Item -Path $logPath -ItemType Directory -Force | Out-Null
    }
    #start logging
    Start-Transcript -Path $logFile -Force
    Write-Host "Collecting Windows Updates Logs"
    #collect windows updates logs
    $process = (Start-Process -FilePath ".\copylogs.exe" -NoNewWindow -PassThru).ExitCode
    Write-Host "Waiting until log is generated"
	#wait until log is generated
    do {
    $zipFile = Get-ChildItem -Path "C:\Windows\SystemTemp" -Filter "WindowsUpdateLogs.zip" -Recurse
	} While (!($zipFile))
	Start-sleep 30
	Write-Host "Copying logs to C:\Windows\Temp"
    #copy logs to C:\Windows\Temp
	Copy-Item -Path $zipFile.FullName -Destination $exportdest
	Write-Host "Cleaning folders after moving WindowsUpdateLogs.zip"
    #clean folders after moving WindowsUpdateLogs.zip
	Remove-Item (Split-Path -Parent $zipFile.FullName) -Recurse -Force
	Remove-Item (Split-Path -Parent (Get-ChildItem -Path "C:\Windows\SystemTemp" -Filter "UpdateAgent.old" -Recurse).Fullname) -Recurse -Force
	Write-Host "Stop hanging process"
    #kill hanging process for copylogs.exe
	Get-Process copylogs | Stop-Process -Force
}
catch {
    $errorMsg = $_.Exception.Message
}
finally {
    if ($errorMsg) {
        Write-Warning $errorMsg
        Stop-Transcript
        throw $errorMsg
        Exit $process
    }
    else {
        Write-Host "Script completed successfully.."
        Stop-Transcript
        Exit $process
    }
}