#!/usr/bin/env bash

script_name=$(basename "${BASH_SOURCE[0]}")

usage() {
    cat <<EOF
Usage: ${script_name} [-hv] FILE [FILE...]

Repace the contents of input in accordance with FILE. It uses 'fq' to
read configurations from FILE. Therefore, it supports all the formats
supported by 'fq'.

By default placeholders must be in the form '{{ placeholder }}'.

Options:
  -f, --fq-options OPTS       WIP. Options for the 'jq' command
                              (e.g. '-d yaml')
  -h, --help                  Print this help and exit
  -i, --input FILE            Input file (default: stdin)
  -l, --left-delimiter STR    String that delimites placeholders from
                              the left (default: '{{ ')
  -o, --output FILE           Output file (default: stdout)
  -r, --right-delimiter STR   String that delimites placeholders from
                              the right (default: ' }}')
  -v, --verbose               Print script debug info
EOF
  exit
}

msg() { echo >&2 -e "${1-}"; }
die() {
    # User defined exit codes:
    #   64: Placeholder not found in configuration files
    msg "$1"
    exit "${2-1}"
}

parse_params() {
    # default values of variables set from params
    input_file=/dev/stdin
    left_delimiter='{{ '
    output_file=/dev/stdout
    right_delimiter=' }}'

    while :; do
        case "${1-}" in
            -r | --right-delimiter) right_delimiter="${2-}"; shift ;;
            -l | --left-delimiter) left_delimiter="${2-}"; shift ;;
            -h | --help) usage ;;
            -i | --input) input_file="${2-}"; shift ;;
            -o | --output) output_file="${2-}"; shift ;;
            -v | --verbose) set -x ;;
            -?*) die "Unknown option: $1" ;;
            *) break ;;
        esac
        shift
    done

    args=("$@")

    # check required params and arguments
    [[ ${#args[@]} -eq 0 ]] && die "Missing script arguments"
    [[ -z "${right_delimiter-}" ]] && \
        die "Missing required parameter: right_delimiter"
    [[ -z "${left_delimiter-}" ]] && \
        die "Missing required parameter: left_delimiter"
    [[ -z "${input_file-}" ]] && \
        die "Missing required parameter: input_file"
    [[ -z "${output_file-}" ]] && \
        die "Missing required parameter: output_file"

    return 0
}

get_placeholder() {
    # Arguments:
    #   1: the left delimiter
    #   2: the right delimiter
    #   3: string to search in
    local tmp
    ptn="[0-9a-zA-Z._-]+"

    # escape all chars in delimiters to not fail next regex
    # See: https://apple.stackexchange.com/a/363400
    # Had to exclude '<' and '>' from this trick for some reason
    fp="$(sed 's/[^<>]/\\&/g' <(echo "$1"))"
    bp="$(sed 's/[^<>]/\\&/g' <(echo "$2"))"

    # search for placeholder
    # `head -n 1` to select only the first match in case there's more
    # than one per line
    tmp="$(grep -o -m 1 -E "${fp}${ptn}${bp}" <(echo "$3") | head -n 1)"

    # remove leading and trailing delimiter strings
    tmp="$(sed -E "s/^${fp}//" <(echo "$tmp"))"
    tmp="$(sed -E "s/${bp}$//" <(echo "$tmp"))"

    echo -n "${tmp}"
}

get_config() {
    # Arguments:
    #   1: the value to extract
    #   2: config file(s) to search in
    #TODO: handle multiple config files
    local tmp

    tmp="$(fq "$1" "$2")"
    tmp="${tmp//\"/}"

    if [ "$tmp" == "null" ]; then
        echo ''
    else
        echo "$tmp"
    fi
}

replace_placeholder() {
    # Arguments:
    #   1: the placeholder to replace
    #   2: the value to replace it with
    #   3: the string into which do the replacement
    sed "s/${1}/${2}/g" <(echo "$3")
}

main() {
    parse_params "$@"

    output_stream=$(<"$input_file")
    config_files=("${args[@]}")

    local tmp
    while true; do
        pholder=$(get_placeholder "$left_delimiter" \
								  "$right_delimiter" "$output_stream")
        if [ -z "$pholder" ]; then
            break;  # no more placeholders
        fi

        value="$(get_config "$pholder" "${config_files[*]}")"
        if [ -z "$value" ]; then
            die "Placeholder '$pholder' not found." 64
        fi

        output_stream="$(replace_placeholder \
            "${left_delimiter}${pholder}${right_delimiter}" \
            "$value" "$output_stream")"
    done
    echo >"$output_file" "$output_stream"
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  set -eu -o pipefail
  main "$@"
fi
