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
$PSMinVersion = [Version]"5.1.0"
if ($PSVersionTable.PSVersion -lt $PSMinVersion) {
    Write-Error "PowerShell $PSMinVersion or higher required. Current: $($PSVersionTable.PSVersion)"
    exit 1
}
Write-Host "PowerShell version: $($PSVersionTable.PSVersion)" -ForegroundColor Green

# Check GPG availability and version
$gpgVersionString = "Not Available"
$GPGMinVersion = [Version]"2.2.0"
$gpgAvailable = $false

try {
    $gpgVersion = & gpg --version 2>$null
    $gpgVersionString = $gpgVersion[0].Replace('gpg (GnuPG) ', '')
    $gpgVersionObj = [Version]$gpgVersionString
    
    if ($gpgVersionObj -lt $GPGMinVersion) {
        Write-Error "GPG $GPGMinVersion or higher required. Current: $gpgVersionString"
        exit 1
    }
    Write-Host "GPG version: $gpgVersionString" -ForegroundColor Green
    $gpgAvailable = $true
} catch {
    Write-Warning "GPG not found. Signature generation will be skipped."
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
    "README.md",
    "Certification-Summary.md",
    "KEY-REVOCATION.md",
    "USB-Distribution-Checklist.md",
    "USB-Chain-of-Custody.md",
    "Generate-USB-Bundle.ps1",
    "Generate-GPG-Keys.ps1",
    "Sign-Manifest.ps1",
    "make-usb-bundle.sh",
    "check-revocation.py"
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

# Generate bundle metadata
Write-Host "Generating bundle metadata..." -ForegroundColor Yellow
$Metadata = @{
    "bundle_metadata" = @{
        "format_version" = "1.0"
        "bundle_name" = "NovaFuse-EGP-VS"
        "bundle_version" = $Version
        "profile_version" = "0.1.0"
        "specification" = "NovaFuse-EGP-0.1"
        
        "build_information" = @{
            "build_host" = $env:COMPUTERNAME
            "build_os" = (Get-CimInstance -ClassName Win32_OperatingSystem).Caption
            "build_architecture" = $env:PROCESSOR_ARCHITECTURE
            "build_timestamp" = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
            "build_timezone" = "UTC"
            "build_environment" = "Production"
        }
        
        "tool_versions" = @{
            "powershell" = @{
                "minimum_version" = "7.0.0"
                "recommended_version" = "7.2.0"
                "build_version" = $PSVersionTable.PSVersion.ToString()
            }
            "gpg" = @{
                "minimum_version" = "2.2.0"
                "recommended_version" = "2.4.0"
                "build_version" = $gpgVersionString
            }
        }
        
        "integrity" = @{
            "bundle_size_bytes" = 0
            "file_count" = 0
            "directory_count" = 0
            "compression_method" = "ZIP"
        }
        
        "security" = @{
            "signing_key_id" = "ABCD1234EF567890"
            "signing_key_email" = "certification@novafuse.ai"
            "signature_algorithm" = "RSA-4096"
            "hash_algorithm" = "SHA-256"
            "signature_format" = "PGP"
        }
    }
}

# Calculate bundle statistics
$files = Get-ChildItem -Path $BundleDir -Recurse -File
$dirs = Get-ChildItem -Path $BundleDir -Recurse -Directory
$Metadata.bundle_metadata.integrity.bundle_size_bytes = ($files | Measure-Object -Property Length -Sum).Sum
$Metadata.bundle_metadata.integrity.file_count = $files.Count
$Metadata.bundle_metadata.integrity.directory_count = $dirs.Count

# Save metadata
$MetadataPath = "$BundleDir\BUNDLE-METADATA.json"
$Metadata | ConvertTo-Json -Depth 10 | Out-File -FilePath $MetadataPath -Encoding UTF8
Write-Host "  Created: BUNDLE-METADATA.json" -ForegroundColor Green

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
Write-Host "  Created: RELEASE-HASHES.txt" -ForegroundColor Green

# Update metadata with bundle hash
$BundleHash = (Get-FileHash -Path $ManifestPath -Algorithm SHA256).Hash
$Metadata.bundle_metadata.integrity.bundle_sha256 = $BundleHash
$Metadata | ConvertTo-Json -Depth 10 | Out-File -FilePath $MetadataPath -Encoding UTF8

# Copy GPG public key if available
if (Test-Path ".\NovaFuse-PublicKey.asc") {
    Copy-Item ".\NovaFuse-PublicKey.asc" "$BundleDir\NovaFuse-PublicKey.asc"
    Write-Host "  Copied: NovaFuse-PublicKey.asc" -ForegroundColor Green
} else {
    Write-Warning "Missing: NovaFuse-PublicKey.asc"
}

# Sign manifest if GPG is available and not skipped
if (-not $SkipSigning -and $gpgAvailable) {
    Write-Host "Signing manifest with GPG..." -ForegroundColor Yellow
    try {
        & gpg --armor --output "$ManifestPath.sig" --detach-sign $ManifestPath
        Write-Host "  Created: RELEASE-HASHES.txt.sig" -ForegroundColor Green
    } catch {
        Write-Warning "GPG signing failed: $($_.Exception.Message)"
    }
}

# Include revocation check if requested
if ($IncludeRevocationCheck) {
    Write-Host "Including revocation check..." -ForegroundColor Yellow
    Copy-Item ".\check-revocation.py" "$BundleDir\check-revocation.py"
    Write-Host "  Copied: check-revocation.py" -ForegroundColor Green
}

# Create archive
Write-Host "Creating distribution archive..." -ForegroundColor Yellow
$ArchivePath = "$OutputPath\NovaFuse-EGP-VS-$Version.zip"
if (Test-Path $ArchivePath) {
    Remove-Item $ArchivePath -Force
}

Compress-Archive -Path "$BundleDir\*" -DestinationPath $ArchivePath
Write-Host "  Created: $ArchivePath" -ForegroundColor Green

# Verification
Write-Host "`nBundle verification:" -ForegroundColor Green
Write-Host "Bundle directory: $BundleDir"
Write-Host "Archive file: $ArchivePath"
Write-Host "Total files: $($files.Count)"
Write-Host "Bundle size: $([math]::Round($Metadata.bundle_metadata.integrity.bundle_size_bytes / 1MB, 2)) MB"
Write-Host "Bundle SHA-256: $BundleHash"

Write-Host "`nVersion pinning verification:" -ForegroundColor Cyan
Write-Host "PowerShell: $($PSVersionTable.PSVersion) (min: $PSMinVersion)"
Write-Host "GPG: $gpgVersionString (min: 2.2.0)"

Write-Host "`nUSB bundle generation complete!" -ForegroundColor Green
Write-Host "Next steps:"
Write-Host "1. Review the bundle contents"
Write-Host "2. Test on an offline machine"
Write-Host "3. Follow the USB-Distribution-Checklist.md"
if (-not $SkipSigning) {
    Write-Host "4. Verify signatures before distribution"
}
Write-Host "5. Complete USB-Chain-of-Custody.md for each transfer"
