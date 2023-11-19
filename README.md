# dags-audit-tool
dag's Audit Tool is a PowerShell script designed for in-depth auditing of various system components in a Windows environment. Key features include:

    - Operating System Information: Captures details like OS version, architecture, and installation date.
    - CPU Information: Gathers data about the CPU, such as name, number of cores, and clock speed.
    - Memory Information: Reports on total physical memory.
    - Disk Information: Details about logical disks including size and free space.
    - Network Information: Network configuration details including IP addresses and subnets.
    - User Accounts: Information on user accounts present on the system.
    - System Services: Lists running services.
    - Installed Software: Details of software installed on the system.
    - Hardware Inventory: Comprehensive hardware details including graphics cards, sound devices, network adapters, and USB devices.
    - Software Licensing: Licensing status of Windows and Office products.
    - Event Log Summary: The latest entries from System and Application logs.
    - Security and Update Status: Status of Windows Defender, installed updates, and firewall.
    - Backup Status: Information about system backup status and history.
    - Open Network Ports: Details of currently open network ports.
    - User Privileges: Lists users and their group memberships.
    - Scan for Suspicious Registry Entries: Checks for specific suspicious entries in the Windows registry.
    - HDD/SSD Health: Basic health check of HDD/SSD using available system data.

>[!IMPORTANT]
>Disclaimer: This tool is provided 'as is', without warranty of any kind.

## EXAMPLE
    To start the interactive audit tool, run the script from PowerShell:
    .\dat_main.ps1

## License
This project is licensed under the MIT License - see the [LICENSE.md](https://github.com/dagnazty/dags-audit-tool/blob/main/LICENSE) file for details
