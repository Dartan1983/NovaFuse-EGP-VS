# NovaFuse-EGP-VS One-Click System Validation
# Complete end-to-end validation of the constitutional compliance infrastructure

param(
    [Parameter(Mandatory=$false)]
    [string]$BundlePath = ".\dist\NovaFuse-EGP-VS-v0.1.0",
    
    [Parameter(Mandatory=$false)]
    [switch]$Detailed,
    
    [Parameter(Mandatory=$false)]
    [switch]$GenerateReport
)

Write-Host "NovaFuse-EGP-VS System Validation" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""

# Validation Results
$Results = @{
    Environment = @{}
    BundleIntegrity = @{}
    VerificationHarness = @{}
    CertificateValidation = @{}
    EvidenceIntegrity = @{}
    OverallStatus = "UNKNOWN"
}

Write-Host "Phase 1: Environment Validation" -ForegroundColor Yellow
Write-Host "----------------------------" -ForegroundColor Yellow

# Check PowerShell Version
$Results.Environment.PowerShellVersion = $PSVersionTable.PSVersion.ToString()
$Results.Environment.PowerShellCompatible = $PSVersionTable.PSVersion -ge [Version]"5.1.0"
$status = if ($Results.Environment.PowerShellCompatible) { '✅' } else { '❌' }
    Write-Host "PowerShell: $($Results.Environment.PowerShellVersion) - $status" -ForegroundColor $(if ($Results.Environment.PowerShellCompatible) { 'Green' } else { 'Red' })

# Check Python
try {
    $pythonVersion = & python --version 2>$null
    $Results.Environment.PythonVersion = $pythonVersion
    $Results.Environment.PythonAvailable = $true
    Write-Host "Python: $pythonVersion - ✅" -ForegroundColor Green
} catch {
    $Results.Environment.PythonAvailable = $false
    Write-Host "Python: Not Available - ⚠️" -ForegroundColor Yellow
}

# Check GPG
try {
    $gpgVersion = & gpg --version 2>$null
    $Results.Environment.GPGVersion = $gpgVersion[0]
    $Results.Environment.GPGAvailable = $true
    Write-Host "GPG: $($Results.Environment.GPGVersion) - ✅" -ForegroundColor Green
} catch {
    $Results.Environment.GPGAvailable = $false
    Write-Host "GPG: Not Available - ⚠️" -ForegroundColor Yellow
}

# Check Bundle Path
$Results.Environment.BundlePath = $BundlePath
$Results.Environment.BundleExists = Test-Path $BundlePath
Write-Host "Bundle Path: $BundlePath - $($($Results.Environment.BundleExists ? '✅' : '❌'))" -ForegroundColor $(if ($Results.Environment.BundleExists) { 'Green' } else { 'Red' })

if (-not $Results.Environment.BundleExists) {
    Write-Host "❌ Bundle not found at $BundlePath" -ForegroundColor Red
    Write-Host "Please run: .\Generate-USB-Bundle-Clean.ps1 -OutputPath .\dist" -ForegroundColor Yellow
    exit 1
}

Write-Host ""
Write-Host "Phase 2: Bundle Integrity Validation" -ForegroundColor Yellow
Write-Host "----------------------------------" -ForegroundColor Yellow

# Check SHA-256 Manifest
$manifestPath = "$BundlePath\RELEASE-HASHES.txt"
$Results.BundleIntegrity.ManifestExists = Test-Path $manifestPath
Write-Host "SHA-256 Manifest: $($($Results.BundleIntegrity.ManifestExists ? '✅' : '❌'))" -ForegroundColor $(if ($Results.BundleIntegrity.ManifestExists) { 'Green' } else { 'Red' })

# Check Public Key
$publicKeyPath = "$BundlePath\NovaFuse-PublicKey.asc"
$Results.BundleIntegrity.PublicKeyExists = Test-Path $publicKeyPath
Write-Host "Public Key: $($($Results.BundleIntegrity.PublicKeyExists ? '✅' : '❌'))" -ForegroundColor $(if ($Results.BundleIntegrity.PublicKeyExists) { 'Green' } else { 'Red' })

# Check Metadata
$metadataPath = "$BundlePath\BUNDLE-METADATA.json"
$Results.BundleIntegrity.MetadataExists = Test-Path $metadataPath
Write-Host "Bundle Metadata: $($($Results.BundleIntegrity.MetadataExists ? '✅' : '❌'))" -ForegroundColor $(if ($Results.BundleIntegrity.MetadataExists) { 'Green' } else { 'Red' })

