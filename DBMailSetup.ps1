if (-not(Get-Module -name 'SQLPS')) {
   if (Get-Module -ListAvailable | Where-Object  {$_.Name -eq 'SQLPS' }) {
       Push-Location                        
       Import-Module -Name 'SQLPS' -DisableNameChecking
       Pop-Location 
    }
 }

 $smtpssrv = 'smtp-relay.infor.com'
 $domain = 'infor.com'
 $toAddress = 'robert.ryks@infor.com'
 #note that you can replace localhost with another server name.  Here I assume we are running this
 #powershell on the server we wish to change
 $svr = new-object ('Microsoft.SqlServer.Management.Smo.Server') localhost
 $inst = $svr.Name
 # Enable Database Mail
 $svr.Configuration.ShowAdvancedOptions.ConfigValue = 1
 $svr.Configuration.DatabaseMailEnabled.ConfigValue = 1
 $svr.Configuration.Alter()
 $mail = $svr.Mail
 $acct = new-object ('Microsoft.SqlServer.Management.Smo.Mail.MailAccount') ($mail, 'sqldba')
 $acct.Description = 'Database Administrator Email'
 $acct.DisplayName = 'Database Administrator'
 $acct.EmailAddress = $toAddress
 $acct.ReplyToAddress = $inst+$domain
 $acct.Create()
 $mlsrv = $acct.MailServers
 $mls = $mlsrv.Item(1)
 $mls.Rename($smtpsrv)
 $mls.EnableSsl = 'False'
 $mls.UserName = ''
 $mls.Alter()
 $acct.Alter()
 $mlp = new-object ('Microsoft.SqlServer.Management.Smo.Mail.MailProfile') ($mail, 'DBAMail2', 'Database Administrator Mail Profile')
 $mlp.Create()
 $mlp.AddAccount('sqldba2', 1)
 $mlp.Alter()