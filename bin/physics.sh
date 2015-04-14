#Copyright (C) 2015 Stone Tickle
#can calculate the trajectory of a projectile, and other basic kinematics
function constants_ {
	pi="3.14159265358979323844"
	gravity="-9.81"
	wind="0"
}
function set-variables_ {
	theta=$1
	vo=$2
	y2=0
	ay=$gravity
	ax=$wind
	x1=0
	theta=$(rad_ $theta)
	vox=$(echo "scale=10;($vo*c($theta))" | bc -l)
	voy=$(echo "scale=10;($vo*s($theta))" | bc -l)
}
function rad_ {
	constants_
	echo "$1*($pi/180)" | bc -l
}
function round_ {
	echo "($1+0.5)/1" | bc
}
function timey_ {
	echo "scale=10;(-$voy-sqrt(($voy*$voy)-4*(0.5*$ay)*($y1-$y2)))/(2*(0.5*$ay))" | bc -l
}
function timex_ {
	x2=$1
	if [[ $ax = 0 ]]; then
		echo "scale=10;($x2/$vox)" | bc -l
	else
		echo "scale=10;(-$vox+sqrt(($vox*$vox)-4*(0.5*$ax)*($x1-$x2)))/(2*(0.5*$ax))" | bc -l
	fi
}
function falling_ {
	y=$1
	ay=$gravity
	echo "scale=3;sqrt( (2*$y) / (-1*$ay) )" | bc -l
}
function range_ {
	timey=$(timey_)
	echo "scale=10;($x1+($vox*$timey)+(0.5*$ax)*($timey*$timey))" | bc -l
}
function height_ {
	x2=$1
	timex=$(timex_ $x2)
	echo "scale=10;($y1+($voy*$timex)+(0.5*$ay)*($timex*$timex))" | bc -l
}
function plot-points_ {
	unset points
	vo=$1; theta=$2; y1=$3
	set-variables_ $theta $vo
	range=$(round_ $(range_))
	if [[ ${weapon_gravity[$weapon]} = false ]]; then
		ay=0
		range=${weapon_range[$weapon]}
	fi
	for ((i=0;i<$range;i++)); do
		h=$(height_ $i)
		rh=$(round_ $h)
		points[$i]="$rh"
	done
	if [[ ${weapon_gravity[$weapon]} = true ]]; then
		points+=(0)
	fi
	log_ 0 "physics.sh: calculated: ${points[@]}"
}
constants_