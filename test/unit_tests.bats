setup_file() {
    load 'common_setup'
    _common_setup_file
}

setup() {
    load 'common_setup'
    _common_setup

    # Load binplate code to test its functions
    source ./binplate.sh
}

teardown_file() {
    rm -rf "$_TEMP"
}

@test "get placeholder with single brackets" {
    run get_placeholder "{ " " }" "Hello { .world }."
    assert_output ".world"
}
@test "get placeholder with double brackets" {
    run get_placeholder "{{ " " }}" "Hello {{ .world }}."
    assert_output ".world"
}

@test "get placeholder with angle brackets" {
    run get_placeholder '<< ' ' >>' "Hello << .world >>."
    assert_output ".world"
}

@test "get placeholder no placeholders" {
    run get_placeholder '<<' '>>' "Hello world."
    [ -z "$output" ]
}

@test "get placeholder two same line" {
    run get_placeholder '<< ' ' >>' "Hello << .world >><< .next >>"
    assert_output ".world"
}

@test "get placeholder with dash" {
    run get_placeholder "{{ " " }}" "Hello {{ .my-world }}."
    assert_output ".my-world"
}

@test "get config" {
    run get_config '.type' "$_CONFIG"
    assert_output "dog"
}

@test "get config placeholder with dash" {
    run get_config '."with-dash"' "$_CONFIG"
    assert_output "serpent"
}

@test "get config returns empty string on missing config" {
    run get_config '.foo' "$_CONFIG"
    assert_output ''
}

@test "get config two files" {
    run get_config '.race' "${_CONFIG}" "${_CONFIG_2}"
    assert_output "Bar"
}

@test "replace placeholder single brackets" {
    run replace_placeholder "{ .world }" "Earth" "Hello { .world }."
    assert_output "Hello Earth."
}

@test "replace placeholder double brackets" {
    run replace_placeholder "{{ .world }}" "Earth" "Hello {{ .world }}."
    assert_output "Hello Earth."
}

@test "replace placeholder angle brackets" {
    run replace_placeholder "<< .world >>" "Earth" "Hello << .world >>."
    assert_output "Hello Earth."
}