# Verify File Hashes
if ($Results.BundleIntegrity.ManifestExists) {
    Write-Host "Verifying file hashes..." -ForegroundColor Gray
    $hashErrors = 0
    $totalFiles = 0
    
    Get-Content $manifestPath | Where-Object { $_ -match "^[a-f0-9]" } | ForEach-Object {
        $expectedHash, $file = $_ -split '  ', 2
        $filePath = "$BundlePath\$file"
        
        if (Test-Path $filePath) {
            $totalFiles++
            $actualHash = (Get-FileHash $filePath -Algorithm SHA256).Hash
            if ($expectedHash -eq $actualHash) {
                if ($Detailed) { Write-Host "  ✅ $file" -ForegroundColor Green }
            } else {
                $hashErrors++
                Write-Host "  ❌ $file - HASH MISMATCH" -ForegroundColor Red
                if ($Detailed) { 
                    Write-Host "    Expected: $expectedHash" -ForegroundColor Gray
                    Write-Host "    Actual: $actualHash" -ForegroundColor Gray
                }
            }
        } else {
            $hashErrors++
            Write-Host "  ❌ $file - MISSING" -ForegroundColor Red
        }
    }
    
    $Results.BundleIntegrity.HashVerificationPassed = ($hashErrors -eq 0)
    $Results.BundleIntegrity.TotalFiles = $totalFiles
    $Results.BundleIntegrity.HashErrors = $hashErrors
    
    Write-Host "Hash Verification: $($totalFiles - $hashErrors) files - $($($Results.BundleIntegrity.HashVerificationPassed ? '✅' : '❌'))" -ForegroundColor $(if ($Results.BundleIntegrity.HashVerificationPassed) { 'Green' } else { 'Red' })
}

Write-Host ""
Write-Host "Phase 3: Verification Harness Test" -ForegroundColor Yellow
Write-Host "--------------------------------" -ForegroundColor Yellow

# Run Verification Harness
$verifierPath = "$BundlePath\verifier"
$Results.VerificationHarness.VerifierExists = Test-Path "$verifierPath\verify.ps1"
Write-Host "Verifier Script: $($($Results.VerificationHarness.VerifierExists ? '✅' : '❌'))" -ForegroundColor $(if ($Results.VerificationHarness.VerifierExists) { 'Green' } else { 'Red' })

