# NovaFuse‑EGP‑VS v0.1 — Assessor Runbook (ASSESSOR-RUN.md)

## Purpose
This runbook defines a deterministic, non-interpretive procedure for an independent assessor
to evaluate a target component (e.g., "NovaDust") against the NovaFuse‑EGP‑0.1 conformance profile
using the NovaFuse‑EGP‑VS verification harness.

The evaluation result is a binary outcome:
- PASS: All EG suites pass and a certificate JSON artifact is generated.
- FAIL: Any EG suite fails and no PASS certificate is generated.

## Scope (Evaluation Boundary)
IN SCOPE:
- The verification harness execution (verify.ps1)
- The harness configuration profile used by the verifier (profile.json)
- The defined EGP test suites and test vectors included in this evaluation package
- The generated artifacts (certificate, logs, SBOM if included)

OUT OF SCOPE:
- Whether the policies enforced are ethically correct
- Whether the organization is compliant with any specific regulation
- Any system outside the assessed component + harness boundary (e.g., models, UI, pipelines)

## Requirements
### Software
- PowerShell:
  - Windows PowerShell 5.1 OR PowerShell 7+
  - Note: `$PSStyle.OutputRendering` exists in PowerShell 7.2+ and may be absent on older versions.
    The harness must not fail if OutputRendering is unsupported. (Presentation is non-normative.)  
- Git (optional, if assessing a repository)
- SHA-256 tool:
  - PowerShell `Get-FileHash` is sufficient.

### Files Provided by Developer (Assessor Pack)
The assessor pack SHOULD include:
- /verifier/verify.ps1
- /verifier/config/profile.json
- /tests/** (test suites and vectors)
- /docs/NovaFuse-EGP-0.1.md (conformance claims EG-01..EG-06)
- /docs/EGP_CLAIMS.md (mapping: claim → test suite → vectors)
- /cert-schema/egp-certificate.schema.json (certificate schema)
- Optional: /sbom/*.spdx.json

## Step 0 — Record Environment (for the Assessment Report)
Run:
- `$PSVersionTable` 
- OS name/version
- CPU architecture (optional)

Record:
- PowerShell version
- OS and version
- Assessment date/time (informational)

## Step 1 — Acquire the Evaluation Package
Option A: Zip delivered by developer
- Unzip into a local directory (e.g., `D:\NovaFuse-EGP-VS\`)

Option B: Git repository tag/commit (if applicable)
- Clone repository
- Checkout the exact tag/commit under assessment

## Step 2 — Verify Package Integrity (Recommended)
If the assessor pack provides expected hashes, verify them BEFORE running.

Example (PowerShell):
- `Get-FileHash .\verifier\verify.ps1 -Algorithm SHA256` 
- `Get-FileHash .\verifier\config\profile.json -Algorithm SHA256` 
- `Get-FileHash .\tests\manifest.json -Algorithm SHA256` (if a manifest exists)

Compare to the expected SHA-256 values documented by the developer for this assessment boundary.

If any mismatch occurs:
- STOP.
- Mark the evaluation as "INTEGRITY FAIL" (package does not match declared boundary).

## Step 3 — Execute the Harness
From the verifier directory:

```powershell
cd .\verifier
.\verify.ps1
```

Optional modes if supported by the harness:

*   Verbose: `.\verify.ps1 -Verbose` 
*   Clean run: `.\verify.ps1 -Clean` 

Expected behavior:

*   The harness prints:
    *   Harness version
    *   Profile version loaded
    *   Each EG suite begins with [RUN] and ends with [PASS] or [FAIL]
*   On success:
    *   The harness generates a certificate JSON artifact
    *   The harness prints the certificate path

## Step 4 — Confirm Deterministic Pass/Fail

The assessor SHOULD run the full harness at least twice on the same machine
to confirm stable results.

Criteria:

*   PASS run: all suites PASS, certificate generated
*   FAIL run: any suite FAIL, certificate not generated (or generated certificate marked FAIL)

## Step 5 — Validate Certificate Artifact

If the harness reports PASS, locate the certificate path printed at the end, e.g.:

*   `artifacts\certs\certificate-egp-0.1-<component>-v<version>.json` 

Perform:

1.  JSON validity check
2.  Schema validation against `cert-schema/egp-certificate.schema.json` 
3.  Integrity check:
    *   Confirm the certificate contains:
        *   verifier_sha256
        *   profile_sha256
        *   test_suites_sha256 (or manifest hash)
4.  Signature check:
    *   If the certificate includes a signature and public key / key id, verify signature
    *   If signature verification tooling is provided, run it and record output

## Step 6 — Evidence Review (EG-05)

Confirm the certificate references evidence artifacts (if produced), such as:

*   logs path(s)
*   test results path(s)
*   SBOM path(s) (optional)

Verify that referenced paths exist in the artifacts directory for the run.

## Step 7 — Assessment Report Inputs (What to Copy into the Report)

Include in the report:

*   Exact command executed
*   Harness version and profile version
*   Pass/fail for EG-01..EG-06
*   Certificate file name and SHA-256 of the certificate
*   verifier_sha256 and profile_sha256 as reported
*   Date/time and environment details (PS version, OS)

Suggested conformance statement:
"<Component> v<version> was assessed against NovaFuse‑EGP‑0.1 using the NovaFuse‑EGP‑VS harness
and demonstrated conformance to EG‑01 through EG‑06 for the defined evaluation boundary."

## Fail Conditions (Non-Interpretive)

Any of the following is a FAIL:

*   Any EG suite reports FAIL
*   Package integrity hash mismatch (if hashes declared)
*   Certificate cannot be validated against schema
*   Certificate signature cannot be validated (if signature is required for conformance in this assessment)
*   Evidence artifacts referenced by the certificate are missing (if required by profile)
