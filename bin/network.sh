function netini_ {
	if [[ -z $ip ]]; then
		ip="127.0.0.1"
	fi
	port=("12345" "22345")
	if [[ $clientid = 0 ]]; then
		oclientid=1
	elif [[ $clientid = 1 ]]; then
		oclientid=0
	fi
	tries=3
}
function netmain_ {
	while true; do
		read -p ">>> " msg
		echo "$msg" | nc -v -v $ip ${port[0]}
	done
}
function netmap_ {
	if [[ $1 = get ]]; then
		log_ 0 "[server] getting data from ${port[$clientid]}"
		echo "waiting for a connection..."
		if [[ $(uname) = "Darwin" ]]; then
			r=$(echo "c" | nc -l ${port[$clientid]})
		elif [[ $(uname) = "Linux" ]]; then
			r=$(echo "c" | nc -l -p ${port[$clientid]} -q 0)
		fi
		echo "waiting for surface on port ${port[$clientid]}"
		netlisten_
		echo "generating map borders based on new surface ${surface[@]}"
		generate-map_ ds
		echo "waiting for final map on port ${port[$clientid]}"
		if [[ $(uname) = "Darwin" ]]; then
			echo "r" | nc -l ${port[$clientid]} > data/ms
		elif [[ $(uname) = "Linux" ]]; then
			echo "r" | nc -l -p ${port[$clientid]} -q 0 > data/ms
		fi
	elif [[ $1 = send ]]; then
		log_ 0 "[server] sending map to $ip ${port[$oclientid]}"
		for ((i=0;i<$tries;i++)); do
			r=$(netsend_ c)
			if [[ $r = c ]]; then
				break
			fi
			if [[ $i = 2 ]]; then
				echo "connection failed"
				exit
			fi
			sleep 0.5
		done
		echo "sending surface ${surface[@]}"
		netsend_ s ${surface[@]}
		sleep 1
		echo "sending map"
		cat data/ms | nc $ip ${port[$oclientid]}
	fi
	exit
}
function netlisten_ {
	if [[ $(uname) = "Darwin" ]]; then
		echo "r" | nc -l ${port[$clientid]} > data/heard
	elif [[ $(uname) = "Linux" ]]; then
		echo "r" | nc -l -p ${port[$clientid]} -q 0 > data/heard
	fi
	heard=$(cat data/heard)
	log_ 0 "[server] heard: $heard"
	if [[ -n $heard ]]; then
		log_ 0 "[server]        not empty!"
		netinterpret_ $heard
	fi
}
function netinterpret_ {
	while [[ -n "$@" ]]; do
		if [[ "$1" = p ]]; then
			pos[0]=$2 pos[1]=$3
			shift 3
		elif [[ "$1" = d ]]; then
			direction=$2
			shift 2
		elif [[ "$1" = f ]]; then
			fire_ -a $2 $3&
			shift 3
		elif [[ "$1" = x ]]; then
			shift
			explosion_ -b "$@"&
			break
		elif [[ "$1" = s ]]; then
			surface[0]=$2 surface[1]=$3
			shift 3
		fi
	done
}
function netsend_ {
	echo "$@" | nc $ip ${port[$oclientid]}
}
function netclient_ {
	touch data/netlock
	weapexplode=false
	while [[ -f data/netlock ]]; do
		memory_ ps 1
		update-wheels_
		place-items_
		netlisten_
	done
}
netini_
if [[ $1 = -i ]]; then
	netmain_
fi