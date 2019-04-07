function Unzip-Files {
    Param (
        [Object]$Files,
        [string]$Destination
    )

    foreach ($file in $files)
    {
        $fileName = $file.FullName

        write-output "Start unzip: $fileName to $Destination"
        
        (new-object -com shell.application).namespace($Destination).CopyHere((new-object -com shell.application).namespace($fileName).Items(),16)
        
        write-output "Finish unzip: $fileName to $Destination"
    }
}

function Follow-Redirect {
    Param (
        [string]$Url
    )

    $webClientObject = New-Object System.Net.WebClient
    $webRequest = [System.Net.WebRequest]::create($Url)
    $webResponse = $webRequest.GetResponse()
    $actualUrl = $webResponse.ResponseUri.AbsoluteUri
    $webResponse.Close()

    return $actualUrl
}

$ErrorActionPreference = 'SilentlyContinue'

# Disable IE ESC
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}" -Name "IsInstalled" -Value 0
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}" -Name "IsInstalled" -Value 0
Stop-Process -Name Explorer

# Install Chrome
$Path = $env:TEMP; 
$Installer = "chrome_installer.exe"
Invoke-WebRequest "http://dl.google.com/chrome/install/375.126/chrome_installer.exe" -OutFile $Path\$Installer
Start-Process -FilePath $Path\$Installer -Args "/silent /install" -Verb RunAs -Wait
Remove-Item $Path\$Installer

# Format data disk
$disk = Get-Disk | ? { $_.PartitionStyle -eq "RAW" }
Initialize-Disk -Number $disk.DiskNumber -PartitionStyle GPT
New-Partition -DiskNumber $disk.DiskNumber -UseMaximumSize -DriveLetter F
Format-Volume -DriveLetter F -FileSystem NTFS -NewFileSystemLabel DATA

# Create paths
$opsDir = "C:\OpsgilityTraining"
$vmDir = "F:\VirtualMachines"
$tempDir = "D:"

if ((Test-Path $opsDir) -eq $false)
{
    New-Item -Path $opsDir -ItemType directory
}

if ((Test-Path $vmDir) -eq $false)
{
    New-Item -Path $vmDir -ItemType directory
}

# We'll download the Azure Migrate appliance to save time during the lab
# These URLs use an HTTP redirect, which we need to resolve first
$migrateApplianceUrl = Follow-Redirect("https://aka.ms/migrate/appliance/hyperv")

# Download disks for nested Hyper-V VMs, and various other files we'll need during the lab
$downloads = @( `
     "https://cloudworkshop.blob.core.windows.net/azure-migration/PostRebootConfigure.ps1" `
    ,"https://cloudworkshop.blob.core.windows.net/azure-migration/ConfigureAzureMigrateApplianceNetwork.ps1" `
    ,"https://go.microsoft.com/fwlink/?linkid=2014306" `
    ,"https://download.microsoft.com/download/C/6/3/C63D8695-CEF2-43C3-AF0A-4989507E429B/DataMigrationAssistant.msi" `
    ,"https://cloudworkshop.blob.core.windows.net/azure-migration/SmartHotelWeb1.zip" `
    ,"https://cloudworkshop.blob.core.windows.net/azure-migration/SmartHotelWeb2.zip" `
    ,"https://cloudworkshop.blob.core.windows.net/azure-migration/SmartHotelSQL1.zip" `
    ,"https://cloudworkshop.blob.core.windows.net/azure-migration/UbuntuWAF.zip" `
    ,$migrateApplianceUrl `
    )

$destinationFiles = @( `
     "$opsDir\PostRebootConfigure.ps1" `
    ,"$opsDir\ConfigureAzureMigrateApplianceNetwork.ps1" `
    ,"$opsDir\SSMS-Setup-ENU.exe" `
    ,"$opsDir\DataMigrationAssistant.msi" `
    ,"$tempDir\SmartHotelWeb1.zip" `
    ,"$tempDir\SmartHotelWeb2.zip" `
    ,"$tempDir\SmartHotelSQL1.zip" `
    ,"$tempDir\UbuntuWAF.zip" `
    ,"$tempDir\AzureMigrateAppliance.zip" `
    )

Import-Module BitsTransfer
Start-BitsTransfer -Source $downloads -Destination $destinationFiles

# Unzip the VMs
$zipfiles = Get-ChildItem -Path "$tempDir\*.zip"
Unzip-Files -Files $zipfiles -Destination $vmDir

# Register task to run post-reboot script once host is rebooted after Hyper-V install
$action = New-ScheduledTaskAction -Execute "C:\Windows\System32\WindowsPowerShell\v1.0\Powershell.exe" -Argument "-executionPolicy Unrestricted -File $opsDir\PostRebootConfigure.ps1"
$trigger = New-ScheduledTaskTrigger -AtStartup
$principal = New-ScheduledTaskPrincipal -UserID "NT AUTHORITY\SYSTEM" -LogonType ServiceAccount -RunLevel Highest
Register-ScheduledTask -TaskName "SetUpVMs" -Action $action -Trigger $trigger -Principal $principal

# Install Hyper-V and reboot. 
Install-WindowsFeature -Name Hyper-V -IncludeManagementTools -Restart