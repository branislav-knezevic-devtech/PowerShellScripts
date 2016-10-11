$LiveCred = Get-Credential
$Session = Connect-MsolService
$DissablePassword = Get-MsolUser | Set-MsolUser -PasswordNeverExpires $True