# SHA256 Checksum Verification

This document explains how to verify the integrity of the Pulse installer script using SHA256 checksums.

## Why Verify Checksums?

SHA256 checksum verification ensures that the installer script you download hasn't been tampered with or corrupted during transmission. This is a critical security measure for supply chain protection.

## Generating the Checksum

When releasing a new version, generate the checksum:

```bash
# From the repository root
sha256sum scripts/pulse-install.sh

# Or using shasum (macOS)
shasum -a 256 scripts/pulse-install.sh
```

## Publishing the Checksum

The checksum should be published in:

1. **README.md** - In the installation section
2. **GitHub Release Notes** - For each tagged release
3. **docs/install/QUICKSTART.md** - Installation documentation

## Verifying Before Installation

### Option 1: Download and Verify

```bash
# Download the installer
curl -fsSL https://raw.githubusercontent.com/astrosteveo/pulse/main/scripts/pulse-install.sh -o pulse-install.sh

# Download the checksum (published in README or release notes)
echo "<PUBLISHED_SHA256>  pulse-install.sh" > pulse-install.sh.sha256

# Verify
sha256sum -c pulse-install.sh.sha256

# If verification passes, run the installer
bash pulse-install.sh
```

### Option 2: Inline Verification

```bash
# Download installer
curl -fsSL https://raw.githubusercontent.com/astrosteveo/pulse/main/scripts/pulse-install.sh -o pulse-install.sh

# Verify checksum matches published value
if echo "<PUBLISHED_SHA256>  pulse-install.sh" | sha256sum -c -; then
  bash pulse-install.sh
else
  echo "ERROR: Checksum verification failed!"
  exit 1
fi
```

### Option 3: Automated Verification (Recommended for CI/CD)

```bash
#!/usr/bin/env bash
# Pulse installer with automatic checksum verification

set -e

INSTALLER_URL="https://raw.githubusercontent.com/astrosteveo/pulse/main/scripts/pulse-install.sh"
EXPECTED_CHECKSUM="<PUBLISHED_SHA256>"

# Download installer
echo "Downloading Pulse installer..."
curl -fsSL "$INSTALLER_URL" -o /tmp/pulse-install.sh

# Verify checksum
echo "Verifying checksum..."
if command -v sha256sum >/dev/null 2>&1; then
  ACTUAL_CHECKSUM=$(sha256sum /tmp/pulse-install.sh | cut -d' ' -f1)
elif command -v shasum >/dev/null 2>&1; then
  ACTUAL_CHECKSUM=$(shasum -a 256 /tmp/pulse-install.sh | cut -d' ' -f1)
else
  echo "ERROR: Neither sha256sum nor shasum found"
  exit 1
fi

if [ "$ACTUAL_CHECKSUM" != "$EXPECTED_CHECKSUM" ]; then
  echo "ERROR: Checksum verification failed!"
  echo "Expected: $EXPECTED_CHECKSUM"
  echo "Got:      $ACTUAL_CHECKSUM"
  exit 1
fi

echo "✓ Checksum verified"
echo "Running installer..."
bash /tmp/pulse-install.sh "$@"
```

## Current Checksum

**Version**: 1.0.0  
**Script**: `scripts/pulse-install.sh`  
**SHA256**: `<TO_BE_GENERATED_BEFORE_RELEASE>`

To generate the current checksum:

```bash
sha256sum scripts/pulse-install.sh
```

## Security Best Practices

1. **Always verify checksums** when installing from untrusted sources
2. **Use HTTPS** for downloads (curl -fsSL includes SSL verification)
3. **Check the source** - Only download from official GitHub repository
4. **Verify the URL** - Ensure it's `raw.githubusercontent.com/astrosteveo/pulse`
5. **Review the script** - Before running, review what it does (it's just a shell script!)

## Checksum Generation for Releases

Automated checksum generation should be part of the release process:

```bash
# In CI/CD pipeline or release script
CHECKSUM=$(sha256sum scripts/pulse-install.sh | cut -d' ' -f1)

# Update README with checksum
sed -i "s/SHA256: .*/SHA256: $CHECKSUM/" README.md

# Create release notes with checksum
git tag -a v1.0.0 -m "Release v1.0.0

SHA256 Checksum:
$CHECKSUM"
```

## Related Documentation

- [Installation Quickstart](QUICKSTART.md)
- [Troubleshooting Guide](TROUBLESHOOTING.md)
- [Feature Specification](../../specs/003-implement-an-install/spec.md)

---

**Note**: This verification process implements FR-008 (SHA256 checksum verification) from the feature specification.
