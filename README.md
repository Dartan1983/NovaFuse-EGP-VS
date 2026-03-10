
# NovaFuse-EGP-VS v0.1.2

[![Build Status](https://github.com/Dartan1983/NovaFuse-EGP-VS/workflows/validation.yml/badge.svg)](https://github.com/Dartan1983/NovaFuse-EGP-VS/actions)
[![Validation](https://img.shields.io/badge/validation-6%2F6%20PASS-brightgreen)](https://github.com/Dartan1983/NovaFuse-EGP-VS)
[![Status](https://img.shields.io/badge/status-pre--release-orange)](https://github.com/Dartan1983/NovaFuse-EGP-VS/releases)
[![Purpose](https://img.shields.io/badge/purpose-auditor%20evaluation-blue)](https://github.com/Dartan1983/NovaFuse-EGP-VS)
[![Use](https://img.shields.io/badge/use-non--production-lightgrey)](https://github.com/Dartan1983/NovaFuse-EGP-VS)
[![Version](https://img.shields.io/badge/version-v0.1.2-orange)](https://github.com/Dartan1983/NovaFuse-EGP-VS/releases/tag/v0.1.2)
[![License](https://img.shields.io/badge/license-Proprietary-blue)](https://github.com/Dartan1983/NovaFuse-EGP-VS/blob/main/LICENSE)
[![Platform](https://img.shields.io/badge/platform-Windows%20%7C%20Linux%20%7C%20macOS-lightgrey)](https://github.com/Dartan1983/NovaFuse-EGP-VS)
## NovaFuse-EGP-VS v0.1.2


**NovaFuse Evidence Governance Protocol (EGP) Verification Harness** — Deterministic, CI-runnable evaluation harness for assessing conformance to NovaFuse-EGP-0.1, designed for auditors, regulators, and high-assurance environments.

## Overview

🧪 **NovaFuse‑EGP‑VS v0.1.2** provides a **deterministic, fully verifiable test harness** for evaluating systems against the NovaFuse Evidence Governance Protocol (EGP). All six core EGP guarantees are verified with CI-compatible tooling and reproducible outcomes.

## Quick Start

> **Prerequisite:** PowerShell 7.0+ must be installed.

```powershell
# Run full verification suite
.\src\scripts\VALIDATE-SYSTEM.ps1

# Run with verbose output
.\src\scripts\VALIDATE-SYSTEM.ps1 -Verbose

# Clean artifacts and rerun
.\src\scripts\VALIDATE-SYSTEM.ps1 -Clean
```

---

## Architecture

```text
                  ┌───────────────────┐
                  │ VALIDATE-SYSTEM.ps1 │
                  │  (Verifier Entry) │
                  └────────┬─────────┘
                           │
           ┌───────────────┴────────────────┐
           │                                │
  ┌────────▼─────────┐             ┌────────▼─────────┐
  │    src/tests/    │             │  config/         │
  │ EG01..EG06 suites│             │ profile.json     │
  └────────┬─────────┘             └────────┬─────────┘
           │                                │
           └───────────────┬────────────────┘
                           │
                  ┌────────▼─────────┐
                  │   artifacts/     │
                  │  logs/           │
                  │  certs/          │
                  │  sbom.spdx.json  │
                  └────────┬─────────┘
                           │
                  ┌────────▼─────────┐
                  │ Verification     │
                  │ Certificate      │
                  │ (Cryptographically Signed) │
                  └───────────────────┘
```

**Diagram Notes:**

* **VALIDATE-SYSTEM.ps1** pulls configuration and executes all EG01–EG06 test suites.
* **artifacts/** stores logs, certificates, and SBOMs for full auditability.
* **Certificate output** includes cryptographic signatures to verify authenticity.

## EGP Test Suites

| Test                                  | Purpose                                                 | Method                                             | Success Criteria                                     |
| ------------------------------------- | ------------------------------------------------------- | -------------------------------------------------- | ---------------------------------------------------- |
| **EG-01 Deterministic Admissibility** | Verify identical inputs produce identical outputs       | 100 deterministic evaluations in randomized order  | Single unique hash across all runs                   |
| **EG-02 Explicit Refusal**            | Ensure invalid proposals receive explicit refusal       | Submit known-invalid proposals                     | Refusal returned with no fallback behavior           |
| **EG-03 Authority Separation**        | Verify no unauthorized proposal-generation capabilities | Static analysis + runtime inspection               | No forbidden capabilities detected                   |
| **EG-04 Identity-Bound Evaluation**   | Ensure decisions differ based on identity               | Test identical proposals from different identities | Decision differentiation and proper failure handling |
| **EG-05 Non-Repudiable Evidence**     | Verify comprehensive evidence generation                | Evidence generation + cryptographic verification   | Complete signed evidence with replay capability      |
| **EG-06 Fail-Closed Semantics**       | Ensure safe failure under all conditions                | Induce various failure conditions                  | Proper refusal with no partial execution             |

## Configuration

Configured via `src/config/profile.json`:

```json
{
  "profile": {
    "name": "NovaFuse-EGP-0.1",
    "version": "0.1.2",
    "componentName": "novadust",
    "egpVersion": "0.1"
  },
  "verification": {
    "determinismRuns": 100,
    "timeoutSeconds": 300,
    "strictMode": true
  },
  "testMatrix": {
    "EG01_Determinism": {
      "runs": 100,
      "randomizedOrder": true,
      "expectedHashUniqueness": 1
    }
    /* Additional tests follow similar configuration */
  }
}
```

> **Note:** SBOM (`sbom.spdx.json`) tracks all dependencies for audit and reproducibility.

## Supported Execution Modes

| Mode                  | Primary User                         | Purpose                               | Notes                                                     |
| --------------------- | ------------------------------------ | ------------------------------------- | --------------------------------------------------------- |
| **Native PowerShell** | Assessors, auditors, regulators      | Official evaluations, on-site reviews | Recommended for high-assurance audits                     |
| **Docker**            | CI/CD pipelines, DevSecOps           | Automated testing, regression testing | Mount artifacts folder; adjust paths for Windows vs Linux |
| **Offline/USB**       | High-trust organizations, regulators | Air-gapped verification               | Verify SHA-256 of key files prior to execution            |

**Docker Example:**

```bash
# Using Docker Compose
docker-compose up novafuse-egp-vs-native

# Direct Docker run
docker run --rm -v $(pwd)/artifacts:/harness/src/artifacts novafuse/egp-vs:0.1.2 ./VALIDATE-SYSTEM.ps1
```

## Certificate Output

Successful verification produces a cryptographically signed certificate:

> **Note:** Certificates generated by this harness are verification artifacts. Only certificates issued or countersigned by NovaFuse Technologies or authorized partners constitute official NovaFuse certification.

```json
{
  "componentName": "novadust",
  "version": "0.1.2",
  "egpVersion": "0.1",
  "timestamp": "2026-03-09T04:21:00Z",
  "verifierHash": "sha256hash",
  "testMatrix": {
    "EG01_Determinism": { "Status": "PASS", "Duration": 2.3 }
    /* Other tests included similarly */
  },
  "overallStatus": "PASS",
  "signature": "PKI_signed_credential"
}
```

## CI/CD Integration

**GitHub Actions:**

```yaml
- name: Run NovaFuse EGP Verification
  run: |
    cd NovaFuse-EGP-VS
    ./src/scripts/VALIDATE-SYSTEM.ps1 -Verbose
```

**Azure Pipelines:**

```yaml
- task: PowerShell@2
  inputs:
    filePath: 'NovaFuse-EGP-VS/src/scripts/VALIDATE-SYSTEM.ps1'
    arguments: '-Verbose'
```

> Tip: Use `-Clean` for fresh artifact generation in CI runs.

---

## Requirements

* PowerShell 7.0+
* Windows 10+ / Windows Server 2019+, or Linux/macOS
* .NET Framework 4.8+
* Minimum 256MB RAM
* Minimum 100MB disk space

---

## Safety & Compliance

* ISO 27001 aligned security controls
* NIST 800-53 compliance framework
* SOC 2 Type II ready
* Export Control compliant
* GDPR privacy considerations

---

## Contributing

1. Fork the repository
2. Create a feature branch
3. Implement tests or verification changes
4. Run verification suite
5. Submit a pull request

---

## License

Proprietary certification infrastructure license (NCIL v0.1).
Source-available for audit and reproducibility.
Certification issuance and mark usage reserved.

## Team

**NovaFuse-EGP-VS** represents a significant advancement in verification technology and institutional compliance. This project embodies the convergence of:

- **Cryptographic verification** with deterministic outcomes
- **Evidence governance** with audit-worthy documentation  
- **Professional architecture** with enterprise-grade security
- **Regulatory alignment** with framework mapping capabilities

**Built with institutional precision and designed for maximum credibility.**

---

---

## Support

* **Security Issues:** [novafuse.technologies@gmail.com](mailto:novafuse.technologies@gmail.com)
* **Compliance Questions:** [novafuse.technologies@gmail.com](mailto:novafuse.technologies@gmail.com)
* **Technical Support:** [novafuse.technologies@gmail.com](mailto:novafuse.technologies@gmail.com)

---

## About

Deterministic verification system for evaluating conformance to the NovaFuse Evidence Governance Protocol (EGP), designed for auditors, regulators, and high‑assurance environments.

## Resources

- **Readme** - Current documentation
- **License** - View license
- **Contributing** - Contributing
- **Security policy** - Security policy
- **Activity** - Project activity

---

**Version:** 0.1.2
**EGP Specification:** 0.1
**Release Date:** 2026-03-09
**Next Review:** 2026-06-09
