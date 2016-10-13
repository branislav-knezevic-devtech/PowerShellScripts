add-type @"
    using System.Net;
    using System.Security.Cryptography.X509Certificates;
    public class TrustAllCertsPolicy : ICertificatePolicy {
        public bool CheckValidationResult(
            ServicePoint srvPoint, X509Certificate certificate,
            WebRequest request, int certificateProblem) {
            return true;
        }
    }
"@

[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy

$location = Invoke-RestMethod -Uri 'https://ec2-54-93-111-100.eu-central-1.compute.amazonaws.com:8000/MachineLocationWebService/'

$creds = New-AWSCredentials -AccessKey %S3AccessKey% -SecretKey %S3SecretKey%
Set-AWSCredentials -Credential $creds -StoreAs devtech

<#
$passwordWebServer = convertto-securestring -asplaintext -force -string '%WebServerPassword%'
$credentialWebServer = new-object -typename system.management.automation.pscredential -argumentlist "\Administrator", $passwordWebServer  
$sessionWebServer = new-pssession %WebServerInstanceIp% -credential $credentialWebServer 


Invoke-Command -Session $sessionWebServer -ScriptBlock {
    iisreset /stop
    Remove-Item C:\inetpub\wwwroot\DemoWebApi\* -Force -Recurse

    $filesWebApi = Get-S3Object -BucketName cloud-migration-platform-dev -KeyPrefix web-api -ProfileName devtech
    $keyPrefix = "web-api/"
	$localPath = "C:\inetpub\wwwroot\DemoWebApi\"
	$replace = '^(.*?)'+$keyPrefix
	foreach($object in $filesWebApi) {
		$localFileName = $object.Key -replace $replace, '$1'
		Write-Host $localFileName
		if ($localFileName -ne '')
		{
			$localFilePath = Join-Path $localPath $localFileName
			Copy-S3Object -BucketName cloud-migration-platform-dev -Key $object.Key -LocalFile $localFilePath -ProfileName devtech
		}
	}
	
    
	Remove-Item C:\inetpub\wwwroot\Demo\* -Force -Recurse
	
	$filesUI = Get-S3Object -BucketName cloud-migration-platform-dev -KeyPrefix ui -ProfileName devtech
    $keyPrefix = "ui/"
	$localPath = "C:\inetpub\wwwroot\Demo\"
	$replace = '^(.*?)'+$keyPrefix
	foreach($object in $filesUI) {
		$localFileName = $object.Key -replace $replace, '$1' 
		if ($localFileName -ne '')
		{
			$localFilePath = Join-Path $localPath $localFileName
			Copy-S3Object -BucketName cloud-migration-platform-dev -Key $object.Key -LocalFile $localFilePath -ProfileName devtech
		}
	}
    
    iisreset /start
}
Remove-PSSession $sessionWebServer
#>

$password3 = ConvertTo-SecureString -AsPlainText -Force -String '%MigrationStatusServiceInstancePassword%'
$credential3 = New-Object -TypeName system.management.automation.pscredential -ArgumentList "\Administrator", $password3
$session3 = New-PSSession %MigrationStatusServiceInstanceIp% -Credential $credential3

Invoke-Command -Session $session3 -ScriptBlock {
    $ServiceName = "MigrationStatusChange"
	Stop-Service $ServiceName
	Remove-Item C:\cloudmesh-migrationstatus-service\*
	$files = Get-S3Object -BucketName 'cloud-migration-platform-dev' -KeyPrefix '/cloudmesh-migrationstatus-service'
	foreach($key in $files.key) {
		if ($key.substring($key.length - 1, 1) -ne '/')
		{
			Copy-S3Object -BucketName 'cloud-migration-platform-dev' -Key $key -LocalFile C:\$key
		}
	}
	Start-Service $ServiceName
}
Remove-PSSession $session3

foreach($handler in $location.MessageHandlers)
{
    $password1 = convertto-securestring -asplaintext -force -string $handler.MachinePassword
    $credential1 = new-object -typename system.management.automation.pscredential -argumentlist "\Administrator", $password1  
    $session1 = new-pssession $handler.PublicIp -credential $credential1  
    enter-pssession $session1 
    Invoke-Command -Session $session1 -ScriptBlock {
        Stop-Service MessageHandler
        Remove-Item C:\message-handler\*
        $files = Get-S3Object -BucketName 'cloud-migration-platform-dev' -KeyPrefix '/message-handler'
		foreach($key in $files.key) {
			if ($key.substring($key.length - 1, 1) -ne '/')
			{
				Copy-S3Object -BucketName 'cloud-migration-platform-dev' -Key $key -LocalFile C:\$key
			}
		}
        Start-Service MessageHandler
    }
    Exit-PSSession
}

$passwordO = convertto-securestring -asplaintext -force -string $location.Orchestrator.MachinePassword
$credentialO = new-object -typename system.management.automation.pscredential -argumentlist "\Administrator", $passwordO  
$sessionO = new-pssession $location.Orchestrator.PublicIp -credential $credentialO  
enter-pssession $sessionO 

Invoke-Command -Session $sessionO -ScriptBlock {
    Stop-Service ResourceOrchestrator
    Remove-Item C:\resource-orchestrator\*
    $files = Get-S3Object -BucketName 'cloud-migration-platform-dev' -KeyPrefix '/resource-orchestrator'
		foreach($key in $files.key) {
			if ($key.substring($key.length - 1, 1) -ne '/')
			{
				Copy-S3Object -BucketName 'cloud-migration-platform-dev' -Key $key -LocalFile C:\$key
			}
		}
    Start-Service ResourceOrchestrator
}
Exit-PSSession


$passwordWCF = ConvertTo-SecureString -AsPlainText -Force -String '%WcfInstancePassword%'
$credentialWCF = New-Object -TypeName system.management.automation.pscredential -ArgumentList "\Administrator", $passwordWCF
$sessionWCF = New-PSSession %WfcInstanceIp% -Credential $credentialWCF

Invoke-Command -Session $sessionWCF -ScriptBlock {
	$ServiceName = "SelfhostedService"
	Stop-Service $ServiceName
	Remove-Item C:\selfhosted-service\*
	$files = Get-S3Object -BucketName 'cloud-migration-platform-dev' -KeyPrefix '/selfhosted-service'
	foreach($key in $files.key) {
		if ($key.substring($key.length - 1, 1) -ne '/')
		{
			Copy-S3Object -BucketName 'cloud-migration-platform-dev' -Key $key -LocalFile C:\$key
		}
	}
	$config = 'C:\selfhosted-service\ExchangeMigrator.WebServiceHost.exe.config'
	$doc = (Get-Content $config) -as [Xml]
	$root = $doc.get_DocumentElement();
	$host1 = invoke-restmethod -uri http://169.254.169.254/latest/meta-data/public-hostname
	foreach ($service in $root.'system.serviceModel'.services.service) {
		$service.host.baseAddresses.add.baseAddress = $service.host.baseAddresses.add.baseAddress.Replace('localhost',$host1)
	}
	($root.appSettings.add | where {$_.Key -eq 'AWSRegion'}).value = 'eu-central-1'
	($root.appSettings.add | where {$_.Key -eq 'EvironmentPrefix'}).value = 'Qa-'
	$doc.Save($config)
	New-NetFirewallRule -DisplayName 'SHService' -Direction Inbound -LocalPort 8000 -Protocol TCP -Action Allow
	Start-Service $ServiceName
}
Remove-PSSession $sessionWCF

<#
foreach($Worker in $location.workers)
{
    $passwordW = convertto-securestring -asplaintext -force -string $location.Workers.MachinePassword
    $credentialW = new-object -typename system.management.automation.pscredential -argumentlist "\Administrator", $passwordW  
    $sessionW = new-pssession $location.Worker.PublicIp -credential $credentialW  
    enter-pssession $sessionW 
    
    Invoke-Command -Session $sessionW -ScriptBlock {
        Stop-Service ExchangeWorker
        Remove-Item C:\exchange-worker\*
        $files = Get-S3Object -BucketName 'cloud-migration-platform-dev' -KeyPrefix '/exchange-worker'
    		foreach($key in $files.key) {
    			if ($key.substring($key.length - 1, 1) -ne '/')
    			{
    				Copy-S3Object -BucketName 'cloud-migration-platform-dev' -Key $key -LocalFile C:\$key
    			}
    		}
        Start-Service ExchangeWorker
    }
    Exit-PSSession
}
#>

