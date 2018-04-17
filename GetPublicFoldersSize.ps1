$name = Read-Host "Unesi ime file-a bez extenzije"
$fileName = "C:\temp\" + $name + ".csv"
Get-PublicFolder -Recurse | where {$_.name -notlike "ipm_subtree"}  | Get-PublicFolderStatistics | select name,folderpath,totalitemsize,itemcount -ErrorAction: SilentlyContinue | Export-Csv $fileName 
Write-Host "Results: $fileName" -ForegroundColor: Cyan