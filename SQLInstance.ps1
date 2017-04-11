get-module Get-SQLInstance.ps1m


$servername = 'M3VE-1513-DB'

$instances = Get-SqlInstance -computername $servername

Write-host $instances.instance