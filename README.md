# artemis-hunter
Hunt for shells with Artemis.

Artemis generates reverse shell payloads &amp; outputs commands for lateral movement in an Active Directory environment.

## Table of Contents

- [Setup](#setup)
- [Functionality](#functionality)
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
```

### Pivoting

## Related Projects
Check out the rest of the Pentesting Pantheon:

Perform recon to see everything your target is hiding with Argus (https://github.com/Komodo-pty/argus-recon/)

Prepare your next attack with Ares (https://github.com/Komodo-pty/ares-attack)

Perform Post-Exploitation enumeration against Windows hosts with Hades (https://github.com/Komodo-pty/hades-PrivEsc)
