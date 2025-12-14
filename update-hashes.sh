#!/usr/bin/env bash
set -euo pipefail

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
  echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
  echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
  echo -e "${RED}[ERROR]${NC} $1"
}

info() {
  echo -e "${BLUE}[DETAIL]${NC} $1"
}

# Check if we have the required tools
check_dependencies() {
  local deps=("curl" "jq")
  for dep in "${deps[@]}"; do
    if ! command -v "$dep" &> /dev/null; then
      error "$dep is required but not installed"
      exit 1
    fi
  done
  
  if ! command -v nix-prefetch-github &> /dev/null; then
    warn "nix-prefetch-github not found, attempting to install..."
    nix-env -iA nixpkgs.nix-prefetch-github || {
      error "Failed to install nix-prefetch-github"
      exit 1
    }
  fi
}

# Function to get latest release tag from GitHub
get_latest_release() {
  local repo="$1"
  curl -s "https://api.github.com/repos/${repo}/releases/latest" | \
    jq -r '.tag_name // empty'
}

# Function to get latest commit SHA from GitHub
get_latest_commit() {
  local repo="$1"
  local branch="${2:-main}"
  curl -s "https://api.github.com/repos/${repo}/commits/${branch}" | \
    jq -r '.sha // empty'
}

# Function to prefetch GitHub source and get hash
prefetch_github() {
  local repo="$1"
  local rev="$2"
  # repo format is "owner/repo", split them
  local owner="${repo%%/*}"
  local pkg_name="${repo##*/}"
  nix-prefetch-github "$owner" "$pkg_name" --rev "${rev}" 2>/dev/null | \
    jq -r '.hash' | sed 's/^sha256-//'
}

