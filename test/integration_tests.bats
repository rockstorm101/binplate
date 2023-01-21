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

make_template() {
    # Arguments:
    #   *: line(s) to write to file
    local tempfile
    tempfile=$(mktemp --tmpdir=$_TEMP)
    for line in "$@"; do
        echo "$line" >> "$tempfile"
    done
    echo "$tempfile"
}

@test "single line replace" {
    template="$(make_template 'Good {{ .type }}, {{ .name }}!')"
    run ./binplate.sh -i "$template" "$_CONFIG"
    assert_output "Good dog, Foo!"
}

@test "multi-line replace" {
    template="$(make_template 'Good {{ .type }}, {{ .name }}!' \
                              'Good {{ .type }}, {{ .name }}!')"
    run ./binplate.sh -i "$template" "$_CONFIG"
    expected_output="$(echo -e 'Good dog, Foo!\nGood dog, Foo!')"
    assert_output "$expected_output"
}

@test "placeholder with spaces" {
    template="$(make_template 'First: {{ .health }}; second: {{ .race }}')"
    run ./binplate.sh -i "$template" "$_CONFIG_2"
    assert_output "First: could be better; second: Bar"
}

@test "fail if placeholder not found in config" {
    template="$(make_template 'First: {{ .gnome }}; second: {{ .race }}')"
    run ./binplate.sh -i "$template" "$_CONFIG_2"
    assert_failure 64
}

@test "replace from multiple config files" {
    template="$(make_template 'Good {{ .race }}, {{ .name }}!' \
                              'Good {{ .type }}, {{ .health }}!')"
    run ./binplate.sh -i "$template" "$_CONFIG" "$_CONFIG_2"
    expected_output="$(echo -e 'Good Bar, Foo!\nGood dog, could be better!')"
    assert_output "$expected_output"
}

@test "replace with fq options" {
    template="$(make_template 'Good {{ .type }}, {{ .name }}!')"
    run ./binplate.sh -f "-d yaml" -i "$template" "$_CONFIG"
    assert_output "Good dog, Foo!"
}

@test "replace with blanks" {
    template="$(make_template 'Good {{ .pet }}, {{ .name }}!')"
    run ./binplate.sh -b -i "$template" "$_CONFIG" 2>/dev/null
    assert_output "Good , Foo!"
}
