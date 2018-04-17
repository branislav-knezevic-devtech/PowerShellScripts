 accepted
	

You can use the AWS Tools For PowerShell to list objects (via Get-S3Object) in the bucket and pull common prefixes from the response object.

Below is a small library to recursively retrieve subdirectories:

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