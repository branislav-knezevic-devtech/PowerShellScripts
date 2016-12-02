# Get all running instances in all regions following Don Jones tool making part guide

$Regions = Get-EC2Region
ForEach ( $Region in $Regions ) 
{
    try 
    {
        $RegionName = $Region.RegionName
        Set-DefaultAWSRegion -Region $RegionName -ErrorAction Stop
        $Groups = (Get-EC2SecurityGroup | where { $_.Description -like "launch-wizard*" })
        $GroupCount = $Groups.count 
        if ($GroupCount -gt 0)
        { 
            foreach ($Group in $Groups)
            {
                Remove-EC2SecurityGroup -GroupId $group.groupID -Confirm:$false
            }
        }
    }
    catch
    {
        Write-Warning "Unable to delete group $($group.groupID)"
    }
    finally
    {
        if ($Groups.count -gt 0)
        {
            if ($GroupCount -eq 1)
            {
                Write-Output "$GroupCount group deleted in $RegionName"
            }
            else
            {
                Write-Output "$GroupCount Groups deleted in $RegionName"
            }
        }
        Else
        {
            Write-Output "There are no Groups in region $RegionName"
        }
    }
}

<#
can be added here
BEGIN {}
PROCESS {}
END {}
#>