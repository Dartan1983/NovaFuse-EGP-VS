# NovaFuse-EGP-VS Security Policy

## Certification Authority and Key Control

NovaFuse-EGP-VS is licensed as certification infrastructure.
Execution of the verification harness does not grant certification authority.

All official signing keys, certificates, and revocation decisions are controlled
exclusively by NovaFuse Technologies or explicitly authorized partners.

Private keys used for signing release manifests and certificates are:
- never distributed;
- stored in hardware-backed key management systems (HSMs) where available;
- rotated and revoked according to documented procedures.

## 🔐 Private Key Management

### **Critical Security Principle**
The NovaFuse Certification Authority private key is **NEVER** stored in this repository, never accessible via CI/CD pipelines, and never transmitted over any network.

### **Private Key Storage**

#### **🏛️ Offline Hardware Security Module (HSM)**
- **Location**: Air-gapped secure facility
- **Access**: Multi-person authorization required
- **Backup**: Encrypted offline backups in separate secure location
- **Rotation**: Every 5 years or upon compromise

#### **🔒 Key Generation Process**
```
1. Generate key pair on air-gapped system
2. Export public key only for distribution
3. Private key never leaves HSM environment
4. All signing operations performed offline
```

### **Public Key Distribution**

#### **✅ What IS Distributed**
- `NovaFuse-PublicKey.asc` - Public key for signature verification
- Public key uploaded to GitHub repository
- Public key included in all USB bundles
- Public key available via public keyservers

#### **❌ What IS NEVER Distributed**
- Private key file
- Private key backup files
- Private key passwords or passphrases
- Any access credentials to HSM

---

## 🛡️ Signing Process

### **Detached GPG Signatures**
All NovaFuse releases use detached GPG signatures:

```bash
# Offline signing process (performed in secure facility)
gpg --armor --output RELEASE-HASHES.txt.sig --detach-sign RELEASE-HASHES.txt
```

### **Signature Verification**
Users can verify signatures without private key:

```bash
# Import public key
gpg --import NovaFuse-PublicKey.asc

# Verify signature
gpg --verify RELEASE-HASHES.txt.sig RELEASE-HASHES.txt
```

---

## 🔍 Key Revocation Framework

### **Revocation Triggers**
- Private key compromise suspected
- HSM security breach
- Unauthorized access detected
- Regulatory requirement
- Key expiration approaching

### **Revocation Process**
1. Generate revocation certificate offline
2. Publish revocation to public channels
3. Update revocation manifests
4. Notify all stakeholders
5. Generate new key pair (if needed)

### **Revocation Verification**

```bash
# Check if key is revoked
python check-revocation.py NovaFuse-PublicKey.asc revocation-manifest.json
```

> **Note:** Revocation mechanisms apply to NovaFuse-issued certificates and keys only. Third-party executions of the harness do not create authoritative certificates and therefore do not require revocation.

---

## 🚨 Security Incident Response

### **Immediate Actions**
1. **Assume Compromise**: Treat any security breach as key compromise
2. **Revoke Immediately**: Generate and publish revocation certificate
3. **Notify Stakeholders**: Alert all users and regulators
4. **Investigate**: Determine scope and impact
5. **Rotate Keys**: Generate new key pair if necessary

### **Communication Channels**
- **GitHub Repository**: Security advisories
- **Email**: security@novafuse.ai
- **Website**: novafuse.ai/security
- **Public Keyservers**: Key revocation notices

---

## 📋 Security Best Practices

### **For Users**
1. **Verify Signatures**: Always verify GPG signatures before use
2. **Check Revocation**: Run revocation check before verification
3. **Secure Storage**: Store bundles in secure location
4. **Access Control**: Limit access to verification systems
5. **Audit Trail**: Maintain records of verification activities

### **For Developers**
1. **No Secrets**: Never commit private keys or credentials
2. **Secure CI/CD**: Use environment variables for secrets
3. **Code Review**: Security-focused code review process
4. **Dependencies**: Regular security updates for dependencies
5. **Testing**: Include security testing in CI/CD pipeline

