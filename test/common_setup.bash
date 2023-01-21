#!/usr/bin/env bash

_common_setup_file() {

    _TEMP=$(mktemp -d)
    _CONFIG=${_TEMP}/config.yml
    _CONFIG_2=${_TEMP}/config2.yml

    cat <<EOF > "${_CONFIG}"
name: Foo
type: dog
with-dash: serpent
EOF
    cat <<EOF > "${_CONFIG_2}"
race: Bar
health: could be better
EOF

    export _TEMP
    export _CONFIG
    export _CONFIG_2
}

_common_setup() {
    # Load supporting libraries
    bats_load_library bats-assert
    bats_load_library bats-support
}
