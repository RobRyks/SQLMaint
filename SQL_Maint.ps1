#$scriptdir = 'C:\SCRIPTS'

#if ((resolve-path .\).path.ToUpper() -ne $scriptdir) {
#    Write-host 'This program must be run from the designated Scripts directory ' -ForegroundColor Red
#    Write-host 'C:\Scripts ' -ForegroundColor Red
#    if (test-path $scriptdir) {
#        Write-host 'changing directory to' $scriptdir  -ForegroundColor Red
#        Set-Location $scriptdir
#    }
#    else {
#        Write-host 'but the directory '$scriptdir' Does not exist!' -ForegroundColor Red
#        Write-host 'Cannot continue' -ForegroundColor Red
#        Exit 1
#    }
#}
Push-Location
# Write-host 'Reading modules'
import-module .\CheckPARMS.psm1 -force
import-module .\get-Exceldata.psm1 -force
import-module .\OptUserDB.psm1 -force
import-module .\ChkUserDB.psm1 -force
import-module .\ChkSYSDB.psm1 -force
import-module .\BkupUserDBFull.psm1 -force
import-module .\BkupSYSDBFull.psm1 -force
import-module .\BkupUserDBFDiff.psm1 -force
import-module .\Cleanup.psm1 -force

# assumes running directly on the database server as a user that has both 
# server admin rights and SA level authority using integrated authentication.
# Adust $servername to effect a remote server

# Adjust the alues below to determine locations, times ,etc.
# set 'day' to zero to skip.
$servername = $env:COMPUTERNAME
$Bkupdir = "E:\backup"
$OptUserDBDay  = 1
$OptUserDBTime = [timespan]"01:00:00"
$ChkUserDBDay  = 1
$ChkUserDBTime = [timespan]"03:00:00"
$ChkSysDBDay   = 1
$ChkSysDBTime  = [timespan]"04:00:00"
$BkupUserDBFullDay = 0            #0 = Skip 
$BkupUserDBFullTime = [timespan]"22:00:00"
$BkupUserDBFullDel =504           # Hours
$BkupUserDBDiffDay = 0            #0 = Skip 
$BkupUserDBDiffTime = [timespan]"22:00:00"
$BkupUserDBDiffDel =504           # Hours
$BkupSysDBFullDay = 0           #0 = Skip
$BkupSysDBFullTime = [timespan]"20:00:00"   
$BkupSysDBFullDel = 504           # Hours
$CleanupDay = 64
$CleanupTime = [timespan]"22:00:00"
$CleanupPeriod = 30               # days
# for intervals See https://msdn.microsoft.com/en-us/library/microsoft.sqlserver.management.smo.agent.jobschedule.frequencyinterval.aspx
    # Sun=1,Mon=2,Tues=4,Wed=8,Thurs=16,Fri=32,Sat=64,WeekDays=62,WeekDays,WeekEnds=65,WeekDays.EveryDay=127


if (-not(Get-Module -name 'SQLPS')) {
   if (Get-Module -ListAvailable | Where-Object  {$_.Name -eq 'SQLPS' }) {
       Push-Location                        
       Import-Module -Name 'SQLPS' -DisableNameChecking
       Pop-Location 
    }
 }


$pcheck = CheckPARMS $servername $Bkupdir $OptUserDBDay $OptUserDBTime $ChkUserDBDay $ChkUserDBTime $ChkSysDBDay $ChkSysDBTime `
           $BkupUserDBFullDay $BkupUserDBFullTime $BkupUserDBFullDel $BkupUserDBDiffDay $BkupUserDBDiffTime $BkupUserDBDiffDel `
           $BkupSysDBFullDay $BkupSysDBFullTime $BkupSysDBFullDel $CleanupDay $CleanupTime $CleanupPeriod


if ($pcheck.Count -gt 0) {
    write-host "Error:"  $pcheck
    write-host "fix errors and rerun this program"
    exit
}

          
push-location
$instances = dir ("sqlserver:\sql\"+$servername)
pop-location

exit
foreach ($instance in $instances) {

    if ($instance.instancename.length -eq 0) {
        $inst = $instance.name + "\"
    }
    else {
        $inst = $instance.Name
    }


    Write-host "Processing "$inst -ForegroundColor Green
    
    $result = invoke-sqlcmd  "SELECT count(*) Value FROM   sysobjects WHERE  id = object_id(N'[dbo].[IndexOptimize]') and OBJECTPROPERTY(id, N'IsProcedure') = 1" -serverinstance $instance
    if ($result.value -eq 1) {
        Write-host 'Maintenance Stored Procedures already exists... Skipping install' -ForegroundColor Magenta
    }
    Else {
        Write-host 'Maintenance stored procedures not found'
        Write-host 'installing stored procedures'
        invoke-sqlcmd  -inputfile ".\MaintenanceSolution.sql" -serverinstance $inst
    }

    #OptUserDB: 1 or more days a week
    if ($OptUserDBDay -gt 0) {
        $result = OptUserDB -servername $servername -instance $inst  -runday $OptUserDBDay -starttime $OptUserDBTime 
        Write-Host "Optimize User DB:" + $result.ToString()
    }
    #ChkUserDB: 1 or more days a week
    if ($ChkUserDBDay -gt 0) {
        $result = ChkUserDB -servername $servername -instance $inst -runday $ChkUserDBDay -starttime $ChkUserDBTime 
        Write-Host "Optimize User DB:" + $result.ToString()
    }
    #ChkSYSDB: 1 or more days a week
    if ($ChkSysDBDay -gt 0) {
        $result = ChkSYSDB -servername $servername -instance $inst -runday $ChkSysDBDay -starttime $ChkSysDBTime
        Write-Host "Optimize User DB:" + $result.ToString()
    }
    #BkupUserDBFull: 1 or more days a week.
    if ($BkupUserDBFullday -gt 0) {
        $result = BkupUserDBFull -servername $servername -instance $inst -runday $BkupUserDBFullDay -starttime $BkupUserDBFulltime -backupdir $BkupDir -bkupDelHours $BkupUserDBFullDel
        Write-Host "Optimize User DB:" + $result.ToString()
    }
    #BkupSysDBFull: 1 or mor days a week
    if ($BkupSysDBFullday -gt 0) {
        $result = BkupSYSDBFull -servername $servername -instance $inst -runday $BkupSysDBFullDay -starttime $BkupSysDBFullTime -backupdir $BkupDir -bkupDelHours $BkupSysDBFullDel
        Write-Host "Optimize User DB:" + $result.ToString()
    }
    #BkupUserDBDiff: 1 or mor days a week
    if ($BkupUserDBDiffday -gt 0) {
        $result = BkupSYSDBFull -servername $servername -instance $inst -runday $BkupUserDBDiffDay -starttime $BkupUserDBDiffTime -backupdir $BkupDir -bkupDelHours $BkupUserDBDiffDel
        Write-Host "Optimize User DB:" + $result.ToString()
    }
    #Cleanup: 1 or mor days a week
    if ($CleanupDay -gt 0) {
        $result = Cleanup -servername $servername -instance $inst -runday $CleanupDay -starttime $CleanupTime  -CleanupPeriod $CleanupPeriod
        Write-Host "Cleanup:" + $result.ToString()
    }

    # for intervals See https://msdn.microsoft.com/en-us/library/microsoft.sqlserver.management.smo.agent.jobschedule.frequencyinterval.aspx
    # Sun=1,Mon=2,Tues=4,Wed=8,Thurs=16,Fri=32,Sat=64,WeekDays=62,WeekDays,WeekEnds=65,WeekDays.EveryDay=127
}
