#!/usr/bin/env bats
# shellcheck disable=SC2059,SC2086,SC2140

load "$BATS_PLUGIN_PATH/load.bash"

command_hook="$PWD/hooks/command"

DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")" >/dev/null 2>&1 && pwd)"
PATH="$DIR/../hooks:$PATH"

# export BUILDKITE_AGENT_STUB_DEBUG=/dev/tty

setup() {
    export BUILDKITE_PLUGIN_UM_VERSION_VALIDATOR_PLATFORM="android-contract"
    export BUILDKITE_PULL_REQUEST_LABELS=""
}

@test "GIVEN base_branch != main THEN do not test or publish" {
    export BUILDKITE_PLUGIN_UM_VERSION_VALIDATOR_BASE_BRANCH="not-main-branch"
    export BUILDKITE_PLUGIN_UM_VERSION_VALIDATOR_CURRENT_BRANCH="pr-branch"
    
    stub buildkite-agent \
        "annotate '(android-contract) - Not merging into main. Skipping tests and publish.' --style 'info' --context 'android-contract-max-versions' : echo 'Not merging to main'"

    run "${command_hook}"

    assert_success
    assert_output --partial "Not merging to main"

    unstub buildkite-agent
}

@test "GIVEN version on PR branch contains -alpha.0 THEN stop and skip tests" {
    export BUILDKITE_PLUGIN_UM_VERSION_VALIDATOR_BASE_BRANCH="main"
    export BUILDKITE_PLUGIN_UM_VERSION_VALIDATOR_CURRENT_BRANCH="pr-branch"

    stub check_skip_alpha_label \
        " \* : echo true" 

    stub get_version_android \
        " 'origin/main' 'android/contract' : echo '1.0.0'" \
        " 'origin/pr-branch' 'android/contract' : echo '1.0.1-alpha.0'"

    # version_new contains -alpha.0
    stub grep \
        "-ce \* \* \* : echo '1'"

    stub buildkite-agent \
        "annotate '(android-contract) - Detected x.x.x-alpha.0 version. Assuming base project files. Skipping tests and publish.' --style 'info' --context 'android-contract-max-versions' : echo 'Detected x.x.x-alpha.0 version'" \

    run "${command_hook}"

    assert_success
    assert_output --partial "Detected x.x.x-alpha.0 version"

    unstub check_skip_alpha_label
    unstub get_version_android
    unstub grep
    unstub buildkite-agent
}

@test "GIVEN new version on PR branch is UNDEFINED THEN annotate version not found" {
    export BUILDKITE_PLUGIN_UM_VERSION_VALIDATOR_BASE_BRANCH="main"
    export BUILDKITE_PLUGIN_UM_VERSION_VALIDATOR_CURRENT_BRANCH="pr-branch"

    stub get_version_android \
        " 'origin/main' 'android/contract' : echo '1.0.0'" \
        " 'origin/pr-branch' 'android/contract' : echo 'UNDEFINED'"

    stub buildkite-agent \
        "annotate \* --style \* --context \* : echo 'Version not found'"

    run "${command_hook}"

    assert_failure 105
    assert_output --partial "Version not found"

    unstub get_version_android
    unstub buildkite-agent
}

@test "GIVEN version on main and pr branch the same THEN annotate no version change" {
    export BUILDKITE_PLUGIN_UM_VERSION_VALIDATOR_BASE_BRANCH="main"
    export BUILDKITE_PLUGIN_UM_VERSION_VALIDATOR_CURRENT_BRANCH="pr-branch"

    stub get_version_android \
        " 'origin/main' 'android/contract' : echo '1.0.0'" \
        " 'origin/pr-branch' 'android/contract' : echo '1.0.0'"

    stub buildkite-agent \
        "annotate \* --style \* --context \* : echo 'No version change'" \
        "meta-data set 'skip-test' 'false' : echo 'set skip-test to false'"

    run "${command_hook}"

    assert_success
    assert_output --partial "No version change"

    unstub get_version_android
    unstub buildkite-agent
}

