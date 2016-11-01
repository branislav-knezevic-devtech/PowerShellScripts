#$option = @{1 = 'Option one'
#            2 = 'Option two'
#            3 = 'Option three'}
#Read-Host $option
#if ($option -eq 1)
#{
#    Write-Output $option[0]
#}
#if ($option -eq 2)
#{
#    Write-Output $option[1]
#}
#if ($option -eq 3)
#{
#    Write-Output $option[2]
#}

$input = Read-Host -Prompt "Select Region from the list by pressing corresponding number: 
[1] North Virginia
[2] Ohio 
[3] California
You select"
$output = if ($input -eq '1')
{
    Write-Output "Default region has been set to North Virginia"
}   
if ($input -eq '2')
{
    Write-Output "Default region has been set to Ohio"
}  
if ($input -eq '3')
{
    Write-Output "Default region has been set to California"
}
else #(($input -notlike "1") -or ($input -notlike "2") -or ($input -notlike "3"))
{
    Write-Output "Error, please choose from numbers 1 - 3"
    .\SelectionTest.ps1 
}  

Write-Output $output
