#! /bin/bash

# PATH var needs to be added so script can be run as a cron job
PATH="/Users/dri/.rvm/gems/ruby-2.3.3/bin:/Users/dri/.rvm/gems/ruby-2.3.3@global/bin:/Users/dri/.rvm/rubies/ruby-2.3.3/bin:/Users/dri/.nvm/versions/node/v6.7.0/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/opt/X11/bin:/Users/dri/.rvm/bin:/usr/local/opt/go/libexec/bin:/Users/dri/.go/bin"

# gem env PATH var needs to be added so script can be run as a cron job
PATH="/Users/dri/.rvm/gems/ruby-2.3.3/bin:/Users/dri/.rvm/gems/ruby-2.3.3@global/bin:/Users/dri/.rvm/rubies/ruby-2.3.3/bin:/Users/dri/.nvm/versions/node/v6.7.0/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/opt/X11/bin:/Users/dri/.rvm/bin:/usr/local/opt/go/libexec/bin:/Users/dri/.go/bin"
GEM_HOME="/Users/dri/.rvm/gems/ruby-2.3.3"
RAILS_ENV="production"


# 0. get number of apps to record (if provided) as option
num_apps=5
option="default"
while getopts ":a:o:" opt; do
	case $opt in
		a) num_apps="$OPTARG"
		;;
		o) option="$OPTARG"
		;;
		\?)
		echo "Invalid option: -$OPTARG" >&2
		;;
	esac
done

# 1. get temperature values
#hard_disk_temp_line=$(smartctl /dev/disk0 -a | grep Temperature_Celsius);
#hard_disk_temp=( $hard_disk_temp_line );
#echo ${hard_disk_temp[9]};
hard_disk_temp_line=( $(smartctl /dev/disk0 -a | grep Temperature_Celsius) )
hard_disk_temp=${hard_disk_temp_line[9]}
#echo $hard_disk_temp

cpu_temp_line=( $(istats cpu) )
cpu_temp=$(echo ${cpu_temp_line[2]})
cpu_temp="${cpu_temp%???}" #trim the last 2 characters (ºC + 1 invisible char)
#cpu_temp=$(echo ${cpu_temp_line[2]} | rev | cut -c 4- | rev)
#echo ${cpu_temp}

battery_temp_line=( $(istats battery temp) )
battery_temp=$(echo ${battery_temp_line[2]})
battery_temp="${battery_temp%???}" #trim the last 2 characters (ºC + 1 invisible char)
#battery_temp=$(echo ${battery_temp_line[2]} | rev | cut -c 4- | rev)
#echo ${battery_temp}


# 2. get system info
date=$(date)


# 3. get lines for top 5 CPU consuming apps (app name, CPU usage and command)
header_line=0

#3.1 - using top => pas top : top does not display apps but processses, not really useful.
#command="top -n 5 -l 1" #top command is different on osx and linux (on linux -n is the number of iterations/samples).

#3.2 - htop => good (output similar to Activity Monitor) but must be run as sudo and it adds adependancy.
#command="sudo htop"

#3.3 - ps => cannot be reliably parsed (can contain spaces). source : https://github.com/giampaolo/psutil/issues/255

#header_line=1 # skip the first header line when using ps
#num_lines=$(($num_apps+$header_line))
##command="ps aux | head -n ${num_lines}"
#command="ps -raxo %cpu,ucomm=_________________app_name_________________,comm | head -n ${num_lines}" #ucomm needs long column name otherwise it is truncated. => even with that app name is never more than 16 charcaters. https://superuser.com/questions/567648/ps-comm-format-always-cuts-the-process-name. ww option has no effect on column width.



# 3.4 - combine ps command with lsappinfo to build a reliable output for app-name and app-command

# get pids and cpu usage of top apps
header_line=1 # skip the first header line when using ps #TODO : use sed similary to line with #MRKR1 for consistency
num_lines=$(($num_apps+1))
command="ps -raxo pid,%cpu | head -n ${num_lines}"

# use lsappinfo to get full app name and reliable command => will be done in step 4
#lsappinfo info -only execpath ${pid}
#lsappinfo info -only name ${pid}



# 3.5 - psutils => psutil needs to be run as sudo on psx https://github.com/giampaolo/psutil/issues/255
# Note (OSX) psutil.AccessDenied is always raised unless running as root (lsof does the same). source : https://pythonhosted.org/psutil/
#command='
#python <<EOF
#import psutil;
#for proc in psutil.process_iter():
# 	print "name : " + proc.name() + " - cpu : " + str(proc.cpu_percent()) + " - cmd : " + str(proc.cmdline());
#EOF
#'