# Function to get vendorHash by attempting a build
get_vendor_hash() {
  local pkg_name="$1"
  log "Getting vendorHash for ${pkg_name}..."
  
  # Build and capture the suggested vendorHash
  # This temporarily uses lib.fakeHash to get the correct value
  local build_output
  build_output=$(nix build .#homeConfigurations.tauraamui.activationPackage 2>&1 || true)
  
  # Extract the suggested hash for this specific package
  # The build output will show something like: 
  # "got sha256: ... expected sha256: lib.fakeHash"
  local suggested_hash
  suggested_hash=$(echo "$build_output" | grep -A2 "${pkg_name}" | grep "got:" | sed 's/.*got: sha256-\([A-Za-z0-9+/=]\+\).*/\1/' || true)
  
  if [ -n "$suggested_hash" ]; then
    info "Found vendorHash: sha256-${suggested_hash}"
    echo "sha256-${suggested_hash}"
  else
    warn "Could not extract vendorHash from build output"
    echo ""
  fi
}

# Function to update a package in home.nix
update_package() {
  local pkg_name="$1"
  local repo="$2"
  local branch="${3:-main}"
  local use_release="${4:-false}"
  
  log "Checking ${pkg_name}..."
  
  # Get current info
  local pkg_section
  pkg_section=$(sed -n "/${pkg_name} = pkgs-unstable.buildGoModule/,/^  };/p" home.nix)
  
  local current_rev
  current_rev=$(echo "$pkg_section" | grep "rev =" | sed 's/.*rev = "\(.*\)";/\1/')
  
  if [ -z "$current_rev" ]; then
    warn "Could not find current rev for ${pkg_name}"
    return 1
  fi
  
  # Get latest info
  local latest_rev
  if [ "$use_release" = "true" ]; then
    latest_rev=$(get_latest_release "${repo}")
  else
    latest_rev=$(get_latest_commit "${repo}" "${branch}")
  fi
  
  if [ -z "$latest_rev" ]; then
    error "Could not get latest rev for ${pkg_name}"
    return 1
  fi
  
  if [ "$current_rev" = "$latest_rev" ]; then
    info "${pkg_name} is already up to date (${current_rev})"
    return 1
  fi
  
  log "Update available: ${current_rev} -> ${latest_rev}"
  
  # Prefetch to get new source hash
  local new_hash
  new_hash=$(prefetch_github "${repo}" "${latest_rev}")
  
  if [ -z "$new_hash" ]; then
    error "Could not prefetch ${pkg_name}"
    return 1
  fi
  
  # Create backup
  cp home.nix home.nix.backup
  
  # Update rev and sha256 in home.nix
  sed -i "/${pkg_name} = pkgs-unstable.buildGoModule/,/^  };/ s|rev = \"${current_rev}\"|rev = \"${latest_rev}\"|" home.nix
  sed -i "/${pkg_name} = pkgs-unstable.buildGoModule/,/^  };/ s|sha256 = \"sha256-[A-Za-z0-9+/=]\+\"|sha256 = \"sha256-${new_hash}\"|" home.nix
  
  # Set vendorHash to fakeHash temporarily - we'll update it after build
  sed -i "/${pkg_name} = pkgs-unstable.buildGoModule/,/^  };/ s|vendorHash = \"sha256-[A-Za-z0-9+/=]\+\"|vendorHash = lib.fakeHash; # Update me|" home.nix
  sed -i "/${pkg_name} = pkgs-unstable.buildGoModule/,/^  };/ s|vendorHash = null|vendorHash = lib.fakeHash; # Update me|" home.nix
  
  log "Updated ${pkg_name} revision and source hash"
  
  # Now try to build and get vendorHash
  log "Building to get correct vendorHash for ${pkg_name}..."
  local vendor_hash
  vendor_hash=$(get_vendor_hash "${pkg_name}")
  
  # If we got a vendorHash, update it
  if [ -n "$vendor_hash" ] && [ "$vendor_hash" != "sha256-" ]; then
    sed -i "/${pkg_name} = pkgs-unstable.buildGoModule/,/^  };/ s|vendorHash = lib.fakeHash; # Update me|vendorHash = \"${vendor_hash}\"|" home.nix
    log "Updated ${pkg_name} vendorHash"
  else
    warn "Could not determine vendorHash for ${pkg_name}. Build will tell you what it should be."
  fi
  
  return 0
}

# Function to update crush (versioned release)
update_crush() {
  log "Checking crush..."
  
  local latest_tag
  latest_tag=$(get_latest_release "charmbracelet/crush")
  
  if [ -z "$latest_tag" ]; then
    error "Could not get latest tag for crush"
    return 1
  fi
  
  local latest_version=${latest_tag#v}
  
  local current_version
  current_version=$(sed -n '/crush = pkgs-unstable.buildGoModule rec/,/^  };/p' home.nix | \
    grep "version =" | sed 's/.*version = "\(.*\)";/\1/')
  
  if [ "$current_version" = "$latest_version" ]; then
    info "crush is already up to date (${current_version})"
    return 1
  fi
  
  log "Updating crush: ${current_version} -> ${latest_version}"
  
  # Get commit for this tag
  local commit_sha
  commit_sha=$(curl -s "https://api.github.com/repos/charmbracelet/crush/git/refs/tags/${latest_tag}" | \
    jq -r '.object.sha // empty')
  
  if [ -z "$commit_sha" ]; then
    error "Could not get commit SHA for tag ${latest_tag}"
    return 1
  fi
  
  # Prefetch
  local new_hash
  new_hash=$(prefetch_github "charmbracelet/crush" "$commit_sha")
  
  if [ -z "$new_hash" ]; then
    error "Could not prefetch crush"
    return 1
  fi
  
  # Update
  sed -i "/crush = pkgs-unstable.buildGoModule rec/,/^  };/ s|version = \"${current_version}\"|version = \"${latest_version}\"|" home.nix
  sed -i "/crush = pkgs-unstable.buildGoModule rec/,/^  };/ s|rev = \"v[0-9.]\+\"|rev = \"${latest_tag}\"|" home.nix
  sed -i "/crush = pkgs-unstable.buildGoModule rec/,/^  };/ s|sha256 = \"sha256-[A-Za-z0-9+/=]\+\"|sha256 = \"sha256-${new_hash}\"|" home.nix
  sed -i "/crush = pkgs-unstable.buildGoModule rec/,/^  };/ s|vendorHash = \"sha256-[A-Za-z0-9+/=]\+\"|vendorHash = lib.fakeHash; # Update me|" home.nix
  
  log "Updated crush version and source hash"
  
  # Get vendorHash from build
  local vendor_hash
  vendor_hash=$(get_vendor_hash "crush")
  
  if [ -n "$vendor_hash" ] && [ "$vendor_hash" != "sha256-" ]; then
    sed -i "/crush = pkgs-unstable.buildGoModule rec/,/^  };/ s|vendorHash = lib.fakeHash; # Update me|vendorHash = \"${vendor_hash}\"|" home.nix
    log "Updated crush vendorHash"
  fi
  
  return 0
}

# Main function
main() {
  log "Starting package hash updates..."
  
  # Check dependencies
  check_dependencies
  
  # Change to script directory
  cd "$(dirname "$0")"
  
  # Track updates
  UPDATES_MADE=0
  
  # Create backup
  log "Creating backup of home.nix..."
  cp home.nix home.nix.backup.$(date +%Y%m%d_%H%M%S)
  
  # Update crush (versioned)
  update_crush && ((UPDATES_MADE++)) || true
  
  # Update branch-based packages
  update_package "gofumpt" "mvdan/gofumpt" "master" && ((UPDATES_MADE++)) || true
  update_package "goimports" "golang/tools" "master" && ((UPDATES_MADE++)) || true
  update_package "scc" "boyter/scc" "master" && ((UPDATES_MADE++)) || true
  update_package "sqlc" "sqlc-dev/sqlc" "main" && ((UPDATES_MADE++)) || true
  update_package "gotestsum" "gotestyourself/gotestsum" "main" && ((UPDATES_MADE++)) || true
  update_package "invoice" "maaslalani/invoice" "main" && ((UPDATES_MADE++)) || true
  
  log "Updates completed!"
  
  if [ $UPDATES_MADE -gt 0 ]; then
    log "$UPDATES_MADE packages were updated."
    log "Testing build..."
    
    if nix build .#homeConfigurations.tauraamui.activationPackage; then
      log "Build successful! All hashes are correct."
    else
      error "Build failed. Check the output for the correct vendorHash values."
      log "You can view the backup file if needed to revert changes."
      exit 1
    fi
  else
    log "No updates were necessary."
  fi
  
  log "Done!"
}

# Show usage if --help is passed
if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
  echo "Usage: $0 [options]"
  echo ""
  echo "Update package hashes in home.nix automatically"
  echo ""
  echo "Options:"
  echo "  -h, --help     Show this help message"
  echo ""
  echo "This script will:"
  echo "1. Check for updates to all Go packages in home.nix"
  echo "2. Update rev/tag, source sha256, and vendorHash automatically"
  echo "3. Test the build to ensure correctness"
  echo ""
  echo "Packages tracked:"
  echo "  - charmbracelet/crush (releases)"
  echo "  - mvdan/gofumpt (master)"
  echo "  - golang/tools (master)"
  echo "  - boyter/scc (master)"
  echo "  - sqlc-dev/sqlc (main)"
  echo "  - gotestyourself/gotestsum (main)"
  echo "  - maaslalani/invoice (main)"
  exit 0
fi

# Run main function
main "$@"
