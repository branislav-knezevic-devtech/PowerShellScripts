$Domain = (Get-PSSession).name
$Admin = "goran.manot@" + $Domain + ".onmicrosoft.com"
$NewPassword = Get-Content "D:\Credentials\Password-new.txt" | ConvertTo-SecureString
Set-Mailbox -Identity goran.manot -Password $NewPassword