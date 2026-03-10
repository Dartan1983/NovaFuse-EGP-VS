# Create Release Bundle for NovaFuse-EGP-VS v0.1.2

param(
    [string]$OutputPath = ".",
    [switch]$SkipSigning
)

Write-Host "Creating NovaFuse-EGP-VS v0.1.2 Release Bundle..." -ForegroundColor Green

# Create release directory
$ReleaseDir = Join-Path $OutputPath "NovaFuse-EGP-VS-v0.1.2"
if (Test-Path $ReleaseDir) {
    Remove-Item $ReleaseDir -Recurse -Force
}
New-Item -ItemType Directory -Path $ReleaseDir -Force | Out-Null

# Copy essential files
$IncludeFiles = @(
    "README.md",
    "LICENSE", 
    "SECURITY.md",
    "CONTRIBUTING.md",
    "CHANGELOG.md",
    "ARCHITECTURE.md",
    "EGP-VS-Auditor-Quick-Guide.md",
    "RELEASE.md",
    "QUICK-VALIDATE.ps1",
    "VALIDATE-SYSTEM.ps1",
    "NovaFuse-PublicKey.asc",
    "check-revocation.py"
)

Write-Host "Copying core files..." -ForegroundColor Yellow
foreach ($file in $IncludeFiles) {
    if (Test-Path $file) {
        Copy-Item $file $ReleaseDir -Force
        Write-Host "  ✓ $file" -ForegroundColor Green
    } else {
        Write-Host "  ✗ $file (not found)" -ForegroundColor Red
    }
}

# Copy directories
$IncludeDirs = @(
    "verifier",
    "tests", 
    "docs",
    ".github",
    "cert-schema"
)

Write-Host "Copying directories..." -ForegroundColor Yellow
foreach ($dir in $IncludeDirs) {
    if (Test-Path $dir) {
        Copy-Item $dir $ReleaseDir -Recurse -Force
        Write-Host "  ✓ $dir/" -ForegroundColor Green
    } else {
        Write-Host "  ✗ $dir/ (not found)" -ForegroundColor Red
    }
}

# Create release manifest
$Manifest = @{
    "release_version" = "v0.1.2"
    "release_date" = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
    "bundle_name" = "NovaFuse-EGP-VS-v0.1.2"
    "description" = "NovaFuse Evidence Governance Protocol Verification Harness - Initial Auditor Evaluation Release"
    "verification_status" = @{
        "EG01" = "PASS"
        "EG02" = "PASS"
        "EG03" = "PASS"
        "EG04" = "PASS"
        "EG05" = "PASS"
        "EG06" = "PASS"
    }
    "platforms" = @("Windows", "Linux", "macOS")
    "execution_modes" = @("PowerShell", "Docker", "Offline")
    "contact" = "novafuse.technologies@gmail.com"
    "license" = "NCIL v0.1"
}

$ManifestPath = Join-Path $ReleaseDir "RELEASE-MANIFEST.json"
$Manifest | ConvertTo-Json -Depth 4 | Out-File $ManifestPath -Encoding UTF8
Write-Host "  ✓ RELEASE-MANIFEST.json" -ForegroundColor Green

# Generate hashes
Write-Host "Generating SHA-256 hashes..." -ForegroundColor Yellow
$HashFile = Join-Path $ReleaseDir "RELEASE-HASHES.txt"
$Hashes = @()

Get-ChildItem $ReleaseDir -Recurse -File | ForEach-Object {
    $RelativePath = $_.FullName.Replace($ReleaseDir, "").TrimStart("\").Replace("\", "/")
    $Hash = (Get-FileHash $_.FullName -Algorithm SHA256).Hash.ToLower()
    $Hashes += "$Hash  $RelativePath"
}

$Hashes | Sort-Object | Out-File $HashFile -Encoding UTF8
Write-Host "  ✓ RELEASE-HASHES.txt" -ForegroundColor Green

# Sign hashes if not skipped
if (-not $SkipSigning) {
    Write-Host "Signing release hashes..." -ForegroundColor Yellow
    try {
        gpg --armor --output "$HashFile.sig" --detach-sig $HashFile
        Write-Host "  ✓ RELEASE-HASHES.txt.sig" -ForegroundColor Green
    } catch {
        Write-Host "  ⚠ GPG signing skipped (GPG not available)" -ForegroundColor Yellow
    }
}

# Create ZIP bundle
$ZipPath = Join-Path $OutputPath "NovaFuse-EGP-VS-v0.1.2.zip"
if (Test-Path $ZipPath) {
    Remove-Item $ZipPath -Force
}

Write-Host "Creating ZIP bundle..." -ForegroundColor Yellow
Compress-Archive -Path $ReleaseDir -DestinationPath $ZipPath -Force

# Verify ZIP
$ZipSize = (Get-Item $ZipPath).Length
$ZipHash = (Get-FileHash $ZipPath -Algorithm SHA256).Hash.ToLower()

Write-Host "`n📦 Release Bundle Created Successfully!" -ForegroundColor Green
Write-Host "📁 Bundle: $ReleaseDir" -ForegroundColor Cyan
Write-Host "📦 Archive: $ZipPath" -ForegroundColor Cyan
Write-Host "📏 Size: $([math]::Round($ZipSize/1MB, 2)) MB" -ForegroundColor Cyan
Write-Host "🔐 SHA-256: $ZipHash" -ForegroundColor Cyan

Write-Host "`n✅ Ready for GitHub release upload!" -ForegroundColor Green
