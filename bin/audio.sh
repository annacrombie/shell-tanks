function audio_ {
	audio_dir=$(pwd)
	if [[ $(which mplayer) ]]; then
		afbin=mplayer
	else
		afbin=$audio_dir/audio/mplayer
	fi
	if [[ $sound = 0 ]]; then
		return 2
	fi
	loopAudio=1
	stopAudio=0
	audioVolume=50
	slave=false
	if [[ -n $* ]]; then
		while [[ -n $* ]]; do
			if [[ $1 = -s ]]; then
				local stopAudio=1
				shift
			elif [[ $1 = -l ]]; then
				local loopAudio=0
				shift
			elif [[ $1 = -t ]]; then
				local audioType=$2
				shift 2
			elif [[ $1 = -v ]]; then
				local audioVolume=$2
				shift 2
			else
				local audioFiles=("$@")
				break
			fi
		done
	else
		return 0
	fi
	if [[ $stopAudio = 1 ]]; then
		killall mplayer
	fi
	if [[ -f $audio_dir/audio/$audioType/${audioFiles[0]}.ogg ]]; then
		for ((i=0;i<${#audioFiles[@]};i++)); do
			if [[ $i = $((${#audioFiles[@]}-1)) ]]; then
				lAudio=$loopAudio
			else
				lAudio=1
			fi
			$afbin -loop $lAudio -volume $audioVolume $audio_dir/audio/$audioType/${audioFiles[$i]}.ogg >/dev/null 2>/dev/null
		done&
		return 1
	else
		return 0
	fi
}
audio_ -t fx ini