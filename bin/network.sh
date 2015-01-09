function listener_ {
	port=21012
	tport=$((port+1))
	rm -rf ./network
	mkdir -p ./network
	while true; do
		log_ 0 "server: waiting for message"
		handler_ $(nc -l -p $port)
		log_ 0 "handled message"
		poscorrect_
		place-items_
	done
}
#${pos[0]} ${pos[1]} ${wheels} ${orientation} $just_fired ${points[@]}
function handler_ {
	log_ 0 "handler: $@"
	pos[0]=$1
	pos[1]=$2
	wheels=$3
	orientation=$4
	if [[ $5 = 1 ]]; then
		shift 5
		points=("$@")
	fi
}
function send_ {
	echo "${pos[0]} ${pos[1]} $wheels $orientation 0" | nc 127.0.0.1 $port
}