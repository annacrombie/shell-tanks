if [[ -n $v ]]; then
	if [[ ${v//./} -gt $(cat ../ver.txt | sed 's/[.]//g') ]]; then
		echo "Update found, installing..."
		echo "Downloading Files..."
		curl -# "pointclearfarm.org/boozon/st/shell-tanks.tar.gz" > "$HOME/.s.tar.gz"
		rm -rf ~/.shell-tanks
		mkdir -p ~/.shell-tanks
		cd ~/.shell-tanks
		tar -xf ../.s.tar.gz
		rm ../.s.tar.gz
		echo "updated!"
		cd ~/shell-tanks/bin
		bash run.sh --no-update
	else
		echo "Up to date!"
	fi
else
	echo "Error, update failed"
fi