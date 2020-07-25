#!/bin/bash -e

#Set an alias for aws and jq.
/usr/bin/alias aws='/usr/bin/aws'
/usr/bin/alias jq='/usr/bin/jq'

# The describe_stacks function.
describe_stacks()
{
aws cloudformation describe-stacks --region eu-west-2  \
  | jq '.[][]|select(.StackName == ("'${1}'", "'${1}'AclEntry", "'${1}'SecurityGroup", "'${1}'SecurityGroupRules", "'${1}'Igw", "'${1}'Subnets", "'${1}'Interfaces", "'${1}'DefaultRoute", "'${1}'Ec2")) |.StackName,.StackStatus'  \
  | paste - -  \
  | awk '{print "\033[1;32m"$2, $1"\033[0m"}'
}

