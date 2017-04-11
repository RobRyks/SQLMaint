if (-not(Get-Module -name 'SQLPS')) {
   if (Get-Module -ListAvailable | Where-Object  {$_.Name -eq 'SQLPS' }) {
       Push-Location                        
       Import-Module -Name 'SQLPS' -DisableNameChecking
       Pop-Location 
    }
 }


$starttime = [timespan]'0.05:00:00'
$runday = 64 #Sat=64, Sun=1, Everday=127 https://msdn.microsoft.com/en-us/library/microsoft.sqlserver.management.smo.agent.jobschedule.frequencyinterval.aspx
$servername='Localhost'
$instance = '\SQLAUX'  #use format such as '\SQLAUX'

 $step1 = @"
 sqlcmd -E -S `$(ESCAPE_SQUOTE(SRVR)) -d master -Q 
 "EXECUTE dbo.IndexOptimize @Databases = 'USER_DATABASES',
 @FragmentationLow = NULL, @FragmentationMedium = 'INDEX_REORGANIZE,INDEX_REBUILD_ONLINE,
 INDEX_REBUILD_OFFLINE',@FragmentationHigh = 'INDEX_REBUILD_ONLINE,INDEX_REBUILD_OFFLINE',
 @FragmentationLevel1 = 5,@FragmentationLevel2 = 30,@UpdateStatistics = 'ALL',
 @OnlyModifiedStatistics = 'Y',@LogToTable = 'Y'"
"@

 #note that you can replace localhost with another server name.  Here I assume we are running this
 #powershell on the server we wish to change
 $svr = new-object ('Microsoft.SqlServer.Management.Smo.Server') $servername$instance
 #svr | get-mod
 $inst = $svr | Select Name
 #Create a Job
 $j = new-object ('Microsoft.SqlServer.Management.Smo.Agent.Job') ($svr.JobServer, 'Optimize-UserDB')
 $j.Description = 'Optimize all user databases on this instance'
 $j.OwnerLoginName = 'sa'
 $j.Create()
 #Create a step
 $js = new-object ('Microsoft.SqlServer.Management.Smo.Agent.JobStep') ($j, 'Step 01')
 $js.SubSystem = 'CmdExec'
 $js.Command =$step1
 $js.OnSuccessAction = 'QuitWithSuccess'
 $js.OnFailAction = 'QuitWithFailure'
 $js.Create()
 #connect step to Job
 $jsid = $js.ID
 $j.ApplyToTargetServer($s.Name)
 $j.StartStepID = $jsid
 $j.Alter()
 # Now set a schedule 
 $jsch = new-object ('Microsoft.SqlServer.Management.Smo.Agent.JobSchedule') ($j, 'Sched 01')
 #		@freq_type=8, 
#		@freq_interval=64, 
#		@freq_subday_type=1, 
#		@freq_subday_interval=30, 
#		@freq_relative_interval=0, 
#		@freq_recurrence_factor=1, 
#		@active_start_date=20030101, 
#		@active_end_date=99991231, 
#		@active_start_time=40000, 
#		@active_end_time=235959, 

$jsch.FrequencyTypes =8      #Weekly  
$jsch.FrequencyInterval = $runday  
$jsch.FrequencySubDayTypes =1
$jsch.FrequencySubDayInterval=30
$jsch.FrequencyRelativeIntervals=0
$jsch.FrequencyRecurrenceFactor=1
$jsch.ActiveStartDate=[datetime]'01/01/2003 00:00:00'
$jsch.ActiveEndDate=[datetime]'12/31/2099 00:00:00'
$jsch.ActiveStartTimeOfDay=$starttime   # start at 5 AM
$jsch.ActiveEndTimeOfDay=[timespan]'0.00:00:00'
$jsch.IsEnabled=1
#$error[0].Exception | fl * -force to get more on any errors

$jsch.Create()
