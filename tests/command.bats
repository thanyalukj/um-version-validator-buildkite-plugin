#!/usr/bin/env bats
# shellcheck disable=SC2059,SC2086,SC2140

load "$BATS_PLUGIN_PATH/load.bash"

# Uncomment the following line to debug stub failures
# export BUILDKITE_AGENT_STUB_DEBUG=/dev/tty

getVersionAndroid() { 
    echo "GetAndroidVersion: $1"
}

@test "GIVEN base_branch != main THEN do not test or publish" {
    export BUILDKITE_PLUGIN_UM_VERSION_VALIDATOR_PLATFORM="android-contract"
    export BUILDKITE_PLUGIN_UM_VERSION_VALIDATOR_BASE_BRANCH="not-main-branch"
    export BUILDKITE_PLUGIN_UM_VERSION_VALIDATOR_CURRENT_BRANCH="pr-branch"
    export BUILDKITE_PULL_REQUEST_LABELS=""
    
    export -f getVersionAndroid # stub getVersionAndroid

    stub buildkite-agent \
        "annotate '(android-contract) - Not merging into main branch, no tests will run and no publish will happen.' --style 'info' --context 'android-contract-max-versions' : echo 'Not merging to main'"

    run "$PWD/hooks/command"

    assert_success
    assert_output --partial "Not merging to main"

    unstub buildkite-agent
}

@test "GIVEN version is UNDEFINED main THEN show error" {
    export BUILDKITE_PLUGIN_UM_VERSION_VALIDATOR_PLATFORM="android-contract"
    export BUILDKITE_PLUGIN_UM_VERSION_VALIDATOR_BASE_BRANCH="main"
    export BUILDKITE_PLUGIN_UM_VERSION_VALIDATOR_CURRENT_BRANCH="pr-branch"
    export BUILDKITE_PULL_REQUEST_LABELS=""
    
    export -f getVersionAndroid # stub getVersionAndroid

    stub buildkite-agent \
        "annotate '(android-contract) - Could not find version code on pr-branch (new branch).  Have you deleted the identifying file for your platform?' --style 'error' --context 'android-contract-max-versions' : echo 'Could not find version code'"

    run "$PWD/hooks/command"

    assert_failure 105
    assert_output --partial "Could not find version code"

    unstub buildkite-agent
}