$UserCredential = Get-Credential
$SessionOptions = New-PSSessionOption –SkipCACheck –SkipCNCheck –SkipRevocationCheck
$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://hex2016.devtech-labs.com/powershell -Authentication Basic -Credential $UserCredential –SessionOption $SessionOptions
Import-PSSession $Session