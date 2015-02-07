#!/bin/bash
function launch_ {
	trap "cleanup_" int
	ini_
	if [[ -n "$@" ]]; then
		while [[ -n "$@" ]]; do
			if [[ "$1" = "-i" ]]; then
				mode=1
				logging=1
				shift
			elif [[ "$1" = "-v" ]]; then
				logging=1
				shift
			elif [[ "$1" = "-l" ]]; then
				logging=2
				shift
			elif [[ "$1" = "-lf" ]]; then
				if [[ -d $(dirname $2) ]]; then
					lf=$2
				else
					lf=bad
				fi
				shift 2
			elif [[ "$1" = "-d" ]]; then
				do_update=0
				do_ccheck=0
				developer=1
				shift
			elif [[ "$1" = "-n" ]]; then
				network=true
				clientid=$2
				ip=$3
				shift 3
			elif [[ "$1" = "-r" ]]; then
				rm -rf ./data/*
				shift
			elif [[ "$1" = "--no-update" ]]; then
				do_update=0
				shift
			elif [[ "$1" = "--force-compatibility" ]]; then
				do_ccheck=0
				shift
			elif [[ "$1" = "-m" ]]; then
				sound=0
				shift
			elif [[ "$1" = "-h" ]]; then
				help_
			else
				echo "Error, Unknown Flag $1, Try -h"
				exit
			fi
		done
	fi
	if [[ $do_ccheck = 1 ]]; then
		bash compatibility.sh
	fi
	if [[ $do_update = 1 ]]; then
		bash update.sh
	fi
	log_ i
	log_ 0 "Initiated"
	import_ audio.sh
	import_ physics.sh
	import_ network.sh
	import_ shell-tanks.sh $(tput lines) $(tput cols)
	if [[ $logging = 1 ]]; then
		echo "->loaded functions: "
		declare -F | sed 's/declare -f /-->/g'
	fi
	log_ 0 "Import Finished"
	audio_ -t fx startup
	if [[ $mode = 0 ]]; then
		main-loop_
	elif [[ $mode = 1 ]]; then
		interactive_
	fi
	exec 2>>$lf
}
function help_ {
	echo "usage: run.sh"
	echo " -h: help"
	echo " -l: log to file"
	echo " -v: log to stty, turned on by -i"
	echo " -r: remove data folder on launch (if shell-tanks did not cleanup)"
	echo " -d: developer mode, equivalent to next two flags"
	echo "     --no-update: dont check for update"
	echo "     --force-compatibility: dont check for compatibility"
	echo " -i: interactive mode, turns on logging to stty by default"
	echo " -m: mute all audio"
	echo " -n <client id> <peer ip>: turns on network mode, client id"
	echo "     must be a 1 or 0.  Client 0 will generate the map, and"
	echo "     client 1 will listen for a finished map, so client 1  "
	echo "     needs to be started before client 0.  If no ip is supplied,"
	echo "     it reverts to 127.0.0.1.  This feature is very buggy!"
	exit
}
function ini_ {
	dlf="./shell-tanks.log"
	oldstty=$(stty -g)
	do_update=1
	do_ccheck=1
	developer=0
	mode=0
	dir=$(dirname $0)
	mkdir -p data
	sound=1
	logging=2
	network=false
	err_ -i
}
function import_ {
	if [[ $1 = -r ]]; then
		if [[ $2 = success ]]; then
			log_ 0 "successfully imported $3"
		elif [[ $2 = fail ]]; then
			log_ 2 "failed to import $3, $(err_ -r)"
		fi
	else
		n=$1; shift
		. $dir/$n "$@" 2>/tmp/shanks2err&&import_ -r success $n || import_ -r success $n
	fi
}
function err_ {
	if [[ $1 = -i ]]; then
		if [[ -f /tmp/shanks2err ]]; then
			rm /tmp/shanks2err
		fi
	elif [[ $1 = -r ]]; then
		if [[ -f /tmp/shanks2err ]]; then
			cat /tmp/shanks2err
			err_ -i
		fi
	fi
}
function log_ {
	if [[ -z $lf ]]; then
		lf=$dlf
	elif [[ $lf = bad ]]; then
		lf=$dlf
		log_ 1 "bad logfile specified, reverting to default"
	fi
	if [[ $1 = i ]]; then
		echo -n "[$(date)] logging to file" > $lf
		return
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
function debug_ {
	if [[ messy_debug = 1 ]]; then
		set +x
		messy_debug=0
	elif [[ $messy_debug = 0 ]]; then
		set -x
		messy_debug=1
	fi
}
function cleanup_ {
	log_ 0 "exiting"
	err_ -i
	echo -n -e "\033]0;\007"
	stty $oldstty
	shanks2cleanup_
	while [[ $(ps aux | grep mplayer | grep -v grep) ]]; do
		killall mplayer 2>/dev/null
	done
	exit
}
function interactive_ {
	stty $oldstty
	tput cnorm
	i_history=(" ")
	hnum=0
	echo "press escape and enter to enter history mode"
	while true; do
		read -p ">>> " key
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