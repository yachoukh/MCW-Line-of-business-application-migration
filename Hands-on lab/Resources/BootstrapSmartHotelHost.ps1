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

# Create path
$opsDir = "C:\OpsgilityTraining"

if ((Test-Path $opsDir) -eq $false)
{
    New-Item -Path $opsDir -ItemType directory
}

# Download disks for nested Hyper-V VMs, and various other files we'll need during the lab
$downloads = @( `
     "https://cloudworkshop.blob.core.windows.net/azure-migration/PostRebootConfigure.ps1" `
    ,"https://cloudworkshop.blob.core.windows.net/azure-migration/ConfigureAzureMigrateApplianceNetwork.ps1" `
    ,"https://download.microsoft.com/download/C/6/3/C63D8695-CEF2-43C3-AF0A-4989507E429B/DataMigrationAssistant.msi" `
    )

$destinationFiles = @( `
     "$opsDir\PostRebootConfigure.ps1" `
    ,"$opsDir\ConfigureAzureMigrateApplianceNetwork.ps1" `
    ,"$opsDir\DataMigrationAssistant.msi" `
    )

Import-Module BitsTransfer
Start-BitsTransfer -Source $downloads -Destination $destinationFiles

# Register task to run post-reboot script once host is rebooted after Hyper-V install
$action = New-ScheduledTaskAction -Execute "C:\Windows\System32\WindowsPowerShell\v1.0\Powershell.exe" -Argument "-executionPolicy Unrestricted -File $opsDir\PostRebootConfigure.ps1"
$trigger = New-ScheduledTaskTrigger -AtStartup
$principal = New-ScheduledTaskPrincipal -UserID "NT AUTHORITY\SYSTEM" -LogonType ServiceAccount -RunLevel Highest
Register-ScheduledTask -TaskName "SetUpVMs" -Action $action -Trigger $trigger -Principal $principal

# Install Hyper-V and reboot. 
Install-WindowsFeature -Name Hyper-V -IncludeManagementTools -Restart