### **For Operators**
1. **Air-Gapped Systems**: Use offline systems for verification
2. **Network Isolation**: Minimize network connectivity
3. **Access Logging**: Log all access to verification systems
4. **Regular Audits**: Periodic security audits
5. **Incident Response**: Documented response procedures

---

## 🔐 Cryptographic Algorithms

### **Supported Algorithms**
- **Hash**: SHA-256 (NIST approved)
- **Signature**: RSA-4096 with GPG
- **Key Exchange**: RSA-4096
- **Symmetric**: AES-256 (for encrypted backups)

### **Algorithm Lifecycle**
- **Minimum Key Size**: RSA-2048 (currently RSA-4096)
- **Hash Algorithm**: SHA-256 (no SHA-1 support)
- **Signature Format**: OpenPGP (RFC 4880)
- **Certificate Format**: JSON with schema validation

---

## 🛡️ Threat Model

### **Threats Mitigated**
- **Key Compromise**: Offline HSM storage + revocation framework
- **Tampering**: SHA-256 integrity verification
- **Spoofing**: GPG signature verification
- **Replay Attacks**: Timestamped evidence
- **Man-in-the-Middle**: Public key verification

### **Assumptions**
- Users verify GPG signatures before use
- Private key storage remains secure
- Revocation mechanisms are functional
- Cryptographic algorithms remain secure

---

## 📊 Security Metrics

### **Key Security**
- **Key Generation**: Offline, air-gapped
- **Key Storage**: Hardware Security Module
- **Key Rotation**: Every 5 years
- **Key Backup**: Encrypted offline storage
- **Access Control**: Multi-person authorization

### **Bundle Security**
- **Integrity**: SHA-256 hashing
- **Authenticity**: GPG digital signatures
- **Confidentiality**: No sensitive data in bundles
- **Availability**: Distributed via multiple channels
- **Non-repudiation**: Cryptographic evidence

### **Operational Security**
- **Verification**: Offline capable
- **Audit Trail**: Complete logging
- **Monitoring**: Revocation status checking
- **Incident Response**: Documented procedures
- **Compliance**: Regulatory framework alignment

---

## 🚨 Reporting Security Issues

### **Vulnerability Reporting**
- **Email**: security@novafuse.ai
- **PGP Key**: Available on request
- **Response Time**: Within 48 hours
- **Coordination**: Coordinated disclosure available

### **Security Questions**
- **Email**: security@novafuse.ai
- **Documentation**: This SECURITY.md file
- **Procedures**: KEY-REVOCATION.md
- **Support**: GitHub Discussions

---

## 🔍 Security Verification

### **Self-Assessment Checklist**
- [ ] Private key never in repository
- [ ] Public key properly distributed
- [ ] Signatures verifiable
- [ ] Revocation framework functional
- [ ] Incident response documented
- [ ] Cryptographic algorithms appropriate
- [ ] Access controls implemented
- [ ] Audit trail maintained

### **Third-Party Validation**
- **Security Audits**: Annual third-party audits
- **Penetration Testing**: Regular security testing
- **Compliance Reviews**: Regulatory compliance validation
- **Code Review**: Security-focused code review
- **Independent Verification**: Third-party validation protocols

---

## 📞 Security Contacts

### **Security Team**
- **Chief Security Officer**: cso@novafuse.ai
- **Security Engineering**: security@novafuse.ai
- **Incident Response**: incident@novafuse.ai

### **Reporting Channels**
- **Vulnerabilities**: security@novafuse.ai
- **Security Questions**: security@novafuse.ai
- **Incidents**: incident@novafuse.ai
- **General**: security@novafuse.ai

---

## 🔐 Commitment to Security

NovaFuse Technologies is committed to maintaining the highest security standards for the NovaFuse-EGP-VS verification system. Our security-by-design approach ensures that:

1. **Private keys never leave secure environments**
2. **All releases are cryptographically signed and verifiable**
3. **Revocation mechanisms are in place and tested**
4. **Security incidents are handled promptly and transparently**
5. **Regular security audits and testing are performed**

This security policy ensures that NovaFuse-EGP-VS remains a trusted, verifiable, and secure constitutional compliance infrastructure system.
