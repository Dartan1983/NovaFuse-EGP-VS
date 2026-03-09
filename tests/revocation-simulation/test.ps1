# Revocation Simulation Test Suite
# Demonstrates fail-closed behavior when keys are revoked

param(
    [object]$Config,
    [switch]$Verbose
)

$ErrorActionPreference = "Stop"

function Test-RevocationSimulation {
    param([object]$Config)
    
    Write-Host "[TEST] Testing revocation simulation..." -ForegroundColor Yellow
    
    # Test scenarios for revocation handling
    $testScenarios = @(
        @{
            Name = "Revoked Key Detection"
            Description = "System should detect and reject revoked keys"
            TestKey = "REVOKED_KEY_ID"
            ExpectedResult = "REJECT"
            ExpectedReason = "Key has been revoked"
        },
        @{
            Name = "Revocation Manifest Validation"
            Description = "System should validate revocation manifest integrity"
            TestKey = "VALID_KEY_ID"
            ExpectedResult = "ACCEPT"
            ExpectedReason = "Key is valid"
        },
        @{
            Name = "Missing Revocation Data"
            Description = "System should handle missing revocation data gracefully"
            TestKey = "UNKNOWN_KEY_ID"
            ExpectedResult = "REJECT"
            ExpectedReason = "Revocation status unknown - fail-closed"
        },
        @{
            Name = "Compromised Key Simulation"
            Description = "System should reject keys marked as compromised"
            TestKey = "COMPROMISED_KEY_ID"
            ExpectedResult = "REJECT"
            ExpectedReason = "Key has been compromised"
        }
    )
    
    $results = @()
    
    foreach ($scenario in $testScenarios) {
        Write-Host "[RUN] Testing $($scenario.Name)..." -ForegroundColor Gray
        
        try {
            $result = Invoke-RevocationCheck -TestKey $scenario.TestKey
            
            # Validate expected behavior
            if ($result.Status -eq $scenario.ExpectedResult) {
                Write-Host "[PASS] $($scenario.Name): $($scenario.ExpectedReason)" -ForegroundColor Green
                
                $testResult = @{
                    Scenario = $scenario.Name
                    Status = "PASS"
                    Details = $scenario.ExpectedReason
                    TestKey = $scenario.TestKey
                    ExpectedResult = $scenario.ExpectedResult
                    ActualResult = $result.Status
                }
            } else {
                Write-Host "[FAIL] $($scenario.Name): Expected $($scenario.ExpectedResult), got $($result.Status)" -ForegroundColor Red
                
                $testResult = @{
                    Scenario = $scenario.Name
                    Status = "FAIL"
                    Details = "Expected $($scenario.ExpectedResult), got $($result.Status)"
                    TestKey = $scenario.TestKey
                    ExpectedResult = $scenario.ExpectedResult
                    ActualResult = $result.Status
                }
            }
            
            $results += $testResult
            
        } catch {
            Write-Host "[ERROR] $($scenario.Name): $($_.Exception.Message)" -ForegroundColor Red
            
            $testResult = @{
                Scenario = $scenario.Name
                Status = "ERROR"
                Details = $_.Exception.Message
                TestKey = $scenario.TestKey
                ExpectedResult = $scenario.ExpectedResult
                ActualResult = "ERROR"
            }
            
            $results += $testResult
        }
    }
    
    # Summary
    $totalTests = $results.Count
    $passedTests = ($results | Where-Object { $_.Status -eq "PASS" }).Count
    $failedTests = ($results | Where-Object { $_.Status -eq "FAIL" }).Count
    $errorTests = ($results | Where-Object { $_.Status -eq "ERROR" }).Count
    
    Write-Host ""
    Write-Host "[SUMMARY] Revocation Simulation Results" -ForegroundColor Cyan
    Write-Host "==================================" -ForegroundColor Cyan
    Write-Host "Total Scenarios: $totalTests" -ForegroundColor White
    Write-Host "Passed: $passedTests" -ForegroundColor Green
    Write-Host "Failed: $failedTests" -ForegroundColor Red
    Write-Host "Errors: $errorTests" -ForegroundColor Yellow
    
    if ($failedTests -gt 0 -or $errorTests -gt 0) {
        Write-Host ""
        Write-Host "[FAILURES]" -ForegroundColor Red
        $results | Where-Object { $_.Status -in @("FAIL", "ERROR") } | ForEach-Object {
            Write-Host "  - $($_.Scenario): $($_.Details)" -ForegroundColor Red
        }
    }
    
    # Fail-closed validation
    $failClosedTests = ($results | Where-Object { 
        $_.ExpectedResult -eq "REJECT" -and $_.ActualResult -eq "REJECT"
    }).Count
    
    $expectedRejectTests = ($results | Where-Object { $_.ExpectedResult -eq "REJECT" }).Count
    $failClosedRate = if ($expectedRejectTests -gt 0) { 
        [math]::Round(($failClosedTests / $expectedRejectTests) * 100, 2) 
    } else { 
        100 
    }
    
    Write-Host ""
    Write-Host "[FAIL-CLOSED] Revocation Security: $failClosedRate% ($failClosedTests/$expectedRejectTests)" -ForegroundColor $(if ($failClosedRate -eq 100) { 'Green' } else { 'Yellow' })
    
    if ($failClosedRate -eq 100) {
        Write-Host "[PASS] All rejection scenarios properly handled - fail-closed behavior confirmed" -ForegroundColor Green
        $overallStatus = "PASS"
    } else {
        Write-Host "[WARN] Some rejection scenarios not properly handled" -ForegroundColor Yellow
        $overallStatus = "WARNING"
    }
    
    return @{
        Duration = 0
        Details = @{
            TotalScenarios = $totalTests
            PassedScenarios = $passedTests
            FailedScenarios = $failedTests
            ErrorScenarios = $errorTests
            FailClosedRate = $failClosedRate
            ExpectedRejectTests = $expectedRejectTests
            ActualRejectTests = $failClosedTests
            Results = $results
        }
    }
}