@test "GIVEN old and new versions are non-alpha AND skip-alpha is false THEN exit with E_VERSION_CANNOT_MOVE_FROM_RELEASE_TO_RELEASE" {
    export BUILDKITE_PLUGIN_UM_VERSION_VALIDATOR_BASE_BRANCH="main"
    export BUILDKITE_PLUGIN_UM_VERSION_VALIDATOR_CURRENT_BRANCH="pr-branch"

    stub check_skip_alpha_label \
        " \* : echo false"

    stub get_version_android \
        " 'origin/main' 'android/contract' : echo '1.0.0'" \
        " 'origin/pr-branch' 'android/contract' : echo '1.0.1'"

    stub buildkite-agent \
        "annotate \* --style \* --context \* : echo 'Cannot move release to release'"

    run "${command_hook}"

    assert_failure 106
    assert_output --partial "Cannot move release to release"

    unstub check_skip_alpha_label
    unstub get_version_android
    unstub buildkite-agent
}

@test "GIVEN old and new versions are non-alpha AND skip-alpha is true THEN allow to move from release to release" {
    export BUILDKITE_PLUGIN_UM_VERSION_VALIDATOR_BASE_BRANCH="main"
    export BUILDKITE_PLUGIN_UM_VERSION_VALIDATOR_CURRENT_BRANCH="pr-branch"

    stub check_skip_alpha_label \
        " \* : echo true"
    stub get_version_android \
        " 'origin/main' 'android/contract' : echo '1.0.0'" \
        " 'origin/pr-branch' 'android/contract' : echo '1.0.1'"
    stub ios_pod_spec \
        " \* 'contract' : echo 'contract.podspec'" \
        " \* 'library' : echo 'library.podspec'"
    stub echo \
        "'1.0.0' > versions.txt : echo '1.0.0 written to versions.txt'" \
        "'1.0.1' >> versions.txt : echo '1.0.1 appended to versions.txt'"
    stub sort \
        " -V \* \* \* : echo '1.0.1'"
    stub buildkite-agent \
        "annotate \* --style \* --context \* : echo '1.0.1 is valid'" \
        "meta-data set 'skip-test' 'false' : echo 'set skip-test to false'" \
        "meta-data set 'skip-publish' 'false' : echo 'set skip-publish to false'"
    stub git \
        " fetch : echo 'git fetch'" 

    run "${command_hook}"

    assert_success
    assert_output --partial "1.0.1 is valid"

    unstub check_skip_alpha_label
    unstub get_version_android
    unstub ios_pod_spec
    unstub sort
    unstub buildkite-agent
    unstub git
}

@test "GIVEN new version is alpha and higher than main THEN new version is valid" {
    export BUILDKITE_PLUGIN_UM_VERSION_VALIDATOR_BASE_BRANCH="main"
    export BUILDKITE_PLUGIN_UM_VERSION_VALIDATOR_CURRENT_BRANCH="pr-branch"

    stub get_version_android \
        " 'origin/main' 'android/contract' : echo '1.0.0'" \
        " 'origin/pr-branch' 'android/contract' : echo '1.0.1-alpha.1'"

    stub check_skip_alpha_label \
        " \* : echo true"
    stub ios_pod_spec \
        " \* 'contract' : echo 'contract.podspec'" \
        " \* 'library' : echo 'library.podspec'"
    stub echo \
        "'1.0.0' > versions.txt : echo '1.0.0 written to versions.txt'" \
        "'1.0.1' > versions.txt : echo '1.0.1 appended to versions.txt'"
    stub sort \
        " -V \* \* \* : echo '1.0.1-alpha.1'"
    stub buildkite-agent \
        "annotate \* --style \* --context \* : echo '1.0.1-alpha.1 is valid'" \
        "meta-data set 'skip-test' 'false' : echo 'set skip-test to false'" \
        "meta-data set 'skip-publish' 'false' : echo 'set skip-publish to false'"
    stub git \
        " fetch : echo 'git fetch'" 

    run "${command_hook}"

    assert_success
    assert_output --partial "1.0.1-alpha.1 is valid"

    unstub check_skip_alpha_label
    unstub get_version_android
    unstub sort
    unstub buildkite-agent
    unstub git
}

