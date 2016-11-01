<#
$RegionSelection = @('[1] North Virginia';
                     '[2] Ohio';
                     '[3] California';
                     '[0] Exit')
#>

$output = $null
$input = $null
$input = Read-Host -Prompt "Select Region from the list by pressing corresponding number: 
[1] North Virginia
[2] Ohio
[3] California
[0] Exit
You select"
if ($input -eq '0')
{
    Exit
}
else # ($input -notlike '0')
{
    if ($input -eq '1')
    {
        $output =  "Default region has been set to North Virginia"
    }   
    if ($input -eq '2')
    {
        $output = "Default region has been set to Ohio"
    }  
    if ($input -eq '3')
    {
        $Output = "Default region has been set to California"
    }
    else
    {
        Write-Output "Error, please choose from numbers 0 - 3"
        .\SelectionTest.ps1 
    }  
}

Write-Output $output


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