if ($Results.VerificationHarness.VerifierExists) {
    Write-Host "Running verification harness..." -ForegroundColor Gray
    
    try {
        Push-Location $verifierPath
        $harnessOutput = & .\verify.ps1 2>&1
        $harnessExitCode = $LASTEXITCODE
        Pop-Location
        
        $Results.VerificationHarness.ExitCode = $harnessExitCode
        $Results.VerificationHarness.Passed = ($harnessExitCode -eq 0)
        
        # Parse Results
        if ($harnessOutput -match "Tests Run: (\d+)") {
            $Results.VerificationHarness.TestsRun = [int]$matches[1]
        }
        if ($harnessOutput -match "Passed: (\d+)") {
            $Results.VerificationHarness.TestsPassed = [int]$matches[1]
        }
        if ($harnessOutput -match "Failed: (\d+)") {
            $Results.VerificationHarness.TestsFailed = [int]$matches[1]
        }
        
        Write-Host "Harness Results: $($Results.VerificationHarness.TestsPassed)/$($Results.VerificationHarness.TestsRun) passed - $($($Results.VerificationHarness.Passed ? '✅' : '❌'))" -ForegroundColor $(if ($Results.VerificationHarness.Passed) { 'Green' } else { 'Red' })
        
        if ($Detailed) {
            Write-Host "Harness Output:" -ForegroundColor Gray
            $harnessOutput | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }
        }
        
    } catch {
        $Results.VerificationHarness.Passed = $false
        $Results.VerificationHarness.Error = $_.Exception.Message
        Write-Host "Harness Error: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Phase 4: Certificate Validation" -ForegroundColor Yellow
Write-Host "-----------------------------" -ForegroundColor Yellow

# Check Generated Certificate
$certPath = "$BundlePath\verifier\artifacts\certs\certificate-egp-0.1-novadust-v0.1.0.json"
$Results.CertificateValidation.CertificateExists = Test-Path $certPath
Write-Host "Certificate Generated: $($($Results.CertificateValidation.CertificateExists ? '✅' : '❌'))" -ForegroundColor $(if ($Results.CertificateValidation.CertificateExists) { 'Green' } else { 'Red' })

if ($Results.CertificateValidation.CertificateExists) {
    try {
        $cert = Get-Content $certPath | ConvertFrom-Json
        $Results.CertificateValidation.OverallStatus = $cert.results.overall
        $Results.CertificateValidation.ValidCertificate = ($cert.results.overall -eq "PASS")
        $Results.CertificateValidation.CertificateId = $cert.metadata.certificate_id
        
        Write-Host "Certificate Status: $($Results.CertificateValidation.OverallStatus) - $($($Results.CertificateValidation.ValidCertificate ? '✅' : '❌'))" -ForegroundColor $(if ($Results.CertificateValidation.ValidCertificate) { 'Green' } else { 'Red' })
        Write-Host "Certificate ID: $($Results.CertificateValidation.CertificateId)" -ForegroundColor Gray
        
        # Check Individual Claims
        $Results.CertificateValidation.Claims = @{}
        $cert.results.claims.PSObject.Properties | ForEach-Object {
            $Results.CertificateValidation.Claims[$_.Name] = $_.Value.status
            $status = if ($_.Value.status -eq "PASS") { "✅" } else { "❌" }
            Write-Host "EG$($_.Name): $($_.Value.status) $status" -ForegroundColor $(if ($_.Value.status -eq "PASS") { 'Green' } else { 'Red' })
        }
        
    } catch {
        $Results.CertificateValidation.ValidCertificate = $false
        $Results.CertificateValidation.Error = $_.Exception.Message
        Write-Host "Certificate Error: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Phase 5: Evidence Integrity" -ForegroundColor Yellow
Write-Host "----------------------" -ForegroundColor Yellow

# Check Evidence Files
$evidencePath = "$BundlePath\verifier\artifacts\logs"
$Results.EvidenceIntegrity.EvidenceLogsExist = Test-Path $evidencePath
Write-Host "Evidence Logs: $($($Results.EvidenceIntegrity.EvidenceLogsExist ? '✅' : '❌'))" -ForegroundColor $(if ($Results.EvidenceIntegrity.EvidenceLogsExist) { 'Green' } else { 'Red' })

if ($Results.EvidenceIntegrity.EvidenceLogsExist) {
    $evidenceFiles = Get-ChildItem $evidencePath -Filter "*.json"
    $Results.EvidenceIntegrity.EvidenceFileCount = $evidenceFiles.Count
    Write-Host "Evidence Files: $($evidenceFiles.Count)" -ForegroundColor Gray
    
    # Verify Evidence Integrity
    $evidenceHashes = @()
    foreach ($file in $evidenceFiles) {
        $hash = (Get-FileHash $file.FullName -Algorithm SHA256).Hash
        $evidenceHashes += $hash
        if ($Detailed) { Write-Host "  $($file.Name): $hash" -ForegroundColor Gray }
    }
    
    $Results.EvidenceIntegrity.UniqueHashes = ($evidenceHashes | Sort-Object -Unique).Count
    $Results.EvidenceIntegrity.EvidenceIntegrityVerified = ($evidenceHashes.Count -eq $Results.EvidenceIntegrity.UniqueHashes)
    
    Write-Host "Evidence Integrity: $($Results.EvidenceIntegrity.UniqueHashes)/$($evidenceFiles.Count) unique - $($($Results.EvidenceIntegrity.EvidenceIntegrityVerified ? '✅' : '❌'))" -ForegroundColor $(if ($Results.EvidenceIntegrity.EvidenceIntegrityVerified) { 'Green' } else { 'Red' })
}

# Calculate Overall Status
$allChecks = @(
    $Results.Environment.PowerShellCompatible,
    $Results.Environment.BundleExists,
    $Results.BundleIntegrity.ManifestExists,
    $Results.BundleIntegrity.HashVerificationPassed,
    $Results.VerificationHarness.Passed,
    $Results.CertificateValidation.ValidCertificate,
    $Results.EvidenceIntegrity.EvidenceIntegrityVerified
)

$passedChecks = ($allChecks | Where-Object { $_ -eq $true }).Count
$totalChecks = $allChecks.Count
$Results.OverallStatus = if ($passedChecks -eq $totalChecks) { "PASS" } elseif ($passedChecks -ge ($totalChecks * 0.8)) { "WARNING" } else { "FAIL" }

Write-Host ""
Write-Host "Validation Summary" -ForegroundColor Cyan
Write-Host "==================" -ForegroundColor Cyan
Write-Host "Overall Status: $($Results.OverallStatus) ($passedChecks/$totalChecks checks passed)" -ForegroundColor $(switch ($Results.OverallStatus) { "PASS" { "Green" } "WARNING" { "Yellow" } "FAIL" { "Red" } })
Write-Host ""

if ($Results.OverallStatus -eq "PASS") {
    Write-Host "🎉 NovaFuse-EGP-VS System Validation PASSED!" -ForegroundColor Green
    Write-Host "The constitutional compliance infrastructure is operational and ready for deployment." -ForegroundColor Green
} elseif ($Results.OverallStatus -eq "WARNING") {
    Write-Host "⚠️  NovaFuse-EGP-VS System Validation completed with warnings" -ForegroundColor Yellow
    Write-Host "Some non-critical issues detected. Review detailed results above." -ForegroundColor Yellow
} else {
    Write-Host "❌ NovaFuse-EGP-VS System Validation FAILED" -ForegroundColor Red
    Write-Host "Critical issues detected. System is not ready for deployment." -ForegroundColor Red
}

# Generate Report
if ($GenerateReport) {
    $reportPath = ".\NovaFuse-EGP-VS-Validation-Report-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
    $Results | ConvertTo-Json -Depth 10 | Out-File -FilePath $reportPath
    Write-Host ""
    Write-Host "Report generated: $reportPath" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
if ($Results.OverallStatus -eq "PASS") {
    Write-Host "1. Deploy to production environment" -ForegroundColor Green
    Write-Host "2. Schedule third-party validation" -ForegroundColor Green
    Write-Host "3. Begin regulatory submission process" -ForegroundColor Green
} else {
    Write-Host "1. Address identified issues" -ForegroundColor Red
    Write-Host "2. Re-run validation after fixes" -ForegroundColor Red
    Write-Host "3. Contact support if issues persist" -ForegroundColor Red
}

exit $(switch ($Results.OverallStatus) { "PASS" { 0 } "WARNING" { 1 } "FAIL" { 2 } })
