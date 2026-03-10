# Release Notes — NovaFuse‑EGP‑VS

This document captures **release‑specific notes, intent, and context** for NovaFuse‑EGP‑VS.  
It complements `RELEASE.md`, which serves as the **canonical technical and governance record**.

Release notes may evolve between versions as the project matures.

---

## v0.1.2 — Initial Public Evaluation Release

**Released:** 2026‑03‑09

### Summary

This is the **first public release** of the **NovaFuse Evidence Governance Protocol Verification Suite (EGP‑VS)**.

Version v0.1.2 introduces a deterministic verification harness for evaluating whether systems implement the structural guarantees required by the **Evidence Governance Protocol (EGP)**.

This release is published as an **evaluation artifact** for structured technical review.

---

### What Changed

- Initial public availability of the EGP‑VS verification harness
- Six core governance invariant test suites (EG01–EG06)
- Deterministic, reproducible verification execution
- Cryptographically verifiable evidence and certificate generation
- CI‑compatible workflows validated and operational
- Offline and air‑gapped evaluation support
- Documentation and schemas prepared for auditor review

---

### Why This Release Exists

Prior approaches to AI governance have relied largely on:

- policy descriptions
- internal testing assurances
- non‑verifiable safety claims

EGP‑VS introduces a different model.

Instead of asking whether a system *claims* to follow governance rules, the harness **directly evaluates those rules** and produces **cryptographically verifiable evidence** of the outcome.

This release exists to move governance from **assertion** to **observable, reproducible verification**.

---

### What This Release Is — and Is Not

**This release is:**

- A deterministic verification harness
- An evaluation tool for auditors and reviewers
- A mechanism for producing verifiable governance evidence

**This release is not:**

- A runtime enforcement system
- A production NovaFuse implementation
- A certification or compliance authority
- A safety or risk guarantee

All outputs should be treated as **signals for further human review**.

---

### Intended Audience

This release is intended for:

- Independent auditors
- Governance and compliance reviewers
- Architecture and assurance teams
- Researchers studying verifiable AI governance

---

### Version Status

- **Version:** v0.1.2
- **Maturity:** Early / Pre‑Standard

The `v0.x` series is intentionally unstable. Breaking changes may occur without notice or backward compatibility.

---

### Relationship to Other Artifacts

- `RELEASE.md` — Canonical release specification and scope
- GitHub Release page — Public release announcement
- Repository structure — Executable verification harness and evidence tooling

For architectural context, see:

- NovaFuse Cyber‑Safety Reference Architecture
- GMI‑VS
- MedGemma‑ERI

---

### Looking Ahead

Future releases may expand:

- governance invariant coverage
- artifact verification mechanisms
- integration capabilities

The deterministic verification model established in v0.1.2 is expected to remain stable.

---

© NovaFuse Technologies — March 2026
