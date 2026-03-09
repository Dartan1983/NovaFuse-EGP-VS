# NovaFuse Manifest Signing Script
# Signs RELEASE-HASHES.txt with GPG for USB bundle integrity

param(
    [Parameter(Mandatory=$false)]
    [string]$ManifestFile = "RELEASE-HASHES.txt",
    
    [Parameter(Mandatory=$false)]
    [string]$KeyEmail = "certification@novafuse.ai",
    
    [Parameter(Mandatory=$false)]
    [switch]$Verify
)

Write-Host "NovaFuse Manifest Signing Utility" -ForegroundColor Green
Write-Host "===============================" -ForegroundColor Green

# Check if GPG is available
try {
    $gpgVersion = & gpg --version 2>$null
    Write-Host "✅ Found GPG: $($gpgVersion[0])" -ForegroundColor Green
} catch {
    Write-Error "❌ GPG not found. Please install GPG (GnuPG) first."
    Write-Host "Download from: https://gnupg.org/download/" -ForegroundColor Yellow
    exit 1
}

# Check if manifest exists
if (-not (Test-Path $ManifestFile)) {
    Write-Error "❌ Manifest file not found: $ManifestFile"
    exit 1
}

Write-Host "Manifest file: $ManifestFile" -ForegroundColor Cyan

if ($Verify) {
    # Verification mode
    $signatureFile = "$ManifestFile.sig"
    
    if (-not (Test-Path $signatureFile)) {
        Write-Error "❌ Signature file not found: $signatureFile"
        exit 1
    }
    
    Write-Host "Verifying signature..." -ForegroundColor Yellow
    try {
        $verifyResult = & gpg --verify $signatureFile $ManifestFile 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Signature verification successful!" -ForegroundColor Green
            Write-Host $verifyResult -ForegroundColor Gray
        } else {
            Write-Error "❌ Signature verification failed!"
            Write-Host $verifyResult -ForegroundColor Red
            exit 1
        }
    } catch {
        Write-Error "❌ Verification error: $($_.Exception.Message)"
        exit 1
    }
    
} else {
    # Signing mode
    Write-Host "Signing manifest with key: $KeyEmail" -ForegroundColor Yellow
    
    try {
        & gpg --armor --output "$ManifestFile.sig" --detach-sign $ManifestFile
        Write-Host "✅ Signature created: $ManifestFile.sig" -ForegroundColor Green
        
        # Show signature info
        $sigInfo = & gpg --list-packets "$ManifestFile.sig" 2>$null
        Write-Host "`nSignature details:" -ForegroundColor Cyan
        Write-Host $sigInfo -ForegroundColor Gray
        
    } catch {
        Write-Error "❌ Signing failed: $($_.Exception.Message)"
        exit 1
    }
    
    Write-Host "`n📌 To verify:" -ForegroundColor Yellow
    Write-Host "gpg --verify $ManifestFile.sig $ManifestFile"
}

Write-Host "`n✅ Operation completed!" -ForegroundColor Green
