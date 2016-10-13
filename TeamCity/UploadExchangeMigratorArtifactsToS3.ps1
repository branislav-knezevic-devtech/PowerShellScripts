$creds = New-AWSCredentials -AccessKey %S3AccessKey% -SecretKey %S3SecretKey%
Set-AWSCredentials -Credential $creds -StoreAs devtech

$bucket = "cloud-migration-platform-dev"
Get-S3Object -BucketName $bucket -KeyPrefix "exchange-worker" -ProfileName devtech | % {Remove-S3Object -BucketName $bucket -Key $_.Key  -Force:$true -ProfileName devtech}
Get-S3Object -BucketName $bucket -KeyPrefix "message-handler" -ProfileName devtech | % {Remove-S3Object -BucketName $bucket -Key $_.Key  -Force:$true -ProfileName devtech}
Get-S3Object -BucketName $bucket -KeyPrefix "resource-orchestrator" -ProfileName devtech | % {Remove-S3Object -BucketName $bucket -Key $_.Key  -Force:$true -ProfileName devtech}
Get-S3Object -BucketName $bucket -KeyPrefix "selfhosted-service" -ProfileName devtech | % {Remove-S3Object -BucketName $bucket -Key $_.Key  -Force:$true -ProfileName devtech}
Get-S3Object -BucketName $bucket -KeyPrefix "cloudmesh-migrationstatus-service" -ProfileName devtech | % {Remove-S3Object -BucketName $bucket -Key $_.Key  -Force:$true -ProfileName devtech}

(Get-ChildItem "%system.teamcity.build.workingDir%/Worker" -Recurse) | % { Write-S3Object -BucketName cloud-migration-platform-dev/exchange-worker -File $_.FullName -Key $_.Name -ProfileName devtech }
(Get-ChildItem "%system.teamcity.build.workingDir%/MessageHandler" -Recurse) | % { Write-S3Object -BucketName cloud-migration-platform-dev/message-handler -File $_.FullName -Key $_.Name -ProfileName devtech }
(Get-ChildItem "%system.teamcity.build.workingDir%/Orchestrator" -Recurse) | % { Write-S3Object -BucketName cloud-migration-platform-dev/resource-orchestrator -File $_.FullName -Key $_.Name -ProfileName devtech }
(Get-ChildItem "%system.teamcity.build.workingDir%/SelfHostedService" -Recurse) | % { Write-S3Object -BucketName cloud-migration-platform-dev/selfhosted-service -File $_.FullName -Key $_.Name -ProfileName devtech }
(Get-ChildItem "%system.teamcity.build.workingDir%/MigrationStatusService" -Recurse) | % { Write-S3Object -BucketName cloud-migration-platform-dev/cloudmesh-migrationstatus-service -File $_.FullName -Key $_.Name -ProfileName devtech }

# FUNCTION – Iterate through sub-folders and upload files to S3
function RecurseFolders([string]$path) {
  $fc = New-Object -com Scripting.FileSystemObject
  $folder = $fc.GetFolder($path)
  foreach ($i in $folder.SubFolders) {
    $thisFolder = $i.Path

    # Transform the local directory path to notation compatible with S3 Buckets and Folders
    # 1. Trim off the drive letter and colon from the start of the Path
    $s3Path = $thisFolder.ToString()
    $s3Path = $s3Path.SubString($sourceDrive.length)
    # 2. Replace back-slashes with forward-slashes
    # Escape the back-slash special character with a back-slash so that it reads it literally, like so: "\\"
    $s3Path = $s3Path -replace "\\", "/"
    $s3Path = "/" + $s3Folder + $s3Path

    # Upload directory to S3
    Write-S3Object -BucketName $s3Bucket -Folder $thisFolder -KeyPrefix $s3Path -ProfileName devtech
  }

  # If sub-folders exist in the current folder, then iterate through them too
  foreach ($i in $folder.subfolders) {
    RecurseFolders($i.path)
  }
}
