$creds = New-AWSCredentials -AccessKey %S3AccessKey% -SecretKey %S3SecretKey%
Set-AWSCredentials -Credential $creds -StoreAs devtech


$bucket = "cloud-migration-platform-dev"
$history = "cloud-migration-platform-dev-history"
$date = (Get-Date).DateTime -replace ",", "" -replace " ", "-" -replace ":", "-"

#create backup of all files to history bucket
Get-S3Object -BucketName $bucket -KeyPrefix "exchange-worker" -ProfileName devtech | % { Copy-S3Object -BucketName $bucket -Key $_.Key -DestinationBucket $history/$date -DestinationKey $_.Key -ProfileName devtech }
Get-S3Object -BucketName $bucket -KeyPrefix "message-handler" -ProfileName devtech| % { Copy-S3Object -BucketName $bucket -Key $_.Key -DestinationBucket $history/$date -DestinationKey $_.Key -ProfileName devtech }
Get-S3Object -BucketName $bucket -KeyPrefix "resource-orchestrator" -ProfileName devtech| % { Copy-S3Object -BucketName $bucket -Key $_.Key -DestinationBucket $history/$date -DestinationKey $_.Key -ProfileName devtech }
Get-S3Object -BucketName $bucket -KeyPrefix "selfhosted-service" -ProfileName devtech | % { Copy-S3Object -BucketName $bucket -Key $_.Key -DestinationBucket $history/$date -DestinationKey $_.Key -ProfileName devtech }
Get-S3Object -BucketName $bucket -KeyPrefix "cloudmesh-migrationstatus-service" -ProfileName devtech | % { Copy-S3Object -BucketName $bucket -Key $_.Key -DestinationBucket $history/$date -DestinationKey $_.Key -ProfileName devtech }

#remove all existing files from dev bucket
Get-S3Object -BucketName $bucket -KeyPrefix "exchange-worker" -ProfileName devtech | % {Remove-S3Object -BucketName $bucket -Key $_.Key  -Force:$true -ProfileName devtech}
Get-S3Object -BucketName $bucket -KeyPrefix "message-handler" -ProfileName devtech | % {Remove-S3Object -BucketName $bucket -Key $_.Key  -Force:$true -ProfileName devtech}
Get-S3Object -BucketName $bucket -KeyPrefix "resource-orchestrator" -ProfileName devtech | % {Remove-S3Object -BucketName $bucket -Key $_.Key  -Force:$true -ProfileName devtech}
Get-S3Object -BucketName $bucket -KeyPrefix "selfhosted-service" -ProfileName devtech | % {Remove-S3Object -BucketName $bucket -Key $_.Key  -Force:$true -ProfileName devtech}
Get-S3Object -BucketName $bucket -KeyPrefix "cloudmesh-migrationstatus-service" -ProfileName devtech | % {Remove-S3Object -BucketName $bucket -Key $_.Key  -Force:$true -ProfileName devtech}

#copy new files from TeamCity to dev bucket
(Get-ChildItem "%system.teamcity.build.workingDir%/Worker" -Recurse) | % { Write-S3Object -BucketName cloud-migration-platform-dev/exchange-worker -File $_.FullName -Key $_.Name -ProfileName devtech }
(Get-ChildItem "%system.teamcity.build.workingDir%/MessageHandler" -Recurse) | % { Write-S3Object -BucketName cloud-migration-platform-dev/message-handler -File $_.FullName -Key $_.Name -ProfileName devtech }
(Get-ChildItem "%system.teamcity.build.workingDir%/Orchestrator" -Recurse) | % { Write-S3Object -BucketName cloud-migration-platform-dev/resource-orchestrator -File $_.FullName -Key $_.Name -ProfileName devtech }
(Get-ChildItem "%system.teamcity.build.workingDir%/SelfHostedService" -Recurse) | % { Write-S3Object -BucketName cloud-migration-platform-dev/selfhosted-service -File $_.FullName -Key $_.Name -ProfileName devtech }
(Get-ChildItem "%system.teamcity.build.workingDir%/MigrationStatusService" -Recurse) | % { Write-S3Object -BucketName cloud-migration-platform-dev/cloudmesh-migrationstatus-service -File $_.FullName -Key $_.Name -ProfileName devtech }

#-----------------
#mid version 
#-----------------

