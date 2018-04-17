#archive log files by month
#script is used to archive log files by month
#param $archiveName
param ([int]$month, [int]$year)
#param $path
#$month = 8
#$year = 2010
if ($month -gt 0 -and $year -gt 0)
{
	$path = "C:\inetpub\logs\LogFiles\W3SVC1"
	$zipPath = 'C:\"Program Files"\7-Zip\7z.exe'
	$files = (Get-ChildItem $path -Filter *.log | Where {$_.LastWriteTime.Month -eq $month -and $_.LastWriteTime.Year -eq $year})
	$logs = ""
	$archiveName = ""
	if ($files -ne $null -and $files.Length -gt 0)
	{
		foreach ($file in $files)
		{
			#Write-Host $file.Name $file.LastWriteTime.Month $file.LastWriteTime.Year
			$archiveName = $file.Directory.Name
			$logs += "`"" + $file.FullName + "`" "
		}
		if ($logs -ne "")
		{
			$archiveName = $year.ToString() + '-' + $month.ToString() + '-' + $archiveName + '.7z'
			$cmd = "$zipPath a $path`\$archiveName $logs -mx9 > $path`\output.txt"
			#Write-Host $cmd
			Invoke-Expression $cmd 
			$output = "$path`\output.txt"
			$line = Get-Content $output | select -Last 1
			#Write-Host $line
			if ($line -eq "Everything is Ok")
			{
				foreach ($file in $files)
				{
					Write-Host $file.FullName
					Remove-Item $file.FullName
				}
			}
		}
	}
}

 