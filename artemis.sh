#!/bin/bash

path=$(readlink $(which artemis) | awk -F 'artemis.sh' '{print $1}')
line="\n============================================================\n"
mode="rce"
module_args=()

detected_module=false
detected_help=false

Help()
{
cat << EOF

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


EOF
exit 0
}

for arg in "$@"
do
  [[ "$arg" == "-m" ]] && detected_module=true
  [[ "$arg" == "-h" ]] && detected_help=true
done	

# If -h was used but -m wasn't, show Artemis help menu
if $detected_help && ! $detected_module
then
  Help
fi

while [[ $# -gt 0 ]]
do
  case "$1" in
    -m)
      mode="$2"
      shift 2
      ;;

    -*)
      #Handle module args, using shift to process args regardless of order

      module_args+=("$1")
      if [[ -n "$2" && "$2" != -* ]]; then
        module_args+=("$2")
	shift
      fi
      shift
      ;;

    *)
      shift
      ;;
  esac
done

case "$mode" in
  rce)
    echo -e "$line\n[RCE]\n"
    bash "$path"rce.sh "${module_args[@]}"
    ;;
  pivot)
    echo -e "$line\n[Pivoting]\n"
    bash "$path"pivot.sh "${module_args[@]}"
    ;;
  *)
    echo -e "\nYou did not select a valid option\n"
    Help
    ;;
esac
