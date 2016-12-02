# Get all running instances in all regions following Don Jones tool making part guide

$Regions = Get-EC2Region
ForEach ( $Region in $Regions ) 
{
    try 
    {
        $RegionName = $Region.RegionName
        Set-DefaultAWSRegion -Region $RegionName -ErrorAction Stop
        $Group = (Get-EC2SecurityGroup | where { $_.Description -like "launch-wizard*" })
        $GroupCount = $Groups.count 
        if ($GroupCount -gt 0)
        { 
            $GroupProperties = $Group | select description,groupID,groupName | fl
        }
    }
    catch
    {
        Write-Warning "AWS is having problems to connect to region $RegionName"
    }
    finally
    {
        if ($Group.count -gt 0)
        {
            if ($GroupCount -eq 1)
            {
                Write-Output "$GroupCount Group found in $RegionName"
            }
            else
            {
                Write-Output "$GroupCount Groups found in $RegionName"
            }
            Write-Output $GroupProperties
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