#!/usr/bin/env bash

script_name=$(basename "${BASH_SOURCE[0]}")

usage() {
    cat <<EOF
Usage: ${script_name} [options] FILE [FILE...]

Read a template, fill in placeholders in accordance with the values
stored in configuration FILE and output the result. By default, the
template is read from stdin and output is sent to stdout. If more than
one FILE is given, configurations from the first FILE will be
preferred over the second one and so on.

By default, template placeholders are expected to be in the form
'{{ placeholder }}'.

It uses 'fq' to read from configuration FILE. Therefore, it supports
all the formats supported by 'fq'.

Options:
  -b, --blanks       Allow for missing values in configuration FILE
                     and replace them with blanks instead of failing
  -f, --fq-options OPTS
                     Options for the 'jq' command (e.g. '-d yaml')
  -h, --help         Print this help and exit
  -i, --input FILE   Input file (default: stdin)
  -l, --left-delimiter STR
                     String that delimits placeholders from the left
                     (default: '{{ ')
  -o, --output FILE  Output file (default: stdout)
  -r, --right-delimiter STR
                     String that delimits placeholders from the right
                     (default: ' }}')
  -v, --verbose      Print script debug info
EOF
#   -u, --unchanged    TODO. Allow for missing values in configuration
#                      FILE and leave them unchanged instead of failing
    exit
}

msg() { echo >&2 -e "${script_name}:" "${1-}"; }
die() {
    # User defined exit codes:
    #   64: Placeholder not found in configuration files
    msg "$1"
    exit "${2-1}"
}

parse_params() {
    # default values of variables set from params
    blanks_flag=0
    fq_opts=''
    input_file=/dev/stdin
    left_delimiter='{{ '
    output_file=/dev/stdout
    right_delimiter=' }}'

    while :; do
        case "${1-}" in
            -b | --blanks)  blanks_flag=1 ;;
            -f | --fq-options) fq_opts="${2-}"; shift ;;
            -h | --help) usage ;;
            -i | --input) input_file="${2-}"; shift ;;
            -l | --left-delimiter) left_delimiter="${2-}"; shift ;;
            -o | --output) output_file="${2-}"; shift ;;
            -r | --right-delimiter) right_delimiter="${2-}"; shift ;;
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
    ptn='[0-9a-zA-Z"._-]+'

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
    #   1:  the value to extract
    #   2:  options for fq
    #   3+: config file(s) to search in
    local args files fq_opts pholder value tmp

    pholder="${1-}"
    fq_opts="${2-}"
    files=("${@:3}")

    value=''
    for f in "${files[@]}"; do
        # shellcheck disable=SC2086
        tmp="$(fq $fq_opts "$pholder" "$f")"
        tmp="${tmp/#\"/}"
        tmp="${tmp/%\"/}"

        if [ "$tmp" == 'null' ]; then
            continue
        else
            value="$tmp"
            break
        fi
    done

    echo "$value"
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
        # Search for a placeholder in template file
        pholder=$(get_placeholder "$left_delimiter" \
                                  "$right_delimiter" "$output_stream")
        if [ -z "$pholder" ]; then
            break;  # no more placeholders
        fi

        # Search for a value for the placeholder in config files
        value="$(get_config "$pholder" "$fq_opts" "${config_files[@]}")"
        if [ -z "$value" ] && [ "$blanks_flag" -eq 0 ]; then
            die "Value for '$pholder' not found." 64
        fi

        # Replace placeholders with value
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
