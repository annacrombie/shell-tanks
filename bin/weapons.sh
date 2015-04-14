weapon_attributes=(
	"name"
	"icon_r"
	"shot_icon"
	"ammo"
	"cost"

	"radius"
	"destruction"

	"type"

	"gravity"
	"range"

	"damage"
	
	"speed"
	"time"
)
function load_weaps_ {
	default_weaps_
	. weap.dat
	for ((i=0;i<${#weapon_name[@]};i++)); do
		wnl="$(echo ${weapon_name[$i]} | wc -c)"
		if [[ $wnl -gt 7 ]]; then
			weapon_name[$i]="  2lng,"
		elif [[ $wnl -lt 7 ]]; then
			weapon_name[$i]="$(printf "%-6s" ${weapon_name[$i]})"
		else
			weapon_name[$i]=${weapon_name[$i]}
		fi
		mweapon_ammo[$i]=0
		wcon=($(echo ${weapon_icon_r[$i]} | sed 's/./& /g;s/</>/g;s/>/</g;s/[{]/\}/g;s/[}]/\{/g;s/[]]/\[/g;s/[[]/\]/g;s/[)]/\(/g;s/[(]/\)/g;s/\//\\/g;s/[\]/\//g'))
		weapon_icon_l[$i]="${wcon[2]}${wcon[1]}${wcon[0]}"
	done
	mweapon_ammo[0]=45
	shottype=${weapon_type[0]}
}
function default_weaps_ {
	weapon_name=(         "cannon"  "mortar"  "nuke"    "missle" "lazer"   )
	weapon_icon_r=(       "+--"     "X=="     "=>>"     "8=>"    "---"     )
	weapon_shot_icon=(    "*"       "*"       "*"       "*"      "-"       )
	weapon_ammo=(         "45"      "6"       "3"       "10"     "20"      )
	weapon_cost=(         "1000"    "1500"    "2000"    "1500"   "3000"    )
	weapon_radius=(       "3"       "5"       "13"      "3"      "2"       )
	weapon_destruction=(  "0"       "0"       "3"       "0"      "10"      )
	weapon_type=(         "normal"  "split"   "normal"  "normal" "normal"  )
	weapon_gravity=(      "true"    "true"    "true"    "true"   "false"   )
	weapon_range=(        "0"       "0"       "0"       "0"      "20"      )
	weapon_damage=(       "5"       "7"       "10"      "20"     "40"      )
	weapon_speed=(        "12"      "9"       "15"      "25"     "40"      )
	weapon_time=(         "0.15"    "0.2"     "0.05"    "0.05"   "0"       )
	weapon_cooldown=(     "1"       "1"       "1"       "2"      "-2")
}
function save_weaps_ {
	totalc=""
	for ((i=0;i<${#weapon_attributes[@]};i++)); do
		c_attn=${weapon_attributes[$i]}
		eval "c_att=(\${weapon_$c_attn[@]//\*/p1o1i2})"
		for ((j=0;j<${#c_att[@]};j++)); do
			c_att[$j]='"'"${c_att[$j]}"'"'
		done
		totalc=$(echo -e "$totalc\nweapon_${c_attn}=( ${c_att[@]} )")
	done
	c=0
	echo -e "$totalc" | column -t | sed 's/"p1o1i2"/"*"     /g' > weaptest.dat
}