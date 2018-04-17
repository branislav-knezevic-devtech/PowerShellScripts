# how to get folder names in new format
$dateNew = [string](Get-Date).DayOfYear + "-" + [string](Get-Date).TimeOfDay.Hours + "-" + [string](Get-Date).TimeOfDay.Minutes + "-" + [string](Get-Date).TimeOfDay.Seconds
# leave just dayOfYear as integer
$number = [int]$dateNew.Substring(0,$dateNew.IndexOf('-'))

# two functions to list only subfolders of a bucket
function Get-Subdirectories
{
  param
  (
    [string] $BucketName,
    [string] $KeyPrefix,
    [bool] $Recurse
  )

  @(get-s3object -BucketName $BucketName -KeyPrefix $KeyPrefix -Delimiter '/') | Out-Null

  if($AWSHistory.LastCommand.Responses.Last.CommonPrefixes.Count -eq 0)
  {
    return
  }

  $AWSHistory.LastCommand.Responses.Last.CommonPrefixes

  if($Recurse)
  {
    $AWSHistory.LastCommand.Responses.Last.CommonPrefixes | % { Get-Subdirectories -BucketName $BucketName -KeyPrefix $_ -Recurse $Recurse }
  }
}

function Get-S3Directories
{
  param
  (
    [string] $BucketName,
    [bool] $Recurse = $false
  )

  Get-Subdirectories -BucketName $BucketName -KeyPrefix '/' -Recurse $Recurse
}

Get-Subdirectories -BucketName cloud-migration-platform-dev-history
(Get-S3Object -BucketName cloud-migration-platform-dev-history -KeyPrefix Wednesday).Key  
| % { remove-s3object -bucket cloud-migration-platform-dev-history -key $_ -Force }


$folders = Get-Subdirectories -BucketName cloud-migration-platform-dev-history
foreach ($f in $folders)
{
    $number = [int]$dateNew.Substring(0,$dateNew.IndexOf('-'))
}
<#
    Problem:
        folderi se izlistavaju posebnom funkcijom, ne postoji .name ili .date parametar
        treba promenuti naziv foldera i pretvoriti u jednostavan integer - uspesno
        od postojecih brojeva, izabrati one koji nisu u najvecih 5 i obrisati - problem oko selekcije
#>