# AWS Network Automation with Bash & AWS CLI

This project automates the creation of a foundational AWS network using Bash scripting and AWS CLI.

## Features
- Creates VPC with DNS hostnames enabled
- Creates Public and Private subnets
- Creates and attaches Internet Gateway
- Creates Public and Private Route Tables
- Adds Internet route to Public Route Table
- Creates custom Network ACL
- Replaces default NACL association
- Uses tagging for resource organization

## Technologies
- AWS CLI
- Bash
- Amazon VPC
- Networking Fundamentals

## How to Run
source create_vpc.sh  
source create_nacl.sh
