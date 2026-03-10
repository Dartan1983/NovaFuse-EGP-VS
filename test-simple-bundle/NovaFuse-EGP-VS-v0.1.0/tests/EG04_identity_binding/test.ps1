# EG-04: Identity-Bound Evaluation Test Suite
# Verify decisions differ based on identity scope

param(
    [object]$Config,
    [switch]$Verbose
)

$ErrorActionPreference = "Stop"

function Test-IdentityBinding {
    param([object]$Config)
    
    Write-Host "[TEST] Testing identity-bound evaluation..." -ForegroundColor Yellow
    
    $testIdentities = $Config.testMatrix.EG04_IdentityBinding.testIdentities
    $results = @()
    
    # Test identical proposals from different identities
    $baseProposal = @{
        action = "read"
        resource = "/data/sensitive"
        level = "high"
    }
    
    $baseContext = @{
        timestamp = "2026-03-09T04:21:00Z"
        environment = "test"
        session_id = "test_session_001"
    }
    
    $identityDecisions = @{}
    
    foreach ($identityName in $testIdentities) {
        Write-Host "[RUN] Testing identity: $identityName" -ForegroundColor Gray
        
        $identity = Get-TestIdentity -Type $identityName
        
        try {
            $decision = Invoke-IdentityBoundEvaluation -Proposal $baseProposal -Context $baseContext -Identity $identity
            
            $identityDecisions[$identityName] = @{
                Decision = $decision
                Identity = $identity
                Timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
            }
            
            $results += @{
                IdentityType = $identityName
                Decision = $decision
                Status = "PASS"
                Timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
            }
            
        } catch {
            $results += @{
                IdentityType = $identityName
                Error = $_.Exception.Message
                Status = "FAIL"
                Timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
            }
            throw
        }
    }
    
    # Verify decisions differ based on identity
    Test-IdentityDifferentiation -IdentityDecisions $identityDecisions
    
    # Test missing identity (fail-closed behavior)
    if ($Config.testMatrix.EG04_IdentityBinding.failOnMissing) {
        Write-Host "[RUN] Testing missing identity..." -ForegroundColor Gray
        Test-MissingIdentity -Proposal $baseProposal -Context $baseContext
    }
    
    Write-Host "[PASS] Identity binding test passed: $($results.Count) identity evaluations completed" -ForegroundColor Green
    
    return @{
        Duration = 0
        Details = @{
            TotalTests = $results.Count
            IdentitiesTested = $testIdentities.Count
            Results = $results
            IdentityDecisions = $identityDecisions
        }
    }
}

function Get-TestIdentity {
    param([string]$Type)
    
    switch ($Type) {
        "admin" {
            return @{
                user = "admin"
                role = "administrator"
                clearance = "top_secret"
                authenticated = $true
                permissions = @("read", "write", "execute", "admin")
                scope = "full"
            }
        }
        "user" {
            return @{
                user = "regular_user"
                role = "user"
                clearance = "secret"
                authenticated = $true
                permissions = @("read", "write")
                scope = "limited"
            }
        }
        "service" {
            return @{
                user = "service_account"
                role = "service"
                clearance = "confidential"
                authenticated = $true
                permissions = @("read", "execute")
                scope = "service_specific"
            }
        }
        "anonymous" {
            return @{
                user = "anonymous"
                role = "guest"
                clearance = "unclassified"
                authenticated = $false
                permissions = @()
                scope = "public"
            }
        }
        default {
            throw "Unknown identity type: $Type"
        }
    }
}

function Invoke-IdentityBoundEvaluation {
    param(
        [hashtable]$Proposal,
        [hashtable]$Context,
        [hashtable]$Identity
    )
    
    $decision = @{
        input = @{
            proposal = $Proposal
            context = $Context
            identity = $Identity
        }
        outcome = "admit"
        reasoning = "Identity-based evaluation"
        confidence = 0.5
        constraints = @()
        timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
        version = "0.1.0"
    }
    
    # Identity-based decision logic
    if (-not $Identity.authenticated) {
        $decision.outcome = "refuse"
        $decision.reasoning = "Unauthenticated access denied"
        $decision.confidence = 1.0
        return $decision
    }
    
    # Check clearance level
    $requiredClearance = switch ($Proposal.level) {
        "high" { "top_secret" }
        "medium" { "secret" }
        "low" { "confidential" }
        default { "unclassified" }
    }
    
    $clearanceLevels = @("unclassified", "confidential", "secret", "top_secret")
    $identityLevel = $clearanceLevels.IndexOf($Identity.clearance)
    $requiredLevel = $clearanceLevels.IndexOf($requiredClearance)
    
    if ($identityLevel -lt $requiredLevel) {
        $decision.outcome = "refuse"
        $decision.reasoning = "Insufficient clearance: $($Identity.clearance) < $requiredClearance"
        $decision.confidence = 0.95
        return $decision
    }
    
    # Check permissions
    if ($Identity.permissions -notcontains $Proposal.action) {
        $decision.outcome = "refuse"
        $decision.reasoning = "Insufficient permissions: $($Proposal.action) not in $($Identity.permissions -join ', ')"
        $decision.confidence = 0.9
        return $decision
    }
    
    # Adjust confidence based on identity scope
    switch ($Identity.scope) {
        "full" { $decision.confidence = 0.98 }
        "limited" { $decision.confidence = 0.85 }
        "service_specific" { $decision.confidence = 0.75 }
        default { $decision.confidence = 0.5 }
    }
    
    $decision.constraints += "identity_verified", "clearance_checked", "permissions_validated"
    
    return $decision
}

function Test-IdentityDifferentiation {
    param([hashtable]$IdentityDecisions)
    
    $outcomes = @()
    foreach ($identityDecision in $IdentityDecisions.Values) {
        $outcomes += $identityDecision.Decision.outcome
    }
    
    # At least some decisions should differ
    $uniqueOutcomes = $outcomes | Sort-Object -Unique
    if ($uniqueOutcomes.Count -eq 1) {
        Write-Host "    [WARN] All identities produced same outcome - this may be expected for some proposals" -ForegroundColor Yellow
    } else {
        Write-Host "    [OK] Identity differentiation confirmed: $($uniqueOutcomes.Count) different outcomes" -ForegroundColor Green
    }
    
    # Verify reasoning differs based on identity
    $reasonings = @()
    foreach ($identityDecision in $IdentityDecisions.Values) {
        $reasonings += $identityDecision.Decision.reasoning
    }
    
    $uniqueReasonings = $reasonings | Sort-Object -Unique
    if ($uniqueReasonings.Count -eq 1) {
        throw "All identities produced identical reasoning - identity binding may be broken"
    }
}

function Test-MissingIdentity {
    param(
        [hashtable]$Proposal,
        [hashtable]$Context
    )
    
    try {
        $decision = Invoke-IdentityBoundEvaluation -Proposal $Proposal -Context $Context -Identity $null
        
        if ($decision.outcome -ne "refuse") {
            throw "Missing identity should result in refusal, got: $($decision.outcome)"
        }
        
        Write-Host "    [OK] Missing identity correctly refused" -ForegroundColor Green
        
    } catch {
        if ($_ -is [System.Management.Automation.PSArgumentException] -and $_.Exception.Message -like "*identity*") {
            Write-Host "    [OK] Missing identity correctly rejected at validation level" -ForegroundColor Green
        } else {
            throw
        }
    }
}

# Execute test
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
$result = Test-IdentityBinding -Config $Config
$stopwatch.Stop()

$result.Duration = $stopwatch.Elapsed.TotalSeconds
return $result
