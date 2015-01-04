function shanks2ini_ {
	surface=("$(($1-2))" "$(($2-2))")
	log_ 0 "shanks2.sh set surface to ${surface[0]}x${surface[1]}"
	pos=($((RANDOM%$((${surface[1]}-2))+2)) $((RANDOM%$((${surface[0]}-15))+13)))
	oldpos=(${pos[@]})
	moldpos=(${pos[@]})
	oldorientation=0
	shots_fired=0
	last_shot=$SECONDS
	mkdir -p data/shot
	generate-map_

	player_color=2
	enemy_color=1
	shot_color=0
	explosion_color=3
	health=20
	smod=0
	angle=45
	speed=25
	points=0
	wheels_tr=("-" '\' "|" "/")
	wheels_tl=("-" "/" "|" '\')
	wheels=0
	direction="r"

	weapon=0
	load_weaps_

	controls=(
		"a" # move left
		"d" # move right
		"f" # fire
		"e" # adjust angle right
		"q" # adjust angle left
		"w" # switch weapon
		"s" # switch weapon
		"h" # help
	)
	control_desc=("move_left" "move_right" "fire" "adjust_angle_right" "adjust_angle_left" "switch_weapon" "switch_weapon" "help")

	stty -echo -icanon time 0 min 0
	tput civis
	echo -n -e "\033]0;shell-tanks build $(cat ../ver.txt)\007"

	audio_ -t theme -l tanktanktank_mayhem
}
function main_ {
	draw_
	title_screen_
	turn_lock=0
	memory_ sh 0 $health
	memory_ sh 1 $health
	display_
	update-wheels_
	ai_&
	#listen_&
	while [[ $turn_lock = 0 ]]; do
		if [[ $(memory_ lh 1) -lt 1 ]]; then
			points=$((points+1000))
			rm -rf ./data/ailock ./data/tlock #ensure removal!
			shop_
			memory_ sh 1 20
			ai_&
		fi
		if [[ $(memory_ lh 0) -lt 1 ]]; then
			explosion_ ${pos[@]} hard
			turn_lock=1
			game_over_
			break
		fi
		memory_ ck 0 ms
		if [[ $pi = true ]]; then
			place-items_
		fi
		pi=true
		sleep 0.$((speed-smod))
		input_
	done
}
#function network_ {

#}
function logos_ {
	hcenter=$(( ( ${surface[1]} - 130 ) / 2 ))
	hy=(25 26 27 28 29)
	if [[ $1 = "big_title" ]]; then
		center=$(( ( ${surface[1]} - 70 ) / 2 ))
		tcolor=(1 2 3 4 5 6)
		((tcycle++))
		if [[ $tcycle = 6 ]]; then
			tcycle=0
		fi
		echo -e "\033[3${tcolor[$tcycle]}m\033[2;${center}H      ___           ___           ___                                 \n\033[3;${center}H     /\__\         /\  \         /\__\                                \n\033[4;${center}H    /:/ _/_        \:\  \       /:/ _/_                               \n\033[5;${center}H   /:/ /\  \        \:\  \     /:/ /\__\                              \n\033[6;${center}H  /:/ /::\  \   ___ /::\  \   /:/ /:/ _/_   ___     ___   ___     ___ \n\033[7;${center}H /:/_/:/\:\__\ /\  /:/\:\__\ /:/_/:/ /\__\ /\  \   /\__\ /\  \   /\__\ \\n\033[8;${center}H \:\/:/ /:/  / \:\/:/  \/__/ \:\/:/ /:/  / \:\  \ /:/  / \:\  \ /:/  /\n\033[9;${center}H  \::/ /:/  /   \::/__/       \::/_/:/  /   \:\  /:/  /   \:\  /:/  / \n\033[10;${center}H   \/_/:/  /     \:\  \        \:\/:/  /     \:\/:/  /     \:\/:/  /  \n\033[11;${center}H     /:/  /       \:\__\        \::/  /       \::/  /       \::/  /   \n\033[12;${center}H     \/__/         \/__/         \/__/         \/__/         \/__/    \n\033[13;${center}H                  ___           ___           ___           ___     \n\033[14;${center}H      ___        /  /\         /__/\         /__/|         /  /\    \n\033[15;${center}H     /  /\      /  /::\        \  \:\       |  |:|        /  /:/_   \n\033[16;${center}H    /  /:/     /  /:/\:\        \  \:\      |  |:|       /  /:/ /\  \n\033[17;${center}H   /  /:/     /  /:/~/::\   _____\__\:\   __|  |:|      /  /:/ /::\ \n\033[18;${center}H  /  /::\    /__/:/ /:/\:\ /__/::::::::\ /__/\_|:|____ /__/:/ /:/\:\ \\n\033[19;${center}H /__/:/\:\   \  \:\/:/__\/ \  \:\~~\~~\/ \  \:\/:::::/ \  \:\/:/~/:/\n\033[20;${center}H \__\/  \:\   \  \::/       \  \:\  ~~~   \  \::/~~~~   \  \::/ /:/ \n\033[21;${center}H      \  \:\   \  \:\        \  \:\        \  \:\        \__\/ /:/  \n\033[22;${center}H       \__\/    \  \:\        \  \:\        \  \:\         /__/:/   \n\033[23;${center}H                 \__\/         \__\/         \__\/         \__\/\033[0m"
	elif [[ $1 = "small_title" ]]; then
		center=$(( ( ${surface[1]} - 5 ) / 2 ))
		tcolor=(1 2 3 4 5 6)
		((tcycle++))
		if [[ $tcycle = 6 ]]; then
			tcycle=0
		fi
		echo -e "\033[3${tcolor[$tcycle]}m\033[2;${center}HSHELL\033[3;${center}HTANKS"
	elif [[ $1 = "humanvcomputer" ]]; then
		echo -e "\033[${hy[0]};${hcenter}H        ##  ## ##  ## ##      ##   ##   ##  ##   ##  ##  ####      #####  ####  ##      ## ####  ##  ## ###### ###### ####        \033[${hy[1]};${hcenter}H   ---+ ##  ## ##  ## ###    ### ###### ### ##   ##  ## ##        ##     ##  ## ###    ### ## ## ##  ##   ##   ##     ## ## +---  \033[${hy[2]};${hcenter}H << A | ###### ##  ## ####  #### ##  ## ######   ##  ##  ####    ##      ##  ## ####  #### ####  ##  ##   ##   ###### ####  | D >>\033[${hy[3]};${hcenter}H   ---+ ##  ## ##  ## ## #### ## ###### ## ###    ####      ##    ##     ##  ## ## #### ## ##    ##  ##   ##   ##     ## ## +---  \033[${hy[4]};${hcenter}H        ##  ##  ####  ##  ##  ## ##  ## ##  ##     ##    ####      #####  ####  ##  ##  ## ##     ####    ##   ###### ## ##       "
	elif [[ $1 = "humanvhuman" ]]; then
		echo -e "\033[${hy[0]};${hcenter}H                 ##  ## ##  ## ##      ##   ##   ##  ##   ##  ##  ####    ##  ## ##  ## ##      ##   ##   ##  ##                  \033[${hy[1]};${hcenter}H            ---+ ##  ## ##  ## ###    ### ###### ### ##   ##  ## ##       ##  ## ##  ## ###    ### ###### ### ## +---             \033[${hy[2]};${hcenter}H          << A | ###### ##  ## ####  #### ##  ## ######   ##  ##  ####    ###### ##  ## ####  #### ##  ## ###### | D >>           \033[${hy[3]};${hcenter}H            ---+ ##  ## ##  ## ## #### ## ###### ## ###    ####      ##   ##  ## ##  ## ## #### ## ###### ## ### +---             \033[${hy[4]};${hcenter}H                 ##  ##  ####  ##  ##  ## ##  ## ##  ##     ##    ####    ##  ##  ####  ##  ##  ## ##  ## ##  ##                  "
	elif [[ $1 = "0" ]]; then
		echo -e "\033[${hy[0]};${hcenter}H                                               ##      ####    #####   ##   ##                                                    \033[${hy[1]};${hcenter}H                                          ---+ ##     ##  ##  ##     ###### ##     +---                                           \033[${hy[2]};${hcenter}H                                        << A | ##     ##  ## ##      ##  ## ##     | D >>                                         \033[${hy[3]};${hcenter}H                                          ---+ ##     ##  ##  ##     ###### ##     +---                                           \033[${hy[4]};${hcenter}H                                               ######  ####    ##### ##  ## ######                                                "
	elif [[ $1 = "network" ]]; then
		echo -e "\033[${hy[0]};${hcenter}H                                         ##  ## ###### ###### ##    ##  ####  ####  ## ##                                         \033[${hy[1]};${hcenter}H                                    ---+ ### ## ##       ##   ##    ## ##  ## ## ## ## ## +---                                    \033[${hy[2]};${hcenter}H                                  << A | ###### ######   ##   ## ## ## ##  ## ####  ####  | D >>                                  \033[${hy[3]};${hcenter}H                                    ---+ ## ### ##       ##   ###  ### ##  ## ## ## ## ## +---                                    \033[${hy[4]};${hcenter}H                                         ##  ## ######   ##   ##    ##  ####  ## ## ## ##                                         "
	fi
}
function title_screen_ {
	tcycle=0
	if [[ ${surface[0]} -ge 25 ]] && [[ ${surface[1]} -ge 80 ]]; then
		touch ./data/tlock
		while [[ -f ./data/tlock ]]; do
			logos_ big_title
			sleep 0.2
		done&
		selection=("humanvhuman" "humanvcomputer")
		mselection=(0 "network")
		sel=0
		mselection=0
		slevel=0
		while true; do
			if [[ $slevel = 0 ]]; then
				logos_ ${selection[$sel]}
			elif [[ $slevel = 1 ]]; then
				logos_ ${mselection[$sel]}
				log_ 0 "logos_ ${mselection[$sel]} $sel"
			fi
			read -s -n 1 key
			if [[ -n $key ]]; then
				if [[ $key = a ]] || [[ $key = A ]]; then
					sel=0
				elif [[ $key = d ]] || [[ $key = D ]]; then
					sel=1
				elif [[ $key =  ]] || [[ $key = w ]] || [[ $key = W ]]; then
					if [[ $slevel = 1 ]]; then
						slevel=0
					fi
				elif [[ $key = h ]] || [[ $key = H ]]; then
					help_
				fi
			else
				if [[ $slevel = 0 ]]; then
					if [[ $sel = 0 ]]; then
						echo -en "\033[32m"
						logos_ ${selection[$sel]}
						sleep 0.2
						slevel=1
						log_ 0 "setting slevel to 1"
					elif [[ $sel = 1 ]]; then
						echo -en "\033[32m"
						logos_ ${selection[$sel]}
						sleep 1
						break
					fi
				elif [[ $slevel = 1 ]]; then
					:
				fi
			fi
		done
	else
		logos_ small_title
	fi
	echo -en "\033[0m"
}
function update-wheels_ {
	if [[ $direction = "r" ]]; then
		wc=${wheels_tr[$wheels]}
	elif [[ $direction = "l" ]]; then
		wc=${wheels_tl[$wheels]}
	fi
	if [[ $wheels = 3 ]]; then
		wheels=0
	else
		((wheels++))
	fi
}
function place-items_ {
	if [[ -n $1 ]]; then
		if [[ $1 = tank ]]; then
			ipos=($((${pos[0]}+1))   $(echo $((${pos[1]}-${surface[0]}-1)) | sed 's/-//g'))
			oipos=($((${oldpos[0]}+1)) $(echo $((${oldpos[1]}-${surface[0]}-1)) | sed 's/-//g'))
			place-items_ clear-tank
			if [[ $orientation = 1 ]]; then 
				echo -e "\033[$((30+player_color))m\033[${ipos[1]};${ipos[0]}H$wc""-""$wc"
			elif [[ $orientation = 2 ]]; then
				echo -e "\033[$((30+player_color))m\033[$((${ipos[1]}-1));$((${ipos[0]}+1))H_$wc"
				echo -e "\033[${ipos[1]};${ipos[0]}H$wc"
			elif [[ $orientation = 0 ]]; then
				echo -e "\033[$((30+player_color))m\033[$((${ipos[1]}-1));${ipos[0]}H$wc""_\033[${ipos[1]};$((${ipos[0]}+2))H$wc"
			fi
			echo -en "\033[0m"
			oldpos=(${pos[@]})
			oldorientation=$orientation
		elif [[ $1 = clear-tank ]]; then
			if [[ $oldorientation = 1 ]]; then
				echo -e "\033[${oipos[1]};${oipos[0]}H   "
			elif [[ $oldorientation = 2 ]]; then
				echo -e "\033[${oipos[1]};${oipos[0]}H \033[$((${oipos[1]}-1));$((${oipos[0]}+1))H  "
			elif [[ $oldorientation = 0 ]]; then
				echo -e "\033[$((${oipos[1]}-1));$((${oipos[0]}))H  \033[${oipos[1]};$((${oipos[0]}+2))H "
			fi
		elif [[ $1 = projectile ]]; then
			rchar="_"
			for ((i=0;i<${#points[@]};i++)); do
				memory_ ml
				if [[ $3 = 0 ]]; then
					shot_x=$((i+${pos[0]}+1))
					oldshot_x=$((shot_x-1))
				elif [[ $3 = 1 ]]; then
					shot_x=$((${pos[0]}+1-i))
					oldshot_x=$((shot_x+1))
				fi
				if [[ $i != 0 ]]; then
					if [[ $i != 1 ]]; then
						oldShot=($((oldshot_x+1)) $(echo $((${points[$((i-1))]}-${surface[0]}-1)) | sed 's/-//g'))
						echo -e "\033[${oldShot[1]};${oldShot[0]}H$rchar"
					fi
					#invert the y
					pointsInverted=$(echo $((${points[$i]}-${surface[0]}-1)) | sed 's/-//g')

					#impact logic
					scx=($((shot_x-1)) $shot_x $((shot_x+1)))
					scy=($((${points[$i]}+1)) ${points[$i]} $((${points[$i]}-1)))
					eval "sb=(\${map${scy[0]}[${scx[0]}]} \${map${scy[0]}[${scx[1]}]} \${map${scy[0]}[${scx[2]}]}
							  \${map${scy[1]}[${scx[0]}]} \${map${scy[1]}[${scx[1]}]} \${map${scy[1]}[${scx[1]}]}
							  \${map${scy[2]}[${scx[0]}]} \${map${scy[2]}[${scx[2]}]} \${map${scy[2]}[${scx[2]}]})"

					#if the shot goes through walls, replace the walls
					if [[ ${sb[4]} = "#" ]]; then
						rchar="#"
					else
						rchar=" "
					fi

					#place the shot
					echo -e "\033[$pointsInverted;$((shot_x+1))H*"
					sleep 0.2

					#if [[ ${sb[0]} = "#" ]] || [[ ${sb[1]} = "#" ]] || [[ ${sb[2]} = "#" ]]; then
					if [[ ${sb[4]} = "#" ]] || [[ $((${#points[@]}-1)) = $i ]]; then
						log_ 0 "shot # $2 hit"
						explosion_ $shot_x ${points[$i]}
						rm data/shot/$2
						tput sgr0
						break
					fi
				fi
			done
			tput sgr0
		fi
	else
		tank_
	fi
}
function tank_ {
	if [[ $1 = surround ]]; then
		w_pos=($((${pos[0]}-1)) $((${pos[0]}+1)))
		groundy=$((${pos[1]}-1))
		eval "grnd=(\${map$groundy[${w_pos[0]}]} \${map$groundy[${pos[0]}]} \${map$groundy[${w_pos[1]}]})"

		w_pos=($((${pos[0]}-1)) $((${pos[0]}+1)))
		y_pos=$((${pos[1]}+1))
		eval "wwb=(\${map${pos[1]}[${w_pos[0]}]} \${map${pos[1]}[${pos[0]}]} \${map${pos[1]}[${w_pos[1]}]}
			       \${map${ypos}[${w_pos[0]}]}                               \${map${ypos}[${w_pos[1]}]})"
	else
		tank_ surround
		fell=0
		lastsleep=0
		while [[ ${grnd[@]} = "_ _ _" ]]; do
			place-items_ tank
			orientation=1
			pos[1]=$((${pos[1]}-1))
			((fell++))
			tank_ surround
			if [[ $fell -gt 1 ]]; then
				ttime=$(falling_ $fell)
				stime=$(echo "$ttime-$lastsleep" | bc -l)
				sleep $stime
				lastsleep=$ttime
			fi
		done
		if [[ ${wwb[0]} = "#" ]] && [[ ${wwb[3]} = "#" ]]; then
			pos=(${moldpos[@]})
		elif [[ ${wwb[2]} = "#" ]] && [[ ${wwb[4]} = "#" ]]; then
			pos=(${moldpos[@]})
		fi

		if [[ ${wwb[0]} = "#" ]]; then
			orientation=0
		elif [[ ${wwb[2]} = "#" ]]; then
			orientation=2
		else
			orientation=1
		fi
		if [[ ${wwb[1]} = "#" ]]; then
			orientation=1
			pos[1]=$((${pos[1]}+1))
		fi
		place-items_ tank
		if [[ $fell -gt 1 ]]; then
			animation_ fall
		fi
	fi
}
function shop_ {
	tput cnorm
	stty $oldstty
	while true; do
		display_
		tput cup 5 5
		echo "+-=SHOP=--------------------+"
		tput cup 6 5
		echo "| 0 speed boost -- 2000 pts |"
		tput cup 7 5
		echo "| 1 cannonballs -- 1000 pts |"
		tput cup 8 5
		echo "| 2 mortars     -- 1500 pts |"
		tput cup 9 5
		echo "| 3 nukes       -- 2500 pts |"
		tput cup 10 5
		echo "| 4 restore hp  -- 500  pts |"
		tput cup 11 5
		echo "+---------------------------+"
		tput cup 12 5
		read -p "item to buy, x to cancel >> " item
		if [[ $item = x ]]; then
			break
		elif [[ $item -ge 0 ]] && [[ $item -le 4 ]]; then
			if [[ $item = 0 ]]; then
				if [[ $points -ge 2000 ]]; then
					if [[ $smod -lt 25 ]]; then
						points=$((points-2000))
						smod=$((smod+5))
						tput cup 13 5
						echo "Speed boosted"
					else
						tput cup 13 5
						echo "speed at max"
					fi
				else
					tput cup 13 5
					echo "You don't have enough points for speed boost!"
				fi
			elif [[ $item = 1 ]]; then
				if [[ $points -ge 1000 ]]; then
					points=$((points-2000))
					mweapon_ammo[0]=${weapon_ammo[0]}
					tput cup 13 5
					echo "Bought cannonballs"
				else
					tput cup 13 5
					echo "You don't have enough points for cannonballs!"
				fi
			elif [[ $item = 2 ]]; then
				if [[ $points -ge 1500 ]]; then
					points=$((points-1500))
					mweapon_ammo[1]=${weapon_ammo[1]}
					tput cup 13 5
					echo "Bought mortars"
				else
					tput cup 13 5
					echo "You don't have enough points for mortars!"
				fi
			elif [[ $item = 3 ]]; then
				if [[ $points -ge 2500 ]]; then
					points=$((points-2500))
					mweapon_ammo[2]=${weapon_ammo[2]}
					tput cup 13 5
					echo "Bought nukes"
				else
					tput cup 13 5
					echo "You don't have enough points for nukes!"
				fi
			elif [[ $item = 4 ]]; then
				if [[ $points -ge 500 ]]; then
					points=$((points-500))
					memory_ sh 0 20
					health=20
					tput cup 13 5
					echo "Restored to full health"
				else
					tput cup 13 5
					echo "You don't have enough points to restore health!"
				fi
			fi
		fi
	done
	tput civis
	stty -echo -icanon time 0 min 0
	display_
}
function ai_ {
	#initialize the ai, make sure it spawns at a different location
	sleep 3
	ai_tick=0.3
	shots_fired=1000
	epos=($((RANDOM%$((${surface[1]}-2))+2)) $((RANDOM%$((${surface[0]}-15))+13)))
	while [[ ${epos[0]} -ge $((${pos[0]}-2)) ]] && [[ ${epos[0]} -le $((${pos[0]}+2)) ]]; do
			epos[0]=$((RANDOM%$((${surface[1]}-2))+2))
	done
	pos=(${epos[@]})
	player_color=$enemy_color
	touch data/ailock

	while [[ -f data/ailock ]]; do
		if [[ $(memory_ lh 1) -lt 1 ]]; then
			explosion_ ${pos[@]}
			rm data/ailock
			break
		fi
		memory_ ml
		memory_ ps 1
		moldpos=(${pos[@]})
		ppos=($(memory_ pl 0))
		edist=$(echo $((${ppos[0]}-${pos[0]})) | sed 's/-//g')
		if [[ $edist -lt 11 ]] && [[ $edist -gt 9 ]]; then
			if [[ $((${ppos[0]}-${pos[0]})) -lt 0 ]]; then
				while [[ $angle != 135 ]]; do
					if [[ $edist -lt 11 ]] && [[ $edist -gt 9 ]]; then
						adjust_angle_ 1 ai
						sleep $ai_tick
					else
						break
					fi
				done
			elif [[ $((${ppos[0]}-${pos[0]})) -gt 0 ]]; then
				while [[ $angle != 45 ]]; do
					if [[ $edist -lt 11 ]] && [[ $edist -gt 9 ]]; then
					adjust_angle_ 0 ai
					sleep $ai_tick
					else
						break
					fi
				done
			fi
			if [[ $(($(ls -l data/shot | wc -l | awk '{print $1}')-1)) -le 3 ]] && [[ $((SECONDS-2)) -gt $last_shot ]] && [[ ${mweapon_ammo[$weapon]} -gt 0 ]]; then
				((shots_fired++))
				fire_&last_shot=$SECONDS
				mweapon_ammo[$weapon]=$((${mweapon_ammo[$weapon]}-1))
			fi
			memory_ sl
		elif [[ $edist -ge 10 ]]; then
			if [[ $((${ppos[0]}-${pos[0]})) -lt 0 ]]; then
				pos[0]=$((${pos[0]}-1))
				direction="l"
				update-wheels_
			elif [[ $((${ppos[0]}-${pos[0]})) -gt 0 ]]; then
				pos[0]=$((${pos[0]}+1))
				direction="r"
				update-wheels_
			fi
		elif [[ $edist -le 9 ]]; then
			if [[ $((${ppos[0]}-${pos[0]})) -lt 0 ]]; then
				direction="r"
				update-wheels_
				pos[0]=$((${pos[0]}+1))
			elif [[ $((${ppos[0]}-${pos[0]})) -gt 0 ]]; then
				pos[0]=$((${pos[0]}-1))
				direction="l"
				update-wheels_
			fi
		fi
		poscorrect_
		place-items_
		sleep $ai_tick
	done
}
function draw_ {
	echo "$border"
	for ((i=$((${surface[0]}-1));i>-1;i--)); do
		eval "print=\${map$i[@]}"
		echo "|"$print"|" | sed 's/ //g;s/_/ /g'
	done
	echo -e "\033[1;1H-=Press H for Help=-"
}
function generate-map_ {
	border="+-"
	for ((i=1;i<$((${surface[1]}));i++)); do
		border="$border""-"
	done
	border="$border""+"
	for ((i=0;i<${surface[0]};i++)); do
		for ((j=0;j<${surface[1]};j++)); do
			eval map$i[$j]="_"
		done
	done
	height=$((RANDOM%4+6))
	lhc=0
	for ((i=0;i<${surface[1]};i++)); do
		for ((j=0;j<$height;j++)); do
			eval map$j[\$i]=\"#\"
		done
		if [[ $lhc = 6 ]]; then
			if [[ $((RANDOM%2)) = 0 ]]; then
				height=$((height-1))
			else
				height=$((height+1))
			fi
			if [[ $height -lt 3 ]]; then
				height=3
			elif [[ $height -gt 15 ]]; then
				height=15
			fi
			lhc=$((RANDOM%2))
		else
			((lhc++))
		fi
	done
	memory_ ms
}
function input_ {
	read discard
	read -s -n 1 key
	memory_ ml
	memory_ ps 0
	moldpos=(${pos[@]})
	if [[ -n $key ]]; then
		if [[ $key = ${controls[0]} ]]; then
			pos[0]=$((${pos[0]}-1))
			direction="l"
			update-wheels_
			poscorrect_
		elif [[ $key = ${controls[1]} ]]; then
			pos[0]=$((${pos[0]}+1))
			direction="r"
			update-wheels_
			poscorrect_
		elif [[ $key = ${controls[2]} ]]; then
			memory_ sl
			if [[ $(($(ls -l data/shot | wc -l | awk '{print $1}')-1)) -le 3 ]] && [[ $((SECONDS-1)) -gt $last_shot ]] && [[ ${mweapon_ammo[$weapon]} -gt 0 ]]; then
				((shots_fired++))
				points=$((points+100))
				fire_&last_shot=$SECONDS
				mweapon_ammo[$weapon]=$((${mweapon_ammo[$weapon]}-1))
				display_stats_
			fi
			poscorrect_
		elif [[ $key = ${controls[3]} ]]; then
			adjust_angle_ "0"
			pi=false
		elif [[ $key = ${controls[4]} ]]; then
			adjust_angle_ "1"
			pi=false
		elif [[ $key = ${controls[5]} ]]; then
			switch_weapon_ "0"
			pi=false
		elif [[ $key = ${controls[6]} ]]; then
			switch_weapon_ "1"
			pi=false
		elif [[ $key = ${controls[7]} ]]; then
			help_
			read -s -n 1
			display_
		fi
		if [[ $developer = 1 ]]; then
			if [[ $key = l ]]; then
				display_
			elif [[ $key = c ]]; then
				tput cnorm
				echo -en "\033[2;2H"
				interactive_
				tput civis
				stty -echo -icanon time 0 min 0
				display_
			elif [[ $key = p ]]; then
				if [[ -f ./data/ailock ]]; then
					rm ./data/ailock
				else
					ai_&
				fi
			fi
		fi
	fi
}
function adjust_angle_ {
	oldangle=$angle
	ipos=(${pos[0]} $( echo $((${pos[1]}-${surface[0]})) | sed 's/-//g'))
	#←↖↑↗→
	if [[ $1 = "0" ]]; then
		angle=$((angle-5))
	elif [[ $1 = "1" ]]; then
		angle=$((angle+5))
	fi
	if [[ $angle -gt 180 ]]; then
		angle=$oldangle
	elif [[ $angle -lt 0 ]]; then
		angle=$oldangle
	fi
	#straight from shanks 1!
	sPos=($(awk "BEGIN {print $angle / 50}" | sed 's/[.]/ /g'))
	if [[ $(echo ${sPos[1]} | sed 's/./& /g' | awk '{print $1}') -ge 6 ]]; then
		sPos=$((${sPos[0]}+1))
	else
		sPos=${sPos[0]}
	fi
	aicon=$(echo "$sPos" | sed 's/0/→/g;s/1/↗/g;s/2/↑/g;s/3/↖/g;s/4/←/g')
	if [[ $orientation = 1 ]]; then
		tput cup $((${ipos[1]})) $((${ipos[0]}+1))
	else
		tput cup $((${ipos[1]}+1)) $((${ipos[0]}+1))
	fi
	echo "$aicon"
	if [[ $2 != ai ]]; then
		display_stats_
	fi
}
function fire_ {
	audio_ -t fx fire/$((RANDOM%4))
	touch data/shot/$shots_fired
	if [[ $angle -gt 90 ]]; then
		cangle=($((90-(angle-90))) 1)
	elif [[ $angle -le 90 ]]; then
		cangle=($angle 0)
	fi
	plot-points_ 10 ${cangle[0]} ${pos[1]}
	place-items_ projectile $shots_fired ${cangle[1]}
}
function animation_ {
	if [[ $1 = fall ]]; then
		fbtch=($((${pos[0]}-2)) $((${pos[0]}+2)))
		eval "rchar=(\${map${pos[1]}[${fbtch[0]}]} \${map${pos[1]}[${fbtch[1]}]})"
		local invy=$(echo $((${pos[1]}-${surface[0]}-1)) | sed 's/-//g')
		echo -e "\033[$invy;$((${pos[0]}+4))H."
		echo -e "\033[$invy;${pos[0]}H."
		sleep 0.2
		echo -e "\033[$invy;$((${pos[0]}+4))H${rchar[1]//_/ }"
		echo -e "\033[$invy;${pos[0]}H${rchar[0]//_/ }"
	fi
}
function coord_ {
	if [[ -z $1 ]]; then
		echo ${pos[@]}
	elif [[ $1 = tp ]]; then
		pos[0]=$2
		pos[1]=$3
	fi
}
function explosion_ {
	e_m=${weapon_damage[$weapon]} # set magnitude
	#make sure it is odd, it just looks better
	local bsub=$(( (e_m) /2))
	for ((a=0;a<$e_m;a++)); do
		for ((b=0;b<$((e_m));b++)); do
			#set possible destroyed blocks
			pbux=$(( $1 + ( b - bsub ) )) pbuy=$(($2 + ( a - bsub ) ))
			#get the distance from the origin in x and y
			d1=$(($1 - pbux)) d2=$(($2 - pbuy))
			#add the absolute values of those differences to get an average distance
			d=$(( ${d1//-/} + ${d2//-/} ))
			#the further away from the origin, the less likely a block is to explode
			if [[ $d -le 0 ]] || [[ $((RANDOM%d)) = 0 ]]; then
				bux+=($pbux) buy+=($pbuy)
			fi
		done
	done
	if [[ $weapon != 2 ]]; then
		audio_ -t fx hit/$((RANDOM%2))
	else
		audio_ -t fx hit/hard
	fi
	memory_ ml
	posspos_0=($(memory_ pl 0))
	posspos_1=($(memory_ pl 1))
	showedexp=0
	for ((i=0;i<${#buy[@]};i++)); do
		if [[ $buy -gt 0 ]] && [[ $bux -gt 0 ]]; then
			if [[ ${posspos_0[0]} -ge $((${bux[$i]}-1)) ]] && [[ ${posspos_0[0]} -le $((${bux[$i]}+1)) ]] && [[ ${posspos_0[1]} -ge $((${buy[$i]}-1)) ]] && [[ ${posspos_0[1]} -le $((${buy[$i]})) ]]; then
				memory_ sh 0 $(( $(memory_ lh 0) - $((RANDOM%5+5)) ))
				showedexp=1
				display_health_
				log_ 0 "hit 0"
			fi
			if [[ ${posspos_1[0]} -ge $((${bux[$i]}-1)) ]] && [[ ${posspos_1[0]} -le $((${bux[$i]}+1)) ]] && [[ ${posspos_1[1]} -ge $((${buy[$i]}-1)) ]] && [[ ${posspos_1[1]} -le $((${buy[$i]})) ]]; then
				memory_ sh 1 $(( $(memory_ lh 1) - $((RANDOM%5+5)) ))
				display_health_
				showedexp=1
				log_ 0 "hit 1"
			fi
			eval map${buy[$i]}[\${bux[$i]}]=\"_\"
			local invy=$((${buy[$i]}-${surface[0]}-1))
			local invy=${invy//-/}
			if [[ $showedexp = 0 ]]; then
				echo -e "\033[$invy;$((${bux[$i]}+2))H\033[$((30+explosion_color))m*"
			else
				echo -e "\033[$invy;$((${bux[$i]}+2))H\033[31m*"
			fi
			sleep 0.1
			echo -e "\033[$invy;$((${bux[$i]}+2))H\033[0m "
			showedexp=0
		fi
	done
	memory_ ms
}
function display_health_ {
	echo -e "\033[2;2Hp0: $(memory_ lh 0) health"
	echo -e "\033[3;2Hp1: $(memory_ lh 1) health"
}
function switch_weapon_ {
	log_ 0 "switch_weapon_: switching $1"
	if [[ $1 = "0" ]]; then
		((weapon--))
	elif [[ $1 = "1" ]]; then
		((weapon++))
	fi
	if [[ $weapon -lt 0 ]]; then
		weapon=0
	elif [[ $weapon -gt $((${#weapon_name[@]}-1)) ]]; then
		weapon=$((${#weapon_name[@]}-1))
	fi
	if [[ $angle -gt 90 ]]; then
		dicon=${weapon_icon_l[$weapon]}
	else
		dicon=${weapon_icon_r[$weapon]}
	fi
	if [[ $orientation = "1" ]]; then
		echo -e "\033[$((${ipos[1]}));$((${ipos[0]}))H$dicon"
	fi
	display_stats_
}
function display_stats_ {
	if [[ $angle -gt 99 ]]; then
		dang="$angle"
	elif [[ $angle -lt 10 ]]; then
		dang="  $angle"
	else
		dang=" $angle"
	fi
	if [[ ${mweapon_ammo[$weapon]} -ge 10 ]]; then
		dammo=${mweapon_ammo[$weapon]}
	else
		dammo=" ${mweapon_ammo[$weapon]}"
	fi
	echo -e "\033[1;$((${surface[1]}-27))H+-----------+----------------+"
	echo -e "\033[2;$((${surface[1]}-27))H| ang. $dang""˚ |weap. ${weapon_name[$weapon]} $dammo|"
	echo -e "\033[3;$((${surface[1]}-27))H+-----------+----------------+"
	echo -e "\033[4;$((${surface[1]}-27))HPoints: $(printf "%-10s %s" $points)"
}
function display_ {
	echo -e "\033[1;1H"
	draw_
	place-items_ tank
	display_stats_
	display_health_
}
function help_ {
	log_ 0 "helping..."
	hd=""
	hl=2
	for ((i=0;i<${#controls[@]};i++)); do
		hd="$(echo -e "$hd\n""| ${controls[$i]} ${control_desc[$i]} |")"
	done
	hb="+"
	log_ 0 $(echo "$hd" | sed -n '2p')
	for ((i=0;i<$(($(echo "$hd" | sed -n '2p' | wc -c)+9));i++)); do
		hb="$hb""-"
	done
	hb="$hb""+"
	hd=$(echo -e "$hd" | column -t)
	hd=$(echo -e "$hd\n$hb")
	echo -e "\033[$hl;2H$hb"
	echo -e "\033[$hl;4H=Help="
	echo "$hd" | while read line; do
		((hl++))
		echo -e "\033[$hl;2H${line//_/ }"
	done
}
function poscorrect_ {
	if [[ ${pos[0]} -lt 2 ]]; then
		pos[0]=2
	elif [[ ${pos[0]} -gt $((${surface[1]}-3)) ]]; then
		pos[0]=$((${surface[1]}-3))
	fi
}
function memory_ {
	if [[ $1 = ms ]]; then
		echo "#$(date "+%s")$((RANDOM))" > ./data/ms
		for ((i=$((${surface[0]}-1));i>-1;i--)); do
			eval "print=\${map$i[@]}"
			echo 'map'$i'=("'$(echo $print | sed 's/ /" "/g')'")' >> ./data/ms
		done
	elif [[ $1 = ml ]]; then
		. ./data/ms
	elif [[ $1 = ps ]]; then
		mkdir -p data/pos/
		echo 'pos_g=('"${pos[@]}"')' > data/pos/_$2
	elif [[ $1 = pl ]]; then
		if [[ -f ./data/pos/_$2 ]]; then
			. ./data/pos/_$2
			echo "${pos_g[@]}"
		fi
	elif [[ $1 = sh ]]; then
		mkdir -p data/health/
		echo 'h_g=('"$3"')' > data/health/_$2
	elif [[ $1 = lh ]]; then
		if [[ -f ./data/health/_$2 ]]; then
			. ./data/health/_$2
			echo "${h_g[0]}"
		fi
	elif [[ $1 = ck ]]; then
		if [[ -z ${omt[$2]} ]]; then
			omt[$2]=$(cat ./data/$3 | head -n 1)
		fi
		if [[ $(cat ./data/$3 | head -n 1) != ${omt[$2]} ]]; then
			memory_ ml
		fi
		omt[$2]=$(cat ./data/$3 | head -n 1)
	fi
}
function load_weaps_ {
	. weap.dat
	for ((i=0;i<${#weapon_name[@]};i++)); do
		wnl="$(echo ${weapon_name[$i]} | wc -c)"
		if [[ $wnl -gt 7 ]]; then
			weapon_name[$i]="  2lng,"
		elif [[ $wnl -lt 7 ]]; then
			weapon_name[$i]="$(printf "%-6s %s" ${weapon_name[$i]},)"
		else
			weapon_name[$i]=${weapon_name[$i]}","
		fi
		if [[ ! ${weapon_damage[$i]} ]] || [[ ! ${weapon_ammo[$i]} ]] || [[ ! ${weapon_icon_r[$i]} ]]; then
			log_ 1 "error parsing weapon file"
			break
		fi
		mweapon_ammo=(45 10 10)
		wcon=($(echo ${weapon_icon_r[$i]} | sed 's/./& /g;s/>/</g'))
		weapon_icon_l[$i]="${wcon[2]}${wcon[1]}${wcon[0]}"
	done
}
function game_over_ {
	echo -e "\033[7;$((${surface[0]}-4))H+---------------+"
	echo -e "\033[8;$((${surface[0]}-4))H|-- GAME OVER --| - press any key"
	echo -e "\033[9;$((${surface[0]}-4))H+---------------+"
	read -s -n 1
	rm ./data/ailock
	sleep 2
	cleanup_
}
function shanks2cleanup_ {
	rm -rf ./data/ailock ./data/pos ./data/health ./data/tlock ./data/ms
	tput cnorm
}
shanks2ini_ "$@"