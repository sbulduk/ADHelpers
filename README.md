[![N|Solid](https://taskin-logistics.com/wp-content/uploads/2015/01/logo.png)](https://taskin-logistics.com/homepage/)
# PREPROCESS FOR POWERSHELL (PS) REMOTE CONNECTION
## 1. SERVER SIDE PROCESS ORDER
**Notice:** These steps have been tried on Windows Server 2019 and Windows Server 2022 operating systems.
**Notice:** Be sure that PowerShell has been run as administrator before following the instructions below.
### 1.1 Enable Remote Management on Windows Server (2019/2022)
Remote management is crucial for executing commands and scripts from the Windows client (Windows 10/11).
**Steps:**
**1.1.a** Enable WinRM (Windows Remote Management): Run the following PowerShell commands on the Windows Server 2019:
```sh
Enable-PSRemoting -Force
Set-Item wsman:\localhost\client\trustedhosts * -Force
```
**1.1.b** Allow Remote Management through the Firewall:
```sh
Enable-NetFirewallRule -DisplayGroup "Remote Desktop"
Enable-NetFirewallRule -DisplayGroup "Windows Remote Management"
```
**1.1.c** Verify Remote Management: Test connectivity from the virtual Windows 10 machine:
```sh
Test-WSMan -ComputerName 192.168.174.129
```
**Notice:** 192.168.174.129 represents the local IP address of the server computer. Do not forget to change the given IP address with the server computer's IP address which is to be controlled!
### 1.2 Configure Windows Server for Remote Administration
**Steps:**
**1.2.a** Install Remote Server Administration Tools (RSAT) Features: Open PowerShell on Windows Server 2019 and run:
```sh
Install-WindowsFeature RSAT-AD-Tools
```
**1.2.b** Allow Remote Desktop Access (Optional):
```sh
Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnections" -Value 0
Enable-NetFirewallRule -DisplayGroup "Remote Desktop"
```
**1.2.c** Enable PowerShell Script Execution:
```sh
Set-ExecutionPolicy RemoteSigned -Force
```
## 2. CLIENT SIDE PROCESS ORDER
### 2.1 Configure Client Machine for Server Management
**Steps:**
**2.1.a** Join the Domain: Ensure that the client computer/PC (Windows 10/11) is joined to the same domain with the server.
Navigate to Settings -> System -> About -> Join a domain.
Enter the domain name and provide domain admin credentials.
**2.1.b** Ensure WinRM is enabled on the local machine
Run the following command to check and enable WinRM:
```sh
winrm quickconfig
```
If WinRM is not configured, the command which is given above will start the WinRM service and configure it to allow remote management. If it prompts to make changes, type `y` and press ``Enter``.
**2.1.c** Check the WinRM listener
Verify that the WinRM listener is configured properly:
```sh
winrm enumerate winrm/config/listener
```
An HTTP or HTTPS listener must be observed for the network interface now.
**2.1.d** Add the Server to Trusted Hosts: On the client machine, open PowerShell as Administrator and run the following:
```sh
Set-Item wsman:\localhost\client\trustedhosts "192.168.174.129" -Force
```
**2.1.e** Test Connection:
Firewall and Network Considerations
Ensure the following:
Firewall rules: Allow WinRM traffic through the firewall. You can enable this rule via PowerShell:
```sh
Enable-NetFirewallRule -Name "WINRM-HTTP-In-TCP"
```
Network profile: Make sure the network is set to Private or Domain. If it's Public, WinRM might not work.
```sh
Enter-PSSession -ComputerName 192.168.174.129 -Credential (Get-Credential)
```
### 2.2 Install Management Tools on Client Machine
**Steps:**
**2.2.a** Install RSAT: On the client machine, install the necessary RSAT tools:
```sh
Get-WindowsCapability -Name RSAT* -Online | Add-WindowsCapability -Online
```
**2.2.b** Enable PowerShell Remoting: On the virtual Windows 10 machine, ensure PowerShell remoting is enabled:
```sh
Enable-PSRemoting -Force
```
**Notice:** Be sure that client PC (Windows 10/11) is connected to the internet. If it is not or any errors are returned try the following (2.2.c):

**2.2.c** Manually Install RSAT Tools:
If an error is recieved when attempting to install RSAT, the necessary RSAT tools can be downloaded manually from the Microsoft website and installed. Download RSAT for your version of Windows 10/11: Go to the official RSAT download page [https://www.microsoft.com/en-us/download/details.aspx?id=45520](https://www.microsoft.com/en-us/download/details.aspx?id=45520). Select the appropriate version for your Windows OS version and download it. Install the downloaded file and follow the installation instructions.
## 3. TEST WITH A SIMPLE SCRIPT (Optional)
From the client PC, test running a PowerShell command on the server:
```sh
Invoke-Command -ComputerName 192.168.174.129 -Credential (Get-Credential) -ScriptBlock {
   Get-Service
}
```
Here's a simple PowerShell script that can be used to test Active Directory functionality. This script will check the health of the Active Directory domain, retrieve information about the domain controllers, and list some basic user details from the domain.
### 3.1 Check the health of the Active Directory domain
```sh
Write-Host "Checking Active Directory domain health..."
$domain = Get-ADDomain
Write-Host "Domain: $($domain.Name)"
Write-Host "Domain Functional Level: $($domain.DomainMode)"
Write-Host "Forest Functional Level: $($domain.ForestMode)"
Write-Host "Is Read-Only Domain Controller: $($domain.ReadOnly)"
```
### 3.2 Retrieve and display all Domain Controllers in the domain
```sh
Write-Host "`nFetching Domain Controllers..."
$domainControllers = Get-ADDomainController -Filter *
foreach ($dc in $domainControllers) {
    Write-Host "DC Name: $($dc.Name)"
    Write-Host "DC IP Address: $($dc.IPAddress)"
    Write-Host "DC Site: $($dc.Site)"
    Write-Host "-------------------------------"
}
```
### 3.3 Retrieve and display basic details of all users in the domain
```sh
Write-Host "`nListing Active Directory Users..."
$users = Get-ADUser -Filter * -Property Name, SamAccountName, Enabled
foreach ($user in $users) {
    Write-Host "User Name: $($user.Name)"
    Write-Host "Username: $($user.SamAccountName)"
    Write-Host "Account Enabled: $($user.Enabled)"
    Write-Host "-------------------------------"
}
```
### 3.4 Test connectivity to the domain controller
```sh
Write-Host "`nTesting connectivity to Domain Controllers..."
foreach ($dc in $domainControllers) {
    $pingResult = Test-Connection -ComputerName $dc.Name -Count 2 -Quiet
    if ($pingResult) {
        Write-Host "Successfully reached Domain Controller: $($dc.Name)"
    } else {
        Write-Host "Failed to reach Domain Controller: $($dc.Name)"
    }
}
```
### What this script does:
Checks the domain health: It retrieves and displays information about the Active Directory domain, including the domain name, functional levels, and whether it's a Read-Only Domain Controller.
Fetches domain controllers: It lists all domain controllers in the Active Directory domain, showing their names, IP addresses, and the sites they belong to.
Lists domain users: It retrieves a list of all users in Active Directory, displaying their names, SamAccountNames, and whether their accounts are enabled.
Tests connectivity: It pings each domain controller to check network connectivity.
Running the Script:
Make sure you're running the script from a machine that has the Active Directory module installed (typically a domain-joined server or a machine with RSAT tools installed).
Execute the script in PowerShell with administrative privileges.
This script will help you verify if the Active Directory environment is working correctly and if your virtual Windows 10 machine can communicate with the domain controllers.