Function Set-VMNetworkConfiguration {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$true,
                   Position=1,
                   ParameterSetName='DHCP',
                   ValueFromPipeline=$true)]
        [Parameter(Mandatory=$true,
                   Position=0,
                   ParameterSetName='Static',
                   ValueFromPipeline=$true)]
        [Microsoft.HyperV.PowerShell.VMNetworkAdapter]$NetworkAdapter,

        [Parameter(Mandatory=$true,
                   Position=1,
                   ParameterSetName='Static')]
        [String[]]$IPAddress=@(),

        [Parameter(Mandatory=$false,
                   Position=2,
                   ParameterSetName='Static')]
        [String[]]$Subnet=@(),

        [Parameter(Mandatory=$false,
                   Position=3,
                   ParameterSetName='Static')]
        [String[]]$DefaultGateway = @(),

        [Parameter(Mandatory=$false,
                   Position=4,
                   ParameterSetName='Static')]
        [String[]]$DNSServer = @(),

        [Parameter(Mandatory=$false,
                   Position=0,
                   ParameterSetName='DHCP')]
        [Switch]$Dhcp
    )

    $VM = Get-WmiObject -Namespace 'root\virtualization\v2' -Class 'Msvm_ComputerSystem' | Where-Object { $_.ElementName -eq $NetworkAdapter.VMName } 
    $VMSettings = $vm.GetRelated('Msvm_VirtualSystemSettingData') | Where-Object { $_.VirtualSystemType -eq 'Microsoft:Hyper-V:System:Realized' }    
    $VMNetAdapters = $VMSettings.GetRelated('Msvm_SyntheticEthernetPortSettingData') 

    $NetworkSettings = @()
    foreach ($NetAdapter in $VMNetAdapters) {
        if ($NetAdapter.Address -eq $NetworkAdapter.MacAddress) {
            $NetworkSettings = $NetworkSettings + $NetAdapter.GetRelated("Msvm_GuestNetworkAdapterConfiguration")
        }
    }

    $NetworkSettings[0].IPAddresses = $IPAddress
    $NetworkSettings[0].Subnets = $Subnet
    $NetworkSettings[0].DefaultGateways = $DefaultGateway
    $NetworkSettings[0].DNSServers = $DNSServer
    $NetworkSettings[0].ProtocolIFType = 4096

    if ($dhcp) {
        $NetworkSettings[0].DHCPEnabled = $true
    } else {
        $NetworkSettings[0].DHCPEnabled = $false
    }

    $Service = Get-WmiObject -Class "Msvm_VirtualSystemManagementService" -Namespace "root\virtualization\v2"
    $setIP = $Service.SetGuestNetworkAdapterConfiguration($VM, $NetworkSettings[0].GetText(1))

    if ($setip.ReturnValue -eq 4096) {
        $job=[WMI]$setip.job 

        while ($job.JobState -eq 3 -or $job.JobState -eq 4) {
            start-sleep 1
            $job=[WMI]$setip.job
        }

        if ($job.JobState -eq 7) {
            write-host "Success"
        }
        else {
            $job.GetError()
        }
    } elseif($setip.ReturnValue -eq 0) {
        Write-Host "Success"
    }
}

# Create the NAT network
New-NetNat -Name "InternalNat" -InternalIPInterfaceAddressPrefix 192.168.0.0/16

# Create an internal switch with NAT
$switchName = 'InternalNATSwitch'
New-VMSwitch -Name $switchName -SwitchType Internal
$adapter = Get-NetAdapter | ? { $_.Name -like "*"+$switchName+"*" }

# Create an internal network (gateway first)
New-NetIPAddress -IPAddress 192.168.0.1 -PrefixLength 24 -InterfaceIndex $adapter.ifIndex

# Add a NAT forwarder for WAF and SQL1 
Add-NetNatStaticMapping -ExternalIPAddress "0.0.0.0" -ExternalPort 80 -Protocol TCP -InternalIPAddress "192.168.0.8" -InternalPort 80 -NatName InternalNat
Add-NetNatStaticMapping -ExternalIPAddress "0.0.0.0" -ExternalPort 1433 -Protocol TCP -InternalIPAddress "192.168.0.6" -InternalPort 1433 -NatName InternalNat

