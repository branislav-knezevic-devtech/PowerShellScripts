$domainNumber = Read-Host "Enter domain number"
$Domain = "@devcmp" + $domainNumber + ".onmicrosoft.com"
$CSVPath = "D:\CSV_Data"

$newShared = Import-CSV -Path $CSVPath\109users.csv
$newShared | ForEach-Object {
    $upn = $_.UserPrincipalName
    $split = $upn.Split("@")
    $name = $split[0]
    $fqdn = $name + $domain
    
    if ((get-mailbox -Identity $name) -eq $null)
    {
        New-Mailbox -shared -name $name
    }
    else
    {
        Write-Host "Mailbox $name already exists"
    }
}
 
 ####   
$domainNumber = Read-Host "Enter domain number"
$Domain = "@devcmp" + $domainNumber + ".onmicrosoft.com"
$CSVPath = "D:\CSV_Data"

$newShared = Import-CSV -Path $CSVPath\109users.csv
$newShared | ForEach-Object {
    $upn = $_.UserPrincipalName
    $split = $upn.Split("@")
    $name = $split[0]
    $fqdn = $name + $domain
    $25 = Import-Csv -Path $CSVPath\25_cloudmigrationservice.net.csv
    
    if ((get-mailbox -Identity $name) -eq $null)
    {
        New-Mailbox -shared -name $name
    }
    else
    {
        Write-Host "Mailbox $name already exists"
    }
}

<#
    go through each mailbox from csv
    check if that mailbox exists on the destination
    if it does not, create corresponding shared mailbox

    

New-Mailbox -Shared -Name SharedTest

(Get-Mailbox petar.petrovic) -ne $null
$test = "goran.manot@devcmp25.onmicrosoft.com"
((Get-Mailbox).userprincipalname) -like $test
#>