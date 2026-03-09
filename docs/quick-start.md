# NovaFuse-EGP-VS Quick Start Guide

> **Scope Notice:** This guide describes how to execute the NovaFuse‑EGP‑VS evaluation harness and generate verification artifacts. Execution of these steps does not, by itself, constitute regulatory approval or confer certification authority.
>
> **Version Note:** Commands below use `v0.1.x` as a placeholder. Substitute the actual release version (e.g., `v0.1.2`) as appropriate.

## 🚀 Get Started in 5 Minutes

### **Prerequisites**
- Windows 10+ or PowerShell 5.1+
- 100MB disk space
- No internet required (offline verification)

---

## ⚡ **Option 1: Quick Validation**

```powershell
# 1. Download and extract NovaFuse-EGP-VS-v0.1.x.zip
# 2. Navigate to the extracted directory
cd NovaFuse-EGP-VS-v0.1.x

# 3. Run quick validation
.\QUICK-VALIDATE.ps1

# Expected output:
# ✅ Bundle found: .\dist\NovaFuse-EGP-VS-v0.1.0
# ✅ Verification harness found
# ✅ Verification harness PASSED
# ✅ Certificate generated
# ✅ Certificate Status: PASS
# 🎉 NovaFuse-EGP-VS Validation PASSED!
```

---

## 🏗️ **Option 2: Full Verification**

```powershell
# 1. Run complete verification harness
cd verifier
.\verify.ps1

# 2. Validate generated certificate
$cert = Get-Content artifacts\certs\certificate-*.json | ConvertFrom-Json
Write-Host "Certificate Status: $($cert.results.overall)"
Write-Host "Certificate ID: $($cert.metadata.certificate_id)"

# 3. Verify integrity
cd ..
Get-Content RELEASE-HASHES.txt | Where-Object {$_ -match "^[a-f0-9]"} | ForEach-Object {
    $hash, $file = $_ -split '  ', 2
    $actualHash = (Get-FileHash $file -Algorithm SHA256).Hash
    Write-Host "$file - $($hash -eq $actualHash ? '✅' : '❌')"
}
```

---

## 📦 **Option 3: Generate USB Bundle**

```powershell
# 1. Generate complete bundle
.\Generate-USB-Bundle-Clean.ps1 -OutputPath .\my-bundle

# 2. Verify bundle contents
Get-ChildItem .\my-bundle\NovaFuse-EGP-VS-v0.1.0 -Recurse -File | Measure-Object

# 3. Create distribution archive
# Archive automatically created: NovaFuse-EGP-VS-v0.1.0.zip
```

---

## 🔍 **What You'll See**

### **Successful Verification Output**
```
[PASS] VERIFICATION PASSED
Tests Run: 6
Passed: 6
Failed: 0
Certificate: artifacts\certs\certificate-egp-0.1-novadust-v0.1.0.json
```

### **Generated Certificate**
- **Status**: PASS
- **Claims**: 6/6 passed
- **Duration**: ~0.6 seconds
- **Evidence**: Cryptographically signed

### **Bundle Contents**
- **Files**: 24 total
- **Size**: ~0.11 MB
- **Integrity**: SHA-256 verified
- **Security**: GPG signed (if available)

---

## 🎯 **Key Results**

### **EGP Claims Validated**
- ✅ **EG01**: Deterministic Processing
- ✅ **EG02**: Explicit Refusal
- ✅ **EG03**: Authority Separation
- ✅ **EG04**: Identity Binding
- ✅ **EG05**: Evidence Generation
- ✅ **EG06**: Fail-Closed Semantics

### **Regulatory Framework Mapping (Informational)**
The verification artifacts produced by NovaFuse‑EGP‑VS can be mapped to common regulatory and assurance frameworks. These mappings are informational and do not constitute regulatory compliance or certification.
- **NIST 800‑53**: Evidence supports multiple control objectives
- **ISO 27001**: Evidence aligns with selected Annex A controls
- **SOC 2**: Evidence supports Trust Services Criteria evaluation
- **GDPR**: Evidence supports accountability and auditability requirements
- **FedRAMP**: Evidence may support control assessment activities

---

## 🔧 **Troubleshooting**

### **Common Issues**

**PowerShell Execution Policy**
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

**Missing Bundle Files**
```powershell
# Generate bundle first
.\Generate-USB-Bundle-Clean.ps1 -OutputPath .\dist
```

**Certificate Not Generated**
```powershell
# Check verifier output
cd verifier
.\verify.ps1 -Verbose
```

---

## 📚 **Next Steps**

### **For Users**
1. Review generated certificate
2. Check evidence logs in `verifier/artifacts/logs/`
3. Validate against your requirements
4. Follow USB-Distribution-Checklist.md for deployment

### **For Developers**
1. Read ASSESSOR-RUN.md for detailed procedures
2. Review REGULATORY-CROSSWALK.md for framework mapping
3. Check CONTRIBUTING.md for development guidelines
4. Run THIRD-PARTY-VALIDATION-PROTOCOL.md for validation

### **For Regulators**
1. Use QUICK-VALIDATE.ps1 for initial assessment
2. Review certificate evidence in detail
3. Validate SHA-256 integrity manifests
4. Follow third-party validation protocol

---

## 🏆 **Success Indicators**

✅ **System Operational**: All 6 EGP claims pass  
✅ **Evidence Generated**: Cryptographic certificates created  
✅ **Integrity Verified**: SHA-256 hashes match  
✅ **Bundle Ready**: USB distribution package created  
✅ **Compliance Validated**: Regulatory frameworks mapped  

---

## 📞 **Need Help?**

- **Documentation**: [README.md](../README.md)
- **Procedures**: [ASSESSOR-RUN.md](../ASSESSOR-RUN.md)
- **Security**: [KEY-REVOCATION.md](../KEY-REVOCATION.md)
- **Community**: [GitHub Discussions](https://github.com/NovaFuse-Technologies/NovaFuse-EGP-VS/discussions)

---

**🎉 Congratulations! You have successfully generated verifiable execution‑governance evidence using NovaFuse‑EGP‑VS.**
