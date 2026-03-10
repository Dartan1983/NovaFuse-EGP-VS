# ---------------------------
# Output / Console compatibility (assessor-grade)
# ---------------------------

# Always force UTF-8 for emitted text where possible
try { :OutputEncoding = [System.Text.UTF8Encoding]::new($false) } catch {}
try { $OutputEncoding = [System.Text.UTF8Encoding]::new($false) } catch {}

# If running on Windows PowerShell / older pwsh, this helps some consoles
try { if ($IsWindows) { chcp 65001 | Out-Null } } catch {}

# Disable ANSI rendering ONLY when supported (PowerShell 7.2+)
try {
    if ($PSVersionTable.PSVersion -ge [Version]"7.2" -and
        $null -ne $PSStyle -and
        $PSStyle.PSObject.Properties.Match('OutputRendering').Count -gt 0) {

        $PSStyle.OutputRendering = 'PlainText'
    }
}
catch {
    # Do not fail verification because of presentation features
}

param(
    $ConfigPath,
    $ArtifactsPath,
    [switch]$Verbose,
    [switch]$Clean
)

# Set default values after param block
if (-not $ConfigPath) { $ConfigPath = "config\profile.json" }
if (-not $ArtifactsPath) { $ArtifactsPath = "artifacts" }

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

Write-Host "[TEST] NovaFuse EGP Verification Harness v0.1" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan

# Create artifacts directories
$dirs = @(
    "$ArtifactsPath\logs",
    "$ArtifactsPath\certs",
    "$ArtifactsPath\temp"
)

foreach ($dir in $dirs) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
}

# Load configuration
if (-not (Test-Path $ConfigPath)) {
    throw "Configuration file not found: $ConfigPath"
}

$config = Get-Content $ConfigPath -Raw | ConvertFrom-Json
Write-Host "[OK] Configuration loaded: $($config.profile.version)" -ForegroundColor Green

# Initialize results
$results = @{}
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

# Run all test suites
$testSuites = @(
    @{Name = "EG01_Determinism"; Path = "..\tests\EG01_determinism"},
    @{Name = "EG02_Refusal"; Path = "..\tests\EG02_refusal"},
    @{Name = "EG03_AuthoritySeparation"; Path = "..\tests\EG03_authority_separation"},
    @{Name = "EG04_IdentityBinding"; Path = "..\tests\EG04_identity_binding"},
    @{Name = "EG05_Evidence"; Path = "..\tests\EG05_evidence"},
    @{Name = "EG06_FailClosed"; Path = "..\tests\EG06_fail_closed"}
)

foreach ($suite in $testSuites) {
    $TestName = $suite.Name
    $TestPath = $suite.Path
    
    Write-Host "[RUN] Running $TestName..." -ForegroundColor Yellow
    
    $testScript = Get-ChildItem -Path $TestPath -Filter "*.ps1" | Select-Object -First 1
    if (-not $testScript) {
        throw "No test script found in $TestPath"
    }
    
    try {
        $testResult = & $testScript.FullName -Config $config -Verbose:$Verbose
        $results[$TestName] = @{
            Status = "PASS"
            Duration = $testResult.Duration
            Details = $testResult.Details
            Timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
        }
        Write-Host "[PASS] $TestName PASSED ($($testResult.Duration)s)" -ForegroundColor Green
    }
    catch {
        $results[$TestName] = @{
            Status = "FAIL"
            Error = $_.Exception.Message
            Timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
        }
        Write-Host "[FAIL] $TestName FAILED: $($_.Exception.Message)" -ForegroundColor Red
        throw
    }
}

$stopwatch.Stop()

