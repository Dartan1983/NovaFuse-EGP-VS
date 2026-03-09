# NovaFuse-EGP-VS USB Distribution Checklist

This checklist ensures that a USB bundle is complete, verifiable, and ready for offline certification use.

## ✅ USB Bundle Contents

- [ ] verifier/verify.ps1
- [ ] verifier/config/profile.json
- [ ] tests/EG01_determinism/
- [ ] tests/EG02_refusal/
- [ ] tests/EG03_authority_separation/
- [ ] tests/EG04_identity_binding/
- [ ] tests/EG05_evidence/
- [ ] tests/EG06_fail_closed/
- [ ] cert-schema/egp-certificate.schema.json
- [ ] ASSESSOR-RUN.md
- [ ] CHANGE_CONTROL.md
- [ ] README.md
- [ ] RELEASE-HASHES.txt
- [ ] RELEASE-HASHES.txt.sig
- [ ] NovaFuse-PublicKey.asc

## 🔐 Integrity Verification

- [ ] All files listed in `RELEASE-HASHES.txt` 
- [ ] Signature file `RELEASE-HASHES.txt.sig` present
- [ ] Public key `NovaFuse-PublicKey.asc` included
- [ ] Signature verified using GPG
- [ ] All file hashes verified using `sha256sum -c` 

## 💾 USB Media Requirements

- [ ] USB drive is write-locked (if possible)
- [ ] USB is labeled with version and date (e.g., "NovaFuse-EGP-VS v0.1.0 – Certified Bundle")
- [ ] SHA-256 summary printed and included in physical packaging (optional)

## 🧪 Final Test

- [ ] Run `verify.ps1` on an offline machine
- [ ] Confirm certificate is generated
- [ ] Confirm certificate validates against schema
- [ ] Confirm certificate includes correct component/version/profile

## 📦 Distribution Notes

- [ ] Bundle zipped for archival (optional)
- [ ] Bundle notarized or timestamped (optional)
- [ ] Distribution logged in internal registry
