

function Cleanup { [CmdletBinding()]
    param (
            [string]$servername,
            [string]$instance,
            [timespan]$starttime,
            [int]$runday,
            [int]$Cleanupperiod
     )


#reset error count
$error.clear()
$jobname ='DBA-Cleanup'
$cleanupperiod = (-1 * $cleanupperiod)
$step1 = @"
sqlcmd -E -S `$(ESCAPE_SQUOTE(SRVR)) -d msdb -Q "DECLARE @CleanupDate datetime SET @CleanupDate = DATEADD(dd,$cleanupperiod,GETDATE()) EXECUTE dbo.sp_delete_backuphistory @oldest_date = @CleanupDate" -b
"@
$step2 = @"
sqlcmd -E -S `$(ESCAPE_SQUOTE(SRVR)) -d msdb -Q "DECLARE @CleanupDate datetime SET @CleanupDate = DATEADD(dd,$cleanupperiod,GETDATE()) EXECUTE dbo.sp_purge_jobhistory @oldest_date = @CleanupDate" -b
"@
$step3 = @"
sqlcmd -E -S `$(ESCAPE_SQUOTE(SRVR)) -d master -Q "DELETE FROM [dbo].[CommandLog] WHERE StartTime < DATEADD(dd,$clenaupperiod,GETDATE())" -b
"@


if (-not(Get-Module -name 'SQLPS')) {
   if (Get-Module -ListAvailable | Where-Object  {$_.Name -eq 'SQLPS' }) {
       Push-Location                        
       Import-Module -Name 'SQLPS' -DisableNameChecking
       Pop-Location 
    }
 }

 Write-host $servername
 Write-host $instance
 
if (($instance -eq "" )) {
    write-host 'Error, missing required parameters'
    return 1
}
 $svr = new-object ('Microsoft.SqlServer.Management.Smo.Server') $instance
 $inst = $svr | Select Name
 #Create a Job
 $joblisting = $svr.jobserver.jobs | select-object -ExpandProperty Name
    if ($joblisting.contains($jobname)) {
        Write-host 'Job ['$jobname'] already exists.  Skipping' -ForegroundColor Magenta
        return 1
    }
    else {
    $j = new-object ('Microsoft.SqlServer.Management.Smo.Agent.Job') ($svr.JobServer,$jobname)
    $j.Description = 'System cleanup job'
    $j.OwnerLoginName = 'sa'
    $j.Create()
    #Create a step
    $js = new-object ('Microsoft.SqlServer.Management.Smo.Agent.JobStep') ($j, 'Step 01 - Job Hist')
    $js.SubSystem = 'CmdExec'
    $js.Command =$step1
    $js.OnSuccessAction = 'QuitWithSuccess'
    $js.OnFailAction = 'QuitWithFailure'
    $js.Create()
    #Create a step
    $js = new-object ('Microsoft.SqlServer.Management.Smo.Agent.JobStep') ($j, 'Step 02 - Backup Hist')
    $js.SubSystem = 'CmdExec'
    $js.Command =$step2
    $js.OnSuccessAction = 'QuitWithSuccess'
    $js.OnFailAction = 'QuitWithFailure'
    $js.Create()
    #Create a step
    $js = new-object ('Microsoft.SqlServer.Management.Smo.Agent.JobStep') ($j, 'Step 03 - Command Log')
    $js.SubSystem = 'CmdExec'
    $js.Command =$step3
    $js.OnSuccessAction = 'QuitWithSuccess'
    $js.OnFailAction = 'QuitWithFailure'
    $js.Create()
    #connect step to Job
    $jsid = $js.ID
    $j.ApplyToTargetServer($servername)
    $j.StartStepID = $jsid
    $j.Alter()
    
    # Now set a schedule 
    $jsch = new-object ('Microsoft.SqlServer.Management.Smo.Agent.JobSchedule') ($j, 'Sched 01')
    $jsch.FrequencyTypes =8      #Weekly  
    $jsch.FrequencyInterval = $runday  
    $jsch.FrequencySubDayTypes =1
    $jsch.FrequencySubDayInterval=30
    $jsch.FrequencyRelativeIntervals=0
    $jsch.FrequencyRecurrenceFactor=1
    $jsch.ActiveStartDate=[datetime]'01/01/2003 00:00:00'
    $jsch.ActiveEndDate=[datetime]'12/31/2099 00:00:00'
    $jsch.ActiveStartTimeOfDay=$starttime  
    $jsch.ActiveEndTimeOfDay=[timespan]'0.00:00:00'
    $jsch.IsEnabled=1
    #$error[0].Exception | fl * -force to get more on any errors

    $jsch.Create()
    #let calling program know if there were errors.
    write-host 'Job and schedule created:'$jobname
    return $error.count
    }
}