# 3.6 - psi => same problem than psutil, needs root on osx.
#command='
#python <<EOF
# import psi.process
# for p in psi.process.ProcessTable().values():
# 	print "name : " + str(p.name) + " - %cpu : " + str(p.pcpu) + " - command : " + str(p.command)
#EOF
#'




# execute the command and put each line into a bash array
OLD_IFS=$IFS
IFS=$'\r\n' GLOBIGNORE='*'
command eval 'top_apps=($('"${command}"'))'
IFS=$OLD_IFS



# 4. parse ouput : build JSON array of app names, CPU % and app commands
# apps_json_arr='['
# # get CPU percentage and app name for each line from `ps aux` output (avoid first line)
# for app_line in "${app_lines[@]:1}"; do
# 	app_line_array=(${app_line})
# 	apps_json_arr+='{ "name":"'
# 	apps_json_arr+="${app_line_array[11]}"
# 	apps_json_arr+='", "cpu": "'
# 	apps_json_arr+="${app_line_array[2]}"
# 	apps_json_arr+='" },'
# done
# apps_json_arr+=']'

apps_json_arr='[]'
# go though each line of `ps aux` output (avoid first line if using ps)
for app_line in "${top_apps[@]:$header_line}"; do

	#convert string to bash array (space delimiter)
	app_line_array=(${app_line})

	# get CPU percentage and pid from the line
	app_pid="${app_line_array[0]}"
	app_cpu="${app_line_array[1]}"

	#TODO : somehow move secondary commands call out from step 4
	lsappinfo=$(lsappinfo info -only name execpath ${app_pid})
	app_name=$(echo ${lsappinfo} | sed -E 's/.*LSDisplayName"=["[]([^]"]*)[]"].*/\1/')
	app_cmd=$(echo ${lsappinfo} | sed -E 's/.*CFBundleExecutablePath"=["[]([^]"]*)[]"].*/\1/')

	if [ "${app_name}" == " NULL " ]
	then
		app_name=$(ps -o ucomm -p ${app_pid} | sed -n 2p | xargs) #MRKR1
		app_cmd=$(ps -o comm -p ${app_pid} | sed -n 2p | xargs)
		# note : sed -n 2p is used to get only second line of the output (to skip header line) and xargs is used to trim whitespaces
	fi

	# create json object and add it to existing json array
	apps_json_arr=$(echo "${apps_json_arr}" | jq ". |= .+ [{\"name\":\"${app_name}\",\"cpu\":\"${app_cpu}\",\"cmd\":\"${app_cmd}\"}]")
done
echo $apps_json_arr



# 5. create json object based on template.json filled with
#jq \
#--arg something "$some_value_here" \
#--arg another "$another_value" \
#'.["something"]=$something | .["another_value"]=$another' \
#<template.json >output.json

# json_object=$(cat template.json | jq -rc \
# --arg hard_disk_temp "$hard_disk_temp" \
# --arg cpu_temp "$cpu_temp" \
# --arg battery_temp "$battery_temp" \
# --arg date "$date" \
# --arg apps_json_arr "$apps_json_arr" \
# '.["hard_disk_temp"]=$hard_disk_temp | .["cpu_temp"]=$cpu_temp | .["battery_temp"]=$battery_temp | .["date"]=$date | .["apps"]=$apps_json_arr')
json_record=$(echo "{}" | jq ". | {\
\"cpu_temp\":\"${cpu_temp}\", \
\"hard_disk_temp\":\"${hard_disk_temp}\", \
\"battery_temp\":\"${battery_temp}\", \
\"date\":\"${date}\", \
\"apps\":${apps_json_arr} \
}")
#echo $json_record


# 6. add the JSON object to the existing records array (end of output file)
#json_records=$(cat temp-records.json | jq \
#--arg json_object "$json_object" \
#'. |= .+ [$json_object]')
#'. |= .+ ["test"]')
#TODO : add check for temp-records.json (if empty add array brackets [])
json_records=$(cat hw-records.json | jq ". |= .+ [${json_record}]")
#echo "${json_records}"


# 7. write to file
#echo "$json_records" > temp-records.json
echo "$json_records" > hw-records.json
