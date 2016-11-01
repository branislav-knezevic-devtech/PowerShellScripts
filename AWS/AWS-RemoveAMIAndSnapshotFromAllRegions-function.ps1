
# in order for this to work, we need to save it under C:\program files\windows powershell\modules\[new folder]folder name\file_name.psm1
# or any other location which is listed within $env:PSModulePath
# after module has been saved and then edited it needs to be removed/added remove-module module_name | import-module module_name
# module is a folder which has been created, not a file within it, that is just a part of that module

<#
.SYNOPSIS
Delets AMIs and Snapshots
.DESCRIPTION
Goes through all regions except eu-central-1, locates desired image(AMI) and snapshot and removes them
In order for this function to run, moduel for AmazonAWS must be imported
.PARAMETER ImageID
Unique ID of an Image (AMI) which needs to be located and deleted
.EXAMPLE
Remove-AMIandSnaphostFromAllRegions -ImageID ami-81f00333
Removes AMI with ID ami-81f00333 and its snapshots from all regions
#>

# [Cmdletbinding(SupportShouldProcess=$true)] #enables -verbose and -whatif and -confirm

### put in someting for set-default region, to chose it from the list perhaps ###

function Remove-AMIandSnapshotFromAllRegions
{
    param 
    (
        [Parameter(Mandatory = $true,
                   ValueFromPipeline = $true,
                   HelpMessage = "Check ImageID on AWS")]
        [string]$ImageID
    )
    
    # $ImageID = "ami-81f00eee"
    $OwnerID = (Get-EC2Image -ImageId $ImageID).OwnerId
    $ImageName = (Get-EC2Image -ImageId $ImageID).name
    $CurrentRegion = (Get-DefaultAWSRegion).Region
    $Regions = Get-EC2Region | where {$_.Region -notlike $CurrentRegion}
    ForEach ($Region in $Regions) 
    {
        try
        {
            $RegionName = $Region.RegionName
            Set-DefaultAWSRegion -Region $RegionName
            $ImageForRemoval = (Get-EC2Image | where {$_.name -like $ImageName}).imageid
            Unregister-EC2Image -ImageId $ImageForRemoval -ErrorAction stop # -Verbose:$false if verbose needs to be switched of
            $SnapshotForRemoval = (Get-EC2Snapshot | where { $_.Description -like "*$ImageID*" }).SnapshotId
            Remove-EC2Snapshot -SnapshotId $SnapshotForRemoval -ErrorAction stop
        }
        catch
        {
            Write-Warning "Image $ImageForRemoval which is a copy of $ImageName was not found in $RegionName"
            Write-Warning "Snapshot $SnapshotForRemoval which belogns to $ImageForRemoval was not found in $RegionName"
        }
        Finally
        {
            Write-Output "Image $ImageForRemoval has been unregistered in $RegionName"
            Write-Output "Snapshot $SnapshotForRemoval which belonged to image $ImageForRemoval has been deleted"
        }
    }
}