@test "GIVEN new version is alpha and lower than main THEN new version is invalid" {
    export BUILDKITE_PLUGIN_UM_VERSION_VALIDATOR_BASE_BRANCH="main"
    export BUILDKITE_PLUGIN_UM_VERSION_VALIDATOR_CURRENT_BRANCH="pr-branch"

    stub get_version_android \
        " 'origin/main' 'android/contract' : echo '1.0.0.alpha.4'" \
        " 'origin/pr-branch' 'android/contract' : echo '1.0.0-alpha.1'"

    stub check_skip_alpha_label \
        " \* : echo true"
    stub ios_pod_spec \
        " \* 'contract' : echo 'contract.podspec'" \
        " \* 'library' : echo 'library.podspec'"
    stub echo \
        "'1.0.0.alpha.4' > 'versions.txt' : echo '1.0.0.alpha.4 written to versions.txt'" \
        "'1.0.0-alpha.1' >> 'versions.txt' : echo '1.0.0-alpha.1 appended to versions.txt'"
    stub sort \
        " -V \* \* \* : echo '1.0.0.alpha.4'"
    stub buildkite-agent \
        "annotate \* --style \* --context \* : echo '1.0.0-alpha.1 is invalid'"

    run "${command_hook}"

    assert_failure $E_VERSION_SMALLER_THAN_BEFORE
    assert_output --partial "Invalid: 1.0.0-alpha.1 < 1.0.0.alpha.4"
    assert_output --partial "1.0.0-alpha.1 is invalid"

    unstub check_skip_alpha_label
    unstub ios_pod_spec
    unstub get_version_android
    unstub sort
    unstub buildkite-agent
}

@test "GIVEN new version is non-alpha and higher than main THEN new version is valid" {
    export BUILDKITE_PLUGIN_UM_VERSION_VALIDATOR_BASE_BRANCH="main"
    export BUILDKITE_PLUGIN_UM_VERSION_VALIDATOR_CURRENT_BRANCH="pr-branch"

    stub get_version_android \
        " 'origin/main' 'android/contract' : echo '1.0.1-alpha.4'" \
        " 'origin/pr-branch' 'android/contract' : echo '1.0.1'"

    stub check_skip_alpha_label \
        " \* : echo true"
    stub ios_pod_spec \
        " \* 'contract' : echo 'contract.podspec'" \
        " \* 'library' : echo 'library.podspec'"
    stub echo \
        "'1.0.1-alpha.4' > versions.txt : echo '1.0.1-alpha.4 written to versions.txt'" \
        "'1.0.1' >> versions.txt : echo '1.0.1 appended to versions.txt'"
    stub sort \
        " -V \* \* \* : echo '1.0.1'"
    stub buildkite-agent \
        "annotate \* --style \* --context \* : echo '1.0.1 is valid'" \
        "meta-data set 'skip-test' 'false' : echo 'set skip-test to false'" \
        "meta-data set 'skip-publish' 'false' : echo 'set skip-publish to false'"
    stub git \
        " fetch : echo 'git fetch'" 

    run "${command_hook}"

    assert_success
    assert_output --partial "1.0.1 is valid"

    unstub check_skip_alpha_label
    unstub get_version_android
    unstub ios_pod_spec
    unstub sort
    unstub buildkite-agent
    unstub git
}

@test "GIVEN new version is non-alpha and lower than main THEN new version is invalid" {
    export BUILDKITE_PLUGIN_UM_VERSION_VALIDATOR_BASE_BRANCH="main"
    export BUILDKITE_PLUGIN_UM_VERSION_VALIDATOR_CURRENT_BRANCH="pr-branch"

    stub get_version_android \
        " 'origin/main' 'android/contract' : echo '1.0.1-alpha.4'" \
        " 'origin/pr-branch' 'android/contract' : echo '1.0.0'"

    stub check_skip_alpha_label \
        " \* : echo true"
    stub ios_pod_spec \
        " \* 'contract' : echo 'contract.podspec'" \
        " \* 'library' : echo 'library.podspec'"
    stub echo \
        "'1.0.1-alpha.4' > versions.txt : echo '1.0.1-alpha.4 written to versions.txt'" \
        "'1.0.0' >> versions.txt : echo '1.0.1 appended to versions.txt'"
    stub sort \
        " -V \* \* \* : echo '1.0.1-alpha.4'"
    stub buildkite-agent \
        "annotate \* --style \* --context \* : echo '1.0.0 is invalid'"

    run "${command_hook}"

    assert_failure $E_VERSION_SMALLER_THAN_BEFORE
    assert_output --partial "Invalid: 1.0.0 < 1.0.1-alpha.4"
    assert_output --partial "1.0.0 is invalid"

    unstub check_skip_alpha_label
    unstub get_version_android
    unstub ios_pod_spec
    unstub sort
    unstub buildkite-agent
}