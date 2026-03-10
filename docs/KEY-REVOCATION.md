# NovaFuse-EGP-VS Key Revocation Framework

## Overview

This document defines the complete key revocation mechanism for NovaFuse Certification Authority signing keys used with USB bundle distribution.

## Revocation Triggers

### Immediate Revocation Required
- **Key Compromise**: Private key exposure or suspected compromise
- **Unauthorized Signing**: Any signature not made by authorized personnel
- **System Breach**: Security incident affecting signing infrastructure
- **Personnel Change**: Termination of authorized signers without key transition

### Scheduled Revocation
- **Key Expiration**: 5-year maximum key lifetime (as per key generation policy)
- **Organizational Policy**: Scheduled key rotation per security policy
- **Cryptographic Advances**: Migration to stronger algorithms if needed

## Revocation Certificate Generation

### Create Revocation Certificate
```bash
# Generate revocation certificate for compromised key
gpg --gen-revoke certification@novafuse.ai

# Export revocation certificate
gpg --armor --export certification@novafuse.ai > NovaFuse-Revocation.asc
```

### Revocation Certificate Format
```
-----BEGIN PGP PUBLIC KEY BLOCK-----
Version: GnuPG v2

[REVOCATION CERTIFICATE DATA]

-----END PGP PUBLIC KEY BLOCK-----
```

## Distribution Channels

### Primary Distribution
1. **Official Website**: https://novafuse.ai/security/revocations/
2. **GitHub Repository**: /security/revocations/ directory
3. **Email Notification**: security@novafuse.ai distribution list
4. **Package Managers**: Update via package management systems

### Revocation File Naming Convention
```
NovaFuse-Revocation-{KeyID}-{Timestamp}.asc
Example: NovaFuse-Revocation-ABCD1234-20260309.asc
```

### Revocation Manifest
```json
{
  "revocation_manifest": {
    "version": "1.0",
    "generated": "2026-03-09T12:00:00Z",
    "authority": "NovaFuse Certification Authority",
    "contact": "security@novafuse.ai",
    "revoked_keys": [
      {
        "key_id": "ABCD1234EF567890",
        "key_email": "certification@novafuse.ai",
        "revocation_reason": "key_compromise",
        "revocation_date": "2026-03-09T12:00:00Z",
        "revocation_certificate": "NovaFuse-Revocation-ABCD1234-20260309.asc"
      }
    ]
  }
}
```

## Verification Procedures

### Before Bundle Verification
```bash
# Download latest revocation manifest
curl -O https://novafuse.ai/security/revocations/revocation-manifest.json

# Check if bundle key is revoked
python3 check-revocation.py NovaFuse-PublicKey.asc revocation-manifest.json
```

### Automated Revocation Check Script
```python
#!/usr/bin/env python3
import json
import sys
import subprocess

def check_revocation(key_file, manifest_file):
    """Check if GPG key is in revocation list"""
    with open(manifest_file, 'r') as f:
        manifest = json.load(f)
    
    # Extract key ID from public key
    result = subprocess.run(['gpg', '--with-colons', '--import-options', 'show-only', '--import', key_file], 
                          capture_output=True, text=True)
    
    key_id = None
    for line in result.stdout.split('\n'):
        if line.startswith('pub:'):
            key_id = line.split(':')[4]
            break
    
    if not key_id:
        print("❌ Could not extract key ID")
        return False
    
    # Check against revoked keys
    for revoked_key in manifest['revocation_manifest']['revoked_keys']:
        if revoked_key['key_id'] == key_id:
            print(f"❌ KEY REVOKED: {revoked_key['revocation_reason']}")
            print(f"   Date: {revoked_key['revocation_date']}")
            return False
    
    print("✅ Key not revoked")
    return True

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: check-revocation.py <key_file> <manifest_file>")
        sys.exit(1)
    
    check_revocation(sys.argv[1], sys.argv[2])
```

## Emergency Revocation Process

### Immediate Actions (Within 1 Hour)
1. **Generate Revocation Certificate**: Use secure, offline system
2. **Update Distribution Channels**: Upload to all primary channels
3. **Send Security Alert**: Email all known bundle recipients
4. **Update Website**: Post prominent security notice
5. **Social Media**: Post revocation notice on official channels

### Notification Template
```
SECURITY ALERT - NovaFuse Key Revocation

Date: [DATE]
Key ID: [KEY_ID]
Reason: [COMPROMISE/EXPIRATION/POLICY]
Action Required: Immediately cease using bundles signed with this key
New Key: Available at https://novafuse.ai/security/
Contact: security@novafuse.ai
```

## Key Transition Process

### Planned Rotation (No Compromise)
1. **Generate New Key**: 30 days before expiration
2. **Dual Signing Period**: Sign bundles with both old and new keys for 30 days
3. **Gradual Transition**: Recipients migrate to new key verification
4. **Old Key Retirement**: Revoke old key after transition period
5. **Documentation Update**: Update all documentation with new key

### Emergency Rotation (Compromise)
1. **Immediate Revocation**: Revoke compromised key immediately
2. **Emergency Key Generation**: Generate new key on secure system
3. **Rapid Distribution**: Distribute new key via all channels
4. **Bundle Resigning**: Resign all active bundles with new key
5. **Incident Report**: Document compromise and response

## Verification Integration

### Bundle Verification Enhancement
Update verification procedures to include revocation checking:

```bash
# Enhanced verification workflow
#!/bin/bash

# 1. Import public key
gpg --import NovaFuse-PublicKey.asc

# 2. Check revocation status
./check-revocation.py NovaFuse-PublicKey.asc revocation-manifest.json
if [ $? -ne 0 ]; then
    echo "❌ KEY REVOKED - Verification aborted"
    exit 1
fi

# 3. Verify signature
gpg --verify RELEASE-HASHES.txt.sig RELEASE-HASHES.txt

# 4. Check hashes
sha256sum -c RELEASE-HASHES.txt
```

## Record Keeping

### Revocation Log
Maintain permanent record of all revocations:

| Date | Key ID | Reason | Method | Certificate File |
|-------|---------|---------|---------|------------------|
|       |         |         |         |                  |

### Audit Requirements
- **Immutable Records**: All revocation certificates archived permanently
- **Access Logs**: Record all access to revocation system
- **Change Tracking**: Version control for revocation manifests
- **Backup Procedures**: Secure backup of revocation data

## Contact Information

### Security Issues
- **Immediate**: security@novafuse.ai
- **PGP Key**: Available on website for encrypted communications
- **Phone**: +1-555-NOVA-SEC (emergency only)

### Documentation Updates
- **Repository**: https://github.com/novafuse/egp-vs/security/
- **Website**: https://novafuse.ai/security/
- **Archive**: All historical revocations maintained online

---

**Document Version**: 1.0  
**Last Updated**: 2026-03-09  
**Next Review**: 2026-06-09  
**Authority**: NovaFuse Certification Authority
