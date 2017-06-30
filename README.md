
**hw-tracker** is a macOS/OSX tool (a set of bash scripts) that keeps track of various aspects of your computer : hardware temperatures, top CPU consuming apps, disk use... Data is logged as JSON, ex :

```
{
  "cpu_temp": "56.13",
  "hard_disk_temp": "50",
  "battery_temp": "31.89",
  "date": "Fri Apr 21 18:21:00 CEST 2017",
  "apps": [
	{
	  "name": "iTerm2",
	  "cpu": "5.1",
	  "cmd": "/Applications/iTerm.app/Contents/MacOS/iTerm2"
	},
	{
	  "name": "Atom Helper",
	  "cpu": "4.5",
	  "cmd": "/Applications/Atom.app/Contents/Frameworks/Atom Helper.app/Contents/MacOS/Atom Helper"
	},
	{
	  "name": "Google Chrome",
	  "cpu": "2.3",
	  "cmd": "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
	}
  ]
}
```

# use

![screencast]()

## one time use

- make executable : `chmod +x hw-logger.sh`
- log with default options : `./hw-logger.sh`
- log a specific number of top CPU consuming apps (ex 10) : `./hw-logger.sh -a 10`


## run regularly (as a cron job)

- make executable : `chmod +x hw-tracker.sh`
- start hw-tracker : `./hw-tracker.sh start`. *default interval is 1 minute*
- modify run frequency *modifies the existing cron job without changing its state (started or stopped)*
	`./hw-tracker.sh -m 1` => every minute
	`./hw-tracker.sh -s 30` => every 30 seconds
	`./hw-tracker.sh -m 2` => every 2 minutes
	`./hw-tracker.sh -h 1` => every hour
	`./hw-tracker.sh -s 15` => every 15 seconds
	*so far combining multiple time arguments is not supported. see features roadmap*

- start with parameters : `./hw-tracker.sh -m 2 start`. *note : so far options work only before arguments*
- stop hw-tracker : surprisingly `./hw-tracker.sh stop`
- disable cron mail: `./hw-tracker.sh -d`.
- select the number of top CPU consuming apps tracked : `./hw-tracker.sh -a 10`  *default number of apps is 5*

I recommend [Cronnix](https://code.google.com/p/cronnix/) to manage the state (started/stopped) of your cron jobs.

## setup an alert

setup a conditional temperature alert : TODO

# why

Sometimes my laptop goes high and when I notice it it's always to late to find the culprit app/processus. Using this tool regularly (as a cron job) helps me to find where the heat comes from afterwards. It can also be used to prevent overheating before it happens by showing a dialog if temperature goes to high when certain conditions are met (see advanced use).

# dependencies

- [istats](https://github.com/Chris911/iStats) `gem install iStats` in terminal.
- [smartmontools](https://www.smartmontools.org/) `brew install smartmontools` in terminal.
- [jq](https://github.com/stedolan/jq). `brew install jq` in terminal.


# code

- `hw-logger.sh` is the main script which records the data.
- `hw-records.json` is the JSON file where the records are stored.
- `hw-tracker.sh` is another bash script made to setup the cron job.

## contributing

This project adheres to the Contributor Covenant [code of conduct](code-of-conduct.md).
By participating, you are expected to uphold this code. Please report unacceptable behavior to monkeydri@github.com.

# Features roadmap

- combine multiple time arguments. ex :
	- `./hw-tracker.sh -h 1.5` => run every hour and half
	- `./hw-tracker.sh -h 1 -m 30`  => run every hour and a half
- log other data related to app use : disk usage...
- conditional temperature alert
- Linux version (in a foreseeable future).


# resources used

- http://apple.stackexchange.com/questions/54329/can-i-get-the-cpu-temperature-and-fan-speed-from-the-command-line-in-os-x
- http://apple.stackexchange.com/questions/59580/get-disk-temperature-in-terminal
- http://stackoverflow.com/a/1975880
- http://stackoverflow.com/a/27658717
- http://stackoverflow.com/questions/25414854/add-json-array-element-with-jq-cmdline
- http://www.pc-freak.net/blog/monitoring-cpu-load-memory-usage-mac-os-command-line-terminal/
- https://apple.stackexchange.com/questions/76638/is-there-a-htop-on-linux-like-alternative-for-top-activity-monitor-on-os-x
- https://apple.stackexchange.com/questions/220127/how-to-show-all-running-processes-on-os-x-el-capitan
- http://dtrace.org/blogs/brendan/2011/10/10/top-10-dtrace-scripts-for-mac-os-x/
- http://stackoverflow.com/questions/8880603/loop-through-array-of-strings-in-bash
- http://stackoverflow.com/questions/6287419/getting-all-elements-of-a-bash-array-except-the-first
- https://unix.stackexchange.com/questions/93029/how-can-i-add-subtract-etc-two-numbers-with-bash
- https://askubuntu.com/questions/717919/how-to-prevent-ps-from-truncating-the-process-name
- http://stackoverflow.com/questions/682446/splitting-out-the-output-of-ps-using-python
- http://stackoverflow.com/questions/40143190/how-to-execute-multiline-python-code-from-a-bash-script
- http://stackoverflow.com/questions/24515436/how-to-get-current-foreground-applications-name-or-pid-in-os-x
- http://stackoverflow.com/a/19242797
- http://stackoverflow.com/questions/30044199/how-can-i-match-square-bracket-in-regex-with-grep
- http://stackoverflow.com/questions/1429556/shell-bash-command-to-get-nth-line-of-stdout
- https://superuser.com/questions/632979/if-i-know-the-pid-number-of-a-process-how-can-i-get-its-name
- http://stackoverflow.com/questions/369758/how-to-trim-whitespace-from-a-bash-variable
- http://stackoverflow.com/questions/878600/how-to-create-a-cron-job-using-bash
- https://askubuntu.com/questions/800/how-to-run-scripts-every-5-seconds
- https://serverfault.com/questions/123629/run-task-every-90-minutes-with-cron
- http://stackoverflow.com/questions/11245144/replace-whole-line-containing-a-string-using-sed
- https://www.mkyong.com/mac/sed-command-hits-undefined-label-error-on-mac-os-x/
- http://stackoverflow.com/questions/407523/escape-a-string-for-a-sed-replace-pattern
- http://stackoverflow.com/questions/11456403/stop-shell-wildcard-character-expansion
- https://unix.stackexchange.com/questions/48535/can-grep-return-true-false-or-are-there-alternative-methods
- http://stackoverflow.com/questions/16576197/how-to-add-new-line-using-sed-mac
- http://stackoverflow.com/questions/17583578/what-command-means-do-nothing-in-a-conditional-in-bash
- http://stackoverflow.com/questions/27787536/how-to-pass-a-variable-containing-slashes-to-sed
- http://www.gonzedge.com/blog/2011/12/16/using-rvm-within-a-cron-job.html
- http://stackoverflow.com/questions/1921279/how-to-get-a-variable-value-if-variable-name-is-stored-as-string
- http://stackoverflow.com/questions/11659970/finding-and-replacing-lines-that-begin-with-a-pattern
