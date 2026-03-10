# NovaFuse-EGP-VS Sample Signed USB Bundle Structure

## Complete Bundle Directory Structure

```
NovaFuse-EGP-VS-v0.1.0-certified-bundle/
├── verifier/
│   └── verify.ps1                         # PowerShell harness script
├── tests/
│   ├── EG01_determinism/
│   │   └── test.ps1                       # Determinism test script
│   ├── EG02_refusal/
│   │   └── test.ps1                       # Refusal behavior test script
│   ├── EG03_authority_separation/
│   │   └── test.ps1                       # Authority separation test
│   ├── EG04_identity_binding/
│   │   └── test.ps1                       # Identity binding test
│   ├── EG05_evidence/
│   │   └── test.ps1                       # Evidence generation test
│   └── EG06_fail_closed/
│       └── test.ps1                       # Fail-closed behavior test
├── cert-schema/
│   └── egp-certificate.schema.json        # JSON schema for certificates
├── README.md                              # Project overview & usage instructions
├── ASSESSOR-RUN.md                        # Assessor runbook (step-by-step guide)
├── CHANGE_CONTROL.md                      # Change control & recertification policy
├── Certification-Summary.md              # Complete certification overview
├── KEY-REVOCATION.md                      # Key revocation framework
├── USB-Distribution-Checklist.md          # Bundle verification checklist
├── USB-Chain-of-Custody.md                # Regulatory tracking form
├── BUNDLE-METADATA.json                   # Build and provenance metadata
├── certificate-egp-0.1-novadust-v0.1.0.json  # Sample certificate artifact
├── RELEASE-HASHES.txt                     # SHA-256 hashes for all files
├── RELEASE-HASHES.txt.sig                 # GPG detached signature
├── NovaFuse-PublicKey.asc                 # NovaFuse public GPG key
├── Generate-USB-Bundle.ps1                # Enhanced bundle generator
├── Generate-GPG-Keys.ps1                   # GPG key generation script
├── Sign-Manifest.ps1                       # Manifest signing utility
├── make-usb-bundle.sh                      # Bash bundle generator
└── check-revocation.py                    # Revocation checking tool
```

## Key File Contents Overview

### 1. Verification Harness (`verifier/verify.ps1`)
- **Purpose**: Main entrypoint for EGP verification
- **Features**: UTF-8 output, ANSI rendering control, comprehensive error handling
- **Lines**: 246 lines of production-grade PowerShell

### 2. Test Suites (`tests/EG0X/test.ps1`)
- **EG01**: Deterministic admissibility (100 runs, hash uniqueness validation)
- **EG02**: Explicit refusal testing (invalid proposals, refusal validation)
- **EG03**: Authority separation (static analysis, runtime inspection)
- **EG04**: Identity-bound evaluation (context-based decision differentiation)
- **EG05**: Evidence generation (cryptographic signatures, replay capability)
- **EG06**: Fail-closed semantics (safe failure under all conditions)

### 3. Certificate Schema (`cert-schema/egp-certificate.schema.json`)
- **Purpose**: JSON schema for certificate validation
- **Size**: 6.4 KB comprehensive validation rules
- **Features**: Required fields, data types, integrity checks

### 4. Sample Certificate (`certificate-egp-0.1-novadust-v0.1.0.json`)
- **Status**: Complete PASS certificate with all 6 EGP claims
- **Integrity**: SHA-256 hashes for verifier, profile, and test suites
- **Metadata**: Assessment details, timing, and cryptographic signatures

### 5. Security Assets
- **RELEASE-HASHES.txt**: Complete SHA-256 manifest for all bundle files
- **RELEASE-HASHES.txt.sig**: GPG detached signature (ASCII-armored)
- **NovaFuse-PublicKey.asc**: NovaFuse Certification Authority public key

### 6. Distribution Tools
- **Generate-USB-Bundle.ps1**: Enhanced PowerShell generator with version pinning
- **make-usb-bundle.sh**: Cross-platform bash generator
- **Generate-GPG-Keys.ps1**: Automated GPG keypair generation
- **Sign-Manifest.ps1**: Manifest signing and verification utility

