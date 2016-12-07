#Create Directory for temporary CSV files
$TestScriptMigration = Test-Path C:\Temp\ScriptMigration
if($TestScriptMigration -eq $false)
    {
    New-Item -ItemType directory -Path C:\Temp\ScriptMigration |
        Out-Null
    }

# testing with default $error variable - works but it is not readable
    try {
    New-Item -ErrorAction SilentlyContinue -ErrorVariable error -ItemType directory -Path C:\Temp\ScriptMigration
} Catch {
    $error
    $ErrorMessage = $_.Exception.message
    }

try {
New-MsolUser -FirstName djura -LastName djuric -ErrorAction SilentlyContinue -ErrorVariable error 
} catch {
    $error
    }
$error | Out-File C:\Temp\Error.txt



# testing with adding + to -ErrorVariable - that appends the errors to that variable, Out-File can be set at the end to 
# show the content. 

try {
    New-Item -ErrorAction SilentlyContinue -ErrorVariable ErrorLog -ItemType directory -Path C:\Temp\ScriptMigration
} Catch {
    $ErrorLog 
    }

try {
New-MsolUser -FirstName djura -LastName djuric -ErrorAction SilentlyContinue -ErrorVariable +ErrorLog 
} catch {
    $ErrorLog 
    }

$ErrorLog | Out-File C:\Temp\ErrorLog.txt




# Testing with $Exception variable - works only if -ErrorAction is Stop

try {
New-MsolUser -FirstName djura -LastName djuric -ErrorAction Stop 
} catch {
    $ErrorMessage = $_.Exception.Message | Out-File C:\Temp\ErrorException.txt -Append
    $FailedItem = $_.Exception.ItemName
    }

try {
    New-Item -ErrorAction Stop  -ItemType directory -Path C:\Temp\ScriptMigration
} Catch {
    $ErrorMessage = $_.Exception.Message | Out-File C:\Temp\ErrorException.txt -Append
    $FailedItem = $_.Exception.ItemName
    }