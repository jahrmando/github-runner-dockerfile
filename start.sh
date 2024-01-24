#!/bin/bash

ORGANIZATION=$ORG
ACCESS_TOKEN=$TOKEN
RUNNER_GROUP=$GROUP

echo "ORGANIZATION ${ORGANIZATION}"

REG_TOKEN=$(curl -X POST -H "Authorization: token ${ACCESS_TOKEN}" -H "Accept: application/vnd.github+json" https://api.github.com/orgs/${ORGANIZATION}/actions/runners/registration-token | jq .token --raw-output)

cd /home/runner/actions-runner

./config.sh --url https://github.com/${ORGANIZATION} --token ${REG_TOKEN} --runnergroup ${RUNNER_GROUP}

cleanup() {
    echo "Removing runner..."
    ./config.sh remove --unattended --token ${REG_TOKEN}
}

trap 'cleanup; exit 130' INT
trap 'cleanup; exit 143' TERM

./run.sh & wait $!
