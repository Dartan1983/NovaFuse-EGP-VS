# NovaFuse‑EGP‑VS v0.1 — Change Control & Recertification Triggers

## Final Certificate Output Rules (Non-Interpretive)

These are the final "no wiggle room" rules that keep certification credible:

1. **PASS only if** all EG01–EG06 are PASS and `results.overall = "PASS"`.
2. **Fail closed on integrity**:
   - If verifier/profile/tests hashes don't match expected values, that run is **FAIL** (or "INTEGRITY FAIL") even if tests pass.
3. **No Unicode in normative logs**:
   - ASCII output for transcripts used in certification reports.
4. **Presentation controls are non-normative**:
   - The harness MUST NOT fail based on PSStyle features. (`PSStyle.OutputRendering` is PowerShell 7.2+ only.)
5. **Certificate ID convention**:
   - Certificate ID suffix is the first 8 hex chars of verifier_sha256.
6. **Schema compliance**:
   - Certificate MUST validate against `cert-schema/egp-certificate.schema.json`.
   - All required fields MUST be present with correct data types.

## Recertification Required

Recertification with the NovaFuse‑EGP‑VS harness is **required** if **any** of the following change:

### Core Integrity Components
- **Verifier hash changes** (`verifier_sha256`)
  - Any modification to `verifier/verify.ps1`
  - Changes to harness logic, test execution, or certificate generation
- **Profile hash changes** (`profile_sha256`)
  - Any modification to `verifier/config/profile.json`
  - Changes to conformance requirements, test parameters, or evaluation scope
- **Test suite hash changes** (`tests_sha256`)
  - Any modification to test vectors in `/tests/` directories
  - Changes to test logic, expected outcomes, or evaluation criteria
- **Evidence schema changes**
  - Changes to certificate schema (`cert-schema/egp-certificate.schema.json`)
  - Changes to evidence collection or artifact structure

### Component Changes
- **Component version changes**
  - Any change to the component under assessment version
  - New builds, deployments, or configuration changes
- **Component interface changes**
  - Changes to APIs, inputs, outputs, or behavior that affect test vectors

### Assessment Boundary Changes
- **Scope modifications**
  - Changes to what is considered in/out of scope for evaluation
  - Addition or removal of test suites or claims
- **Environment changes**
  - Changes to runtime environment that could affect deterministic behavior

## Change Classification

### Minor Changes (Documentation Only)
- Updates to this CHANGE_CONTROL.md file
- Updates to ASSESSOR-RUN.md runbook procedures
- Comments or formatting changes that do not affect logic

### Major Changes (Require Recertification)
- Any change listed under "Recertification Required" above
- Changes that affect the binary PASS/FAIL outcome of any EG suite
- Changes to integrity hashes or certificate schema

## Verification Process

### Before Deployment
1. Calculate SHA-256 hashes of all integrity components
2. Compare against baseline hashes from last certification
3. If any hash differs, initiate recertification process

### Recertification Steps
1. Run full verification harness: `.\verify.ps1`
2. Validate new certificate against schema
3. Update baseline hash documentation
4. Archive previous certificate and artifacts
5. Issue new certificate with updated integrity hashes

## Change Log Template

```markdown
## [Date] - Change Description
**Type:** [Minor/Major]
**Components Affected:** [verifier/profile/tests/schema]
**Hash Impact:** [Yes/No]
**Recertification Required:** [Yes/No]
**Reason:** [Detailed explanation]
**Baseline Hashes:**
- verifier_sha256: [hash]
- profile_sha256: [hash]
- tests_sha256: [hash]
```

## Baseline Hashes (v0.1.0)

*Initial baseline established at first certification:*

- **verifier_sha256**: [To be populated after first run]
- **profile_sha256**: [To be populated after first run]  
- **tests_sha256**: [To be populated after first run]
- **certificate_schema_sha256**: [To be populated after first run]

## Contact

For questions about change control or recertification requirements:
- Review the ASSESSOR-RUN.md for evaluation procedures
- Consult the NovaFuse‑EGP‑0.1 specification for conformance requirements
- Reference the certificate schema for validation requirements
