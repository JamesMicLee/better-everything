#!/bin/bash -e

#Import functions and aliases.
. ./functions.bash

#Make sure jq is installed
set +e
/usr/bin/yum install -y jq
set -e
/usr/bin/rpm -q jq

#Run describe_stacks ${1:-TestStack} before we begin.
describe_stacks ${1:-TestStack}

#Make an empty VPC
aws cloudformation create-stack  \
  --template-body file://./vpc_base.json  \
  --stack-name ${1:-TestStack}  \
  --region eu-west-2 
describe_stacks ${1:-TestStack}
#Wait for the vpc to be created
aws cloudformation wait stack-create-complete --stack-name ${1:-TestStack} --region eu-west-2

#Grab the identity of the VPC
JSON_PAY=`aws cloudformation describe-stack-resources --stack-name ${1:-TestStack} --region eu-west-2  `
THEVPC=`echo $JSON_PAY  \
       | jq --sort-keys '.[][]|select(.ResourceType == "AWS::EC2::VPC")|.PhysicalResourceId'  `
echo $THEVPC

#Grab the dhcp
THEDHC=`echo $JSON_PAY  \
       | jq --sort-keys '.[][]|select(.ResourceType == "AWS::EC2::DHCPOptions")|.PhysicalResourceId'  `
echo $THEDHC

#Grab the route table
JSON_PAY=`aws ec2 describe-route-tables --region eu-west-2  `
THERTB=`echo $JSON_PAY | jq --sort-keys '.[][]|select(.VpcId == '${THEVPC}').RouteTableId'  `
echo $THERTB

#Grab the identity of the ACL
JSON_PAY=`aws ec2 describe-network-acls --region eu-west-2`
THEACL=`echo $JSON_PAY  \
      | jq --sort-keys '.[][]|select(.VpcId == '$THEVPC')|.NetworkAclId'  `
echo $THEACL

#create acl entries
aws cloudformation create-stack  \
  --template-body file://./vpc_acls.json  \
  --stack-name ${1:-TestStack}AclEntry  \
  --parameters  \
    ParameterKey=myVpcName,ParameterValue=${THEVPC}  \
    ParameterKey=myNetworkAcl,ParameterValue=${THEACL}  \
  --region eu-west-2

#create a security group
aws cloudformation create-stack  \
  --template-body file://./vpc_security_group.json  \
  --stack-name ${1:-TestStack}SecurityGroup  \
  --parameters  \
    ParameterKey=myVpcName,ParameterValue=${THEVPC}  \
  --region eu-west-2

#create and attach an internet gateway
aws cloudformation create-stack  \
  --template-body file://./vpc_igw.json  \
  --stack-name ${1:-TestStack}Igw  \
  --parameters ParameterKey=myVpcName,ParameterValue=${THEVPC}  \
  --region eu-west-2
describe_stacks ${1:-TestStack}

aws cloudformation wait stack-create-complete --stack-name ${1:-TestStack}AclEntry --region eu-west-2
aws cloudformation wait stack-create-complete --stack-name ${1:-TestStack}SecurityGroup --region eu-west-2
aws cloudformation wait stack-create-complete --stack-name ${1:-TestStack}Igw --region eu-west-2

#Grab the gateway
JSON_PAY=`aws ec2 describe-internet-gateways --region eu-west-2  `
THEIGW=`echo $JSON_PAY | jq --sort-keys '.[][]|select(.Attachments|.[].VpcId == '${THEVPC}').InternetGatewayId'  `
echo $THEIGW

#Grab the ACL Entries
THEACE=`aws cloudformation describe-stack-resources --stack-name ${1:-TestStack}AclEntry --region eu-west-2 \
       | jq .[][][] \
       | grep acl`
echo $THEACE

#Grab the identity of the Security Group
JSON_PAY=`aws ec2 describe-security-groups --region eu-west-2  `
THESGR=`echo $JSON_PAY | jq --sort-keys '.[][]|select(.VpcId == '${THEVPC}')|.GroupId,.GroupName' | paste - -| grep -v '"default"'\$ | awk '{ print $1 } '  `
echo $THESGR

#create routes
aws cloudformation create-stack  \
  --template-body file://./vpc_routes.json  \
  --stack-name ${1:-TestStack}DefaultRoute  \
  --parameters  \
    ParameterKey=myVpcName,ParameterValue=${THEVPC}  \
    ParameterKey=myInternetGateway,ParameterValue=${THEIGW}  \
    ParameterKey=myRouteTable,ParameterValue=${THERTB}  \
  --region eu-west-2

#create and attach subnets
aws cloudformation create-stack  \
  --template-body file://./vpc_subnets.json  \
  --stack-name ${1:-TestStack}Subnets  \
  --parameters  \
    ParameterKey=myVpcName,ParameterValue=${THEVPC}  \
    ParameterKey=myNetworkAcl,ParameterValue=${THEACL}  \
  --region eu-west-2

#create security group rules
aws cloudformation create-stack  \
  --template-body file://./vpc_gress.json  \
  --stack-name ${1:-TestStack}SecurityGroupRules  \
  --parameters  \
    ParameterKey=mySecurityGroup,ParameterValue=${THESGR}  \
  --region eu-west-2
describe_stacks ${1:-TestStack}

aws cloudformation wait stack-create-complete --stack-name ${1:-TestStack}SecurityGroupRules --region eu-west-2
aws cloudformation wait stack-create-complete --stack-name ${1:-TestStack}Subnets --region eu-west-2

# list the subnets for a flare
aws cloudformation describe-stacks  \
  --stack-name ${1:-TestStack}Subnets  \
  --region eu-west-2  \
  | jq .[][].'Outputs'[]  \
  | jq '.OutputKey,.OutputValue'  \
  | egrep -i subnet
echo

#Grab the identity of the Security Group
JSON_PAY=`aws ec2 describe-security-groups --region eu-west-2  `
THESGR=`echo $JSON_PAY | jq --sort-keys '.[][]|select(.VpcId == '${THEVPC}')|.GroupId,.GroupName' | paste - -| grep -v '"default"'\$ | awk '{ print $1 } '  `
echo $THESGR

SUBNET=\"${2:-Subnet4Ec2}\"
THESUB=`aws cloudformation describe-stacks  \
  --stack-name ${1:-TestStack}Subnets  \
  --region eu-west-2  \
  | jq --sort-keys '.[][].Outputs[]|select(.OutputKey == '${SUBNET}')' \
  | jq '.OutputValue'  `
echo $THESUB

#create network interfaces
aws cloudformation create-stack  \
  --template-body file://./vpc_interfaces.json  \
  --stack-name ${1:-TestStack}Interfaces  \
  --parameters  \
    ParameterKey=mySecurityGroup,ParameterValue=${THESGR}  \
    ParameterKey=mySubnet,ParameterValue=${THESUB}  \
  --region eu-west-2
describe_stacks ${1:-TestStack}
aws cloudformation wait stack-create-complete --stack-name ${1:-TestStack}Interfaces --region eu-west-2

echo
describe_stacks ${1:-TestStack}
