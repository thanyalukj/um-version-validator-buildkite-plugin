#!/usr/bin/env bash

function get_version_android() {
    local ref=$1
    local file_path=$2

    if git cat-file -e "${ref}:${file_path}/build.gradle" 2>/dev/null; then
        git show "${ref}:${file_path}/build.gradle" | grep versionName | tr \" "\n" | grep -e "\."
    else
        echo "UNDEFINED"
    fi
}

function get_version_ios() {
    local ref=$1
    local podspec=$2
    
    if git cat-file -e "$ref:${podspec}" 2>/dev/null; then
        git show "${ref}:${podspec}" | grep -m 1 s.version | tr \' "\n" | tail -2 | head -1
    else
        echo "UNDEFINED"
    fi
}

function get_version_react() {
    local ref=$1
    local file_path=$2
    
    if git cat-file -e "$ref:${file_path}/package.json" 2>/dev/null; then
        git show "${ref}:${file_path}/package.json" | grep version | tr \" "\n" | grep -e "\."
    else
        echo "UNDEFINED"
    fi
}

function check_skip_alpha_label() {
    local pr_labels=$1
    local skip_label='skip-alpha'

    if [[ "$BUILDKITE_PULL_REQUEST" == "false"]]; then
        echo true
    elif [[ "$pr_labels" == *"$skip_label"* ]]; then
        echo true
    else
        echo false
    fi
}

function ios_pod_spec() {
    local ref=$1
    local ios_platform=$2

    if git cat-file -e "${ref}:fanbrew.json" 2>/dev/null; then
        git show "${ref}:fanbrew.json" | jq -r "(.platforms.ios.${ios_platform}.podspec)?"
    else
        echo "UNDEFINED"
    fi
}