# Generate certificate matching GMI-VS class schema
function New-Certificate {
    param(
        [hashtable]$Results,
        [object]$Config,
        [string]$ArtifactsPath
    )
    
    # Calculate integrity hashes
    $verifierHash = (Get-FileHash -Path $PSCommandPath -Algorithm SHA256).Hash
    $profileHash = (Get-FileHash -Path (Join-Path (Split-Path $PSCommandPath) $ConfigPath) -Algorithm SHA256).Hash
    
    # Calculate test suite hashes for integrity verification
    $testHashes = @()
    foreach ($suite in @("EG01_determinism", "EG02_refusal", "EG03_authority_separation", "EG04_identity_binding", "EG05_evidence", "EG06_fail_closed")) {
        $testPath = "..\tests\$suite\test.ps1"
        if (Test-Path $testPath) {
            $testHashes += @{
                suite = $suite
                sha256 = (Get-FileHash -Path $testPath -Algorithm SHA256).Hash
            }
        }
    }
    
    # Generate deterministic certificate ID
    $certId = "egp-0.1-$($Config.profile.componentName)-v$($Config.profile.version)-$($verifierHash.Substring(0, 8))"
    
    # Map test results to claims
    $claims = @{
        EG01 = @{
            status = if ($Results["EG01_Determinism"].Status -eq "PASS") { "PASS" } else { "FAIL" }
            details = "Per-input determinism verified"
        }
        EG02 = @{
            status = if ($Results["EG02_Refusal"].Status -eq "PASS") { "PASS" } else { "FAIL" }
            details = "Explicit refusal semantics verified"
        }
        EG03 = @{
            status = if ($Results["EG03_AuthoritySeparation"].Status -eq "PASS") { "PASS" } else { "FAIL" }
            details = "Authority separation verified"
        }
        EG04 = @{
            status = if ($Results["EG04_IdentityBinding"].Status -eq "PASS") { "PASS" } else { "FAIL" }
            details = "Identity binding verified"
        }
        EG05 = @{
            status = if ($Results["EG05_Evidence"].Status -eq "PASS") { "PASS" } else { "FAIL" }
            details = "Evidence generation verified"
        }
        EG06 = @{
            status = if ($Results["EG06_FailClosed"].Status -eq "PASS") { "PASS" } else { "FAIL" }
            details = "Fail-closed semantics verified"
        }
    }
    
    # Generate certificate matching schema
    $certificate = @{
        schema_version = "egp-certificate-0.1"
        certificate_id = $certId
        issued_at = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
        
        profile = @{
            profile_id = "NovaFuse-EGP"
            profile_version = "0.1"
            scope_note = "Conformance to NovaFuse-EGP-0.1 claims EG-01 through EG-06"
        }
        
        component = @{
            name = $Config.profile.componentName
            version = $Config.profile.version
        }
        
        harness = @{
            name = "NovaFuse-EGP-VS"
            version = "0.1.0"
            entrypoint = "verifier/verify.ps1"
        }
        
        results = @{
            overall = if ($Results.Values.Where({$_.Status -eq "FAIL"}).Count -eq 0) { "PASS" } else { "FAIL" }
            claims = $claims
            tests_run = @("EG01_Determinism", "EG02_Refusal", "EG03_AuthoritySeparation", "EG04_IdentityBinding", "EG05_Evidence", "EG06_FailClosed")
            metrics = @{
                total_duration_ms = [int]($stopwatch.Elapsed.TotalMilliseconds)
                suite_count = 6
            }
        }
        
        integrity = @{
            verifier_sha256 = $verifierHash
            profile_sha256 = $profileHash
            tests_sha256 = @{
                suite_hashes = $testHashes
            }
        }
        
        artifacts = @{
            certificate_path = "artifacts\certs\certificate-egp-0.1-$($Config.profile.componentName)-v$($Config.profile.version).json"
            logs = @("artifacts\logs")
        }
        
        # Signature block (placeholder - optional for conformance)
        signature = $null
    }
    
    $certPath = "$ArtifactsPath\certs\certificate-egp-0.1-$($Config.profile.componentName)-v$($Config.profile.version).json"
    $certificate | ConvertTo-Json -Depth 10 | Out-File -FilePath $certPath -Encoding UTF8
    
    Write-Host "[CERT] Certificate generated: $certPath" -ForegroundColor Cyan
    Write-Host "[INFO] Certificate ID: $certId" -ForegroundColor Gray
    Write-Host "[INFO] Verifier SHA256: $($verifierHash.Substring(0, 16))..." -ForegroundColor Gray
    Write-Host "[INFO] Profile SHA256: $($profileHash.Substring(0, 16))..." -ForegroundColor Gray
    
    return $certPath
}

# Generate certificate
$certPath = New-Certificate -Results $results -Config $config -ArtifactsPath $ArtifactsPath

# Summary
Write-Host "`n[SUMMARY] VERIFICATION SUMMARY" -ForegroundColor Cyan
Write-Host "======================" -ForegroundColor Cyan
Write-Host "Total Duration: $($stopwatch.Elapsed.TotalSeconds)s" -ForegroundColor White
Write-Host "Tests Run: $($results.Count)" -ForegroundColor White
Write-Host "Passed: $($($results.Values.Where({$_.Status -eq 'PASS'}).Count))" -ForegroundColor Green
Write-Host "Failed: $($($results.Values.Where({$_.Status -eq 'FAIL'}).Count))" -ForegroundColor $(if ($results.Values.Where({$_.Status -eq 'FAIL'}).Count -gt 0) { 'Red' } else { 'Green' })
Write-Host "Certificate: $certPath" -ForegroundColor Cyan

if ($results.Values.Where({$_.Status -eq "FAIL"}).Count -gt 0) {
    Write-Host "`n[FAIL] VERIFICATION FAILED" -ForegroundColor Red
    exit 1
} else {
    Write-Host "`n[PASS] VERIFICATION PASSED" -ForegroundColor Green
    exit 0
}
