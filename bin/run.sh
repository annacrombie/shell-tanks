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
			elif [[ "$1" = "-d" ]]; then
				do_update=0
				do_ccheck=0
				developer=1
				shift
			elif [[ "$1" = "-n" ]]; then
				network=true
				clientid=$2
				ip=$3
				shift 2
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
	log_ 0 "Import Finished"
	audio_ -t fx startup
	if [[ $mode = 0 ]]; then
		main-loop_
	elif [[ $mode = 1 ]]; then
		interactive_
	fi
}
function help_ {
	echo "usage: run.sh"
	echo " -h: help"
	echo " -l: log to file"
	echo " -v: log to stty"
	echo " -r: remove data folder"
	echo " -d: developer mode, equivalent to next two flags"
	echo "     --no-update: dont check for update"
	echo "     --force-compatibility: dont check for compatibility"
	echo " -i: interactive mode, turns on logging to stty by default"
	echo " -m: mute all audio"
	exit
}
function ini_ {
	oldstty=$(stty -g)
	do_update=1
	do_ccheck=1
	developer=0
	mode=0
	dir=$(dirname $0)
	mkdir -p data
	sound=1
	logging=2
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
	lf="./shell-tanks.log"
	if [[ $1 = i ]]; then
		echo -n "" > $lf
		return
	fi
	if [[ $logging = 0 ]]; then
		return 0
	elif [[ $logging = 1 ]]; then
		if [[ $1 = 0 ]]; then
			shift
			echo "[$(date)][normal] $@"
		elif [[ $1 = 1 ]]; then
			shift
			echo "[$(date)][warn] $@"
		elif [[ $1 = 2 ]]; then
			shift
			echo "[$(date)][severe] $@"
		fi
	elif [[ $logging = 2 ]]; then
		if [[ $1 = 0 ]]; then
			shift
			echo "[$(date)][normal] $@" >> $lf
		elif [[ $1 = 1 ]]; then
			shift
			echo "[$(date)][warn] $@" >> $lf
		elif [[ $1 = 2 ]]; then
			shift
			echo "[$(date)][severe] $@" >> $lf
		fi
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
		$key
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