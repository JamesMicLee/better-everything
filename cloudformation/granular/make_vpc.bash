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

#Grab the identity of the VPC
THEVPC=`aws cloudformation describe-stack-resources --stack-name ${1:-TestStack} --region eu-west-2 \
       | jq .[][][]  \
       | grep vpc`
echo $THEVPC

#Grab the dhcp
THEDHC=`aws cloudformation describe-stack-resources --stack-name ${1:-TestStack} --region eu-west-2 \
       | jq .[][]  \
       | grep '"PhysicalResourceId": "dopt'`
echo $THEDHC

#Grab the route
THEROU=`aws cloudformation describe-stack-resources --stack-name ${1:-TestStack} --region eu-west-2 \
       | jq .[][][]  \
       | grep rtb`
echo $THEROU

#Grab the identity of the ACL
THEACL=`aws cloudformation describe-stack-resources --stack-name ${1:-TestStack} --region eu-west-2 \
       | jq .[][][] \
       | grep acl`
echo $THEACL

#create acl entries
aws cloudformation create-stack  \
  --template-body file://./vpc_acls.json  \
  --stack-name ${1:-TestStack}AclEntry  \
  --parameters  \
    ParameterKey=myVpcName,ParameterValue=${THEVPC}  \
    ParameterKey=myNetworkAcl,ParameterValue=${THEACL}  \
  --region eu-west-2
aws cloudformation describe-stacks --region eu-west-2 | jq .[][] | egrep "StackStatus|StackName\":"
aws cloudformation wait stack-create-complete --stack-name ${1:-TestStack}AclEntry --region eu-west-2

#Grab the ACL Entries
THEACE=`aws cloudformation describe-stack-resources --stack-name ${1:-TestStack}AclEntry --region eu-west-2 \
       | jq .[][][] \
       | grep acl`
echo $THEACE

#create a security group
aws cloudformation create-stack  \
  --template-body file://./vpc_security_group.json  \
  --stack-name ${1:-TestStack}SecurityGroup  \
  --parameters  \
    ParameterKey=myVpcName,ParameterValue=${THEVPC}  \
  --region eu-west-2
aws cloudformation describe-stacks --region eu-west-2 | jq .[][] | egrep "StackStatus|StackName\":"
aws cloudformation wait stack-create-complete --stack-name ${1:-TestStack}SecurityGroup --region eu-west-2

#Grab the identity of the Security Group
THESG=`aws cloudformation describe-stack-resources --stack-name ${1:-TestStack}SecurityGroup --region eu-west-2 \
       | jq .[][][] \
       | grep sg`
echo $THESG

#create security group rules
aws cloudformation create-stack  \
  --template-body file://./vpc_gress.json  \
  --stack-name ${1:-TestStack}SecurityGroupRules  \
  --parameters  \
    ParameterKey=mySecurityGroup,ParameterValue=${THESG}  \
  --region eu-west-2
aws cloudformation describe-stacks --region eu-west-2 | jq .[][] | egrep "StackStatus|StackName\":"
aws cloudformation wait stack-create-complete --stack-name ${1:-TestStack}SecurityGroupRules --region eu-west-2

#create and attach an internet gateway
aws cloudformation create-stack  \
  --template-body file://./vpc_igw.json  \
  --stack-name ${1:-TestStack}Igw  \
  --parameters ParameterKey=myVpcName,ParameterValue=${THEVPC}  \
  --region eu-west-2
aws cloudformation describe-stacks --region eu-west-2 | jq .[][] | egrep "StackStatus|StackName\":"
aws cloudformation wait stack-create-complete --stack-name ${1:-TestStack}Igw --region eu-west-2

#Grab the internet gateway for making a route
THEIG=`aws cloudformation describe-stacks --stack-name ${1:-TestStack}Igw --region eu-west-2  \
       | jq .[][].'Outputs'[].'OutputValue'  `
echo $THEIG

