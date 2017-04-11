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


write-host $servername


If ($servername.Length -gt 1) {
    Write-Host "Servername Parameter Eroor"
    $error.Add("Servername Parameter Error")



}

return $error



}