[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SMO") | Out-Null

function getsqlinfo {
   param (
      [string]$servername,
      [string]$instance
      )
$SQLInfo = @{}

if ($instance.ToUpper() -eq 'MSSQLSERVER') {
    $inst = $servername + "\"
}
else {
       $inst = $servername + "\" + $instance
}

# Create an ADO.Net connection to the instance
Write-Host $inst

$cn = new-object system.data.SqlClient.SqlConnection("Data Source=$inst;Integrated Security=SSPI;Initial Catalog=master");
# Create an SMO connection to the instance
$s = new-object ('Microsoft.SqlServer.Management.Smo.Server') $inst


$SQLinfo.Collation = $s.Information.Collation
$SQLinfo.Version = $s.Information.Version
$SQLinfo.Build = $s.Information.BuildNumber
$SQLinfo.Edition = $s.Information.Edition
$SQLinfo.Processors = $s.Information.Processors
$SQLinfo.SP = $s.Information.ProductLevel

$SQLinfo.FullText = $s.Information.IsFullTextInstalled
$SQLinfo.Clustered = $s.Information.IsClustered
$SQLinfo.MinMinMemory = $s.Configuration.MinServerMemory.ConfigValue
$SQLinfo.MaxMaxMemory = $s.Configuration.MaxServerMemory.ConfigValue


Foreach ($key in $SQLInfo.Keys) {
 Write-host $key : $SQLinfo.$key
}







}

getsqlinfo -servername 'M3VE-1513-DB' -instance 'MSSQLSERVER'
