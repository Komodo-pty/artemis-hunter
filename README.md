# artemis-hunter
Hunt for shells with Artemis.

Artemis generates reverse shell payloads &amp; outputs commands for lateral movement in an Active Directory environment.

## Table of Contents

- [Setup](#setup)
- [Functionality](#functionality)
- [RCE](#rce)
- [Pivoting](#pivoting)
- [Related Projects](#related-projects)

## Setup
After installing the dependencies, give `artemis.sh` permission to execute & create a symbolic link in your PATH.

For example, run the following in this Repo's directory:

`chmod +x artemis.sh`

`ln -s $(pwd)/artemis.sh /home/user/.local/bin/artemis`

### Dependencies
rlwrap

ncat

pwsh
(Installation instructions: https://learn.microsoft.com/en-us/powershell/scripting/install/install-ubuntu?view=powershell-7.4)

## Functionality
```
Artemis will interactively prompt you for input unless the necessary arguments are provided for the selected module.
	
[Options]
	-h: Show this help menu
	-m <MODULE>: Specify the module you want to use
	-m <MODULE> -h: Show specified module's help menu

[Modules]
	rce: Generate reverse shell payloads {used by default}
	pivot: Output commands for lateral movement in an Active Directory environment

[Usage]
	artemis -m rce -h
	artemis -i 10.10.144.68 -p 443 -s php -t nix -l
	artemis -m pivot -x dcom
```

### RCE
Generate reverse shell payloads.

```
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
```

### Pivoting
Output commands for lateral movement in an Active Directory environment.

```
[Options]
	-h: Show this help message
	-x <METHOD>: Specify the pivoting method

[Methods]
	wmi
	winrm
	dcom
	psexec
```

## Related Projects
Check out the rest of the Pentesting Pantheon:

Perform recon to see everything your target is hiding with Argus (https://github.com/Komodo-pty/argus-recon/)

Prepare your next attack with Ares (https://github.com/Komodo-pty/ares-attack)

Perform Post-Exploitation enumeration against Windows hosts with Hades (https://github.com/Komodo-pty/hades-PrivEsc)
