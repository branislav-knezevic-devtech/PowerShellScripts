<#
$RegionSelection = @('[1] North Virginia';
                     '[2] Ohio';
                     '[3] California';
                     '[0] Exit')
#>

$output = $null
#$input = $null
DO
{
    $input = Read-Host -Prompt "Select Region from the list by pressing corresponding number: 
    [1] North Virginia
    [2] Ohio
    [3] California
    [0] Exit
    You select"

    $output = if ($input -eq '1')
    {
        "Default region has been set to North Virginia"
    }   
    if ($input -eq '2')
    {
        "Default region has been set to Ohio"
    }  
    if ($input -eq '3')
    {
       "Default region has been set to California"
    }
    if ($input -eq '0')
    {
        Exit
    }
    if (($input -notlike "1") -or ($input -notlike "2") -or ($input -notlike "2") -or ($input -notlike "3")) 
    {
        "Error, please choose from numbers 0 - 3"
    } 
Write-Output $output 
}
Until (($input -eq "1") -or ($input -eq "2") -or ($input -eq "3") -or ($input -eq "0"))



<#
$allregions = Get-AWSRegion
$regions = @("[1] $allregions[0].name",
             "[2] $allregions[1].name",
             "[3] $allregions[2].name",
             "[4] $allregions[3].name",
             "[5] $allregions[4].name",
             "[6] $allregions[5].name",
             "[7] $allregions[6].name",
             "[8] $allregions[7].name",
             "[9] $allregions[8].name",
             "[0] Exit")
Write-Output $regions
    
$allregions[8].name        
#>