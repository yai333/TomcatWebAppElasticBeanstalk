#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -d|--deploy) deploy="$2"; shift ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

STACK_NAME="web-artifect-$deploy"
REGION="ap-southeast-2"

# Deploy VPC and Security Groups
aws cloudformation deploy \
    --stack-name "${STACK_NAME}" \
    --template-file "${DIR}/cf-templates/s3.yaml" \
    --region "${REGION}" \
    --parameter-overrides \
    EnvType="${deploy}" \
    --capabilities CAPABILITY_IAM \
    && aws cloudformation wait stack-create-complete \
    --stack-name "${STACK_NAME}"  || \
    aws cloudformation describe-stack-events \
    --stack-name "${STACK_NAME}" \
    --max-items 2 | \
    grep -B2 -A8 CREATE_FAILED


exit 0
