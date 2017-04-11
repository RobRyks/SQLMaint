$ServerInstance = "M3VE-1513-DB\"
Invoke-sqlcmd -Query "SELECT GETDATE() AS TimeOfQuery;" -ServerInstance $ServerInstance