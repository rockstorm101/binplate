setup_file() {
    load 'common_setup'
    _common_setup_file
}

setup() {
    load 'common_setup'
    _common_setup
}

teardown_file() {
    rm -rf "$_TEMP"
}

@test "single line replace" {
    template=$(mktemp --tmpdir=$_TEMP)
    cat <<EOF >${template}
Good {{ .type }}, {{ .name }}!
EOF
    run ./binplate.sh -i "$template" "$_CONFIG"
    assert_output "Good dog, Foo!"
}

@test "multi-line replace" {
    template=$(mktemp --tmpdir=$_TEMP)
    cat <<EOF >${template}
Good {{ .type }}, {{ .name }}!
Good {{ .type }}, {{ .name }}!
EOF

    out_file=$(mktemp --tmpdir=$_TEMP)
    cat <<EOF >${out_file}
Good dog, Foo!
Good dog, Foo!
EOF
    run ./binplate.sh -i "$template" "$_CONFIG"
    expected_output="$(cat "$out_file")"
    assert_output "$expected_output"
}

@test "placeholder with spaces" {
    template=$(mktemp --tmpdir=$_TEMP)
    cat <<EOF >${template}
First: {{ .health }}; second: {{ .race }}
EOF
    run ./binplate.sh -i "$template" "$_CONFIG_2"
    assert_output "First: could be better; second: Bar"
}

@test "fail if placeholder not found in config" {
    template=$(mktemp --tmpdir=$_TEMP)
    cat <<EOF >${template}
First: {{ .gnome }}; second: {{ .race }}
EOF
    run ./binplate.sh -i "$template" "$_CONFIG_2"
    assert_failure 64
}

@test "replace from multiple config files" {
    template=$(mktemp --tmpdir=$_TEMP)
    cat <<EOF >${template}
Good {{ .race }}, {{ .name }}!
Good {{ .type }}, {{ .health }}!
EOF

    out_file=$(mktemp --tmpdir=$_TEMP)
    cat <<EOF >${out_file}
Good Bar, Foo!
Good dog, could be better!
EOF
    run ./binplate.sh -i "$template" "$_CONFIG" "$_CONFIG_2"
    expected_output="$(cat "$out_file")"
    assert_output "$expected_output"
}

@test "replace with fq options" {
    template=$(mktemp --tmpdir=$_TEMP)
    cat <<EOF >${template}
Good {{ .type }}, {{ .name }}!
EOF
    run ./binplate.sh -f "-d yaml" -i "$template" "$_CONFIG"
    assert_output "Good dog, Foo!"
}
