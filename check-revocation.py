#!/usr/bin/env python3
"""
NovaFuse-EGP-VS Key Revocation Checker

Checks if a GPG public key has been revoked according to the revocation manifest.
Usage: python3 check-revocation.py <key_file> <manifest_file>
"""

import json
import sys
import subprocess
import os
from typing import Dict, List, Optional

def extract_key_id(key_file: str) -> Optional[str]:
    """Extract key ID from GPG public key file"""
    try:
        result = subprocess.run(
            ['gpg', '--with-colons', '--import-options', 'show-only', '--import', key_file],
            capture_output=True, 
            text=True, 
            timeout=30
        )
        
        if result.returncode != 0:
            print(f"❌ Error reading key file: {result.stderr}")
            return None
            
        # Parse GPG colon output to find key ID
        for line in result.stdout.split('\n'):
            if line.startswith('pub:'):
                parts = line.split(':')
                if len(parts) >= 5:
                    key_id = parts[4]
                    return key_id
                    
        print("❌ Could not extract key ID from public key")
        return None
        
    except subprocess.TimeoutExpired:
        print("❌ GPG command timed out")
        return None
    except FileNotFoundError:
        print("❌ GPG command not found. Please install GPG.")
        return None
    except Exception as e:
        print(f"❌ Error extracting key ID: {e}")
        return None

def load_revocation_manifest(manifest_file: str) -> Optional[Dict]:
    """Load revocation manifest from JSON file"""
    try:
        with open(manifest_file, 'r') as f:
            manifest = json.load(f)
        
        # Validate manifest structure
        if 'revocation_manifest' not in manifest:
            print("❌ Invalid revocation manifest: missing 'revocation_manifest'")
            return None
            
        if 'revoked_keys' not in manifest['revocation_manifest']:
            print("❌ Invalid revocation manifest: missing 'revoked_keys'")
            return None
            
        return manifest
        
    except FileNotFoundError:
        print(f"❌ Revocation manifest file not found: {manifest_file}")
        return None
    except json.JSONDecodeError as e:
        print(f"❌ Invalid JSON in manifest file: {e}")
        return None
    except Exception as e:
        print(f"❌ Error loading manifest: {e}")
        return None

def check_revocation_status(key_id: str, manifest: Dict) -> bool:
    """Check if key ID is in revocation list"""
    revoked_keys = manifest['revocation_manifest']['revoked_keys']
    
    for revoked_key in revoked_keys:
        if revoked_key['key_id'] == key_id:
            print(f"❌ KEY REVOKED")
            print(f"   Key ID: {revoked_key['key_id']}")
            print(f"   Email: {revoked_key['key_email']}")
            print(f"   Reason: {revoked_key['revocation_reason']}")
            print(f"   Date: {revoked_key['revocation_date']}")
            print(f"   Certificate: {revoked_key['revocation_certificate']}")
            return False
    
    return True

def validate_manifest_version(manifest: Dict) -> bool:
    """Check if manifest version is supported"""
    try:
        version = manifest['revocation_manifest'].get('version', '1.0')
        # Simple version check - could be more sophisticated
        if version.startswith('1.'):
            return True
        else:
            print(f"⚠️  Unsupported manifest version: {version}")
            return False
    except Exception:
        return False

def main():
    """Main function"""
    if len(sys.argv) != 3:
        print("Usage: python3 check-revocation.py <key_file> <manifest_file>")
        print("")
        print("Example:")
        print("  python3 check-revocation.py NovaFuse-PublicKey.asc revocation-manifest.json")
        sys.exit(1)
    
    key_file = sys.argv[1]
    manifest_file = sys.argv[2]
    
    # Validate input files
    if not os.path.exists(key_file):
        print(f"❌ Key file not found: {key_file}")
        sys.exit(1)
    
    if not os.path.exists(manifest_file):
        print(f"❌ Manifest file not found: {manifest_file}")
        sys.exit(1)
    
    print("NovaFuse Key Revocation Checker")
    print("===============================")
    print(f"Key file: {key_file}")
    print(f"Manifest file: {manifest_file}")
    print("")
    
    # Extract key ID
    key_id = extract_key_id(key_file)
    if not key_id:
        sys.exit(1)
    
    print(f"Extracted key ID: {key_id}")
    print("")
    
    # Load revocation manifest
    manifest = load_revocation_manifest(manifest_file)
    if not manifest:
        sys.exit(1)
    
    # Validate manifest version
    if not validate_manifest_version(manifest):
        sys.exit(1)
    
    # Check revocation status
    if check_revocation_status(key_id, manifest):
        print("✅ Key not revoked")
        print("")
        print("Manifest information:")
        manifest_info = manifest['revocation_manifest']
        print(f"  Generated: {manifest_info.get('generated', 'Unknown')}")
        print(f"  Authority: {manifest_info.get('authority', 'Unknown')}")
        print(f"  Contact: {manifest_info.get('contact', 'Unknown')}")
        print(f"  Total revoked keys: {len(manifest_info.get('revoked_keys', []))}")
        sys.exit(0)
    else:
        sys.exit(1)

if __name__ == "__main__":
    main()
