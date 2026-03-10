# NovaFuse-EGP-VS USB Bundle Generator (Enhanced)
# Generates complete USB distribution package with integrity verification and provenance

param(
    [Parameter(Mandatory=$false)]
    [string]$OutputPath = ".\USB-Bundle",
    
    [Parameter(Mandatory=$false)]
    [string]$Version = "v0.1.0",
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipSigning,
    
    [Parameter(Mandatory=$false)]
    [switch]$IncludeRevocationCheck
)

Write-Host "NovaFuse-EGP-VS USB Bundle Generator v2.0" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green

# Version pinning - Check minimum tool versions

# Check PowerShell version
$PSMinVersion = [Version]"7.0.0"
if ($PSVersionTable.PSVersion -lt $PSMinVersion) {
    Write-Error "❌ PowerShell $PSMinVersion or higher required. Current: $($PSVersionTable.PSVersion)"
    exit 1
}
Write-Host "✅ PowerShell version: $($PSVersionTable.PSVersion)" -ForegroundColor Green

# Check GPG availability and version
try {
    $gpgVersion = & gpg --version 2>$null
    $gpgVersionString = $gpgVersion[0].Replace('gpg (GnuPG) ', '')
    $gpgVersionObj = [Version]$gpgVersionString
    $GPGMinVersion = [Version]"2.2.0"
    
    if ($gpgVersionObj -lt $GPGMinVersion) {
        Write-Error "❌ GPG $GPGMinVersion or higher required. Current: $gpgVersionString"
        exit 1
    }
    Write-Host "✅ GPG version: $gpgVersionString" -ForegroundColor Green
} catch {
    Write-Warning "⚠️  GPG not found. Signature generation will be skipped."
    $SkipSigning = $true
}

# Create output directory
$BundleDir = "$OutputPath\NovaFuse-EGP-VS-$Version"
if (Test-Path $BundleDir) {
    Remove-Item $BundleDir -Recurse -Force
}
New-Item -ItemType Directory -Path $BundleDir -Force | Out-Null

# Required files and directories
$RequiredItems = @(
    "verifier\verify.ps1",
    "verifier\config\profile.json",
    "tests\EG01_determinism",
    "tests\EG02_refusal",
    "tests\EG03_authority_separation",
    "tests\EG04_identity_binding",
    "tests\EG05_evidence",
    "tests\EG06_fail_closed",
    "cert-schema\egp-certificate.schema.json",
    "ASSESSOR-RUN.md",
    "CHANGE_CONTROL.md",
    "README.md"
)

Write-Host "Copying required files..." -ForegroundColor Yellow

# Copy files and directories
foreach ($Item in $RequiredItems) {
    $Source = ".\$Item"
    $Destination = "$BundleDir\$Item"
    
    if (Test-Path $Source) {
        Write-Host "  Copying: $Item"
        
        # Create destination directory if needed
        $DestDir = Split-Path $Destination -Parent
        if ($DestDir -and !(Test-Path $DestDir)) {
            New-Item -ItemType Directory -Path $DestDir -Force | Out-Null
        }
        
        Copy-Item -Path $Source -Destination $Destination -Recurse -Force
    } else {
        Write-Warning "Missing required item: $Item"
    }
}

# Generate SHA-256 manifest
Write-Host "Generating SHA-256 manifest..." -ForegroundColor Yellow
$ManifestPath = "$BundleDir\RELEASE-HASHES.txt"
$ManifestContent = @(
    "# NovaFuse-EGP-VS $Version - SHA-256 Integrity Manifest",
    "# Generated: $(Get-Date -Format 'yyyy-MM-dd')",
    "# Profile: NovaFuse-EGP-0.1",
    "# Harness: NovaFuse-EGP-VS $Version",
    ""
)

Get-ChildItem -Path $BundleDir -Recurse -File | ForEach-Object {
    $RelativePath = $_.FullName.Replace($BundleDir, "").TrimStart('\').Replace('\', '/')
    $Hash = (Get-FileHash -Path $_.FullName -Algorithm SHA256).Hash
    $ManifestContent += "$Hash  $RelativePath"
}

$ManifestContent | Out-File -FilePath $ManifestPath -Encoding UTF8
Write-Host "  Created: RELEASE-HASHES.txt"

# Copy GPG public key
if (Test-Path ".\NovaFuse-PublicKey.asc") {
    Copy-Item ".\NovaFuse-PublicKey.asc" "$BundleDir\NovaFuse-PublicKey.asc"
    Write-Host "  Copied: NovaFuse-PublicKey.asc"
} else {
    Write-Warning "Missing: NovaFuse-PublicKey.asc"
}

# Sign manifest if GPG is available
if (-not $SkipSigning) {
    try {
        $gpg = Get-Command gpg -ErrorAction SilentlyContinue
        if ($gpg) {
            Write-Host "Signing manifest with GPG..." -ForegroundColor Yellow
            & gpg --detach-sign --armor "$ManifestPath"
            Write-Host "  Created: RELEASE-HASHES.txt.sig"
        } else {
            Write-Warning "GPG not found. Skipping signature generation."
        }
    } catch {
        Write-Warning "GPG signing failed: $($_.Exception.Message)"
    }
}

# Copy checklist
Copy-Item ".\USB-Distribution-Checklist.md" "$BundleDir\USB-Distribution-Checklist.md"
Write-Host "  Copied: USB-Distribution-Checklist.md"

# Create archive
Write-Host "Creating distribution archive..." -ForegroundColor Yellow
$ArchivePath = "$OutputPath\NovaFuse-EGP-VS-$Version.zip"
if (Test-Path $ArchivePath) {
    Remove-Item $ArchivePath -Force
}

Compress-Archive -Path "$BundleDir\*" -DestinationPath $ArchivePath
Write-Host "  Created: $ArchivePath"

# Verification
Write-Host "`nBundle verification:" -ForegroundColor Green
Write-Host "Bundle directory: $BundleDir"
Write-Host "Archive file: $ArchivePath"
Write-Host "Total files: $(Get-ChildItem -Path $BundleDir -Recurse -File | Measure-Object).Count"
Write-Host "Bundle size: $([math]::Round((Get-ChildItem -Path $BundleDir -Recurse | Measure-Object -Property Length -Sum).Sum / 1MB, 2)) MB"

Write-Host "`nUSB bundle generation complete!" -ForegroundColor Green
Write-Host "Next steps:"
Write-Host "1. Review the bundle contents"
Write-Host "2. Test on an offline machine"
Write-Host "3. Follow the USB-Distribution-Checklist.md"
