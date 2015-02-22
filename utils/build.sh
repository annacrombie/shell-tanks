#!/bin/bash
function launch_ {
	trap "cleanup_" int
	local=false
	if [[ -n "$@" ]]; then
		while [[ -n "$@" ]]; do
			parseargs_ $@
			shift $?
		done
	fi
}
function parseargs_ {
	if [[ $1 = -l ]]; then
		local=true
		return 1
	fi
}
function cleanup_ {
	echo -e "\033[36mCleaning Up..."
	rm -rf ~/shell-tanks.tar.gz ~/i.sh
	echo -e "\033[32mDone.\033[0m"
	exit
}
echo -e "\033[32mBuilding Package..."

if [[ ! -d bin ]] || [[ ! -d utils ]]; then
	echo -e "\033[31myou are not in the right directory, run build.sh from the project root, e.g. bash utils/build.sh should be how you run it"
	exit
fi

echo -e "\033[36mupdating build files (ver.txt and build.txt)"
if [[ -f ver.txt ]]; then
	nver=$(echo "$(cat ver.txt) + 0.1" | bc -l)
	echo $nver > ver.txt
else
	echo "0.0" > ver.txt
fi
echo "built on $(date)" > build.txt

echo -e "\033[36mremove some un-neccesary files"
rm -rf ./bin/compatible ./bin/shell-tanks.log ./bin/data

echo -e "\033[36mmaking tarball"
tar -cf ~/.shell-tanks.tar *
gzip ~/.shell-tanks.tar
if [[ $local = false ]]; then
	mv ~/.shell-tanks.tar.gz ~/shell-tanks.tar.gz
elif [[ $local = true ]]; then
	mv ~/.shell-tanks.tar.gz ~/www/boozon/st/shell-tanks.tar.gz
fi
echo -e "\033[36mconverting installer"
if [[ $local = false ]]; then
	cat utils/install.sh | tr '\n' '; ' > ~/i.sh
elif [[ $local = true ]]; then
	cat utils/install.sh | tr '\n' '; ' > ~/www/boozon/st/i.sh
fi
if [[ $local = false ]]; then
	echo -e "\033[36mUploading Package..."
	read -p "ftp:username >> " usr
	read -s -p "ftp:password >> " pass
	echo ""
	curl -u $usr:$pass -T "{$HOME/shell-tanks.tar.gz,ver.txt,$HOME/i.sh}" ftp://162.238.92.18/www/boozon/st/
elif [[ $local = true ]]; then
	cat ver.txt > ~/www/boozon/st/ver.txt
fi
cleanup_
