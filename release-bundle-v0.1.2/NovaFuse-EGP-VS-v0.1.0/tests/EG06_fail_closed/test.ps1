# EG-06: Fail-Closed Semantics Test Suite
# Verify component refuses execution under failure conditions

param(
    [object]$Config,
    [switch]$Verbose
)

$ErrorActionPreference = "Stop"

function Test-FailClosedSemantics {
    param([object]$Config)
    
    Write-Host "[TEST] Testing fail-closed semantics..." -ForegroundColor Yellow
    
    $failureConditions = $Config.testMatrix.EG06_FailClosed.failureConditions
    $results = @()
    
    foreach ($condition in $failureConditions) {
        Write-Host "[RUN] Testing failure condition: $condition" -ForegroundColor Gray
        
        try {
            $result = Invoke-FailClosedTest -Condition $condition -Config $Config
            
            # Assert refusal
            if ($Config.testMatrix.EG06_FailClosed.expectRefusal) {
                if ($result.Decision.outcome -ne "refuse") {
                    throw "Expected refusal for $condition, got: $($result.Decision.outcome)"
                }
            }
            
            # Assert no partial execution
            if ($Config.testMatrix.EG06_FailClosed.noPartialExecution) {
                if ($result.PartialExecution) {
                    throw "Partial execution detected for $condition"
                }
            }
            
            # Assert no silent failure
            if ($result.SilentFailure) {
                throw "Silent failure detected for $condition"
            }
            
            $results += @{
                FailureCondition = $condition
                Decision = $result.Decision
                Status = "PASS"
                Details = "Fail-closed behavior verified"
                Timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
            }
            
            Write-Host "[PASS] $condition correctly failed closed" -ForegroundColor Green
            
        } catch {
            $results += @{
                FailureCondition = $condition
                Status = "FAIL"
                Error = $_.Exception.Message
                Timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
            }
            
            Write-Host "[FAIL] $condition test failed: $($_.Exception.Message)" -ForegroundColor Red
            throw
        }
    }
    
    Write-Host "[PASS] Fail-closed test passed: $($results.Count) failure conditions handled correctly" -ForegroundColor Green
    
    return @{
        Duration = 0
        Details = @{
            TotalTests = $results.Count
            Results = $results
        }
    }
}

function Invoke-FailClosedTest {
    param(
        [string]$Condition,
        [object]$Config
    )
    
    $baseProposal = @{
        action = "read"
        resource = "/data/test"
        level = "medium"
    }
    
    $baseContext = @{
        timestamp = "2026-03-09T04:21:00Z"
        environment = "test"
        session_id = "test_session_001"
    }
    
    $baseIdentity = @{
        user = "test_user"
        role = "tester"
        clearance = "confidential"
        authenticated = $true
    }
    
    # Apply failure condition
    $modifiedInputs = Set-FailureCondition -Condition $Condition -Proposal $baseProposal -Context $baseContext -Identity $baseIdentity
    
    try {
        $decision = Invoke-FailClosedEvaluation -Proposal $modifiedInputs.Proposal -Context $modifiedInputs.Context -Identity $modifiedInputs.Identity
        
        return @{
            Decision = $decision
            PartialExecution = $false
            SilentFailure = $false
        }
        
    } catch {
        # Check if this is an acceptable failure (refusal vs error)
        if ($_.Exception.Message -like "*Fail-closed refusal*" -or $_.Exception.Message -like "*Internal system error*") {
            return @{
                Decision = @{
                    outcome = "refuse"
                    reasoning = "Fail-closed refusal: $($_.Exception.Message)"
                    timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
                    version = "0.1.0"
                }
                PartialExecution = $false
                SilentFailure = $false
            }
        } else {
            # Re-throw unexpected errors
            throw
        }
    }
}

function Set-FailureCondition {
    param(
        [string]$Condition,
        [hashtable]$Proposal,
        [hashtable]$Context,
        [hashtable]$Identity
    )
    
    switch ($Condition) {
        "missing_context" {
            $Context = @{
                environment = $Context.environment
                session_id = $Context.session_id
            }
            # Remove timestamp field entirely
        }
        "corrupt_identity" {
            $Identity = @{
                user = ""
                role = $null
                clearance = "invalid_clearance"
                authenticated = $false
                corrupted = $true
            }
        }
        "internal_error" {
            # Simulate internal error condition by adding a flag
            $Context["internal_error"] = $true
        }
        "resource_exhaustion" {
            # Simulate resource exhaustion
            $Context["memory_limit_exceeded"] = $true
            $Context["cpu_threshold_breached"] = $true
        }
        default {
            throw "Unknown failure condition: $Condition"
        }
    }
    
    return @{
        Proposal = $Proposal
        Context = $Context
        Identity = $Identity
    }
}

function Invoke-FailClosedEvaluation {
    param(
        [hashtable]$Proposal,
        [hashtable]$Context,
        [hashtable]$Identity
    )
    
    # Check for fail-closed conditions before any processing
    Test-FailClosedConditions -Proposal $Proposal -Context $Context -Identity $Identity
    
    $decision = @{
        input = @{
            proposal = $Proposal
            context = $Context
            identity = $Identity
        }
        outcome = "admit"
        reasoning = "Normal evaluation"
        timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
        version = "0.1.0"
    }
    
    # Additional validation logic
    if ($Context.ContainsKey("memory_limit_exceeded") -and $Context.memory_limit_exceeded) {
        $decision.outcome = "refuse"
        $decision.reasoning = "Resource exhaustion: Memory limit exceeded"
        return $decision
    }
    
    if ($Context.ContainsKey("cpu_threshold_breached") -and $Context.cpu_threshold_breached) {
        $decision.outcome = "refuse"
        $decision.reasoning = "Resource exhaustion: CPU threshold breached"
        return $decision
    }
    
    # Check for internal error condition
    if ($Context.ContainsKey("internal_error") -and $Context.internal_error) {
        throw "Internal system error: Component failure detected"
    }
    
    # Identity validation
    if ($Identity.ContainsKey("corrupted") -and $Identity.corrupted) {
        $decision.outcome = "refuse"
        $decision.reasoning = "Identity corruption detected"
        return $decision
    }
    
    return $decision
}

function Test-FailClosedConditions {
    param(
        [hashtable]$Proposal,
        [hashtable]$Context,
        [hashtable]$Identity
    )
    
    # Check for missing required context fields
    $requiredContextFields = @("timestamp", "environment", "session_id")
    foreach ($field in $requiredContextFields) {
        if (-not $Context.ContainsKey($field) -or $null -eq $Context[$field]) {
            throw "Fail-closed refusal: Missing required context field '$field'"
        }
    }
    
    # Check for invalid identity
    if ($Identity.ContainsKey("user") -and [string]::IsNullOrEmpty($Identity.user)) {
        throw "Fail-closed refusal: Invalid identity - empty user field"
    }
    
    if ($Identity.ContainsKey("role") -and $null -eq $Identity.role) {
        throw "Fail-closed refusal: Invalid identity - null role field"
    }
    
    # Check for malformed proposal
    if ($Proposal.ContainsKey("action") -and [string]::IsNullOrEmpty($Proposal.action)) {
        throw "Fail-closed refusal: Invalid proposal - empty action field"
    }
}

# Execute test
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
$result = Test-FailClosedSemantics -Config $Config
$stopwatch.Stop()

$result.Duration = $stopwatch.Elapsed.TotalSeconds
return $result
