# Terraform issues fixed and how

## 1. Wrong EC2 public IP in Terraform output
### Problem
Terraform was still pointing to an old management instance, so the pipeline generated the inventory with the wrong public IP.

### Fix
- Checked the Terraform state for the management instance.
- Removed the stale `aws_instance.management` entry from state.
- Imported the correct EC2 instance using its instance ID.
- Re-ran Terraform refresh so the output `management_ec2_public_ip` matched the correct host.

### Result
The Terraform output now resolves to the correct public IP for the management EC2 instance.

---

## 2. Terraform backend/state mismatch
### Problem
Terraform could not fully refresh the remote state because the backend state and local state were out of sync.

### Fix
- Reinitialized Terraform with the S3 backend configuration.
- Reconciled the state by aligning it with the actual AWS resource.
- Confirmed the workspace was `dev` before reading outputs.

### Result
Terraform could successfully read the workspace state and produce outputs for the pipeline.

---

## 3. Jenkins pipeline using stale Terraform values
### Problem
The Jenkins pipeline was reading Terraform outputs from a state that no longer matched the live resource.

### Fix
- Updated the pipeline to log the workspace and the Terraform output values.
- Verified the generated inventory came from the corrected Terraform output.

### Result
The Ansible inventory is now generated from the correct management host IP.
