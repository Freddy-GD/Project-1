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
