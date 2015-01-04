function compatible_ {
	binary=(cat awk bc sed killall grep column)
	echo -n "$(tput sgr0)testing bash version..."
	if [[ $(bash --version | sed -n '1p' | awk '{print $4}' | sed 's/./& /g' | awk '{print $1}') -ge 3 ]]; then
		echo -e "\033[32mpass"
	else
		echo -e "\033[31mfail"
	fi
	for ((a=0;a<${#binary[@]};a++)); do
		echo -en "\033[0m"
		echo -n "checking for ${binary[$a]}..."
		if [[ $(which ${binary[$a]}) ]]; then
			echo -e "\033[32mpass"
		else
			echo -e "\033[31mfail"
			rm ~/compatible
		fi
	done
}
if [[ ! -f compatible ]]; then
	touch compatible
	compatible_
	echo -e "\033[0m"
	if [[ -f compatible ]]; then
		echo "check passed!"
		read -s -n 1 -p "[space]"
	else
		echo "check failed :( make sure ${binary[@]} are all installed!"
		echo "you should probably press ctrl+c and exit but if you still really want to test it out"
		echo "press any key to continue..."
		read -s -n 1 -p
	fi
fi