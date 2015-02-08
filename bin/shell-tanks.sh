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
	weapexplode=true

	#colors
	c_no="\033[0m"
	c_black="\033[30m"
	c_red="\033[31m"
	c_green="\033[32m"
	c_yellow="\033[33m"
	c_blue="\033[34m"
	c_purple="\033[35m"
	c_cyan="\033[36m"
	c_light_grey="\033[37m"
	c_dark_grey="\033[38m"

	#load terrain blocks
	. ./graphic/terrain/default

	#sets the color of each block
	for ((i=0;i<${#blocks[@]};i++)); do
		if [[ -n ${bcolor[$i]} ]]; then
			ins_color=c_${bcolor[$i]}
		else
			ins_color=c_no
		fi
		cblock[$i]="${!ins_color}${blocks[$i]}"
	done

	#list of blocks that can be impacted
	iblock=[${blocks[0]}${blocks[1]}]

	if [[ $network = true ]]; then
		if [[ $clientid = 0 ]]; then
			log_ 0 "generating map"
			generate-map_
			log_ 0 "sending map"
			netmap_ send
		elif [[ $clientid = 1 ]]; then
			log_ 0 "getting map"
			netmap_ get
			memory_ ml
		fi
	else
		generate-map_
	fi

	#load the tank graphics
	. ./graphic/tank/lines

	player_color=2
	enemy_color=1
	shot_color=0
	explosion_color=3
	health=20
	smod=0
	angle=45
	speed=10
	points=0
	wheels=0
	momentum=0
	plit=true
	direction="r"
	isai=false
	aikilled=0

	weapon=0
	load_weaps_

	controls=(
		"Aa" # move left
		"Dd" # move right
		"Ff" # fire
		"Ee" # adjust angle right
		"Qq" # adjust angle left
		"Ww" # switch weapon
		"Ss" # switch weapon
		"Hh" # help
	)
	control_desc=("move_left" "move_right" "fire" "adjust_angle_right" "adjust_angle_left" "switch_weapon" "switch_weapon" "help")

	stty -echo -icanon time 0 min 0
	tput civis
	echo -n -e "\033]0;shell-tanks build $(cat ../ver.txt)\007"

	audio_ -t theme -l tanktanktank0 tanktanktank1
}
function main_ {
	draw_
	title_screen_
	turn_lock=0
	memory_ sh 0 $health
	memory_ sh 1 $health
	display_
	update-wheels_
	if [[ $network = true ]]; then
		netclient_&
	else
		#:
		ai_&
	fi
	while [[ $turn_lock = 0 ]]; do
		if [[ $(memory_ lh 1) -lt 1 ]]; then
			((aikilled++))
			points=$(( points + ( 1000 + ( 100 * aikilled ) ) ))
			rm -rf ./data/shot ./data/tlock
			mkdir data/shot
			shop_
			mainlogo_
			memory_ sh 0 $health
			memory_ sh 1 $(( health + ( 5 * aikilled ) ))
			ai_&
		fi
		if [[ $(memory_ lh 0) -lt 1 ]]; then
			explosion_ ${pos[@]} hard
			turn_lock=1
			game_over_
			break
		fi
		memory_ ck 0 ms
		if [[ $plit = true ]]; then
			place-items_
		fi
		plit=true
		sleep 0.$((speed-smod))
		input_
		eval "blockin=\${map${pos[1]}[${pos[0]}]}"
		blockin=
		log_ 0 "blockin -> $blockin"
		if [[ $network = true ]]; then
			netsend_ p ${pos[@]} d $direction
		fi
	done
}
function logos_ {
	if [[ $logosize = small ]]; then
		hcenter=$(( ( ${surface[1]} - 19 ) / 2 ))
		hy=(4)
		if [[ $1 = "title" ]]; then
			center=$(( ( ${surface[1]} - 5 ) / 2 ))
			tcolor=(1 2 3 4 5 6)
			((tcycle++))
			if [[ $tcycle = 6 ]]; then
				tcycle=0
			fi
			echo -e "\033[3${tcolor[$tcycle]}m\033[2;${center}HSHELL\033[3;${center}HTANKS\033[0m"
		elif [[ $1 = "humanvcomputer" ]]; then
			echo -e "\033[${hy[0]};${hcenter}H HUMAN VS COMPUTER"
		elif [[ $1 = "humanvhuman" ]]; then
			echo -e "\033[${hy[0]};${hcenter}H  HUMAN VS HUMAN  "
		elif [[ $1 = "local" ]]; then
			echo -e "\033[${hy[0]};${hcenter}H       LOCAL      "
		elif [[ $1 = "network" ]]; then
			echo -e "\033[${hy[0]};${hcenter}H      NETWORK     "
		elif [[ $1 = "exit" ]]; then
			echo -e "\033[${hy[0]};${hcenter}H       EXIT       "
		fi
	elif [[ $logosize = big ]]; then
		hcenter=$(( ( ${surface[1]} - 130 ) / 2 ))
		hy=(25 26 27 28 29)
		hcolor=(1 6 3 4 5 6)
		((hcycle++))
		if [[ $hcycle = 6 ]]; then
			hcycle=0
		fi
		if [[ $1 = "title" ]]; then
			center=$(( ( ${surface[1]} - 70 ) / 2 ))
			tcolor=(1 2 3 4 5 6)
			((tcycle++))
			if [[ $tcycle = 6 ]]; then
				tcycle=0
			fi
			echo -e "\033[3${tcolor[$tcycle]}m\033[2;${center}H      ___           ___           ___                                 \n\033[3;${center}H     /\__\         /\  \         /\__\                                \n\033[4;${center}H    /:/ _/_        \:\  \       /:/ _/_                               \n\033[5;${center}H   /:/ /\  \        \:\  \     /:/ /\__\                              \n\033[6;${center}H  /:/ /::\  \   ___ /::\  \   /:/ /:/ _/_   ___     ___   ___     ___ \n\033[7;${center}H /:/_/:/\:\__\ /\  /:/\:\__\ /:/_/:/ /\__\ /\  \   /\__\ /\  \   /\__\ \\n\033[8;${center}H \:\/:/ /:/  / \:\/:/  \/__/ \:\/:/ /:/  / \:\  \ /:/  / \:\  \ /:/  /\n\033[9;${center}H  \::/ /:/  /   \::/__/       \::/_/:/  /   \:\  /:/  /   \:\  /:/  / \n\033[10;${center}H   \/_/:/  /     \:\  \        \:\/:/  /     \:\/:/  /     \:\/:/  /  \n\033[11;${center}H     /:/  /       \:\__\        \::/  /       \::/  /       \::/  /   \n\033[12;${center}H     \/__/         \/__/         \/__/         \/__/         \/__/    \n\033[13;${center}H                  ___           ___           ___           ___     \n\033[14;${center}H      ___        /  /\         /__/\         /__/|         /  /\    \n\033[15;${center}H     /  /\      /  /::\        \  \:\       |  |:|        /  /:/_   \n\033[16;${center}H    /  /:/     /  /:/\:\        \  \:\      |  |:|       /  /:/ /\  \n\033[17;${center}H   /  /:/     /  /:/~/::\   _____\__\:\   __|  |:|      /  /:/ /::\ \n\033[18;${center}H  /  /::\    /__/:/ /:/\:\ /__/::::::::\ /__/\_|:|____ /__/:/ /:/\:\ \\n\033[19;${center}H /__/:/\:\   \  \:\/:/__\/ \  \:\~~\~~\/ \  \:\/:::::/ \  \:\/:/~/:/\n\033[20;${center}H \__\/  \:\   \  \::/       \  \:\  ~~~   \  \::/~~~~   \  \::/ /:/ \n\033[21;${center}H      \  \:\   \  \:\        \  \:\        \  \:\        \__\/ /:/  \n\033[22;${center}H       \__\/    \  \:\        \  \:\        \  \:\         /__/:/   \n\033[23;${center}H                 \__\/         \__\/         \__\/         \__\/\033[0m"
		elif [[ $1 = "humanvcomputer" ]]; then
			echo -e "\033[3${hcolor[$hcycle]}m\033[${hy[0]};${hcenter}H        ##  ## ##  ## ##      ##   ##   ##  ##   ##  ##  ####      #####  ####  ##      ## ####  ##  ## ###### ###### ####        \033[${hy[1]};${hcenter}H   ---+ ##  ## ##  ## ###    ### ###### ### ##   ##  ## ##        ##     ##  ## ###    ### ## ## ##  ##   ##   ##     ## ## +---  \033[${hy[2]};${hcenter}H << A | ###### ##  ## ####  #### ##  ## ######   ##  ##  ####    ##      ##  ## ####  #### ####  ##  ##   ##   ###### ####  | D >>\033[${hy[3]};${hcenter}H   ---+ ##  ## ##  ## ## #### ## ###### ## ###    ####      ##    ##     ##  ## ## #### ## ##    ##  ##   ##   ##     ## ## +---  \033[${hy[4]};${hcenter}H        ##  ##  ####  ##  ##  ## ##  ## ##  ##     ##    ####      #####  ####  ##  ##  ## ##     ####    ##   ###### ## ##       "
		elif [[ $1 = "humanvhuman" ]]; then
			echo -e "\033[3${hcolor[$hcycle]}m\033[${hy[0]};${hcenter}H                 ##  ## ##  ## ##      ##   ##   ##  ##   ##  ##  ####    ##  ## ##  ## ##      ##   ##   ##  ##                  \033[${hy[1]};${hcenter}H            ---+ ##  ## ##  ## ###    ### ###### ### ##   ##  ## ##       ##  ## ##  ## ###    ### ###### ### ## +---             \033[${hy[2]};${hcenter}H          << A | ###### ##  ## ####  #### ##  ## ######   ##  ##  ####    ###### ##  ## ####  #### ##  ## ###### | D >>           \033[${hy[3]};${hcenter}H            ---+ ##  ## ##  ## ## #### ## ###### ## ###    ####      ##   ##  ## ##  ## ## #### ## ###### ## ### +---             \033[${hy[4]};${hcenter}H                 ##  ##  ####  ##  ##  ## ##  ## ##  ##     ##    ####    ##  ##  ####  ##  ##  ## ##  ## ##  ##                  "
		elif [[ $1 = "local" ]]; then
			echo -e "\033[3${hcolor[$hcycle]}m\033[${hy[0]};${hcenter}H                                               ##      ####    #####   ##   ##                                                    \033[${hy[1]};${hcenter}H                                          ---+ ##     ##  ##  ##     ###### ##     +---                                           \033[${hy[2]};${hcenter}H                                        << A | ##     ##  ## ##      ##  ## ##     | D >>                                         \033[${hy[3]};${hcenter}H                                          ---+ ##     ##  ##  ##     ###### ##     +---                                           \033[${hy[4]};${hcenter}H                                               ######  ####    ##### ##  ## ######                                                "
		elif [[ $1 = "network" ]]; then
			echo -e "\033[3${hcolor[$hcycle]}m\033[${hy[0]};${hcenter}H                                         ##  ## ###### ###### ##    ##  ####  ####  ## ##                                         \033[${hy[1]};${hcenter}H                                    ---+ ### ## ##       ##   ##    ## ##  ## ## ## ## ## +---                                    \033[${hy[2]};${hcenter}H                                  << A | ###### ######   ##   ## ## ## ##  ## ####  ####  | D >>                                  \033[${hy[3]};${hcenter}H                                    ---+ ## ### ##       ##   ###  ### ##  ## ## ## ## ## +---                                    \033[${hy[4]};${hcenter}H                                         ##  ## ######   ##   ##    ##  ####  ## ## ## ##                                         "
		elif [[ $1 = "exit" ]]; then
			echo -e "\033[3${hcolor[$hcycle]}m\033[${hy[0]};${hcenter}H                                                   ###### ##  ## ###### ######                                                    \033[${hy[1]};${hcenter}H                                              ---+ ##      ####    ##     ##   +---                                               \033[${hy[2]};${hcenter}H                                            << A | ######   ##     ##     ##   | D >>                                             \033[${hy[3]};${hcenter}H                                              ---+ ##      ####    ##     ##   +---                                               \033[${hy[4]};${hcenter}H                                                   ###### ##  ## ######   ##                                                      "
		elif [[ $1 = "settings" ]]; then
			echo -e "\033[3${hcolor[$hcycle]}m\033[${hy[0]};${hcenter}H                                      ####  ###### ###### ###### ###### ##  ##  #####   ####                                      \033[${hy[1]};${hcenter}H                                ---+ ##     ##       ##     ##     ##   ### ## ##      ##     +---                                \033[${hy[2]};${hcenter}H                              << A |  ####  ######   ##     ##     ##   ###### ##  ###  ####  | D >>                              \033[${hy[3]};${hcenter}H                                ---+     ## ##       ##     ##     ##   ## ### ##   ##     ## +---                                \033[${hy[4]};${hcenter}H                                      ####  ######   ##     ##   ###### ##  ##  #####   ####                                      "
		elif [[ $1 = "sun" ]]; then
			center=$(( ( ${surface[1]} - 27 ) / 2 ))
			sun_height=(0 0 3 4 5 6 7 8 9 10 11 12 13 14 15)
			sun_height=(0 0)
			sun_margin=5
			tcolor=(3 1 3 1 3 1 3 1 3 1 3 1 3 1 3 1 3 1 3 1 3 1 3 1 3 1 3 1 3 1)
			((tcycle++))
			if [[ $tcycle = 16 ]]; then
				tcycle=0
			fi
			for ((i=0;i<13;i++)); do
				sun_height+=($((sun_margin+i)))
				scolor[$i]=${tcolor[$((tcycle+i))]}
			done
			echo -e "\033[3${scolor[0]}m\033[${sun_height[2]};${center}H"'      _,,ddP"""Ybb,,_      '"\n\033[3${scolor[1]}m\033[${sun_height[3]};${center}H"'    ,d888888888888888b,    '"\n\033[3${scolor[2]}m\033[${sun_height[4]};${center}H"'  ,d8888888888888888888b,  '"\n\033[3${scolor[3]}m\033[${sun_height[5]};${center}H"' d88888888888888888888888b '"\n\033[3${scolor[4]}m\033[${sun_height[6]};${center}H"'d8888888888888888888888888b'"\n\033[3${scolor[5]}m\033[${sun_height[7]};${center}H"'888888888888888888888888888'"\n\033[3${scolor[6]}m\033[${sun_height[8]};${center}H"'888888888888888888888888888'"\n\033[3${scolor[7]}m\033[${sun_height[9]};${center}H"'888888888888888888888888888'"\n\033[3${scolor[8]}m\033[${sun_height[10]};${center}H"'Y8888888888888888888888888P'"\n\033[3${scolor[9]}m\033[${sun_height[11]};${center}H"' Y88888888888888888888888P '"\n\033[3${scolor[10]}m\033[${sun_height[12]};${center}H"'  "Y8888888888888888888P"  '"\n\033[3${scolor[11]}m\033[${sun_height[13]};${center}H"'    "Y888888888888888P"    '"\n\033[3${scolor[12]}m\033[${sun_height[14]};${center}H"'      `""YbbgggddP""`      '
		elif [[ $1 = "moon" ]]; then
			center=$(( ( ${surface[1]} - 27 ) / 2 ))
			mun_height=(0 0 3 4 5 6 7 8 9 10 11 12 13 14 15)
			mun_height=(0 0)
			mun_margin=5
			tcolor=(5 4 5 4 5 4 5 4 5 4 5 4 5 4 5 4 5 4 5 4 5 4 5 4 5 4 5 4)
			((tcycle++))
			if [[ $tcycle = 16 ]]; then
				tcycle=0
			fi
			for ((i=0;i<13;i++)); do
				mun_height+=($((mun_margin+i)))
				mcolor[$i]=${tcolor[$((tcycle+i))]}
			done
			echo -e "\033[3${mcolor[0]}m\033[${mun_height[2]};${center}H"'      _,,ddP"""Ybb,,_      '"\n\033[3${mcolor[1]}m\033[${mun_height[3]};${center}H"'    ,d888888888888888b,    '"\n\033[3${mcolor[2]}m\033[${mun_height[4]};${center}H"'  ,d8/        \88888888b,  '"\n\033[3${mcolor[3]}m\033[${mun_height[5]};${center}H"' d/              \8888888b '"\n\033[3${mcolor[4]}m\033[${mun_height[6]};${center}H"'                  \8888888b'"\n\033[3${mcolor[5]}m\033[${mun_height[7]};${center}H"'                   |8888888'"\n\033[3${mcolor[6]}m\033[${mun_height[8]};${center}H"'                    |888888'"\n\033[3${mcolor[7]}m\033[${mun_height[9]};${center}H"'                   |8888888'"\n\033[3${mcolor[8]}m\033[${mun_height[10]};${center}H"'                  /8888888P'"\n\033[3${mcolor[9]}m\033[${mun_height[11]};${center}H"' Y\              /8888888P '"\n\033[3${mcolor[10]}m\033[${mun_height[12]};${center}H"'  "Y8\        /88888888P"  '"\n\033[3${mcolor[11]}m\033[${mun_height[13]};${center}H"'    "Y888888888888888P"    '"\n\033[3${mcolor[12]}m\033[${mun_height[14]};${center}H"'      `""YbbgggddP""`      '
		fi
	fi
}
function mainlogo_ {
	touch ./data/tlock
	while [[ -f ./data/tlock ]]; do
		if [[ $intitlescreen = true ]]; then
			logos_ title
			sleep 0.2
		elif [[ $intitlescreen = false ]]; then
			logos_ sun
			sleep 0.7
		fi
	done&
}
function title_screen_ {
	intitlescreen=true
	tcycle=0
	if [[ ${surface[0]} -ge 30 ]] && [[ ${surface[1]} -ge 130 ]]; then
		logosize=big
	else
		logosize=small
	fi
	selection=("humanvcomputer" "exit")
	sel=0
	mainlogo_
	while true; do
		logos_ ${selection[$sel]}
		read -s -n 1 key
		if [[ -n $key ]]; then
			if [[ $key = [${controls[0]}] ]]; then
				sel=0
			elif [[ $key = [${controls[1]}] ]]; then
				sel=1
			elif [[ $key = h ]] || [[ $key = H ]]; then
				help_
			fi
		else
			audio_ -t fx hit/$((RANDOM%2))
			if [[ $sel = 0 ]]; then
				intitlescreen=false
				break
			elif [[ $sel = 1 ]]; then
				cleanup_
			fi
		fi
	done
	echo -en "\033[0m"
}
function update-wheels_ {
	if [[ $direction = "r" ]]; then
		wc=${wheels_tr[$wheels]}
	elif [[ $direction = "l" ]]; then
		wc=${wheels_tl[$wheels]}
	fi
	if [[ ${#wheels_tr[@]} = $((wheels+1)) ]]; then
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
				echo -e "\033[$((30+player_color))m\033[${ipos[1]};${ipos[0]}H$wc""${cockpit[0]}""$wc"
			elif [[ $orientation = 2 ]]; then
				echo -e "\033[$((30+player_color))m\033[$((${ipos[1]}-1));$((${ipos[0]}+1))H${cockpit[1]}$wc"
				echo -e "\033[${ipos[1]};${ipos[0]}H$wc"
			elif [[ $orientation = 0 ]]; then
				echo -e "\033[$((30+player_color))m\033[$((${ipos[1]}-1));${ipos[0]}H$wc""${cockpit[1]}\033[${ipos[1]};$((${ipos[0]}+2))H$wc"
			fi
			echo -en "\033[0m"
			oldpos=(${pos[@]})
			oldorientation=$orientation
		elif [[ $1 = clear-tank ]]; then
			if [[ $oldorientation = 1 ]]; then # /-/
				w_pos=($((${oldpos[0]}-1)) $((${oldpos[0]}+1)))
				ofs=(0 0 0)
				eval "ot=(\${map$((${oldpos[1]}+${ofs[0]}))[${w_pos[0]}]} \${map$((${oldpos[1]}+${ofs[1]}))[${pos[0]}]} \${map$((${oldpos[1]}+${ofs[2]}))[${w_pos[1]}]})"
				echo -e "\033[${oipos[1]};${oipos[0]}H${ot[0]//_/ }${ot[1]//_/ }${ot[2]//_/ }"
			elif [[ $oldorientation = 2 ]]; then # _-
				w_pos=($((${oldpos[0]}-1)) $((${oldpos[0]}+1)))
				ofs=(0 1 1)
				eval "ot=(\${map$((${oldpos[1]}+${ofs[0]}))[${w_pos[0]}]} \${map$((${oldpos[1]}+${ofs[1]}))[${pos[0]}]} \${map$((${oldpos[1]}+${ofs[2]}))[${w_pos[1]}]})"
				echo -e "\033[${oipos[1]};${oipos[0]}H${ot[0]//_/ }\033[$((${oipos[1]}-1));$((${oipos[0]}+1))H${ot[1]//_/ }${ot[2]//_/ }"
			elif [[ $oldorientation = 0 ]]; then # -_
				w_pos=($((${oldpos[0]}-1)) $((${oldpos[0]}+1)))
				ofs=(1 1 0)
				eval "ot=(\${map$((${oldpos[1]}+${ofs[0]}))[${w_pos[0]}]} \${map$((${oldpos[1]}+${ofs[1]}))[${pos[0]}]} \${map$((${oldpos[1]}+${ofs[2]}))[${w_pos[1]}]})"
				echo -e "\033[$((${oipos[1]}-1));$((${oipos[0]}))H${ot[0]//_/ }${ot[1]//_/ }\033[${oipos[1]};$((${oipos[0]}+2))H${ot[2]//_/ }"
			fi
		elif [[ $1 = projectile ]]; then
			wateryshot=false
			rchar="_" maxh=0 breaknext=false
			for ((i=0;i<${#points[@]};i++)); do
				if [[ ${points[$i]} -gt $maxh ]]; then
					maxh=${points[$i]}
				fi
			done
			log_ 0 "max height $maxh"
			for ((i=0;i<${#points[@]};i++)); do
				if [[ ! -d ./data/shot ]]; then
					break
				fi
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
						rcx=$((${scx[1]}-1))
						eval "rchar=\${map${scy[1]}[$rcx]}"
						log_ 0 "$rchar"
						echo -e "\033[${oldShot[1]};${oldShot[0]}H${rchar//_/ }"
					fi
					if [[ $breaknext = true ]]; then
						break
					fi
					
					#invert the y
					pointsInverted=$(echo $((${points[$i]}-${surface[0]}-1)) | sed 's/-//g')

					#impact logic
					if [[ $shot_x -gt 0 ]]; then
						scx=($((shot_x-1)) $shot_x $((shot_x+1)))
						scy=($((${points[$i]}+1)) ${points[$i]} $((${points[$i]}-1)))
						eval "sb=(\${map${scy[0]}[${scx[0]}]} \${map${scy[0]}[${scx[1]}]} \${map${scy[0]}[${scx[2]}]}
								  \${map${scy[1]}[${scx[0]}]} \${map${scy[1]}[${scx[1]}]} \${map${scy[1]}[${scx[1]}]}
								  \${map${scy[2]}[${scx[0]}]} \${map${scy[2]}[${scx[2]}]} \${map${scy[2]}[${scx[2]}]})"
					else
						if [[ $shottype != beensplit ]]; then
							rm -rf data/shot/$2
						fi
						break
					fi

					if [[ ${sb[4]//\\033\[3[0-9]m/} = ${blocks[2]} ]] || [[ ${sb[3]//\\033\[3[0-9]m/} = ${blocks[2]} ]] || [[ ${sb[5]//\\033\[3[0-9]m/} = ${blocks[2]} ]]; then
						wateryshot=true
						log_ 0 "wateryshot"
					fi

					#place the shot
					echo -e "\033[$pointsInverted;$((shot_x+1))H*"
					sleep ${weapon_time[$weapon]}

					if [[ $shottype = split ]] && [[ ${points[$i]} = $maxh ]]; then
						log_ 0 "shot # $2 split"
						rm -rf data/shot/$2
						firesplit_ $shot_x ${points[$i]}&
						breaknext=true
					fi

					#if [[ ${sb[0]} = "#" ]] || [[ ${sb[1]} = "#" ]] || [[ ${sb[2]} = "#" ]]; then
					if [[ ${sb[4]//\\033\[3[0-9]m/} = $iblock ]] || [[ $((${#points[@]}-1)) = $i ]]; then
						log_ 0 "shot # $2 hit"
						explosion_ $shot_x ${points[$i]}
						if [[ $shottype != beensplit ]]; then
							rm -rf data/shot/$2
						fi
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
		while [[ ${grnd[0]//\\033\[3[0-9]m/} != $iblock ]] && [[ ${grnd[1]//\\033\[3[0-9]m/} != $iblock ]] && [[ ${grnd[2]//\\033\[3[0-9]m/} != $iblock ]]; do
			if [[ $isai = true ]] && [[ ! -f data/ailock ]]; then
				break
			fi
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
		if [[ ${wwb[0]//\\033\[3[0-9]m/} = $iblock ]] && [[ ${wwb[3]//\\033\[3[0-9]m/} = $iblock ]]; then
			pos=(${moldpos[@]})
		elif [[ ${wwb[2]//\\033\[3[0-9]m/} = $iblock ]] && [[ ${wwb[4]//\\033\[3[0-9]m/} = $iblock ]]; then
			pos=(${moldpos[@]})
		fi
		if [[ ${wwb[0]//\\033\[3[0-9]m/} = $iblock ]]; then
			orientation=0
		elif [[ ${wwb[2]//\\033\[3[0-9]m/} = $iblock ]]; then
			orientation=2
		else
			orientation=1
		fi
		if [[ ${wwb[1]//\\033\[3[0-9]m/} = $iblock ]]; then
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
	bLg=2
	while true; do
		echo -e "\033[5;6H+-=SHOP=-x to exit----------+"
		for ((i=0;i<${#weapon_name[@]};i++)); do
			echo -e "\033[$((6+i));6H| $i ${weapon_name[$i]} -- ${weapon_cost[$i]} pts      |"
		done
		echo -e "\033[$((6+i));6H+---------------------------+"
		read -p "$(echo -e "\033[$((6+i+1));6HItem to buy >> ")" item
		if [[ $item = x ]]; then
			break
		elif [[ -z ${item//[0-9]/} ]] && [[ $item -lt ${#weapon_name[@]} ]]; then
			if [[ $points -ge ${weapon_cost[$item]} ]]; then
				points=$((points-${weapon_cost[$item]}))
				mweapon_ammo[$item]=${weapon_ammo[$item]}
				echo -e "\033[$((6+i+bLg));6Hbought ${weapon_name[$item]} ammo"
			else
				echo -e "\033[$((6+i+bLg));6Hyou don't have enough points for ${weapon_name[$item]}"
			fi
		else
			echo -e "\033[$((6+i+bLg));6Hunknown item $item"
		fi
		((bLg++))
	done
	tput civis
	stty -echo -icanon time 0 min 0
	display_
}
function ai_ {
	#initialize the ai, make sure it spawns at a different location
	touch data/ailock
	isai=true
	#sleep 3
	ai_tick=0.3
	shots_fired=1000
	epos=($((RANDOM%$((${surface[1]}-2))+2)) $((RANDOM%$((${surface[0]}-15))+13)))
	while [[ ${epos[0]} -ge $((${pos[0]}-2)) ]] && [[ ${epos[0]} -le $((${pos[0]}+2)) ]]; do
			epos[0]=$((RANDOM%$((${surface[1]}-2))+2))
	done
	pos=(${epos[@]})
	player_color=$enemy_color

	while [[ -f data/ailock ]]; do
		if [[ $(memory_ lh 1) -lt 1 ]]; then
			explosion_ ${pos[@]}
			rm -rf data/ailock
			break
		fi
		memory_ ml
		memory_ ps 1
		moldpos=(${pos[@]})
		ppos=($(memory_ pl 0))
		edist=$(echo $((${ppos[0]}-${pos[0]})) | sed 's/-//g')
		if [[ $edist -lt 11 ]] && [[ $edist -gt 9 ]]; then
			if [[ $((${ppos[0]}-${pos[0]})) -lt 0 ]]; then
				while [[ $angle != 135 ]] && [[ -f data/ailock ]]; do
					if [[ $edist -lt 11 ]] && [[ $edist -gt 9 ]]; then
						adjust_angle_ 1 ai
						sleep $ai_tick
					else
						break
					fi
				done
			elif [[ $((${ppos[0]}-${pos[0]})) -gt 0 ]]; then
				while [[ $angle != 45 ]] && [[ -f data/ailock ]]; do
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
		echo -e "|"$print"|" | sed 's/ //g;s/_/ /g'
	done
	echo -e "\033[1;1H-=Press H for Help=-"
}
function generate-map_ {
	hdir=1
	waterlvl=10
	border="+-"
	treeplace=(0 0 0)
	for ((i=1;i<$((${surface[1]}));i++)); do
		border="$border""-"
	done
	border="$border""+"
	for ((i=0;i<${surface[0]};i++)); do
		for ((j=0;j<${surface[1]};j++)); do
			eval map$i[$j]="_"
		done
	done
	height=$((RANDOM%$((${surface[0]}/4))+$((${surface[0]}/5))))
	lhc=0
	if [[ $height -lt 5 ]]; then
		height=5
	elif [[ $height -ge $((${surface[0]}/4)) ]]; then
		height=$((${surface[0]}/4))
	fi
	for ((i=0;i<${surface[1]};i++)); do
		if [[ $height -ge $waterlvl ]]; then
			for ((j=0;j<$height;j++)); do
				if [[ $j = $((height-1)) ]]; then
					eval map$j[\$i]=\"${cblock[1]}\"
				else
					eval map$j[\$i]=\"${cblock[0]}\"
				fi
			done

			if [[ $((RANDOM%6)) = 0 ]] && [[ ${treeplace[0]} = 0 ]]; then
				treeplace[0]=$((j+1))
				if [[ $((RANDOM%3)) != 0 ]]; then
					eval map$((j+1))[\$i]=\"${cblock[4]}\"
				fi
				eval map$((j+2))[\$i]=\"${cblock[4]}\"
			elif [[ ${treeplace[1]} = 1 ]]; then
				set -x
				if [[ $((RANDOM%3)) != 0 ]]; then
					eval map$((treeplace[0]))[\$i]=\"${cblock[5]}\"
				fi
				eval map$((treeplace[0]+1))[\$i]=\"${cblock[5]}\"
				treeplace=(0 0 0)
				set +x
			elif [[ ${treeplace[0]} -gt 0 ]]; then
				treeplace[1]=1
				eval map$((${treeplace[0]}))[\$i]=\"${cblock[3]}\"
				eval map$((${treeplace[0]}+1))[\$i]=\"${cblock[3]}\"
				eval map$((${treeplace[0]}-1))[\$i]=\"${cblock[3]}\"
			fi
		elif [[ $waterlvl -gt $height ]]; then
			for ((j=0;j<$waterlvl;j++)); do
				if [[ $j -ge $height ]]; then
					eval map$j[\$i]=\"${cblock[2]}\"
				else
					eval map$j[\$i]=\"${cblock[0]}\"
				fi
			done
		fi
		if [[ $((RANDOM%4+lhc)) -ge 5 ]]; then
			if [[ $((RANDOM%3)) = 0 ]]; then
				hdir=$((RANDOM%2))
			fi
			if [[ $hdir = 0 ]]; then
				height=$((height-1))
			elif [[ $hdir = 1 ]]; then
				height=$((height+1))
			fi
			if [[ $height -lt 5 ]]; then
				height=5
			elif [[ $height -ge $((${surface[0]}/2)) ]]; then
				height=$((${surface[0]}/2))
			fi
			lhc=$((RANDOM%2))
		else
			((lhc++))
		fi
	done
	if [[ $1 != ds ]]; then
		log_ 0 "saving map"
		memory_ ms
	fi
}
function input_ {
	read discard
	read -s -n 1 key
	memory_ ml
	memory_ ps 0
	moldpos=(${pos[@]})
	if [[ -n $key ]]; then
		if [[ $key = [${controls[0]}] ]]; then
			pos[0]=$((${pos[0]}-1))
			direction="l"
			update-wheels_
			poscorrect_
		elif [[ $key = [${controls[1]}] ]]; then
			pos[0]=$((${pos[0]}+1))
			direction="r"
			update-wheels_
			poscorrect_
		elif [[ $key = [${controls[2]}] ]]; then
			memory_ sl
			if [[ $(($(ls -l data/shot | wc -l | awk '{print $1}')-1)) -le 3 ]] && [[ $((SECONDS-1)) -gt $last_shot ]] && [[ ${mweapon_ammo[$weapon]} -gt 0 ]]; then
				((shots_fired++))
				points=$((points+100))
				fire_&last_shot=$SECONDS
				mweapon_ammo[$weapon]=$((${mweapon_ammo[$weapon]}-1))
				display_stats_
				if [[ $network = true ]]; then
					netsend_ f "$angle" 10
				fi
			fi
			poscorrect_
		elif [[ $key = [${controls[3]}] ]]; then
			adjust_angle_ "0"
			plit=false
		elif [[ $key = [${controls[4]}] ]]; then
			adjust_angle_ "1"
			plit=false
		elif [[ $key = [${controls[5]}] ]]; then
			switch_weapon_ "0"
			plit=false
		elif [[ $key = [${controls[6]}] ]]; then
			switch_weapon_ "1"
			plit=false
		elif [[ $key = [${controls[7]}] ]]; then
			help_
			read -s -n 1
			display_
		fi
		if [[ $developer = 1 ]]; then
			if [[ $key = l ]]; then
				display_
			elif [[ $key = c ]]; then
				if [[ -f data/tlock ]]; then
					rm data/tlock
				fi
				tput cnorm
				echo -en "\033[2;2H"
				interactive_
				tput civis
				stty -echo -icanon time 0 min 0
				display_
			elif [[ $key = i ]]; then
				if [[ -f ./data/ailock ]]; then
					rm -rf ./data/ailock
				else
					ai_&
				fi
			elif [[ $key = n ]]; then
				for ((i=0;i<${#mweapon_ammo[@]};i++)); do
					mweapon_ammo[$i]=99
				done
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
	if [[ $shottype != beensplit ]]; then
		touch data/shot/$shots_fired
	fi
	if [[ $1 = "-a" ]]; then
		angle=$2
		shspeed=$3
	else
		shspeed=${weapon_speed[$weapon]}
	fi
	if [[ $angle -gt 90 ]]; then
		cangle=($((90-(angle-90))) 1)
	elif [[ $angle -le 90 ]]; then
		cangle=($angle 0)
	fi
	plot-points_ $shspeed ${cangle[0]} ${pos[1]}
	place-items_ projectile $shots_fired ${cangle[1]}
}
function firesplit_ {
	pos=($1 $2)
	for ((i=0;i<3;i++)); do
		achoice=$((RANDOM%2))
		if [[ $achoice = 0 ]]; then
			rangle=$((angle-RANDOM%35))
		elif [[ $achoice = 1 ]]; then
			rangle=$((angle+RANDOM%35))
		fi
		if [[ $rangle -lt 10 ]]; then
			rangle=10
		elif [[ $rangle -gt 170 ]]; then
			rangle=170
		fi
		shottype=beensplit
		fire_ -a $rangle $((RANDOM%7+14))&
	done
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
	if [[ $wateryshot = true ]]; then
		erchar=("${cblock[2]}" "${cblock[2]}")
	else
		erchar=(" " "_")
	fi
	e_m=${weapon_damage[$weapon]} # set magnitude
	#make sure it is odd, it just looks better
	if [[ $1 = "-b" ]]; then
		shift
		log_ 0 "[explosion_] using custom bup: $@"
		bup=("$@")
		weapexplode=true
		cbup=true
	else
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
					bup+=($d"."$pbux"."$pbuy)
				fi
			done
		done
		#from so
		oldifs=$IFS
		IFS=$'\n' sbup=($(sort <<<"${bup[*]}"))
		IFS=$oldifs
		bup=(${sbup[@]})
	fi
	if [[ $weapon != 2 ]]; then
		audio_ -t fx hit/$((RANDOM%2))
	else
		audio_ -t fx hit/hard
	fi
	memory_ ml
	showedexp=0
	if [[ $network = true ]] && [[ $weapexplode = false ]]; then
		log_ 0 "[explosion_] not exploding weapexplode->false"
		return
	elif [[ $network = true ]] && [[ $weapexplode = true ]] && [[ $cbup != true ]]; then
		log_ 0 "[explosion_] sending explosion data"
		netsend_ x ${bup[@]}
	fi
	for ((i=0;i<${#bup[@]};i++)); do
		posspos_0=($(memory_ pl 0))
		posspos_1=($(memory_ pl 1))
		bup1=(${bup[$i]#*.})
		touch data/explosionlock
		if [[ ${bup1%.*} -gt 0 ]] && [[ ${bup1#*.} -gt 0 ]]; then
			oldlevel=$level
			level=${bup[$i]%%.*}
			if [[ $level -gt $oldlevel ]]; then
				sleep 0.1
			fi
			if [[ ${posspos_0[0]} -ge $((${bup1%.*}-1)) ]] && [[ ${posspos_0[0]} -le $((${bup1%.*}+1)) ]] && [[ ${posspos_0[1]} -ge $((${bup1#*.}-1)) ]] && [[ ${posspos_0[1]} -le $((${bup1#*.})) ]]; then
				memory_ sh 0 $(( $(memory_ lh 0) - $((RANDOM%5+5)) ))
				showedexp=1
				display_health_
				log_ 0 "hit 0"
			fi
			if [[ ${posspos_1[0]} -ge $((${bup1%.*}-1)) ]] && [[ ${posspos_1[0]} -le $((${bup1%.*}+1)) ]] && [[ ${posspos_1[1]} -ge $((${bup1#*.}-1)) ]] && [[ ${posspos_1[1]} -le $((${bup1#*.})) ]]; then
				memory_ sh 1 $(( $(memory_ lh 1) - $((RANDOM%5+5)) ))
				display_health_
				showedexp=1
				log_ 0 "hit 1"
			fi
			eval map${bup1#*.}[\${bup1%.*}]=\"${erchar[1]}\"
			local invy=$((${bup1#*.}-${surface[0]}-1))
			local invy=${invy//-/}
			if [[ $showedexp = 0 ]]; then
				echo -e "\033[$invy;$((${bup1%.*}+2))H\033[$((30+explosion_color))m*"&&sleep 0.1&&echo -e "\033[$invy;$((${bup1%.*}+2))H\033[0m${erchar[0]}"&
			else
				echo -e "\033[$invy;$((${bup1%.*}+2))H\033[31m*"&&sleep 0.1&&echo -e "\033[$invy;$((${bup1%.*}+2))H\033[0m${erchar[0]}"&
			fi
			showedexp=0
		fi
	done
	memory_ ms
	if [[ -f data/explosionlock ]]; then
		rm -rf data/explosionlock
	fi
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
	shottype=${weapon_type[$weapon]}
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
	echo -e "\033[2;$((${surface[1]}-27))H| ang. $dang""˚ |weap. ${weapon_name[$weapon]}, $dammo|"
	echo -e "\033[3;$((${surface[1]}-27))H+-----------+----------------+"
	echo -e "\033[4;$((${surface[1]}-27))HPoints: $(printf "%-10s %s" $points)"
}
function display_ {
	if [[ -f ./data/tlock ]]; then
		rm -rf ./data/tlock
		wastlock=true
	else
		wastlock=false
	fi
	echo -e "\033[0;0H"
	draw_
	place-items_ tank
	display_stats_
	display_health_
	if [[ $wastlock = true ]]; then
		mainlogo_
	fi
}
function help_ {
	log_ 0 "helping..."
	hd=""
	hl=2
	for ((i=0;i<${#controls[@]};i++)); do
		hd="$(echo -e "$hd\n""| ${controls[$i]:1} ${control_desc[$i]} |")"
	done
	hb="+"
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
			weapon_name[$i]="$(printf "%-6s" ${weapon_name[$i]})"
		else
			weapon_name[$i]=${weapon_name[$i]}
		fi
		if [[ ! ${weapon_damage[$i]} ]] || [[ ! ${weapon_ammo[$i]} ]] || [[ ! ${weapon_icon_r[$i]} ]]; then
			log_ 1 "error parsing weapon file"
			break
		fi
		mweapon_ammo[$i]=0
		wcon=($(echo ${weapon_icon_r[$i]} | sed 's/./& /g;s/</>/g;s/>/</g;s/[{]/\}/g;s/[}]/\{/g;s/[]]/\[/g;s/[[]/\]/g;s/[)]/\(/g;s/[(]/\)/g;s/\//\\/g;s/[\]/\//g'))
		weapon_icon_l[$i]="${wcon[2]}${wcon[1]}${wcon[0]}"
	done
	mweapon_ammo[0]=45
	shottype=${weapon_type[0]}
}
function game_over_ {
	rm -rf ./data/tlock
	echo -e "\033[7;$((${surface[0]}-4))H+---------------+"
	echo -e "\033[8;$((${surface[0]}-4))H|-- GAME OVER --| - press any key"
	echo -e "\033[9;$((${surface[0]}-4))H+---------------+"
	read -s -n 1
	rm -rf ./data/ailock
	sleep 2
	cleanup_
}
function shanks2cleanup_ {
	rm -rf ./data/ailock ./data/pos ./data/health ./data/tlock ./data/ms ./data/shot ./data/netlock
	tput cnorm
}
shanks2ini_ "$@"