$creds = New-AWSCredentials -AccessKey %S3AccessKey% -SecretKey %S3SecretKey%
Set-AWSCredentials -Credential $creds -StoreAs devtech


$bucket = "cloud-migration-platform-dev"
$history = "cloud-migration-platform-dev-history"
$date = (Get-Date).DateTime -replace ",", "" -replace " ", "-" -replace ":", "-"

#create backup of all files to history bucket
Get-S3Object -BucketName $bucket -KeyPrefix "exchange-worker" -ProfileName devtech | % { Copy-S3Object -BucketName $bucket -Key $_.Key -DestinationBucket $history/$date -DestinationKey $_.Key -ProfileName devtech }
Get-S3Object -BucketName $bucket -KeyPrefix "message-handler" -ProfileName devtech| % { Copy-S3Object -BucketName $bucket -Key $_.Key -DestinationBucket $history/$date -DestinationKey $_.Key -ProfileName devtech }
Get-S3Object -BucketName $bucket -KeyPrefix "resource-orchestrator" -ProfileName devtech| % { Copy-S3Object -BucketName $bucket -Key $_.Key -DestinationBucket $history/$date -DestinationKey $_.Key -ProfileName devtech }
Get-S3Object -BucketName $bucket -KeyPrefix "selfhosted-service" -ProfileName devtech | % { Copy-S3Object -BucketName $bucket -Key $_.Key -DestinationBucket $history/$date -DestinationKey $_.Key -ProfileName devtech }
Get-S3Object -BucketName $bucket -KeyPrefix "cloudmesh-migrationstatus-service" -ProfileName devtech | % { Copy-S3Object -BucketName $bucket -Key $_.Key -DestinationBucket $history/$date -DestinationKey $_.Key -ProfileName devtech }

#remove all existing files from dev bucket
Get-S3Object -BucketName $bucket -KeyPrefix "exchange-worker" -ProfileName devtech | % {Remove-S3Object -BucketName $bucket -Key $_.Key  -Force:$true -ProfileName devtech}
Get-S3Object -BucketName $bucket -KeyPrefix "message-handler" -ProfileName devtech | % {Remove-S3Object -BucketName $bucket -Key $_.Key  -Force:$true -ProfileName devtech}
Get-S3Object -BucketName $bucket -KeyPrefix "resource-orchestrator" -ProfileName devtech | % {Remove-S3Object -BucketName $bucket -Key $_.Key  -Force:$true -ProfileName devtech}
Get-S3Object -BucketName $bucket -KeyPrefix "selfhosted-service" -ProfileName devtech | % {Remove-S3Object -BucketName $bucket -Key $_.Key  -Force:$true -ProfileName devtech}
Get-S3Object -BucketName $bucket -KeyPrefix "cloudmesh-migrationstatus-service" -ProfileName devtech | % {Remove-S3Object -BucketName $bucket -Key $_.Key  -Force:$true -ProfileName devtech}

#copy new files from TeamCity to dev bucket
(Get-ChildItem "%system.teamcity.build.workingDir%\*.zip") | % { Write-S3Object -BucketName cloud-migration-platform-dev -File $_.FullName -Key $_.Name -ProfileName devtech }

#-----------------
#end version version 
#-----------------

$creds = New-AWSCredentials -AccessKey %S3AccessKey% -SecretKey %S3SecretKey%
Set-AWSCredentials -Credential $creds -StoreAs devtech


$bucket = "cloud-migration-platform-staging"
$history = "cloud-migration-platform-stagning-history"
$date = (Get-Date).DateTime -replace ",", "" -replace " ", "-" -replace ":", "-"

#create backup of all files to history bucket
Get-S3Object -BucketName $bucket -ProfileName devtech | % { Copy-S3Object -BucketName $bucket -Key $_.Key -DestinationBucket $history/$date -DestinationKey $_.Key -ProfileName devtech }

#remove all existing files from dev bucket
Get-S3Object -BucketName $bucket -ProfileName devtech | % {Remove-S3Object -BucketName $bucket -Key $_.Key  -Force:$true -ProfileName devtech}

#copy new files from TeamCity to dev bucket
(Get-ChildItem "%system.teamcity.build.workingDir%/*.zip") | % { Write-S3Object -BucketName $bucket -File $_.FullName -Key $_.Name -ProfileName devtech }
