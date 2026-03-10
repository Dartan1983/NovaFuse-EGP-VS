# NovaFuse-EGP-VS Quick Validation Script
# Simple end-to-end validation

Write-Host "NovaFuse-EGP-VS Quick Validation" -ForegroundColor Cyan
Write-Host "==============================" -ForegroundColor Cyan

# Check Bundle
$bundlePath = if ($IsWindows) { ".\test-bundle\NovaFuse-EGP-VS-v0.1.0" } else { "./test-bundle/NovaFuse-EGP-VS-v0.1.0" }
if (Test-Path $bundlePath) {
    Write-Host "✅ Bundle found: $bundlePath" -ForegroundColor Green
} else {
    Write-Host "❌ Bundle not found" -ForegroundColor Red
    exit 1
}

# Check Verification Harness
$verifierPath = Join-Path $bundlePath "verifier/verify.ps1"
if (Test-Path $verifierPath) {
    Write-Host "✅ Verification harness found" -ForegroundColor Green
} else {
    Write-Host "❌ Verification harness not found" -ForegroundColor Red
    exit 1
}

# Run Verification
Write-Host "Running verification harness..." -ForegroundColor Yellow
Push-Location (Join-Path $bundlePath "verifier")
try {
    $output = & .\verify.ps1
    $exitCode = $LASTEXITCODE
    Pop-Location
    
    if ($exitCode -eq 0) {
        Write-Host "✅ Verification harness PASSED" -ForegroundColor Green
        
        # Check Certificate
        $certPath = Join-Path $bundlePath "verifier/artifacts/certs/certificate-egp-0.1-novadust-v0.1.0.json"
        if (Test-Path $certPath) {
            Write-Host "✅ Certificate generated" -ForegroundColor Green
            
            # Validate Certificate
            $cert = Get-Content $certPath | ConvertFrom-Json
            Write-Host "✅ Certificate Status: $($cert.results.overall)" -ForegroundColor Green
            Write-Host "✅ Certificate ID: $($cert.metadata.certificate_id)" -ForegroundColor Gray
            
            Write-Host ""
            Write-Host "🎉 NovaFuse-EGP-VS Validation PASSED!" -ForegroundColor Green
            Write-Host "The constitutional compliance infrastructure is operational." -ForegroundColor Green
        } else {
            Write-Host "❌ Certificate not generated" -ForegroundColor Red
        }
    } else {
        Write-Host "❌ Verification harness FAILED" -ForegroundColor Red
        Write-Host "Exit code: $exitCode" -ForegroundColor Red
    }
} catch {
    Pop-Location
    Write-Host "❌ Error running verification harness" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
}
