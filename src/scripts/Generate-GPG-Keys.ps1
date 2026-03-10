# NovaFuse GPG Key Generation Script
# Generates NovaFuse Certification Authority keypair for USB bundle signing

param(
    [Parameter(Mandatory=$false)]
    [string]$KeyName = "NovaFuse Certification Authority",
    
    [Parameter(Mandatory=$false)]
    [string]$KeyEmail = "certification@novafuse.ai",
    
    [Parameter(Mandatory=$false)]
    [int]$KeyLength = 4096,
    
    [Parameter(Mandatory=$false)]
    [int]$ExpireYears = 5
)

Write-Host "NovaFuse GPG Key Generation" -ForegroundColor Green
Write-Host "=============================" -ForegroundColor Green

# Check if GPG is available
try {
    $gpgVersion = & gpg --version 2>$null
    Write-Host "✅ Found GPG: $($gpgVersion[0])" -ForegroundColor Green
} catch {
    Write-Error "❌ GPG not found. Please install GPG (GnuPG) first."
    Write-Host "Download from: https://gnupg.org/download/" -ForegroundColor Yellow
    exit 1
}

# Create batch file for key generation
$batchContent = @"
%no-protection
Key-Type: RSA
Key-Length: $KeyLength
Name-Real: $KeyName
Name-Email: $KeyEmail
Expire-Date: ${ExpireYears}y
%commit
"@

$batchFile = "keygen-batch.txt"
$batchContent | Out-File -FilePath $batchFile -Encoding UTF8

Write-Host "Generating GPG keypair..." -ForegroundColor Yellow
Write-Host "  Key Name: $KeyName"
Write-Host "  Email: $KeyEmail"
Write-Host "  Key Length: $KeyLength bits"
Write-Host "  Expires: $ExpireYears years"

try {
    & gpg --batch --generate-key $batchFile
    Write-Host "✅ Key generation successful!" -ForegroundColor Green
} catch {
    Write-Error "❌ Key generation failed: $($_.Exception.Message)"
    Remove-Item $batchFile -ErrorAction SilentlyContinue
    exit 1
}

# Clean up batch file
Remove-Item $batchFile -ErrorAction SilentlyContinue

# Export public key
$publicKeyFile = "NovaFuse-PublicKey.asc"
Write-Host "Exporting public key to $publicKeyFile..." -ForegroundColor Yellow

try {
    & gpg --armor --export $KeyEmail > $publicKeyFile
    Write-Host "✅ Public key exported: $publicKeyFile" -ForegroundColor Green
} catch {
    Write-Error "❌ Failed to export public key: $($_.Exception.Message)"
    exit 1
}

# List generated keys
Write-Host "`nGenerated keys:" -ForegroundColor Cyan
& gpg --list-secret-keys --keyid-format LONG

Write-Host "`n📌 Next steps:" -ForegroundColor Yellow
Write-Host "1. Keep the private key secure and offline"
Write-Host "2. Distribute $publicKeyFile with USB bundles"
Write-Host "3. Use 'gpg --armor --output file.sig --detach-sign file' to sign manifests"
Write-Host "4. Verify with 'gpg --verify file.sig file'"
