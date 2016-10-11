
$FoldersToCreate = 3
$Path = "\RootPF"
for ($i=1; $i -le $FoldersToCreate; $i++)
{
    $PFName = "PublicFolder" + "-" + $i
    New-PublicFolder -Path $Path -Name $PFName
}

$ListFolders = Get-PublicFolder \RootPF -Recurse | where {$_.name -notlike "rootPF"}
$PFs = $ListFolders
ForEach ($PF in $PFs)
    {
    $PFName = $PF.name
    $FoldersToCreate = 3
    $Path = "\RootPF\$PFName"
    for ($i=1; $i -le $FoldersToCreate; $i++)
        {
        $PFName1 = "$PFName" + "." + $i
        New-PublicFolder -Path $Path -Name $PFName1
        } 
    }