#!/bin/bash

function hash_file {
    local FILE=$1

    if [[ "$OSTYPE" == "darwin"* ]]; then
        shasum -a 256 "$FILE" | awk '{print $1}'
    elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
        sha256sum "$FILE" | awk '{print $1}'
    fi
}

if git branch --show-current | grep -q "main"; then
    echo "$(git rev-parse HEAD)" >./restore.cachekey
    echo "$(git rev-parse HEAD)" >./save.cachekey
else
    PLATFORM=$1
    TARGET_BRANCH=$2
    NUM_COMMITS=$(($(git rev-list --count origin/${TARGET_BRANCH}..HEAD) - 1))
    KEY_PREFIX=${PLATFORM}-cmake-build-cache

    gh extension install actions/gh-actions-cache

    for i in $(seq 0 $NUM_COMMITS); do
        git diff origin/${TARGET_BRANCH}..HEAD~${i} | grep -v -F "index" >./${i}.diff

        if [[ $? -ne 0 ]]; then
            break
        fi

        KEY_SUFFIX="$(hash_file ./${i}.diff)"
        rm "./${i}.diff"
        KEY=${KEY_PREFIX}-${KEY_SUFFIX}

        if [[ $i -eq 0 ]]; then
            echo "For saving, use the key: ${KEY} (./save.cachekey)"
            echo "$KEY" >./save.cachekey
        fi

        CACHE_HIT=$(gh actions-cache list --key $KEY | grep -q '$KEY' && echo 'true' || echo 'false')

        if [[ $CACHE_HIT == "true" ]]; then
            echo "Found a cache for key ${KEY}!"
            echo "For restoring, use the key: ${KEY} (./restore.cachekey)"
            echo "$KEY" >./restore.cachekey
            exit 0
        fi
    done

    KEY="${KEY_PREFIX}-$(git rev-parse origin/${TARGET_BRANCH})"
    echo "Failed to find any caches based on the diff! Falling back to use the target branch's commit SHA instead..."
    echo "For restoring, use the key: ${KEY} (./restore.cachekey)"
    echo "$KEY" >./restore.cachekey
fi
