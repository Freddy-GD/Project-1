#Project 1

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

