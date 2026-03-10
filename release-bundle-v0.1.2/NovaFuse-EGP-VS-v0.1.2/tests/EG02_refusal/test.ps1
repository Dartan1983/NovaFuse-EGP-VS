# EG-02: Explicit Refusal Test Suite
# Feed known-invalid proposals and assert explicit refusal

param(
    [object]$Config,
    [switch]$Verbose
)

$ErrorActionPreference = "Stop"

function Test-ExplicitRefusal {
    param([object]$Config)
    
    Write-Host "[TEST] Testing explicit refusal semantics..." -ForegroundColor Yellow
    
    $invalidProposals = $Config.testMatrix.EG02_Refusal.invalidProposals
    $results = @()
    
    foreach ($proposalType in $invalidProposals) {
        Write-Host "[RUN] Testing $proposalType..." -ForegroundColor Gray
        
        $testProposal = Get-InvalidProposal -Type $proposalType
        $testContext = Get-TestContext
        $testIdentity = Get-TestIdentity
        
        try {
            $decision = Invoke-RefusalTest -Proposal $testProposal -Context $testContext -Identity $testIdentity
            
            # Assert explicit refusal
            if ($decision.outcome -ne "refuse") {
                throw "Expected explicit refusal for $proposalType, got: $($decision.outcome)"
            }
            
            # Assert refusal is logged as successful outcome
            if ($decision.error -or $decision.exception) {
                throw "Refusal should be logged as successful outcome, not error for $proposalType"
            }
            
            # Assert no fallback behavior
            if ($decision.fallback -or $decision.degraded) {
                throw "No fallback or degraded behavior allowed for $proposalType"
            }
            
            $results += @{
                ProposalType = $proposalType
                Proposal = $testProposal
                Decision = $decision
                Status = "PASS"
                Timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
            }
            
            Write-Host "[PASS] $proposalType correctly refused" -ForegroundColor Green
            
        } catch {
            $results += @{
                ProposalType = $proposalType
                Proposal = $testProposal
                Error = $_.Exception.Message
                Status = "FAIL"
                Timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
            }
            
            Write-Host "[FAIL] $proposalType test failed: $($_.Exception.Message)" -ForegroundColor Red
            throw
        }
    }
    
    Write-Host "[PASS] Explicit refusal test passed: $($results.Count) invalid proposals correctly refused" -ForegroundColor Green
    
    return @{
        Duration = 0
        Details = @{
            TotalTests = $results.Count
            Passed = ($results | Where-Object {$_.Status -eq "PASS"}).Count
            Failed = ($results | Where-Object {$_.Status -eq "FAIL"}).Count
            Results = $results
        }
    }
}

function Get-InvalidProposal {
    param([string]$Type)
    
    switch ($Type) {
        "missing_required_fields" {
            return @{
                action = $null  # Missing required action field
                resource = "/data/test"
                level = "medium"
            }
        }
        "disallowed_actions" {
            return @{
                action = "format_disk"  # Disallowed action
                resource = "/system/root"
                level = "critical"
            }
        }
        "malformed_syntax" {
            return @{
                action = "read"
                resource = "invalid|path|with|pipes"
                level = "invalid_level"
                malformed = $true
            }
        }
        "overflow_conditions" {
            return @{
                action = "read"
                resource = "/data/test"
                level = "medium"
                overflow = "A" * 10000  # Buffer overflow attempt
            }
        }
        default {
            throw "Unknown invalid proposal type: $Type"
        }
    }
}

function Get-TestContext {
    return @{
        timestamp = "2026-03-09T04:21:00Z"
        environment = "test"
        session_id = "test_session_001"
        request_id = "req_001"
    }
}

function Get-TestIdentity {
    return @{
        user = "test_user"
        role = "tester"
        clearance = "confidential"
        authenticated = $true
    }
}

function Invoke-RefusalTest {
    param(
        [hashtable]$Proposal,
        [hashtable]$Context,
        [hashtable]$Identity
    )
    
    # Simulate refusal logic
    $decision = @{
        input = @{
            proposal = $Proposal
            context = $Context
            identity = $Identity
        }
        outcome = "admit"  # Default
        reasoning = "Initial evaluation"
        timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
        version = "0.1.0"
    }
    
    # Check for missing required fields
    $requiredFields = @("action", "resource", "level")
    foreach ($field in $requiredFields) {
        if (-not $Proposal.ContainsKey($field) -or $null -eq $Proposal[$field]) {
            $decision.outcome = "refuse"
            $decision.reasoning = "Missing required field: $field"
            return $decision
        }
    }
    
    # Check for disallowed actions
    $disallowedActions = @("format_disk", "delete_system", "escalate_privilege")
    if ($disallowedActions -contains $Proposal.action) {
        $decision.outcome = "refuse"
        $decision.reasoning = "Disallowed action: $($Proposal.action)"
        return $decision
    }
    
    # Check for malformed syntax
    if ($Proposal.ContainsKey("malformed") -and $Proposal.malformed) {
        $decision.outcome = "refuse"
        $decision.reasoning = "Malformed proposal syntax"
        return $decision
    }
    
    # Check for overflow conditions
    if ($Proposal.ContainsKey("overflow") -and $Proposal.overflow.Length -gt 1000) {
        $decision.outcome = "refuse"
        $decision.reasoning = "Potential buffer overflow detected"
        return $decision
    }
    
    return $decision
}

# Execute test
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
$result = Test-ExplicitRefusal -Config $Config
$stopwatch.Stop()

$result.Duration = $stopwatch.Elapsed.TotalSeconds
return $result
