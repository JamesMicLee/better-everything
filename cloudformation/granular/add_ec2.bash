#!/bin/bash 

#Make sure jq is installed
set +e
/usr/bin/yum install -y jq
set -e
/usr/bin/rpm -q jq

#Set an alias for aws.
/usr/bin/alias aws='/usr/bin/aws'

describe_stacks()
{
aws cloudformation describe-stacks --region eu-west-2  \
  | jq '.[][]|select(.StackName == ("TestStack", "TestStackAclEntry", "TestStackSecurityGroup", "TestStackSecurityGroupRules", "TestStackIgw", "TestStackSubnets", "TestStackInterfaces", "TestStackDefaultRoute", "TestStackEc2")) |.StackName,.StackStatus'  \
  | paste - -  \
  | awk '{print "\033[1;32m"$2, $1"\033[0m"}'
}
describe_stacks

#Grab the identity of the VPC
JSON_PAY=`aws cloudformation describe-stack-resources --stack-name ${1:-TestStack} --region eu-west-2  `
THEVPC=`echo $JSON_PAY  \
       | jq --sort-keys '.[][]|select(.ResourceType == "AWS::EC2::VPC")|.PhysicalResourceId'  `
echo $THEVPC

#Grab the identity of the ACL
JSON_PAY=`aws ec2 describe-network-acls --region eu-west-2`
THEACL=`echo $JSON_PAY  \
      | jq --sort-keys '.[][]|select(.VpcId == '$THEVPC')|.NetworkAclId'  `
echo $THEACL

#Grab the identity of the Security Group
JSON_PAY=`aws ec2 describe-security-groups --region eu-west-2  `
THESG=`echo $JSON_PAY | jq --sort-keys '.[][]|select(.VpcId == '${THEVPC}')|.GroupId,.GroupName' | paste - -| grep -v '"default"'\$ | awk '{ print $1 } '  `
echo $THESG

# grab the subnet
SUBNET=\"${2:-Subnet4Ec2}\"
THESUB=`aws cloudformation describe-stacks  \
  --stack-name ${1:-TestStack}Subnets  \
  --region eu-west-2  \
  | jq --sort-keys '.[][].Outputs[]|select(.OutputKey == '${SUBNET}')' \
  | jq '.OutputValue'  `
echo $THESUB

# grab the ami
THEAMI=`./find_ami.bash`
echo $THEAMI

#create ec2 stack 
aws cloudformation create-stack  \
  --template-body file://./vpc_ec2.json  \
  --stack-name ${1:-TestStack}Ec2  \
  --parameters  \
    ParameterKey=mySubnet,ParameterValue=${THESUB}  \
    ParameterKey=myAmi,ParameterValue=${THEAMI}  \
    ParameterKey=mySecurityGroup,ParameterValue=${THESG}  \
  --region eu-west-2  
describe_stacks
aws cloudformation wait stack-create-complete --stack-name ${1:-TestStack}Ec2 --region eu-west-2

echo
describe_stacks