# Add a firewall rule for HTTP and SQL
New-NetFirewallRule -DisplayName "HTTP Inbound" -Direction Inbound -LocalPort 80 -Protocol TCP -Action Allow
New-NetFirewallRule -DisplayName "Microsoft SQL Server Inbound" -Direction Inbound -LocalPort 1433 -Protocol TCP -Action Allow

# Enable Enhanced Session Mode on Host
Set-VMHost -EnableEnhancedSessionMode $true

# Create the nested Windows VMs - from VHDs
$opsDir = "F:\VirtualMachines"
New-VM -Name smarthotelweb1 -MemoryStartupBytes 4GB -BootDevice VHD -VHDPath "$opsdir\SmartHotelWeb1\SmartHotelWeb1.vhdx" -Path "$opsdir\SmartHotelWeb1" -Generation 2 -Switch $switchName 
New-VM -Name smarthotelweb2 -MemoryStartupBytes 4GB -BootDevice VHD -VHDPath "$opsdir\SmartHotelWeb2\SmartHotelWeb2.vhdx" -Path "$opsdir\SmartHotelWeb2" -Generation 2 -Switch $switchName
New-VM -Name smarthotelSQL1 -MemoryStartupBytes 4GB -BootDevice VHD -VHDPath "$opsdir\SmartHotelSQL1\SmartHotelSQL1.vhdx" -Path "$opsdir\SmartHotelSQL1" -Generation 2 -Switch $switchName

# Create nested Ubuntu VM - from exported VM
$vmFile = Get-ChildItem -Path 'F:\VirtualMachines\UbuntuWAF\Virtual Machines' -Include *.vmcx -Recurse
Import-VM -Path $vmFile.FullName

# Configure IP addresses (don't change the IPs! VM config depends on them)
$vmweb1 = Get-VMNetworkAdapter -VMName "smarthotelweb1"
$vmweb2 = Get-VMNetworkAdapter -VMName "smarthotelweb2"
$vmsql1 = Get-VMNetworkAdapter -VMName "smarthotelsql1"
$vmwaf  = Get-VMNetworkAdapter -VMName "ubuntuwaf"

$vmweb1 | Set-VMNetworkConfiguration -IPAddress "192.168.0.4" -Subnet "255.255.255.0" -DefaultGateway "192.168.0.1" -DNSServer "8.8.8.8"
$vmweb2 | Set-VMNetworkConfiguration -IPAddress "192.168.0.5" -Subnet "255.255.255.0" -DefaultGateway "192.168.0.1" -DNSServer "8.8.8.8"
$vmsql1 | Set-VMNetworkConfiguration -IPAddress "192.168.0.6" -Subnet "255.255.255.0" -DefaultGateway "192.168.0.1" -DNSServer "8.8.8.8"
$vmwaf  | Set-VMNetworkConfiguration -IPAddress "192.168.0.8" -Subnet "255.255.255.0" -DefaultGateway "192.168.0.1" -DNSServer "8.8.8.8"

# Start all the VMs
Get-VM | where {$_.State -eq 'Off'} | Start-VM

while((Get-VM | where {$_.State -eq "Running"}).Count -lt 4) {
    Start-Sleep -Seconds 5
}

# Give them a minute to finish booting
Start-Sleep 60

# Rearm (extend evaluation license) and reboot each Windows VM
Write-Output "Configuring VMs..."
$localusername = "Administrator"
$password = ConvertTo-SecureString "demo@pass123" -AsPlainText -Force
$localcredential = New-Object System.Management.Automation.PSCredential ($localusername, $password)
$vmStopIP = 6

for ($i = 4; $i -le $vmStopIP; $i++) {
    Write-Output "Configuring VM at 192.168.0.$i..."
    set-item wsman:\localhost\Client\TrustedHosts -value "192.168.0.$i" -Force
    Invoke-Command -ComputerName "192.168.0.$i" -ScriptBlock { 
        slmgr.vbs /rearm
        net accounts /maxpwage:unlimited
        Restart-Computer -Force
    } -Credential $localcredential
    Write-Output "Configuration complete"
}

# Give them a minute to finish booting
Start-Sleep 60

# Make some requests to 'warm up' the servers
Invoke-WebRequest 'http://192.168.0.4/'
Start-Sleep 15
Invoke-WebRequest 'http://192.168.0.8/'

# Unregister scheduled task so this script doesn't run again on next reboot
Unregister-ScheduledTask -TaskName "SetUpVMs"