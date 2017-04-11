

Function test123 { [CmdletBinding()]
param (
    [string]$ServerInstance    
) 

$SampleFrequencySeconds = 10
$CollectionDurationSeconds = 120
write-host "starting"
# do a check to ensure that collection duration is greater than
# or equal to the frequency rate
if ($CollectionDurationSeconds -lt $SampleFrequencySeconds) {
    Write-Error "CollectionDurationSeconds cannot be less than SampleFrequencySeconds"
    exit
}
write-host "next 1"
 
# loop through all of the drives, sampling them
$DrivesOutput = for ($i = 0; $i -lt [int]($CollectionDurationSeconds / $SampleFrequencySeconds); $i++) {
    Get-Counter -Counter "\LogicalDisk(*)\avg. disk sec/transfer" |
        Select-Object -ExpandProperty CounterSamples |
        Where-Object {$_.InstanceName -ne "_total"} |
        Select-Object InstanceName, @{Name = "Type"; Expression = {"LOGICAL"}}, CookedValue
 
    Get-Counter -Counter "\PhysicalDisk(*)\avg. disk sec/transfer" |
        Select-Object -ExpandProperty CounterSamples |
        Where-Object {$_.InstanceName -ne "_total"} |
        Select-Object InstanceName, @{Name = "Type"; Expression = {"PHYSICAL"}},CookedValue
 
    # Sleep for the specified frequency before continuing in the loop
    Write-Host "." -NoNewline
    Start-Sleep -Seconds $SampleFrequencySeconds
}
 
# Group by the drive and Calculate the average for each drive we have
# round to the nearest [ms]
#$DrivesOutput |
#    Group-Object InstanceName, Type |
#    Select-Object @{Name = "InstanceName";Expression = {$_.Group.InstanceName[0]}}, 
#    @{Name = "Type"; Expression = {$_.Group.Type[0]}},
#    @{Name = "DiskLatencyMs"; Expression = {[int](($_.Group.CookedValue | Measure-Object -Average).Average * 1000)}} |
#    Sort-Object InstanceName
Write-host "done"
}

$result = test123 -ServerInstance "M3VE-1513-DB\"