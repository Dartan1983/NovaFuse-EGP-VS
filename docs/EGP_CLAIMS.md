# EGP Claims Mapping
# Mapping of EG-01…EG-06 to test cases and verification criteria

## Overview

This document maps the NovaFuse Evidence Governance Protocol (EGP) claims to their corresponding test implementations in the NovaFuse-EGP-VS verification harness.

## EG-01: Deterministic Admissibility

**Claim**: The component produces identical decision outputs for identical inputs across multiple runs, platforms, and timestamps.

### Test Implementation
- **Location**: `tests/EG01_determinism/test.ps1`
- **Verification Method**: Run 100 deterministic evaluations with randomized order
- **Success Criteria**: Single unique hash across all evaluations
- **Configuration**: `config/profile.json` → `testMatrix.EG01_Determinism`

### Test Cases
1. **High-clearance access request** - Admin user accessing top-secret data
2. **Medium-clearance operation** - Service account writing to production config
3. **Low-clearance maintenance** - Operator executing staging scripts

### Assertions
- ✅ Identical inputs produce identical outputs
- ✅ Hash uniqueness maintained across runs
- ✅ Randomized execution order doesn't affect determinism
- ✅ Timestamp variations don't influence decision logic

## EG-02: Explicit Refusal as First-Class Outcome

**Claim**: The component returns explicit refusal for invalid proposals without fallback or degraded behavior.

### Test Implementation
- **Location**: `tests/EG02_refusal/test.ps1`
- **Verification Method**: Submit known-invalid proposals
- **Success Criteria**: Explicit refusal returned, logged as success
- **Configuration**: `config/profile.json` → `testMatrix.EG02_Refusal`

### Test Cases
1. **Missing required fields** - Null action field
2. **Disallowed actions** - System disk formatting attempt
3. **Malformed syntax** - Invalid path characters
4. **Overflow conditions** - Buffer overflow attempt

### Assertions
- ✅ Refusal outcome explicitly returned
- ✅ No error or exception states
- ✅ No fallback to degraded operation
- ✅ Refusal logged as successful outcome

## EG-03: Authority Separation

**Claim**: The component has no proposal-generation capability and maintains strict authority boundaries.

### Test Implementation
- **Location**: `tests/EG03_authority_separation/test.ps1`
- **Verification Method**: Static analysis + runtime inspection
- **Success Criteria**: No forbidden capabilities detected
- **Configuration**: `config/profile.json` → `testMatrix.EG03_AuthoritySeparation`

### Test Cases
1. **Static code analysis** - Scan for forbidden patterns
2. **Runtime inspection** - Check interface capabilities
3. **Boundary violation attempts** - Test internal proposal generation

### Assertions
- ✅ No proposal generation interfaces found
- ✅ No self-modification capabilities detected
- ✅ No privilege escalation paths identified
- ✅ Boundary violations properly blocked

## EG-04: Identity-Bound Evaluation

**Claim**: Decisions differ based on identity scope and missing identity triggers fail-closed behavior.

### Test Implementation
- **Location**: `tests/EG04_identity_binding/test.ps1`
- **Verification Method**: Test identical proposals from different identities
- **Success Criteria**: Decision differentiation and proper failure handling
- **Configuration**: `config/profile.json` → `testMatrix.EG04_IdentityBinding`

### Test Cases
1. **Administrator identity** - Full scope access
2. **Regular user identity** - Limited scope access
3. **Service account identity** - Service-specific scope
4. **Anonymous identity** - Public scope only
5. **Missing identity** - Fail-closed behavior

### Assertions
- ✅ Different identities produce different decisions
- ✅ Clearance levels properly enforced
- ✅ Permission boundaries respected
- ✅ Missing identity triggers refusal

## EG-05: Non-Repudiable Evidence

**Claim**: Each decision generates cryptographically signed log evidence supporting replay verification.

### Test Implementation
- **Location**: `tests/EG05_evidence/test.ps1`
- **Verification Method**: Evidence generation and verification
- **Success Criteria**: Complete log artifacts with valid signatures
- **Configuration**: `config/profile.json` → `testMatrix.EG05_Evidence`

### Test Cases
1. **Admission decision evidence** - Complete evidence for approved request
2. **Refusal decision evidence** - Complete evidence for denied request
3. **Conditional decision evidence** - Evidence for complex evaluation

### Assertions
- ✅ All required log fields present
- ✅ Cryptographic signatures valid
- ✅ Evidence hash integrity maintained
- ✅ Replay verification produces identical decisions
- ✅ Non-repudiation guarantees satisfied

## EG-06: Fail-Closed Semantics

**Claim**: The component refuses execution under failure conditions with no partial execution or silent failure.

### Test Implementation
- **Location**: `tests/EG06_fail_closed/test.ps1`
- **Verification Method**: Induce various failure conditions
- **Success Criteria**: Proper refusal and no partial execution
- **Configuration**: `config/profile.json` → `testMatrix.EG06_FailClosed`

### Test Cases
1. **Missing context fields** - Incomplete request context
2. **Corrupt identity** - Invalid identity parameters
3. **Internal error** - Simulated component failure
4. **Resource exhaustion** - Memory/CPU threshold breach

### Assertions
- ✅ Failure conditions trigger explicit refusal
- ✅ No partial execution occurs
- ✅ No silent failures detected
- ✅ Proper error handling and logging

## Verification Matrix

| EGP Claim | Test Suite | Pass Criteria | Configuration |
|-----------|------------|----------------|--------------|
| EG-01 | EG01_determinism | Hash uniqueness = 1 | `determinismRuns = 100` |
| EG-02 | EG02_refusal | Explicit refusal only | `expectExplicitRefusal = true` |
| EG-03 | EG03_authority_separation | No forbidden capabilities | `staticAnalysis = true` |
| EG-04 | EG04_identity_binding | Decision differentiation | `failOnMissing = true` |
| EG-05 | EG05_evidence | Complete signed evidence | `cryptographicSigning = true` |
| EG-06 | EG06_fail_closed | Refusal on failure | `expectRefusal = true` |

## Certificate Output

Successful verification generates:
```
certificate-egp-0.1-novadust-vX.Y.json
```

Containing:
- Component name and version
- EGP version compliance
- Test matrix results
- Cryptographic signature
- Verification timestamp

## Continuous Integration

The verification harness is designed for CI/CD integration:
- Deterministic execution
- No interpretive dependencies
- Clear pass/fail outcomes
- Artifact generation for audit trails

---

**Version**: 0.1.0  
**EGP Specification**: 0.1  
**Last Updated**: 2026-03-09T04:21:00Z
