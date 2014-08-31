clip() {
	local sleep_argv0="password store sleep for user $(id -u)"
	pkill -f "^$sleep_argv0" 2>/dev/null && sleep 0.5
	local before="$(pbpaste | openssl base64)"
	echo -n "$1" | pbcopy
	(
		( exec -a "$sleep_argv0" sleep "$CLIP_TIME" )
		local now="$(pbpaste | openssl base64)"
		[[ $now != $(echo -n "$1" | openssl base64) ]] && before="$now"
		echo "$before" | openssl base64 -d | pbcopy
	) 2>/dev/null & disown
	echo "Copied $2 to clipboard. Will clear in $CLIP_TIME seconds."
}
