#!/bin/bash

CLIP_TIME="${PASSWORD_STORE_CLIP_TIME:-45}"

#
# BEGIN platform definable
#

clip() {
	# This base64 business is because bash cannot store binary data in a shell
	# variable. Specifically, it cannot store nulls nor (non-trivally) store
	# trailing new lines.

	local sleep_argv0="password store sleep on display $DISPLAY"
	pkill -f "^$sleep_argv0" 2>/dev/null && sleep 0.5
	local before="$(xclip -o -selection "$X_SELECTION" | base64)"
	echo -n "$1" | xclip -selection "$X_SELECTION"
	(
		( exec -a "$sleep_argv0" sleep "$CLIP_TIME" )
		local now="$(xclip -o -selection "$X_SELECTION" | base64)"
		[[ $now != $(echo -n "$1" | base64) ]] && before="$now"

		# It might be nice to programatically check to see if klipper exists,
		# as well as checking for other common clipboard managers. But for now,
		# this works fine -- if qdbus isn't there or if klipper isn't running,
		# this essentially becomes a no-op.
		#
		# Clipboard managers frequently write their history out in plaintext,
		# so we axe it here:
		qdbus org.kde.klipper /klipper org.kde.klipper.klipper.clearClipboardHistory &>/dev/null

		echo "$before" | base64 -d | xclip -selection "$X_SELECTION"
	) 2>/dev/null & disown
	echo "Copied $2 to clipboard. Will clear in $CLIP_TIME seconds."
}

source "$(dirname "$0")/platform/$(uname | cut -d _ -f 1 | tr '[:upper:]' '[:lower:]').sh" 2>/dev/null # PLATFORM_FUNCTION_FILE

#
# END platform definable
#

#
# BEGIN subcommand functions
#

user_input() {
	echo
	read -n 1 -p "Please make a choice: " input
	echo
	echo
	re='^[0-9q]+$'
	if ! [[ $input =~ $re ]] ; then
		echo "Invalid input";
	else
		if [[ $input -eq "q" ]]; then
			exit 1
		fi
		clip "${values[$input]}" "$pass_path ${keys[$input]}"
	fi
	user_input
}

show() {
	i=1
	echo "Which key or line do you want to copy to the clipboard?"
	echo
	while read -r line; do
		if [[ $i -eq 1 ]]; then
			keys[$i]="password"
			values[$i]=$line
		else
			keys[$i]="$(sed -n 's/^\(.*\): \(.*\)/\1/p' <<< "$line")"
			values[$i]="$(sed 's/^.*: //g' <<< "$line")"
		fi
		if [[ -z ${keys[$i]} ]]; then
			keys[$i]="line $i"
		fi
		echo "$i) ${keys[$i]}"
		(( i++ ))
	done <<< "$pass_input"
	echo "q) quit"
	user_input
}

#
# END subcommand functions
#

pass_path=$1
pass_input=$(pass show $pass_path)

if [ $? != 0 ]; then
	echo $pass_input
	exit $ERROR_CODE
fi

show
