#!/bin/bash
#Copyright (C) 2015 Stone Tickle
function launch_ {
	LINES=$(tput lines)
	COLS=$(tput cols)
	exec 2>./shell-tanks-error.log
	trap "cleanup_" int
	ini_
	if [[ -n "$@" ]]; then
		while [[ -n "$@" ]]; do
			arg_ "$@"
			shift $?
		done
	fi
	log_ i
	echo -e "Loading..."
	reload_
	log_ 0 "Initiated"
	if [[ $logging = 1 ]]; then
		echo "->loaded functions: "
		declare -F | sed 's/declare -f /--> /g'
	fi
	log_ 0 "Import Finished"
	if [[ $mode = 0 ]]; then
		main-loop_
	elif [[ $mode = 1 ]]; then
		interactive_
	fi
}
function arg_ {
	shiftam=0
	loadsettings=0
	if [[ "$1" = "-i" ]]; then
		mode=1
		logging=1
		shiftam=1
	elif [[ "$1" = "-v" ]]; then
		logging=1
		shiftam=1
	elif [[ "$1" = "-l" ]]; then
		logging=2
		shiftam=1
	elif [[ "$1" = "-lf" ]]; then
		if [[ -d $(dirname $2) ]]; then
			lf=$2
		else
			lf=bad
		fi
		shiftam=1 2
	elif [[ "$1" = "-d" ]]; then
		developer=1
		shiftam=1
	elif [[ "$1" = "-g" ]]; then
		if [[ "$2" = "tank" ]]; then
			tank_graphics="$3"
		elif [[ "$2" = "terrain" ]]; then
			terrain_graphics="$3"
		fi
		shiftam=3
	elif [[ "$1" = "-n" ]]; then
		network=true
		clientid=$2
		ip=$3
		shiftam=3
	elif [[ "$1" = "-r" ]]; then
		rm -rf ./data/* ./settings
		shiftam=1
	elif [[ "$1" = "-m" ]]; then
		sound=0
		shiftam=1
	elif [[ "$1" = "-fx" ]]; then
		sound=1
		shiftam=1
	elif [[ "$1" = "-waterlvl" ]]; then
		waterlvl=$2
		shiftam=2
	elif [[ "$1" = "-treechance" ]]; then
		treechance=$2
		shiftam=2
	elif [[ "$1" = "-hmod" ]]; then
		hmod=$2
		shiftam=2
	elif [[ "$1" = "-height" ]]; then
		height=$2
		shiftam=2
	elif [[ "$1" = "-noai" ]]; then
		noai=1
		shiftam=1
	elif [[ "$1" = "-ghost" ]]; then
		ghost=1
		shiftam=1
	elif [[ "$1" = "-h" ]]; then
		help_
	elif [[ "$1" = "-p" ]]; then
		players=$2
		shiftam=2
	elif [[ "$1" = "-notitle" ]]; then
		title_screen=false
		shiftam=1
	elif [[ "$1" = "-mvsleep" ]]; then
		speed=$2
		shiftam=2
	elif [[ "$1" = "-noshop" ]]; then
		noshop=1
		shiftam=1
	else
		echo "Error, Unknown Flag $1, Try -h"
		exit
	fi
	return $shiftam
}
function reload_ {
	import_ audio.sh
	import_ physics.sh
	import_ network.sh
	import_ weapons.sh
	import_ shell-tanks.sh $1 $LINES $COLS
}
function help_ {
	echo "Warning: Bash was never meant to be used for something like this and this program will eat tons of memory.  Use at your own risk"
	echo "usage: run.sh, (passing any arguments will prevent settings file from being parsed)"
	echo " Utilities"
	echo " -h: print this message and exit"
	echo " -l: log to file"
	echo " -lf: specify log file"
	echo " -v: log to stty, turned on by -i"
	echo " -i: interactive mode, turns on logging to stty by default"
	echo " -r: reset settings / clear all data"
	echo ""
	echo " Settings / Gameplay"
	echo " -d: developer mode, enables a few top secret cheats"
	echo " -m: mute all audio"
	echo " -fx: mute theme and play only fx"
	echo " -noai: disables ai from automatically spawning"
	echo " -p <int>: the number of players, taking the human-controlled player into account e.g. 2 players means one ai and you"
	echo " -ghost: disables writing of position data by human-controlled player i.e. ai's won't track you"
	echo " -notitle: skips the title screen"
	echo " -mvsleep <float>: the amount of seconds that the loop sleeps before you can move again.  Does not effect ais"
	echo ""
	echo " Terrain / Graphic Modifications"
	echo " -g <tank, terrain> <file>: specify a graphics file for either the tank (located in bin/graphic/tank/) or terrain (located in bin/graphic/terrain/"
	echo " -waterlvl <int>: set water level"
	echo " -treechance <int>: set tree density, lower number = higher density"
	echo " -hmod <int>: the integer that sets how crazy terrain is.  A higher number means flatter terain"
	echo " -height <int>: set the base height of terrain generation"
	echo ""
	echo " Experimental / Buggy"
	echo " -n <client id> <peer ip>: turns on network mode, client id"
	echo "     must be a 1 or 0.  Client 0 will generate the map, and"
	echo "     client 1 will listen for a finished map, so client 1  "
	echo "     needs to be started before client 0.  If no ip is supplied,"
	echo "     it reverts to 127.0.0.1.  This feature only really allows for movement"
	echo ""
	echo " Examples:"
	echo " "
	echo " -> 9-AI Battle on relatively flat ground:"
	echo "    ./shell-tanks -ghost -notitle -p 10 -waterlvl 0 -treechance 1000 -hmod 10 -height 8"
	echo "    This is really laggy  :^)"
	exit
}
function ini_ {
	rlc=0
	dlf="./shell-tanks.log"
	oldstty=$(stty -g)
	developer=0
	mode=0
	dir=$(dirname $0)
	mkdir -p data
	sound=2
	logging=2
	ghost=0
	loadsettings=1
	noai=0
	network=false
}
function import_ {
	n=$1; shift
	. $dir/$n "$@"
	log_ 0 "imported $n"
}
function log_ {
	if [[ -z $lf ]]; then
		lf=$dlf
	elif [[ $lf = bad ]]; then
		lf=$dlf
		log_ 1 "bad logfile specified, reverting to default"
	fi
	if [[ $1 = i ]]; then
		if [[ $logging = 2 ]]; then
			echo -n "[$(date)] logging to file $lf" > $lf
			return
		fi
	fi
	if [[ $logging = 0 ]]; then
		return 0
	elif [[ $logging = 1 ]]; then
		if [[ $1 = 0 ]]; then
			shift
			echo "[$SECONDS][normal] $@"
		elif [[ $1 = 1 ]]; then
			shift
			echo "[$SECONDS][warn] $@"
		elif [[ $1 = 2 ]]; then
			shift
			echo "[$SECONDS][severe] $@"
		fi
	elif [[ $logging = 2 ]]; then
		if [[ $1 = 0 ]]; then
			shift
			echo "[$SECONDS][normal] $@" >> $lf
		elif [[ $1 = 1 ]]; then
			shift
			echo "[$SECONDS][warn] $@" >> $lf
		elif [[ $1 = 2 ]]; then
			shift
			echo "[$SECONDS][severe] $@" >> $lf
		fi
	fi
}
function cleanup_ {
	log_ 0 "exiting"
	stty $oldstty
	st_cleanup_
	mpkilltries=0
	while [[ $(ps aux | grep mplayer | grep -v grep) ]]; do
		killall mplayer 2>/dev/null
		if [[ $mpkilltries -gt 10 ]]; then
			break
		else
			((mpkilltries++))
		fi
	done
	echo -en "\033]0;\007\033[0m\033[${LINES};0H"
	exit
}
function interactive_ {
	stty $oldstty
	tput cnorm
	i_history=(" ")
	hnum=0
	echo 'shell-tanks version '$(cat ../ver.txt)', Copyright (C) 2015 Stone Tickle'
	echo 'shell-tanks comes with ABSOLUTELY NO WARRANTY'
	echo 'This is free software, and you are welcome to redistribute it'
	echo 'under certain conditions'
	echo "press escape and enter to enter history mode"
	while true; do
		read -p ">>> " key 2>&1
		if [[ "$key" =  ]]; then
			hc=$((hnum-1))
			echo -en "\033[s"
			while true; do
				echo -en "\033[u\033[K>>> ${i_history[$hc]}"
				read -s -n 3 -p "$(echo -n"")" key
				if [[ "$key" = $(echo -e "\033[A") ]]; then
					((hc--))
				elif [[ "$key" = $(echo -e "\033[B") ]]; then
					((hc++))
				elif [[ -z "$key" ]]; then
					key="${i_history[$hc]}"
					echo ""
					break
				fi
				if [[ $hc -lt 0 ]]; then
					hc=0
				elif [[ $hc -gt $((${#i_history[@]}-1)) ]]; then
					hc=$((${#i_history[@]}-1))
				fi
			done
		fi
		if [[ $key = exit ]] || [[ $key = x ]]; then
			break
		fi
		if [[ $key = "echo"* ]]; then
			key=(${key[@]})
			unset key[0]
			key=(${key[@]})
			for ((i=0;i<${#key[@]};i++)); do
				dvar=${key[$i]}
				if [[ $dvar = '${'*'['*']}' ]]; then
					am=${dvar//[\{,\},\$]/}
					echo -n "${!am} "
				elif [[ $dvar = '$'* ]]; then
					am=${dvar//\$/}
					echo -n "${!am} "
				else
					echo -n "$dvar "
				fi
			done
			unset key
			echo ""
		elif [[ $key = exit ]]; then
			cleanup_
		else
			$key
		fi
		if [[ -n "$key" ]]; then
			i_history[$hnum]="$key"
			((hnum++))
		fi
		echo -en " return: $?\n"
	done
}
function main-loop_ {
	main_
}
launch_ "$@"