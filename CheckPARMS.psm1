function CheckPARMS { [CmdletBinding()]
    param (
         [string]$servername
        ,[string]$Bkupdir
        ,[int]$OptUserDBDay
        ,[timespan]$OptUserDBTime
        ,[int]$ChkUserDBDay
        ,[timespan]$ChkUserDBTime
        ,[int]$ChkSysDBDay
        ,[timespan]$ChkSysDBTime
        ,[int]$BkupUserDBFullDay
        ,[timespan]$BkupUserDBFullTime
        ,[int]$BkupUserDBFullDel
        ,[int]$BkupUserDBDiffDay
        ,[timespan]$BkupUserDBDiffTime
        ,[int]$BkupUserDBDiffDel
        ,[int]$BkupSysDBFullDay
        ,[timespan]$BkupSysDBFullTime
        ,[int]$BkupSysDBFullDel
        ,[int]$CleanupDay
        ,[timespan]$CleanupTime
        ,[int]$CleanupPeriod 
     )

#reset error count
$error.clear()





If ($servername.Length -lt 1) {
    #Write-Host "Servername Parameter Error"
    $error.Add("Servername Parameter Error") | Out-Null
}

$ValidPath = Test-Path $Bkupdir -IsValid
If ($ValidPath -eq $False) {
    #Write-Host "Backup DIR path is not usable"
    $error.Add("Backup DIR path $Bkupdir is not usable") |Out-Null
}

return $error

}