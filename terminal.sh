#!/bin/bash
bold=$(tput bold)
normal=$(tput sgr0)

#normal=$(tput sgr0)                      # normal text
reset=$'\e[0m'                           # (works better sometimes)
bold=$(tput bold)                         # make colors bold/bright
red="$bold$(tput setaf 1)"                # bright red text
green=$(tput setaf 2)                     # dim green text
fawn=$(tput setaf 3); beige="$fawn"       # dark yellow text
yellow="$bold$fawn"                       # bright yellow text
darkblue=$(tput setaf 4)                  # dim blue text
blue="$bold$darkblue"                     # bright blue text
purple=$(tput setaf 5); magenta="$purple" # magenta text
pink="$bold$purple"                       # bright magenta text
darkcyan=$(tput setaf 6)                  # dim cyan text
cyan="$bold$darkcyan"                     # bright cyan text
gray=$(tput setaf 7)                      # dim white text
darkgray="$bold"$(tput setaf 0)           # bold black = dark gray text
white="$bold$gray"                        # bright white text

while true
do
	# GET container IDS
	containerids=()
	for pid in `docker ps | grep -v ID | awk '{print $1}'` ; do containerids=("${containerids[@]}" "$pid") ; done
	# GET container NAMES (for menu display)
	containernames=()
	for name in `docker ps | grep -v ID | awk '{print $2}'` ; do containernames=("${containernames[@]}" "$name") ; done

	# GET number of containers from the ps command
	arraylength=${#containernames[@]}

	# DISPLAY options
	for (( i=1; i<${arraylength}+1; i++ ));
	do
	  echo -e "[${bold}$i${normal}]\t${containerids[$i-1]}\t${green}${containernames[$i-1]}${reset}"
	done

	# USER selects a container
	read -p "> " SELECTION

	# Handle docker-compose commands
	case $SELECTION in
		up)
			./dc up;
			OPERATION="exit"
			;;
		down)
			./dc down;
			OPERATION="exit"
			;;
		stats)
			docker stats
			;;
		lcd)
			echo "working directory: $(pwd)"
			read -p "...change local working directory > " CMD
			cd $CMD
			echo "$(pwd)"
			OPERATION="exit"
			;;
		clear)
			clear
			;;
		help)
			echo -e "${cyan}up${reset}\t-\tdocker-compose up
${cyan}down${reset}\t-\tdocker-compose down
${cyan}lcd${reset}\t-\tchange local current directory
"
			OPERATION="exit"
			;;
		*)
			INSTANCE_ID=${containerids[$SELECTION-1]}
			INSTANCE_NAME=${containernames[$SELECTION-1]}

			OPERATION="none"
	esac

	# ENTER container operations
	while [[ "$OPERATION" != "exit" ]]
	do
		case $OPERATION in
			logs)
				docker logs --follow $INSTANCE_ID
				;;
			bash)
				docker exec -it $INSTANCE_ID /bin/bash
				;;
			sh)
				docker exec -it $INSTANCE_ID /bin/sh
				;;
			exec)
				read -p "...command to execute > " CMD
				docker exec -it $INSTANCE_ID $CMD
				;;
			restart)
				docker restart $INSTANCE_ID
				;;
			stop)
				docker stop $INSTANCE_ID
				;;
			kill)
				docker kill $INSTANCE_ID && docker rm $INSTANCE_ID
				OPERATION="exit"
				;;
			rm)
				docker rm $INSTANCE_ID
				;;
			top)
				docker top $INSTANCE_ID
				;;
			port)
				docker port $INSTANCE_ID
				read -p "...test port > " CMD
				docker port $INSTANCE_ID $CMD
				;;
			stats)
				docker stats
				;;
			clear)
				clear
				;;
			exit)
				echo "Back to container selection"
				;;
			help)
				echo -e "${cyan}help${reset}\t-\tHelp screen
${cyan}logs${reset}\t-\tLogs of docker instance
${cyan}bash${reset}\t-\tExecute bash script into container
${cyan}sh${reset}\t-\tExecute sh into container
${cyan}stop${reset}\t-\tStop container
${cyan}reset${reset}\t-\tReset container
${cyan}kill${reset}\t-\tKill container (rm as well)
${cyan}rm${reset}\t-\tRemove container
${cyan}top${reset}\t-\tDocer top
${yellow}CMD${reset}\t-\tType any linux command and have it executed within the container"
				;;
			none)
				;;
			*)
				docker exec -it $INSTANCE_ID $OPERATION
		esac

		if [[ "$OPERATION" != "exit" ]]; then
			# SHOW instance ID and command prompt
			read -p "$INSTANCE_ID@${bold}$(docker inspect --format '{{.Config.Image}}({{ .NetworkSettings.IPAddress }})' $INSTANCE_ID)${normal} > $ " OPERATION
		fi
	done
done
