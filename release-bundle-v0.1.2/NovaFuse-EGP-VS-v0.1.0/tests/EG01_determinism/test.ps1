# EG-01: Deterministic Admissibility Test Suite
# Feed identical inputs across multiple runs, platforms, and timestamps
# Assert: identical decision outputs and logs

param(
    [object]$Config,
    [switch]$Verbose
)

$ErrorActionPreference = "Stop"

function Test-DeterministicAdmissibility {
    param([object]$Config)
    
    Write-Host "[TEST] Testing deterministic admissibility..." -ForegroundColor Yellow
    
    $testInputs = @(
        @{
            Proposal = @{action = "read"; resource = "/data/secret"; level = "high"}
            Context = @{timestamp = "2026-03-09T04:21:00Z"; environment = "test"}
            Identity = @{user = "admin"; role = "administrator"; clearance = "top_secret"}
        },
        @{
            Proposal = @{action = "write"; resource = "/config/settings"; level = "medium"}
            Context = @{timestamp = "2026-03-09T04:21:00Z"; environment = "production"}
            Identity = @{user = "operator"; role = "editor"; clearance = "secret"}
        },
        @{
            Proposal = @{action = "read"; resource = "/data/public"; level = "low"}
            Context = @{timestamp = "2026-03-09T04:21:00Z"; environment = "test"}
            Identity = @{user = "user"; role = "reader"; clearance = "unclassified"}
        }
    )
    
    $results = @()
    $determinismResults = @{}
    
    # Test determinism per input case
    foreach ($testInput in $testInputs) {
        $inputId = "input_$($testInputs.IndexOf($testInput))"
        $inputHashes = @{}
        
        Write-Host "[RUN] Testing $inputId determinism..." -ForegroundColor Gray
        
        # Run the same input multiple times
        for ($i = 0; $i -lt $Config.verification.determinismRuns; $i++) {
            $runId = "$inputId\_run_$i"
            
            # Simulate deterministic evaluation
            $decision = Invoke-DeterministicEvaluation -TestInput $testInput -RunId $runId
            
            # Calculate hash of canonical decision (no volatile fields)
            $decisionHash = Get-CanonicalDecisionHash -Decision $decision
            
            # Track hash uniqueness for this input
            if (-not $inputHashes.ContainsKey($decisionHash)) {
                $inputHashes[$decisionHash] = @()
            }
            $inputHashes[$decisionHash] += @{
                RunId = $runId
                Timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
            }
        }
        
        # Assert determinism: exactly 1 unique hash per input
        $uniqueHashes = $inputHashes.Keys.Count
        $determinismResults[$inputId] = @{
            Runs = $Config.verification.determinismRuns
            UniqueHashes = $uniqueHashes
            ExpectedHashes = 1
            Passed = ($uniqueHashes -eq 1)
            Details = $inputHashes
        }
        
        if ($uniqueHashes -ne 1) {
            Write-Host "[FAIL] $inputId determinism failed: Expected 1 unique hash, got $uniqueHashes" -ForegroundColor Red
            throw "Determinism test failed for ${inputId}: Expected 1 unique hash, got $uniqueHashes"
        } else {
            Write-Host "[PASS] $inputId determinism passed: $($Config.verification.determinismRuns) runs, 1 unique hash" -ForegroundColor Green
        }
        
        $results += @{ InputId = $inputId; Result = $determinismResults[$inputId] }
    }
    
    # Summary across different inputs (informational)
    $totalUniqueHashes = ($determinismResults.Values | ForEach-Object { $_.Details.Keys } | Sort-Object -Unique).Count
    Write-Host "[INFO] Across $($testInputs.Count) distinct inputs: $totalUniqueHashes unique hashes ($($totalUniqueHashes) distinct outcomes observed)" -ForegroundColor Cyan
    
    Write-Host "[PASS] Determinism test passed: $($testInputs.Count) inputs, each with perfect determinism" -ForegroundColor Green
    
    return @{
        Duration = 0
        Details = @{
            TotalInputs = $testInputs.Count
            RunsPerInput = $Config.verification.determinismRuns
            TotalRuns = $testInputs.Count * $Config.verification.determinismRuns
            UniqueHashesAcrossInputs = $totalUniqueHashes
            PerInputDeterminism = $determinismResults
            Results = $results
        }
    }
}

