# AWS Multi-AZ Production Network & Automation

This project demonstrates a production-grade AWS network architecture deployed across multiple Availability Zones, with automation using Bash scripts and AWS CLI. It includes lessons learned from troubleshooting real-world networking issues and automates resource creation, configuration, and validation.

---

## Features

- Multi-AZ deployment with Public and Private subnets
- Internet-facing Application Load Balancer
- Bastion host for secure SSH access
- NAT Gateway for outbound connectivity
- CLI automation for creating VPC, subnets, route tables, security groups, NACLs, ALB, EC2 instances
- Infrastructure validation script to verify deployments and test ALB health
- Resource tagging for organization and clarity

---

## Architecture Diagram


*Figure 1: Multi-AZ AWS architecture showing public and private subnets, Bastion host, NAT Gateway, and Internet-facing ALB.*

---

## Architecture Components

| Component                  | Purpose |
|----------------------------|---------|
| VPC                        | Isolates network (CIDR: 172.1.0.0/16) |
| AZ-A & AZ-B                | Multi-AZ redundancy for high availability |
| Public Subnet              | Hosts ALB and Bastion host |
| Private Subnet             | Hosts EC2 application servers (no public IP) |
| Bastion Host               | Secure SSH access to private EC2 instances |
| NAT Gateway                | Allows outbound internet access from private subnets |
| Internet Gateway           | Provides ingress and egress to the Internet |
| Application Load Balancer  | Distributes traffic across private EC2 instances |

---

## Traffic Flow

1. Users access the ALB through the Internet Gateway.
2. ALB distributes traffic across private EC2 instances in AZ-A and AZ-B.
3. Private EC2 instances use the NAT Gateway for outbound internet traffic.
4. SSH access to private EC2 instances is only possible via the Bastion host.

---

## Automation Scripts

All automation scripts are located in the `aws-network-automation` directory. They provision the network components in the correct order.

| Script                          | Purpose |
|---------------------------------|---------|
| `Create_vpc.sh`                  | Creates VPC with DNS hostnames enabled |
| `Create_sec_subnet_diff_az.sh`  | Creates secondary public and private subnets across AZs |
| `Create_SGs.sh`                  | Creates security groups for Bastion, EC2, ALB |
| `Create_NACL.sh`                 | Creates and attaches custom Network ACL |
| `Create_nat_gateway.sh`          | Creates NAT Gateway and updates route tables |
| `Create_ec2.sh`                  | Launches private EC2 instances |
| `Create_alb.sh`                  | Creates and configures Application Load Balancer |
| `Verify_infra.sh`                | Validates infrastructure by describing resources and testing ALB returns HTTP 200 |

### How to Run

Run the scripts sequentially to provision the infrastructure:

```bash
source Create_vpc.sh
source Create_sec_subnet_diff_az.sh
source Create_SGs.sh
source Create_NACL.sh
source Create_nat_gateway.sh
source Create_ec2.sh
source Create_alb.sh
source Verify_infra.sh
````

---


## Troubleshooting & Lessons Learned

### Issue: EC2 Instance Had No Internet Access

Symptoms:
- yum could not reach repositories
- httpd failed to install
- curl / browser timed out

Root Cause:
Custom Network ACL only allowed inbound ports 22/80/443 and outbound all traffic.
Return traffic on ephemeral ports was blocked.

Fix:
Added outbound rule allowing TCP 1024-65535.

Result:
Instance gained internet access and cloud-init succeeded.

### Issue: NAT Gateway Route Creation Failed

Root Cause:
Route was created immediately after NAT creation while NAT was still in pending state.

Resolution:
Used AWS CLI waiter (aws ec2 wait nat-gateway-available) to ensure NAT reached available state before creating route.

Lesson:
Cloud resources are provisioned asynchronously. Always wait for dependent resource states before chaining operations.


### Issue: Retrieving Network ACL Association ID via AWS CLI

While automating Network ACL (NACL) reassociation using the Amazon Web Services CLI, I needed to retrieve the NetworkAclAssociationId in order to replace the default NACL with a custom NACL.

Initial Attempt

I attempted to retrieve the association ID using a positional query:

"aws ec2 describe-network-acls \
  --filters "Name=vpc-id,Values=$VPC_ID" \
  --query 'NetworkAcls[0].Associations[0].NetworkAclAssociationId' \
  --output text"

However, this command returned None, even though the association clearly existed.

Troubleshooting Steps:
- Ran the command manually to rule out scripting issues.
- Verified in the AWS Management Console that:
Both the default and custom NACLs existed
Subnets were correctly associated
- Re-ran the command without the --query filter to inspect the full JSON response:

"aws ec2 describe-network-acls \
  --filters "Name=vpc-id,Values=$VPC_ID""

- Observed that the order of NACLs in the NetworkAcls array was different than expected.

Root Cause:
The original query relied on positional indexing:

> NetworkAcls[0]

This assumed that the default NACL would always appear first in the returned array.

However,

---> AWS API responses do not guarantee array ordering

In this case, the custom NACL appeared before the default NACL

As a result, NetworkAcls[0] referenced the custom NACL, which did not contain the expected association

This caused the query to return "None"

Resolution:
- To make the query deterministic, I updated it to explicitly filter for the default NACL using the default=true flag:

"ASSOCIATION_NACL_ID=$(aws ec2 describe-network-acls \
  --filters "Name=vpc-id,Values=$VPC_ID" "Name=default,Values=true" \
  --query 'NetworkAcls[0].Associations[0].NetworkAclAssociationId' \
  --output text)"

This ensured:
- The correct NACL was always selected
- No dependency on array ordering
- Reliable results for automation scripts

Key Lesson:
- AWS CLI responses should not rely only on positional array indexing
- API result ordering is not deterministic
- Always filter using explicit identifiers or attributes (e.g., default=true)
- Deterministic queries are essential for production-grade automation

Architectural Takeaway,
This issue reinforced the importance of:
- Inspecting raw API responses during automation
- Writing resilient CLI scripts
- Avoiding assumptions about ordering in distributed systems

---

## Key Engineering Learnings

* Multi-AZ architecture improves availability and fault tolerance
* Public vs Private subnet separation is critical for security
* Bastion host pattern ensures secure SSH access
* NAT Gateway allows controlled outbound internet access
* Internet-facing ALB must be deployed in public subnets
* CLI automation requires logging, idempotent scripts, and deterministic queries
* Troubleshooting reinforces production-ready cloud engineering practices

