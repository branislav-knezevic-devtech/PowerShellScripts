####################################
# Get VM config from json template #
####################################

$VMs = Get-Content -Raw C:\Temp\WinMachines.json | ConvertFrom-Json

##############################################
# Allow PowerShell remoting and load modules #
##############################################

Set-Item WSMan:\localhost\Client\TrustedHosts -Value "*" -Force

Import-Module Hyper-V

$LocalAdmin = "Administrator"
$LocalPassword = ConvertTo-SecureString "m1cr0s0ft$" -AsPlainText -Force
$LocalCredentials = New-Object System.Management.Automation.PSCredential -ArgumentList $LocalAdmin,$LocalPassword

############################################################
# Check switches on Hyper-V and copy VHDX from template VM #
############################################################


# Check Frontnet switch
For($i = 0; $i -le $VMs.Count-1; $i++)
{
    $IP = $VMs[0].FrontNetIP
    $FrontnetTag = $IP[8] + $IP[9]
    $FrontnetName = $VMs[0].FrontnetName
    $BacknetName = $VMs[0].BacknetName

    $Test = $null
    if($FrontnetName -ne "VPNswitch")
        {
            $Test = Get-VMSwitch | where {$_.Name -eq $FrontnetName} | Select-Object -Property *

        }
    else
        {
            $Test = 1
        }


    if($Test -eq $null)
        {
            Write-Host "switch for $FrontnetName does not exist, please configure it and rerun this script." -ForegroundColor Red
            Write-Host "This script will now terminate" -ForegroundColor Red
            start-sleep -Seconds 30
            Exit
        }
}


# Check is FrontNet IP occupied
For($i = 0; $i -le $VMs.Count-1; $i++)
{

    $IP = $null
    $IP = $VMs[$i].FrontNetIP

    $Ping = Get-WmiObject Win32_PingStatus -Filter "Address='$IP'"
    $Ping | Out-Null
    if($Ping.StatusCode -eq 0)
        {
            Write-Host "$IP is already in use by another VM, please check Resources_list.xlsx for the list of available IP addresses." -ForegroundColor Red
            Write-Host "This script will now terminate" -ForegroundColor Red
            start-sleep -Seconds 30
            Exit
        }
}



# Check is Private NIC defined
if($BacknetName -ne $null)
    {
        # Check does private NIC exists
        Write-Host "Checking does required private NIC exists" -ForegroundColor Yellow
        $PrivateNIC = $null
        $PrivateNIC = Get-VMSwitch | where {$_.Name -eq $BacknetName} | Select-Object -Property *

        if($PrivateNIC -eq $null)
            {
                New-VMSwitch -Name $BacknetName -SwitchType Private
                Write-Host "$BacknetName NIC created" -ForegroundColor Green
            }
        else
            {
            Write-Host "$BacknetName NIC already exists" -ForegroundColor Yellow
            }
        }
else
    {
        Write-Host "Private NIC (Backnet) not defined, skipping configuration" -ForegroundColor Green
    }

Write-Host "All prerequisites are met, time to party :)"

# Copy template VM
Write-Host "Shutting down Windows template VM, please wait" -ForegroundColor Yellow

$Server = $env:COMPUTERNAME
if($Server -eq "Server7")
    {
        $Server = "localhost"
    }
else
    {
        $Server = "Server7"
    }

Stop-VM -ComputerName $Server -Name "VMTemplate-Windows"
Write-Host "template VM turned off" -ForegroundColor Green


# Create folders and copy VHDX

For($i = 0; $i -le $VMs.Count-1; $i++)
{

$VMName = $VMs[$i].Name


$Test = Test-Path C:\HyperV\$VMName
if($Test -eq $false)
    {
        New-Item C:\HyperV\$VMName -ItemType Directory
    }


Write-Host "Copying VHD from template VM" -ForegroundColor Yellow
Import-Module BitsTransfer

if($Server -eq "localhost")
    {
        Start-BitsTransfer -Source 'C:\HyperV\VMTemplate-Windows\VMTemplate-Windows\VMTemplate-Windows.vhdx' -Destination C:\HyperV\$VMName\$VMName.vhdx -Description "This may take a while, because Windows images like to be large :)" -DisplayName "Copying $VMName.vhdx"
    }
else
    {
        Start-BitsTransfer -Source '\\192.168.88.212\C$\HyperV\VMTemplate-Windows\VMTemplate-Windows\VMTemplate-Windows.vhdx' -Destination C:\HyperV\$VMName\$VMName.vhdx -Description "This may take a while, because Windows images like to be large :)" -DisplayName "Copying $VMName.vhdx"
    }

}


Write-Host "Folder(s) with corresponding VHDX(es) created in C:\HyperV, now creating VM(s)" -ForegroundColor Green

Start-VM -ComputerName $Server -Name "VMTemplate-Windows"