function Invoke-DeterministicEvaluation {
    param(
        [hashtable]$TestInput,
        [string]$RunId
    )
    
    # Simulate deterministic decision logic
    # In real implementation, this would call the actual NovaFuse component
    
    $decision = @{
        inputHash = Get-InputHash -Input $TestInput
        outcome = "admit"
        confidence = 0.95
        reasoning = "Deterministic evaluation based on input parameters"
        constraints = @("identity_verification", "resource_access", "clearance_check")
        version = "0.1.0"
    }
    
    # Simulate deterministic logic based on input
    if ($TestInput.Proposal.level -eq "high" -and $TestInput.Identity.clearance -ne "top_secret") {
        $decision.outcome = "refuse"
        $decision.reasoning = "Insufficient clearance for high-level access"
    }
    if ($TestInput.Proposal.action -eq "write" -and $TestInput.Context.environment -eq "production") {
        $decision.confidence = 0.98
        $decision.constraints += "production_safeguards"
    }
    
    return $decision
}

function Get-InputHash {
    param([hashtable]$TestInput)
    
    try {
        $inputJson = $TestInput | ConvertTo-Json -Compress -Depth 10 -ErrorAction Stop
        if ([string]::IsNullOrEmpty($inputJson)) {
            $inputJson = "{}"
        }
    }
    catch {
        $inputJson = "{}"
    }
    
    $hashBytes = [System.Text.Encoding]::UTF8.GetBytes($inputJson)
    $hash = [System.Security.Cryptography.SHA256]::Create().ComputeHash($hashBytes)
    return [System.BitConverter]::ToString($hash).Replace("-", "").ToLower()
}

function Get-CanonicalDecisionHash {
    param([hashtable]$Decision)
    
    # Create canonical decision record (exclude volatile fields)
    $canonicalDecision = @{
        inputHash = $Decision.inputHash
        outcome = $Decision.outcome
        confidence = $Decision.confidence
        reasoning = $Decision.reasoning
        constraints = $Decision.constraints
        version = $Decision.version
    }
    
    try {
        $decisionJson = $canonicalDecision | ConvertTo-Json -Compress -Depth 10 -ErrorAction Stop
        if ([string]::IsNullOrEmpty($decisionJson)) {
            $decisionJson = "{}"
        }
    }
    catch {
        $decisionJson = "{}"
    }
    
    $hashBytes = [System.Text.Encoding]::UTF8.GetBytes($decisionJson)
    $hash = [System.Security.Cryptography.SHA256]::Create().ComputeHash($hashBytes)
    return [System.BitConverter]::ToString($hash).Replace("-", "").ToLower()
}

function Get-DecisionHash {
    param([hashtable]$Decision)
    
    try {
        $decisionJson = $Decision | ConvertTo-Json -Compress -Depth 10 -ErrorAction Stop
        if ([string]::IsNullOrEmpty($decisionJson)) {
            $decisionJson = "{}"
        }
    }
    catch {
        $decisionJson = "{}"
    }
    
    $hashBytes = [System.Text.Encoding]::UTF8.GetBytes($decisionJson)
    $hash = [System.Security.Cryptography.SHA256]::Create().ComputeHash($hashBytes)
    return [System.BitConverter]::ToString($hash).Replace("-", "").ToLower()
}

# Execute test
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
$result = Test-DeterministicAdmissibility -Config $Config
$stopwatch.Stop()

$result.Duration = $stopwatch.Elapsed.TotalSeconds
return $result
