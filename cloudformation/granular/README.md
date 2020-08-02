Modular Cloudformation Templates
================================

A series of Bash scripts and JSON Cloudformation Templates. The AWS command line is used to create stacks from the Cloudformation templates. 

From an Amazon Linux 2 EC2 that has the correct IAM policies, running make_vpc.bash and add_ec2.bash will spin up a VPC with subnets for EC2 and Lambda, and deploy the latest Amazon Linux 2 AMI as an EC2.

Requirements
------------
Amazon Linux 2.


The VPC
-------
The VPC creates automatically DHCP options, an ACL and a Security Group. 


The Route Table
---------------
The Route Table has to have the default route added after the Internet Gateway is added. 


The ACL Entries
---------------
The ACL entries just overwrite the default values.


The Security Group
------------------
The Security Group is for ssh access only. It's in addition to the default Security Group - which is the same. 

The EC2
-------
The EC2 uses the latest available Amazon Linux 2 AMI. 

Region
------
The region is hard coded. 

Dedeploy
--------
No dedeploy script is provided. 

Testing
-------
Automated test for JSON syntax and manual test by running make_vpc.bash and add_ec2.bash from an Amazon Linux 2 EC2 with appropriate IAM policies applied. 
