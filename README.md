1. Enable Remote Management on Windows Server (2019/2022)
Remote management is crucial for executing commands and scripts from the Windows 10 client.

Steps:
Enable WinRM (Windows Remote Management): Run the following PowerShell commands on the Windows Server 2019:
# // powershell
Enable-PSRemoting -Force
Set-Item wsman:\localhost\client\trustedhosts * -Force

Allow Remote Management through the Firewall:
# // powershell
Enable-NetFirewallRule -DisplayGroup "Remote Desktop" // or //Enable-NetFirewallRule -Name "Remote Desktop" -Direction Inbound -Action Allow
Enable-NetFirewallRule -DisplayGroup "Windows Remote Management" // or // Enable-NetFirewallRule -Name "Windows Remote Management (HTTP-In)" -Direction Inbound -Action Allow

Verify Remote Management: Test connectivity from the virtual Windows 10 machine:
# // powershell
Test-WSMan -ComputerName 192.168.174.129 # (Local IP address of the server computer)

2. Configure Windows Server for Remote Administration
Steps:

Install Remote Server Administration Tools (RSAT) Features: Open PowerShell on Windows Server 2019 and run:
# // powershell
Install-WindowsFeature RSAT-AD-Tools

Allow Remote Desktop Access (Optional):
# // powershell
Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnections" -Value 0
Enable-NetFirewallRule -DisplayGroup "Remote Desktop"

Enable PowerShell Script Execution:
# // powershell
Set-ExecutionPolicy RemoteSigned -Force

3. Configure Virtual Windows 10/11 for Server Management
Steps:
Join the Domain: Ensure that the virtual Windows 10 PC is joined to the same domain as the server.
Navigate to Settings > System > About > Join a domain.
Enter the domain taslogwinserver and provide domain admin credentials.

Ensure WinRM is enabled on the local machine
Run the following command to check and enable WinRM:
# // powershell
winrm quickconfig

If WinRM is not configured, this will start the WinRM service and configure it to allow remote management.
If it prompts to make changes, type y and press Enter.

Check the WinRM listener
Verify that the WinRM listener is configured properly:
# // powershell
winrm enumerate winrm/config/listener

You should see an HTTP or HTTPS listener for your network interface.

Add the Server to Trusted Hosts: On the virtual Windows 10 machine, open PowerShell as Administrator and run:
# // powershell
Set-Item wsman:\localhost\client\trustedhosts "192.168.174.129" -Force # (Local IP address of the server computer)

Test Connection:

Firewall and Network Considerations
Ensure the following:

Firewall rules: Allow WinRM traffic through the firewall. You can enable this rule via PowerShell:

# // powershell
Enable-NetFirewallRule -Name "WINRM-HTTP-In-TCP"
Network profile: Make sure the network is set to Private or Domain. If it's Public, WinRM might not work.

# // powershell
Enter-PSSession -ComputerName 192.168.174.129 -Credential (Get-Credential)

4. Install Management Tools on Virtual Windows 10
Steps:
Install RSAT: On the virtual Windows 10 machine, install the necessary RSAT tools:

# // powershell
Get-WindowsCapability -Name RSAT* -Online | Add-WindowsCapability -Online
Enable PowerShell Remoting: On the virtual Windows 10 machine, ensure PowerShell remoting is enabled:

# // powershell
Enable-PSRemoting -Force

Notice: Be sure that client PC (Windows 10/11) is connected to the internet. If it is not or any errors are returned try the following:
Manually Install RSAT Tools
Since you're getting an error when attempting to install RSAT, you can manually download and install the necessary RSAT tools from the Microsoft website.

Download RSAT for your version of Windows 10:

Go to the official RSAT download page (https://www.microsoft.com/en-us/download/details.aspx?id=45520).
Select the appropriate version for your Windows 10 version and download it.
Install the downloaded file and follow the installation instructions.

5. Setup Credential Management (Optional)

To avoid entering credentials repeatedly:

Store Credentials Securely:
# // powershell
$cred = Get-Credential
Export-Clixml -Path "C:\Path\To\Secure\Credential.xml" -InputObject $cred

Use Stored Credentials:
# // powershell
$cred = Import-Clixml -Path "C:\Path\To\Secure\Credential.xml"
Enter-PSSession -ComputerName 192.168.174.129 -Credential $cred

6. Test with a Sample Script

From the virtual Windows 10 PC, test running a PowerShell command on the server:
# // powershell
Invoke-Command -ComputerName 192.168.174.129 -Credential (Get-Credential) -ScriptBlock {
   Get-Service
}

Here's a simple PowerShell script that you can use to test Active Directory functionality. This script will check the health of the Active Directory domain, retrieve information about the domain controllers, and list some basic user details from the domain.

PowerShell Script for Active Directory Testing
# // powershell
# Import Active Directory Module
Import-Module ActiveDirectory

# 1. Check the health of the Active Directory domain
Write-Host "Checking Active Directory domain health..."
$domain = Get-ADDomain
Write-Host "Domain: $($domain.Name)"
Write-Host "Domain Functional Level: $($domain.DomainMode)"
Write-Host "Forest Functional Level: $($domain.ForestMode)"
Write-Host "Is Read-Only Domain Controller: $($domain.ReadOnly)"

# 2. Retrieve and display all Domain Controllers in the domain
Write-Host "`nFetching Domain Controllers..."
$domainControllers = Get-ADDomainController -Filter *
foreach ($dc in $domainControllers) {
    Write-Host "DC Name: $($dc.Name)"
    Write-Host "DC IP Address: $($dc.IPAddress)"
    Write-Host "DC Site: $($dc.Site)"
    Write-Host "-------------------------------"
}

# 3. Retrieve and display basic details of all users in the domain
Write-Host "`nListing Active Directory Users..."
$users = Get-ADUser -Filter * -Property Name, SamAccountName, Enabled
foreach ($user in $users) {
    Write-Host "User Name: $($user.Name)"
    Write-Host "Username: $($user.SamAccountName)"
    Write-Host "Account Enabled: $($user.Enabled)"
    Write-Host "-------------------------------"
}

# 4. Test connectivity to the domain controller
Write-Host "`nTesting connectivity to Domain Controllers..."
foreach ($dc in $domainControllers) {
    $pingResult = Test-Connection -ComputerName $dc.Name -Count 2 -Quiet
    if ($pingResult) {
        Write-Host "Successfully reached Domain Controller: $($dc.Name)"
    } else {
        Write-Host "Failed to reach Domain Controller: $($dc.Name)"
    }
}
What this script does:
Checks the domain health: It retrieves and displays information about the Active Directory domain, including the domain name, functional levels, and whether it's a Read-Only Domain Controller.
Fetches domain controllers: It lists all domain controllers in the Active Directory domain, showing their names, IP addresses, and the sites they belong to.
Lists domain users: It retrieves a list of all users in Active Directory, displaying their names, SamAccountNames, and whether their accounts are enabled.
Tests connectivity: It pings each domain controller to check network connectivity.
Running the Script:
Make sure you're running the script from a machine that has the Active Directory module installed (typically a domain-joined server or a machine with RSAT tools installed).
Execute the script in PowerShell with administrative privileges.
This script will help you verify if the Active Directory environment is working correctly and if your virtual Windows 10 machine can communicate with the domain controllers.