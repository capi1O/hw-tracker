#! /bin/bash

# 0. get, if provided, arguments (start/stop) and options (frequency, number of apps to record, disable mail)
num_apps=5
second_frequency=0
minute_frequency=1
hour_frequency=0
option="default"
disable_mail=false
start=false
#TODO : make options work after argument : ex ./setup-cron-job.sh start -m 5
while getopts :a:s:m:h:do:t opt; do
	case $opt in
		a) num_apps="$OPTARG" ;;
		s) second_frequency="$OPTARG"; minute_frequency=0; hour_frequency=0 ;;
		m) minute_frequency="$OPTARG"; hour_frequency=0 ;;
		h) hour_frequency="$OPTARG" ;;
		d) disable_mail=true ;;
		o) option="$OPTARG" ;;
		t) echo "test!" ;;
		\?) echo "Invalid option : -$OPTARG" >&2 ;;
	esac
done

# TODO : if start with no options and already a cron job, do not use default values.

shift $((OPTIND - 1))


# for argument in "$@"; do
# 	#options $argument
# 	echo "arg is ${argument}"
# done

# 1. read current cron jobs and save it to a temp file
temp_file="temp-cron-jobs"
crontab -l > "${temp_file}"
running_cron_job=$(grep -cE '^[^#].*#hw-tracker' "${temp_file}")


# TODO : create functions for start and stop so no code is inside case statement (no need to exit), and read cron, install cron and rm temp steps are common.
case "${1}" in
	start)  echo "starting hw-tracker with frequency :"; start=true;; # TODO : if start with no options and already a cron job, should just uncomment the cron line.
	stop)  echo  "stopping hw-tracker..."

		# check if there is a running hw-tracker cron job
		#if grep -qE '^[^#].*#hw-tracker' "${temp_file}" # there is a running cron job for hw-tracker - comment out or delete the line and reload crontab to stop hw-tracker
		if [ "${running_cron_job}" -eq "0" ] # there is a running cron job for hw-tracker - comment out or delete the line and reload crontab to stop hw-tracker
		then
			echo "hw-tracker was not running"
			exit 1
		else # there is no running cron job for hw-tracker - do nothing
			echo "hw-tracker was running"

			# 1. comment out hw-tracker cron job line
			sed -i '.bak' '/^[^#].*#hw-tracker/ s/^/#/' "${temp_file}"

			# 2. install new cron file
			crontab "${temp_file}"

			# 3. remove temp file
			rm "${temp_file}"

			exit 1
		fi
		;;
	*) echo "Invalid argument : ${1}" ;; #TODO : fix invalid argument message
esac



# build script call
hw_logger_command="./hw-logger.sh -a ${num_apps} >> ./cron-job-output.log 2>&1"

# 2. compute frequency for crontab
#TODO : handle combination (ex : every hour and half) - and use a different conditional approach (case)

if ((${hour_frequency} > 0)) # script runs less frequently than once an hour
then
	cron_hour="*/${hour_frequency}"
	cron_minute="0"
	repeat=0
elif ((${minute_frequency} > 0)) # script runs less frequently than once a minute
then
	cron_hour="*"
	cron_minute="*/${minute_frequency}"
	repeat=0
else # script runs more frequently than once a minute : run it every minute but multiple times with a delay.
	cron_hour="*"
	cron_minute="*/1"
	repeat=$((60/${second_frequency})) #ex 7s. needs to be run 8 times. 0-7-14-21-28-35-42-49 (not 56 otherwise too frequent)
fi


# 3. create hw-logger.sh cron job line
hw_logger_cron_job="${cron_minute} ${cron_hour} *	* *	cd ${PWD} && ${hw_logger_command}"

# add other calls if frequency < minute
for (( i=1; i<repeat; i++ ))
do
	hw_logger_cron_job+=" && sleep ${second_frequency} && ${hw_logger_command}"
done

# add a marker at the end (to find line of temp-tracker cron job in crontab)
hw_logger_cron_job+=" #hw-tracker"




# 4. add or replace the line with hw-logger cron job (into temp cron jobs file)
#cron_job_line_number=$(grep -n -m 1 "#hw-tracker" temp-cron-jobs  |cut -f1 -d:)
#if (($cron_job_line_number > 0)) # there is already a cron job for temp-tracker
if grep -q "#hw-tracker" "${temp_file}" # there is already a cron job for hw-tracker (either running or not, ie commented out) - replace the line
then
	echo "already a cron job"
	set -f # disable star expension
	sed_escaped_hw_logger_cron_job=$(echo ${hw_logger_cron_job} | sed -e 's/[\/&]/\\&/g')
	set +f # re-enable star expension
	#sed -i '.bak' "${cron_job_line_number}s/.*/${sed_escaped_temp_logger_cron_job}/" temp-cron-jobs
	# replace entire line except # (if line commented out)
	if [ "$start" = true ] #replace entire line
	then
		#echo "start true"
		sed -i '.bak' "s/.*#hw-tracker.*/${sed_escaped_hw_logger_cron_job}/" "${temp_file}"
	else #replace entire line except eventual starting #
		#echo "start false"
		sed -i '.bak' "s/[^#]*#hw-tracker.*/${sed_escaped_hw_logger_cron_job}/" "${temp_file}"
	fi
else # there is no cron job for hw-tracker
	echo "not already a cron job"
	echo "${hw_logger_cron_job}" >> "${temp_file}"
fi



# 5. Add necessary env vars to crontab (PATH and ruby env vars)
env_vars=("PATH" "GEM_HOME" "GEM_PATH" "MY_RUBY_HOME" "IRBRC" "RUBY_VERSION")
for env_var in "${env_vars[@]}"; do
	eval "env_var_value=\$$env_var"
	if grep -q "${env_var}=" "${temp_file}" # env var already in crontab - replace the line
	then
		sed -i '.bak' "s~^${env_var}=.*~${env_var}=\"${env_var_value}\"~" "${temp_file}"
		#: #
	else # env var not already in crontab - add it on first line
		sed -i '.bak' "1s~^~${env_var}=\"""${env_var_value}"'"\
~' "${temp_file}"
	fi
done



# 6. optional : disable mail from crontab : add or replace MAILTO directive
if [ "$disable_mail" = true ]
then
	echo "disable mail"
	if grep -q "MAILTO" "${temp_file}" # there is already a MAILTO directive in crontab - replace it
	then
		sed -i '.bak' 's/^MAILTO.*/MAILTO = ""/' "${temp_file}"
	else # there is no MAILTO directive in crontab - add it on first line
		sed -i '.bak' '1s/^/MAILTO = ""\
/' "${temp_file}"
	fi
fi

# 7. install new cron file
crontab "${temp_file}"

# 8. remove temp file
rm "${temp_file}"
