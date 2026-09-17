#!/usr/bin/env bash

COOKIE=''

CURLCOMMAND=(curl -s --url 'https://www.metal-archives.com/bookmark/ajax-list/type/band?sEcho=3&iColumns=6&sColumns=&iDisplayStart=0&iDisplayLength=500&mDataProp_0=0&mDataProp_1=1&mDataProp_2=2&mDataProp_3=3&mDataProp_4=4&mDataProp_5=5&iSortCol_0=3&sSortDir_0=desc&iSortingCols=1&bSortable_0=true&bSortable_1=true&bSortable_2=true&bSortable_3=true&bSortable_4=true&bSortable_5=false&_=1789544483715' \
  -b "$COOKIE" \
  -H 'user-agent: ma.sh release tracker')

input=""

urldecode() {
  echo -e "$(sed 's/+/ /g;s/%\(..\)/\\x\1/g;')"
}

input_builder() {
    local value="${1:-}"

    if [ -z "$value" ]; then
        input='seconds ago|minutes ago|hour ago|hours ago|Yesterday|Today'
        return
    fi

    case "$value" in
        *" minutes ago")
            value=${value%% *}
            value=$(printf "\"%s minutes ago|" $(seq 2 $value))
            input=$(echo "$value" | sed 's/|$//')
            input="seconds ago|$input"
            ;;

        "1 hour ago")
            input="seconds ago|minutes ago|1 hour ago"
            ;;

        *" hours ago")
            value=${value%% *}
            value=$(printf "\"%s hours ago|" $(seq 2 $value))
            input=$(echo "$value" | sed 's/|$//')
            input="seconds ago|minutes ago|hour ago|$input"
            ;;

        Today)
            input='seconds ago|minutes ago|hour ago|hours ago|Today'
            ;;

        Yesterday)
            input='seconds ago|minutes ago|hour ago|hours ago|Today|Yesterday'
            ;;

        *" days ago")
            local days="${value%% *}"
            input='seconds ago|minutes ago|hour ago|hours ago|Today|Yesterday'

            for ((i=2; i<=days; i++)); do
                input+="|${i} days ago"
            done
            ;;

        "1 week ago")
            input='seconds ago|minutes ago|hour ago|hours ago|Today|Yesterday'

            for ((i=2; i<=6; i++)); do
                input+="|${i} days ago"
            done

            input+='|1 week ago'
            ;;

        *" weeks ago")
            local weeks="${value%% *}"
            input='seconds ago|minutes ago|hour ago|hours ago|Today|Yesterday'

            for ((i=2; i<=6; i++)); do
                input+="|${i} days ago"
            done

            input+='|1 week ago'

            for ((i=2; i<=weeks; i++)); do
                input+="|${i} weeks ago"
            done
            ;;

        ~*" months ago" | *" months ago")
            local months="${value#\~}"
            months="${months%% *}"

            input='seconds ago|minutes ago|hour ago|hours ago|Today|Yesterday'

            for ((i=2; i<=6; i++)); do
                input+="|${i} days ago"
            done

            input+='|1 week ago'

            for ((i=2; i<=8; i++)); do
                input+="|${i} weeks ago"
            done

            for ((i=2; i<=months; i++)); do
                input+="|~${i} months ago"
            done
            ;;

        *)
            echo "Unknown input: $value" >&2
            return 1
            ;;
    esac
}

band_fetch_last_album() {
	OUTPUT="$(curl -s $1)"
	echo "$OUTPUT" | tac  | grep -v "/reviews/" | grep -m1 "https://" | grep -o "https://.*" | sed -E 's/https:\/\/.*class="[^"]*">([^<]*)<.*/\1 - /' | tr -d "\n"
    echo "$OUTPUT" | tac | grep -oP -m1 '">[0-2]\d{3}</td>' | grep -oP "[0-9]{4}"
	sleep 1
}

fetch_bands_and_filter() {
	OUTPUT=$("${CURLCOMMAND[@]}")
	OUTPUT=$(echo "$OUTPUT" | grep -P "a href=| ago\",|Today\",|Yesterday\",")
	read -p "Enter when (default=yesterday): " input
	input_builder "$input"
	CLEANLINKS=$(echo "$OUTPUT" | grep -P -B1 "$input" | grep -o "https://[^\\]*")
    [ -z "$CLEANLINKS" ] && echo "Nothing new!" && exit
	while IFS= read -r link; do
		artist=$(echo "$link" | sed -E 's/https:\/\/www.metal-archives.com\/bands\/([^\/]*)\/([0-9]*)/\1/') ;
		link=$(echo "$link" | sed -E 's/https:\/\/www.metal-archives.com\/bands\/([^\/]*)\/([0-9]*)/https:\/\/www.metal-archives.com\/band\/discography\/id\/\2\/tab\/all/') ;
		echo "$artist: " | urldecode ;
		band_fetch_last_album "$link" ;
	done <<< "$CLEANLINKS"
}

fetch_bands_and_filter
