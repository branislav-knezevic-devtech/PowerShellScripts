$UserCredential = Get-Credential
$SessionOptions = New-PSSessionOption –SkipCACheck –SkipCNCheck –SkipRevocationCheck
$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://mail.cloudmigrationservice.net/powershell -Authentication Basic -Credential $UserCredential –SessionOption $SessionOptions
Import-PSSession $Session