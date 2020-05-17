#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -d|--deploy) deploy="$2"; shift ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

REGION="ap-southeast-2"
STACK_NAME="webapp-$deploy"
ARTIFACTS_BUCKET_NAME="webapp-artifacts-$deploy"
WEB_ASG_MAX=5


echo ">>>Deploy VPC and Security Groups. Env: $deploy<<<"
aws cloudformation deploy \
    --stack-name "${STACK_NAME}" \
    --template-file "${DIR}/cf-templates/vpc.yaml" \
    --region "${REGION}" \
    --capabilities CAPABILITY_IAM 


echo ">>>Deploy EFS File System. Env: $deploy<<<"
aws cloudformation deploy \
    --stack-name "${STACK_NAME}-efs" \
    --template-file "${DIR}/cf-templates/efs.yaml" \
    --region ${REGION} \
    --capabilities CAPABILITY_IAM \
    --parameter-overrides \
    ParentStackName="${STACK_NAME}" 


echo ">>>Deploy Elasticbeanstalk Web App. Env: $deploy<<<"
EFS_FILE_SYSTEM_ID=$(aws  --region ap-southeast-2 \
    cloudformation describe-stacks --stack-name ${STACK_NAME}-efs \
    --query 'Stacks[0].Outputs[?OutputKey==`FileSystem`].OutputValue' \
    --output text)

aws cloudformation deploy \
    --stack-name "${STACK_NAME}-eb" \
    --template-file "${DIR}/cf-templates/ebapp.yaml" \
    --region ${REGION} \
    --capabilities CAPABILITY_IAM \
    --parameter-overrides \
    ParentStackName="${STACK_NAME}" \
    WebAsgMax=5 \
    EfsID="${EFS_FILE_SYSTEM_ID}" \
    EBBucket="${ARTIFACTS_BUCKET_NAME}" \
    EC2KeyName="emr" \
    EnvType="${deploy}" 

# CREATE_STACK_STATUS=$(aws --region ${REGION} cloudformation describe-stacks \
#                         --stack-name ${STACK_NAME}-eb --query \
#                         'Stacks[0].StackStatus' --output text)

# while [[ $CREATE_STACK_STATUS == "REVIEW_IN_PROGRESS" ]] || [[ $CREATE_STACK_STATUS == "CREATE_IN_PROGRESS" ]]
# do
#     sleep 30
#     CREATE_STACK_STATUS=$(aws --region ${REGION}  \
#                         cloudformation describe-stacks --stack-name ${STACK_NAME}-eb \
#                          --query 'Stacks[0].StackStatus' --output text)
# done
exit 0