### 7. Compliance & Documentation
- **ASSESSOR-RUN.md**: 163-line detailed evaluation procedures
- **CHANGE_CONTROL.md**: 108-line change management framework
- **KEY-REVOCATION.md**: Complete key revocation mechanism
- **USB-Distribution-Checklist.md**: 17-point verification checklist
- **USB-Chain-of-Custody.md**: Regulatory tracking form

## Zipped Bundle Distribution

### Archive Name
```
NovaFuse-EGP-VS-v0.1.0-certified-bundle.zip
```

### Integrity Verification
**PowerShell (Windows):**
```powershell
Get-FileHash .\NovaFuse-EGP-VS-v0.1.0-certified-bundle.zip -Algorithm SHA256
```

**Linux/macOS:**
```bash
sha256sum NovaFuse-EGP-VS-v0.1.0-certified-bundle.zip
```

## Verification Workflow

### 1. Extract Bundle
```bash
unzip NovaFuse-EGP-VS-v0.1.0-certified-bundle.zip
cd NovaFuse-EGP-VS-v0.1.0-certified-bundle
```

### 2. Import Public Key
```bash
gpg --import NovaFuse-PublicKey.asc
```

### 3. Verify Signature
```bash
gpg --verify RELEASE-HASHES.txt.sig RELEASE-HASHES.txt
```

### 4. Check File Hashes
```bash
sha256sum -c RELEASE-HASHES.txt
```

### 5. Run Verification
```powershell
cd verifier
.\verify.ps1
```

### 6. Validate Certificate
```powershell
# Check certificate schema validation
# Verify certificate integrity hashes
# Confirm all EGP claims passed
```

## QR Code Access

**NovaFuse Public Key QR Code:**  
https://novafuse.ai/certs/NovaFuse-PublicKey-QR.png

Scan to download the public key directly to mobile devices.

## Security Features

### Cryptographic Integrity
- ✅ SHA-256 hashing for all files
- ✅ GPG RSA-4096 signatures
- ✅ Detached signature format
- ✅ Public key distribution

### Provenance Tracking
- ✅ Build environment metadata
- ✅ Tool version pinning
- ✅ Bundle creation timestamps
- ✅ Complete audit trail

### Revocation Support
- ✅ Key revocation framework
- ✅ Automated revocation checking
- ✅ Emergency response procedures
- ✅ Key transition protocols

## Compliance Alignment

### Standards Supported
- ✅ ISO 27001 - Information Security Management
- ✅ NIST 800-53 - Security and Privacy Controls
- ✅ SOC 2 Type II - Service Organization Controls
- ✅ GDPR - Privacy Protection
- ✅ Export Control - Compliance Framework

### Audit Readiness
- ✅ Complete documentation package
- ✅ Chain of custody forms
- ✅ Change control procedures
- ✅ Evidence generation and replay

## Bundle Statistics

### File Composition
- **Total Files**: 25 production-ready assets
- **Core Components**: 10 verification and test files
- **Security Assets**: 4 cryptographic integrity files
- **Documentation**: 5 comprehensive guides
- **Distribution Tools**: 4 automation scripts
- **Compliance Forms**: 2 regulatory tracking forms

### Size Estimates
- **Bundle Size**: ~2-5 MB (depending on included artifacts)
- **Certificate**: ~4-6 KB (JSON format)
- **Signatures**: ~2-3 KB (ASCII-armored)
- **Documentation**: ~50-100 KB total

## Usage Scenarios

### High-Security Environments
- Air-gapped certification workflows
- Regulatory audit preparation
- Supply chain security verification
- Third-party assessment support

### Enterprise Deployment
- CI/CD pipeline integration
- Automated regression testing
- Compliance monitoring
- Risk management reporting

### Regulatory Compliance
- Formal certification processes
- Audit trail generation
- Evidence collection
- Chain of custody management

---

**Bundle Version**: v0.1.0  
**Specification**: NovaFuse-EGP-0.1  
**Release Date**: 2026-03-09  
**Next Review**: 2026-06-09  
**Authority**: NovaFuse Certification Authority
