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

$bucket = "cloud-migration-platform-dev"

$location = Invoke-RestMethod -Uri 'https:\\ec2-35-158-157-27.eu-central-1.compute.amazonaws.com:8000/MachineLocationWebService/' | ConvertFrom-Json

$creds = New-AWSCredentials -AccessKey %S3AccessKey% -SecretKey %S3SecretKey%
Set-AWSCredentials -Credential $creds -StoreAs devtech

# MigratonStatusChange

$password3 = ConvertTo-SecureString -AsPlainText -Force -String '%MigrationStatusServiceInstancePassword%'
$credential3 = New-Object -TypeName system.management.automation.pscredential -ArgumentList "\Administrator", $password3
$session3 = New-PSSession %MigrationStatusServiceInstanceIp% -Credential $credential3

Invoke-Command -Session $session3 -ScriptBlock {
    $bucket = "cloud-migration-platform-dev"
    $MSCService = "MigrationStatusChange"
	Stop-Service $MSCService
    DO
    {
        Start-Sleep -Seconds 5
    }
    until ( (Get-Service -Name $MSCService).Status -eq "Stopped"  )
	Remove-Item C:\cloudmesh-migrationstatus-service\*
    Start-Sleep -Seconds 5
	$files = Get-S3Object -BucketName 'cloud-migration-platform-dev' -KeyPrefix '/cloudmesh-migrationstatus-service'
	foreach($key in $files.key) {
		if ($key.substring($key.length - 1, 1) -ne '/')
		{
			Copy-S3Object -BucketName 'cloud-migration-platform-dev' -Key $key -LocalFile C:\$key
		}
	}
	Start-Service $MSCService
}
Remove-PSSession $session3

# MessageHandlers

foreach($handler in $location.MessageHandlers)
{
    $password1 = convertto-securestring -asplaintext -force -string $handler.MachinePassword
    $credential1 = new-object -typename system.management.automation.pscredential -argumentlist "\Administrator", $password1  
    $session1 = new-pssession $handler.PublicIp -credential $credential1  
    enter-pssession $session1 
    Invoke-Command -Session $session1 -ScriptBlock {
        $bucket = "cloud-migration-platform-dev"
        $MHService = "MessageHandler"
        Stop-Service $MHService
        DO
        {
            Start-Sleep -Seconds 5
        }
        until ( (Get-Service -Name $MHService).Status -eq "Stopped"  )
        Remove-Item C:\message-handler\*
        Start-Sleep -Seconds 5
        $files = Get-S3Object -BucketName 'cloud-migration-platform-dev' -KeyPrefix '/message-handler'
		foreach($key in $files.key) {
			if ($key.substring($key.length - 1, 1) -ne '/')
			{
				Copy-S3Object -BucketName 'cloud-migration-platform-dev' -Key $key -LocalFile C:\$key
			}
		}
        Start-Service $MHService
    }
    Exit-PSSession
}

# Orchestrator

$passwordO = convertto-securestring -asplaintext -force -string $location.Orchestrator.MachinePassword
$credentialO = new-object -typename system.management.automation.pscredential -argumentlist "\Administrator", $passwordO  
$sessionO = new-pssession $location.Orchestrator.PublicIp -credential $credentialO  
enter-pssession $sessionO 

Invoke-Command -Session $sessionO -ScriptBlock {
    $bucket = "cloud-migration-platform-dev"
    $OrchestratorService = "ResourceOrchestrator"
    Set-ExecutionPolicy RemoteSigned
    Import-Module AWSPowerShell
    Stop-Service $OrchestratorService
    DO
    {
        Start-Sleep -Seconds 5
    }
    until ( (Get-Service -Name $OrchestratorService).Status -eq "Stopped"  )
    Remove-Item C:\resource-orchestrator\*
    $files = Get-S3Object -BucketName 'cloud-migration-platform-dev' -KeyPrefix '/resource-orchestrator'
		foreach($key in $files.key) {
			if ($key.substring($key.length - 1, 1) -ne '/')
			{
				Copy-S3Object -BucketName 'cloud-migration-platform-dev' -Key $key -LocalFile C:\$key
			}
		}
    Start-Service $OrchestratorService
}
Exit-PSSession


# WCF

$passwordWCF = ConvertTo-SecureString -AsPlainText -Force -String '%WcfInstancePassword%'
$credentialWCF = New-Object -TypeName system.management.automation.pscredential -ArgumentList "\Administrator", $passwordWCF
$sessionWCF = New-PSSession %WfcInstanceIp% -Credential $credentialWCF

Invoke-Command -Session $sessionWCF -ScriptBlock {
    $bucket = "cloud-migration-platform-dev"
	$WCFService = "SelfhostedService"
	Stop-Service $WCFService
    DO
    {
        Start-Sleep -Seconds 5
    }
    until ( (Get-Service -Name $WCFService).Status -eq "Stopped"  )
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
	Start-Service $WCFService
}
Remove-PSSession $sessionWCF

# Workers

<#
foreach($Worker in $location.workers)
{
    $passwordW = convertto-securestring -asplaintext -force -string $location.Workers.MachinePassword
    $credentialW = new-object -typename system.management.automation.pscredential -argumentlist "\Administrator", $passwordW  
    $sessionW = new-pssession $location.Worker.PublicIp -credential $credentialW  
    enter-pssession $sessionW 
    
    Invoke-Command -Session $sessionW -ScriptBlock {
        $bucket = "cloud-migration-platform-dev"
        $WorkerService = "ExchangeWorker"
        Stop-Service $WorkerService
        DO
        {
            Start-Sleep -Seconds 5
        }
        until ( (Get-Service -Name $WorkerService).Status -eq "Stopped"  )
        Remove-Item C:\exchange-worker\*
        Start-Sleep -Seconds 5
        $files = Get-S3Object -BucketName 'cloud-migration-platform-dev' -KeyPrefix '/exchange-worker'
    		foreach($key in $files.key) {
    			if ($key.substring($key.length - 1, 1) -ne '/')
    			{
    				Copy-S3Object -BucketName 'cloud-migration-platform-dev' -Key $key -LocalFile C:\$key
    			}
    		}
        Start-Service WorkerService
    }
    Exit-PSSession
}
#>