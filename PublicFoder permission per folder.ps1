$Fs = Get-PublicFolder -Recurse | where {$_.parentPath -like "\"}
ForEach ($f in $Fs)
{
    $fn = $f.ParentPath + $f.name
    Get-PublicFolderClientPermission $fn | where {$_.user -like "default"} | select identity,accessRights
}

Get-PublicFolderClientPermission "\root folder" 