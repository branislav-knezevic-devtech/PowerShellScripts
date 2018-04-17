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
    $MSCServicePath = "C:\cloudmesh-migrationstatus-service"
    $MSCkey = "MigrationStatusService.zip"
	# stop service, clear folder and obtain zip from S3
    Stop-Service $MSCService
    DO
    {
        Start-Sleep -Seconds 3
    }
    until ( (Get-Service -Name $MSCService).Status -eq "Stopped"  )
	Remove-Item "$MSCServicePath\*"
    Start-Sleep -Seconds 3
	Copy-S3Object -BucketName $bucket -Key $MSCkey -LocalFile "$MSCServicePath\$MSCkey"
	
    # Extract .zip file and start the service
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    function Unzip
    {
        param([string]$zipfile, [string]$outpath)
    
        [System.IO.Compression.ZipFile]::ExtractToDirectory($zipfile, $outpath)
    }

    Unzip "$MSCServicePath\$MSCkey" "$MSCServicePath"
    Remove-Item "$MSCServicePath\$MSCkey"
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
        $MHServicePath = "C:\message-handler"
        $MHkey = "MessageHandler.zip"
        # stop service, clear folder and obtain zip from S3
        Stop-Service $MHService
        DO
        {
            Start-Sleep -Seconds 3
        }
        until ( (Get-Service -Name $MHService).Status -eq "Stopped"  )
        Remove-Item C:\message-handler\*
        Start-Sleep -Seconds 3
        Copy-S3Object -BucketName $bucket -Key $MHkey -LocalFile "$MHServicePath\$MHkey"
       
        # Extract .zip file and start the service
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        function Unzip
        {
            param([string]$zipfile, [string]$outpath)
        
            [System.IO.Compression.ZipFile]::ExtractToDirectory($zipfile, $outpath)
        }

        Unzip "$MHServicePath\$MHkey" "$MHServicePath"
        Remove-Item "$MHServicePath\$MHkey"
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
    $OServicePath = "C:\resource-orchestrator"
    $OKey = "Orchestrator.zip"
    # stop service, clear folder and obtain zip from S3
    Set-ExecutionPolicy RemoteSigned
    Import-Module AWSPowerShell
    Stop-Service $OrchestratorService
    DO
    {
        Start-Sleep -Seconds 3
    }
    until ( (Get-Service -Name $OrchestratorService).Status -eq "Stopped"  )
    Remove-Item "$OServicePath\*"
    Start-Sleep -Seconds 3
    Copy-S3Object -BucketName $bucket -Key $Okey -LocalFile "$OServicePath\$Okey"

    # Extract .zip file and start the service
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    function Unzip
    {
        param([string]$zipfile, [string]$outpath)
        
        [System.IO.Compression.ZipFile]::ExtractToDirectory($zipfile, $outpath)
    }

    Unzip "$OServicePath\$Okey" "$OServicePath"
    Remove-Item "$OServicePath\$Okey"
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
    $WCFServicePath = "C:\selfhosted-service"
    $WCFKey = "SelfHostedService.zip"
    # stop service, clear folder and obtain zip from S3
	Stop-Service $WCFService
    DO
    {
        Start-Sleep -Seconds 3
    }
    until ( (Get-Service -Name $WCFService).Status -eq "Stopped"  )
	Remove-Item "$WCFServicePath\*"
    Start-Sleep -Seconds 3
    Copy-S3Object -BucketName $bucket -Key $WCFkey -LocalFile "$WCFServicePath\$WCFkey"
	
    # Extract .zip file and start the service
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    function Unzip
    {
        param([string]$zipfile, [string]$outpath)
        
        [System.IO.Compression.ZipFile]::ExtractToDirectory($zipfile, $outpath)
    }

    Unzip "$WCFServicePath\$WCFkey" "$WCFServicePath"
    Remove-Item "$WCFServicePath\$WCFkey"

	$config = "$WCFServicePath\ExchangeMigrator.WebServiceHost.exe.config"
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
        $WorkerServicePath = "C:\exchange-worker"
        $WorkerKey = "Worker.zip"
        # stop service, clear folder and obtain zip from S3
        Stop-Service $WorkerService
        DO
        {
            Start-Sleep -Seconds 3
        }
        until ( (Get-Service -Name $WorkerService).Status -eq "Stopped"  )
        Remove-Item "$WorkerServicePath\*"
        Start-Sleep -Seconds 3
        Copy-S3Object -BucketName $bucket -Key $Workerkey -LocalFile "$WorkerServicePath\$WorkerKey"

        # Extract .zip file and start the service
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        function Unzip
        {
            param([string]$zipfile, [string]$outpath)
        
            [System.IO.Compression.ZipFile]::ExtractToDirectory($zipfile, $outpath)
        }

        Unzip "$WorkerServicePath\$Workerkey" "$WorkerServicePath"
        Remove-Item "$WorkerServicePath\$Workerkey"
        Start-Service WorkerService
    }
    Exit-PSSession
}
#>