#!/bin/bash

JSONPAY=`/usr/bin/aws ec2 describe-images --filters  \
  'Name=is-public,Values=true'  \
  'Name=architecture,Values=x86_64'  \
  'Name=description,Values=Amazon Linux 2 AMI 2.0.202*gp2'  \
  'Name=state,Values=available'  \
  'Name=block-device-mapping.volume-size,Values=8'  \
  --region eu-west-2  `
LASTAL2=`echo $JSONPAY | jq .[][].CreationDate | sort -n | tail -1`  # The latest EC2
echo $JSONPAY | jq --sort-keys '.[][]|select(.CreationDate == '${LASTAL2}')|.ImageId'
