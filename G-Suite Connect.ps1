$ClietnID = Get-Content D:\Credentials\G-Suite-ClientId.txt
$ClientSecret = Get-Content D:\Credentials\G-Suite-ClientSecret.txt

Set-gShellClientSecrets -ClientId $ClietnID -ClientSecret $ClientSecret 