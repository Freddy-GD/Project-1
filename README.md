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