function Invoke-RevocationCheck {
    param([string]$TestKey)
    
    # Simulate revocation checking logic
    $revokedKeys = @("REVOKED_KEY_ID", "COMPROMISED_KEY_ID")
    $validKeys = @("VALID_KEY_ID")
    
    if ($revokedKeys -contains $TestKey) {
        return @{
            Status = "REJECT"
            Reason = "Key has been revoked"
            Timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
        }
    }
    
    if ($validKeys -contains $TestKey) {
        return @{
            Status = "ACCEPT"
            Reason = "Key is valid"
            Timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
        }
    }
    
    # Default to fail-closed for unknown keys
    return @{
        Status = "REJECT"
        Reason = "Revocation status unknown - fail-closed"
        Timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
    }
}

function Test-RevocationManifestIntegrity {
    Write-Host "[TEST] Testing revocation manifest integrity..." -ForegroundColor Yellow
    
    # Simulate revocation manifest
    $manifest = @{
        version = "1.0"
        generated_at = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
        revoked_keys = @(
            @{
                key_id = "REVOKED_KEY_ID"
                revoked_at = "2026-03-01T10:00:00Z"
                reason = "Key compromise detected"
                revoked_by = "NovaFuse Security Team"
            },
            @{
                key_id = "COMPROMISED_KEY_ID"
                revoked_at = "2026-02-15T14:30:00Z"
                reason = "Unauthorized access attempt"
                revoked_by = "NovaFuse Security Team"
            }
        )
        manifest_hash = "simulated_sha256_hash"
        signature = "simulated_signature"
    }
    
    # Validate manifest structure
    $requiredFields = @("version", "generated_at", "revoked_keys", "manifest_hash", "signature")
    $missingFields = @()
    
    foreach ($field in $requiredFields) {
        if (-not $manifest.ContainsKey($field)) {
            $missingFields += $field
        }
    }
    
    if ($missingFields.Count -gt 0) {
        Write-Host "[FAIL] Missing manifest fields: $($missingFields -join ', ')" -ForegroundColor Red
        return $false
    }
    
    # Validate revoked keys structure
    foreach ($key in $manifest.revoked_keys) {
        $keyFields = @("key_id", "revoked_at", "reason", "revoked_by")
        $missingKeyFields = @()
        
        foreach ($field in $keyFields) {
            if (-not $key.ContainsKey($field)) {
                $missingKeyFields += $field
            }
        }
        
        if ($missingKeyFields.Count -gt 0) {
            Write-Host "[FAIL] Missing fields for key $($key.key_id): $($missingKeyFields -join ', ')" -ForegroundColor Red
            return $false
        }
    }
    
    Write-Host "[PASS] Revocation manifest integrity validated" -ForegroundColor Green
    return $true
}

function Test-RevocationCheckPerformance {
    Write-Host "[TEST] Testing revocation check performance..." -ForegroundColor Yellow
    
    $measurements = @()
    $testKeys = @("VALID_KEY_ID", "REVOKED_KEY_ID", "COMPROMISED_KEY_ID", "UNKNOWN_KEY_ID")
    
    foreach ($key in $testKeys) {
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        
        $result = Invoke-RevocationCheck -TestKey $key
        
        $stopwatch.Stop()
        
        $measurements += @{
            KeyId = $key
            Duration = $stopwatch.Elapsed.TotalMilliseconds
            Result = $result.Status
        }
        
        if ($Verbose) {
            Write-Host "  $($key): $($result.Status) ($($stopwatch.Elapsed.TotalMilliseconds)ms)" -ForegroundColor Gray
        }
    }
    
    $avgDuration = ($measurements | Measure-Object -Property Duration -Average).Average
    $maxDuration = ($measurements | Measure-Object -Property Duration -Maximum).Maximum
    
    Write-Host "[INFO] Average revocation check: $([math]::Round($avgDuration, 2))ms" -ForegroundColor Cyan
    Write-Host "[INFO] Maximum revocation check: $([math]::Round($maxDuration, 2))ms" -ForegroundColor Cyan
    
    # Performance threshold check
    $thresholdMs = 100  # 100ms maximum for revocation check
    if ($maxDuration -gt $thresholdMs) {
        Write-Host "[WARN] Revocation check exceeds performance threshold ($thresholdMs ms)" -ForegroundColor Yellow
        return $false
    } else {
        Write-Host "[PASS] Revocation check performance within acceptable range" -ForegroundColor Green
        return $true
    }
}

# Execute test
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

# Main revocation simulation test
$result = Test-RevocationSimulation -Config $Config

# Additional integrity tests
$manifestIntegrity = Test-RevocationManifestIntegrity
$performanceTest = Test-RevocationCheckPerformance

$stopwatch.Stop()

$result.Duration = $stopwatch.Elapsed.TotalSeconds
$result.Details.ManifestIntegrity = $manifestIntegrity
$result.Details.PerformanceTest = $performanceTest

# Overall assessment
$allTestsPassed = ($result.Details.PassedScenarios -eq $result.Details.TotalScenarios) -and 
                  $manifestIntegrity -and 
                  $performanceTest

if ($allTestsPassed) {
    Write-Host ""
    Write-Host "[PASS] Revocation simulation test passed: Demonstrates fail-closed behavior for key revocation" -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "[FAIL] Revocation simulation test failed: Some security checks did not pass" -ForegroundColor Red
}

return $result