For($i = 0; $i -le $VMs.Count-1; $i++)
{

$VMName = $VMs[$i].Name
$Cpu = $VMs[$i].CPU
$IP = $VMs[$i].FrontNetIP
$Hostname = $VMs[$i].HostName
$Gateway = $VMs[$i].Gateway
$DNS = $VMs[$i].DNS
[int64]$Memory = 1GB*($VMs[$i].RAM)
$PrivateIP = $VMs[$i].BacknetIP
$SysprepRequired = $VMs[$i].Sysprep



New-VM –Name $VMName –MemoryStartupBytes $Memory -Path C:\HyperV\$VMName

Add-VMHardDiskDrive -VMName $VMName -ControllerType IDE -Path C:\HyperV\$VMName\$VMName.vhdx

Get-VMNetworkAdapter -VMName $VMName | Remove-VMNetworkAdapter
Add-VMNetworkAdapter –VMName $VMName –Switchname Trunk
Get-VMNetworkAdapter -VMName $VMName | Set-VMNetworkAdapterVlan -Access -VlanId 66
    
Set-VMProcessor –VMName $VMName –count $Cpu
    
Write-Host "$VMName successfuly created, now just to configure it" -ForegroundColor Green

Start-VM -Name $VMName

# Wait for OS to start
Start-Sleep -Seconds 90


################
# Configure VM #
################

# Get temporary IP address (assigned by DHCP), connect to VM and execute sysprep
$CurrentIP = (Get-VMNetworkAdapter -VMName $VMName).IPAddresses[0]

        Write-Host "Running sysprep, please wait..." -ForegroundColor Yellow
        Invoke-Command -ComputerName $CurrentIP -Credential $LocalCredentials -ScriptBlock {cmd /c C:\Windows\System32\Sysprep\sysprep.exe /generalize /oobe /unattend:c:\Temp\unattend.xml /reboot /quiet}


        # Wait for sysprep to complete
        Start-Sleep -Seconds 600

        # If temporary IP has changed after sysprep, obtain new IP
        $CurrentIP = $null
        $CurrentIP = (Get-VMNetworkAdapter -VMName $VMName).IPAddresses[0]

        # Check connectivity
        DO
            {
                $Ping = Get-WmiObject Win32_PingStatus -Filter "Address='$CurrentIP'"
                $Ping
            }
        Until($Ping.PrimaryAddressResolutionStatus -eq 0)

        Write-Host "Sysprep completed" -ForegroundColor Green


# Set static IP for FrontNet
Write-Host "Setting static IP for FrontNet NIC" -ForegroundColor Yellow

Invoke-Command -ComputerName $CurrentIP -Credential $LocalCredentials -InDisconnectedSession -ScriptBlock {param([string]$IP,[string]$Gateway,[string]$DNS) $adapter = Get-NetAdapter;New-NetIPAddress -InterfaceAlias $adapter.Name -AddressFamily IPv4 -IPAddress $IP -PrefixLength 24 -DefaultGateway $Gateway;Set-DnsClientServerAddress -InterfaceAlias $adapter.Name -ServerAddresses $DNS;Set-NetIPInterface -DHCP Disabled;cmd /c netsh firewall set service type=fileandprint mode=enable profile=all;cmd /c netsh advfirewall set rule group="network discovery" new enable=yes} -ArgumentList $IP,$Gateway,$DNS

Start-Sleep -Seconds 30
Write-Host "Static IP for FrontNet NIC set" -ForegroundColor Green

# Change VNIC
Write-Host "Replacing Trunk NIC with $FrontnetName" -ForegroundColor Yellow

Disconnect-VMNetworkAdapter -VMName $VMName
Connect-VMNetworkAdapter -SwitchName $FrontnetName -VMName $VMName

if($FrontnetName -ne "VPNswitch")
    {
        Get-VMNetworkAdapter -VMName $VMName | Set-VMNetworkAdapterVlan -Access -VlanId $FrontnetTag
    }
else
    {
        Get-VMNetworkAdapter -VMName $VMName | Set-VMNetworkAdapterVlan -Untagged
    }

Write-Host "FrontNet NIC set to $FrontnetName" -ForegroundColor Green


# Check are static IP and new VNIC set properly
Start-Sleep -Seconds 10

$Ping = Get-WmiObject Win32_PingStatus -Filter "Address='$IP'"

if($Ping.PrimaryAddressResolutionStatus -ne 0)
    {
        Write-host "Frontnet IP for $VMName not set properly, terminating" 
        Exit
    }


# Rename VM
Write-Host "Renaming VM" -ForegroundColor Yellow

Invoke-Command -ComputerName $IP -Credential $LocalCredentials -ScriptBlock {param($Hostname) Rename-Computer -NewName $Hostname} -ArgumentList $Hostname
Stop-VM -Name $VMName

Write-Host "VM renamed to $VMName" -ForegroundColor Green

# Add BackNet vNIC
Write-Host "Adding Backnet NIC" -ForegroundColor Yellow

Add-VMNetworkAdapter –VMName $VMName –Switchname $BacknetName
Write-Host "BackNet NIC added, waiting for OS" -ForegroundColor Green


# Wait for OS
Start-VM -Name $VMName

DO
        {
            $Status = Get-VM $VMName
            $Status
            Start-Sleep -Seconds 5
        }
    Until($Status.State -eq "Running")

DO
        {
            $Ping = Get-WmiObject Win32_PingStatus -Filter "Address='$IP'"
            $Ping
            Start-Sleep -Seconds 5
        }
    Until($Ping.PrimaryAddressResolutionStatus -eq 0)


# Add more time for services to start
Start-Sleep -Seconds 30


# Obtain MAC address for BackNet vNIC

$Details = Get-VMNetworkAdapter -VMName $VMName | where {$_.SwitchName -eq $BacknetName}
$Mac = $Details.MacAddress
$identifyer = $Mac[11]

# Set static IP for BackNet NIC
Write-Host "Setting static IP for BackNet" -ForegroundColor Yellow

Invoke-Command -ComputerName $IP -Credential $LocalCredentials -ScriptBlock {param ([string]$identifyer,[string]$PrivateIP) Get-NetAdapter | where {$_.MacAddress[16] -eq $identifyer} | New-NetIPAddress -AddressFamily IPv4 -IPAddress $PrivateIP -PrefixLength 24} -ArgumentList $identifyer,$PrivateIP



Write-Host "$VMName is configured, FrontNet IP address is $IP" -ForegroundColor Blue -BackgroundColor White

}

Write-Host "All done :)" -ForegroundColor Green