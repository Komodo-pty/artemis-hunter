# artemis-hunter
Too lazy to keep typing out the same payloads, or to write a simple shell script to generate them for you?

Well then this is the tool suite for you!

Artemis helps Pentesters hunt for Web shells and Reverse shells.

## Functionality
Artemis generates payloads in various languages for Linux or Windows targets, provides tips for stabilizing the shell, and spawns a listener for you.

If no arguments are specified, Artemis will run in interactive mode. For a list of supported arguments, run `artemis -h`

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
