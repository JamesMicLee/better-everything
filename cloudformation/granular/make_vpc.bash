#!/bin/bash

#Make sure jq is installed
set +e
/usr/bin/yum install -y jq
set -e
/usr/bin/rpm -q jq

#Set an alias for aws.
/usr/bin/alias aws='/usr/bin/aws'

#Make an empty VPC
aws cloudformation create-stack  \
  --template-body file://./vpc_base.json  \
  --stack-name ${1:-TestStack}  \
  --region eu-west-2 
aws cloudformation describe-stacks --region eu-west-2 | jq .[][] | egrep "StackStatus|StackName\":"

#Wait for the vpc to be created
aws cloudformation wait stack-create-complete --stack-name ${1:-TestStack} --region eu-west-2
aws cloudformation describe-stacks --region eu-west-2 | jq .[][] | egrep "StackStatus|StackName\":"

#Grab the identity of the VPC
THEVPC=`aws cloudformation describe-stack-resources --stack-name ${1:-TestStack} --region eu-west-2 \
       | jq .[][][]  \
       | grep vpc`
echo $THEVPC
