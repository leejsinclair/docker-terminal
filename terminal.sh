#!/bin/bash
bold=$(tput bold)
normal=$(tput sgr0)

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
	  echo "[$i] ${containernames[$i-1]} - ${containerids[$i-1]}"
	done

	# USER selects a container
	read -p "> " SELECTION

	# Handle docker-compose commands
	case $SELECTION in
		up)
			./dc up;
			OPERATION="q"
			;;
		down)
			./dc down;
			OPERATION="q"
			;;
		*)
			INSTANCE_ID=${containerids[$SELECTION-1]}
			INSTANCE_NAME=${containernames[$SELECTION-1]}

			OPERATION="help"
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
			exit)
				echo "Back to container selection"
				;;
			help)
				echo "help, logs, bash, sh, stop, restart, kill (rm as well), rm, top, bas level any linux command"
				;;
			*)
				docker exec -it $INSTANCE_ID $OPERATION
		esac

		if [[ "$OPERATION" != "exit" ]]; then
			# SHOW container base details
			echo "${bold}" && docker inspect --format '{{.Config.Image}}  {{ .NetworkSettings.IPAddress }}' $INSTANCE_ID

			# SHOW instance ID and command prompt
			read -p "${normal}$INSTANCE_ID > $ " OPERATION
		fi
	done
done
