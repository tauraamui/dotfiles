#!/usr/bin/env bash
set -euo pipefail

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
  echo -e "${GREEN}[INFO]${NC} $1" >&2
}

warn() {
  echo -e "${YELLOW}[WARN]${NC} $1" >&2
}

error() {
  echo -e "${RED}[ERROR]${NC} $1" >&2
}

info() {
  echo -e "${BLUE}[DETAIL]${NC} $1" >&2
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
    error "nix-prefetch-github is required but not found in PATH"
    error ""
    error "Install it with: nix profile install nixpkgs#nix-prefetch-github"
    error "Or in GitHub Actions, add this step before running the script:"
    error "  - run: nix profile install nixpkgs#nix-prefetch-github"
    exit 1
  fi
}

# Function to check GitHub API rate limit
check_rate_limit() {
  log "Checking GitHub API rate limit..."
  local response
  local remaining
  
  if [ -n "${GITHUB_TOKEN:-}" ]; then
    response=$(curl -s -H "Authorization: token $GITHUB_TOKEN" https://api.github.com/rate_limit)
  else
    response=$(curl -s https://api.github.com/rate_limit)
  fi
  
  remaining=$(echo "$response" | jq -r '.rate.remaining // empty')
  
  if [ -n "$remaining" ]; then
    log "API requests remaining: $remaining"
    if [ "$remaining" -lt 10 ]; then
      warn "Low on API requests! Consider setting GITHUB_TOKEN environment variable."
      if [ -z "${GITHUB_TOKEN:-}" ]; then
        warn "Without GITHUB_TOKEN: 60 requests/hour limit"
        warn "With GITHUB_TOKEN: 5000 requests/hour limit"
      fi
    fi
  else
    warn "Could not check rate limit (this is okay)"
  fi
}

# Function to get latest release tag from GitHub
get_latest_release() {
  local repo="$1"
  local auth_header=""
  
  if [ -n "${GITHUB_TOKEN:-}" ]; then
    auth_header="-H Authorization: token $GITHUB_TOKEN"
  fi
  
  curl -s $auth_header "https://api.github.com/repos/${repo}/releases/latest" | \
    jq -r '.tag_name // empty'
}

# Function to get latest commit SHA from GitHub
get_latest_commit() {
  local repo="$1"
  local branch="${2:-main}"
  local auth_header=""
  
  if [ -n "${GITHUB_TOKEN:-}" ]; then
    auth_header="-H Authorization: token $GITHUB_TOKEN"
  fi
  
  curl -s $auth_header "https://api.github.com/repos/${repo}/commits/${branch}" | \
    jq -r '.sha // empty'
}

# Function to prefetch GitHub source and get hash
prefetch_github() {
  local repo="$1"
  local rev="$2"
  # repo format is "owner/repo", split them
  local owner="${repo%%/*}"
  local pkg_name="${repo##*/}"
  local output
  local exit_code
  
  info "Prefetching $owner/$pkg_name at rev $rev..."
  
  if [ -n "${GITHUB_TOKEN:-}" ]; then
    # Use authenticated request for higher rate limits
    output=$(nix-prefetch-github "$owner" "$pkg_name" --rev "${rev}" --github-access-token "$GITHUB_TOKEN" 2>&1)
    exit_code=$?
  else
    output=$(nix-prefetch-github "$owner" "$pkg_name" --rev "${rev}" 2>&1)
    exit_code=$?
  fi
  
  if [ $exit_code -ne 0 ]; then
    error "nix-prefetch-github failed with exit code $exit_code"
    error "Command output: $output"
    echo ""
    return 1
  fi
  
  # Extract the hash from the JSON output
  local hash
  hash=$(echo "$output" | jq -r '.hash // empty' 2>/dev/null)
  
  if [ -z "$hash" ]; then
    error "Could not extract hash from nix-prefetch-github output"
    error "Raw output: $output"
    echo ""
    return 1
  fi
  
  # Remove sha256- prefix if present
  echo "$hash" | sed 's/^sha256-//'
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
    error "This may be due to GitHub API rate limiting."
    if [ -z "${GITHUB_TOKEN:-}" ]; then
      error "Try setting GITHUB_TOKEN environment variable for higher rate limits."
    fi
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
  local prefetch_exit=$?
  if [ $prefetch_exit -ne 0 ] || [ -z "$new_hash" ]; then
    error "Could not prefetch ${pkg_name} (exit: $prefetch_exit, hash: '$new_hash')"
    return 1
  fi
  
  info "Successfully prefetched ${pkg_name}, new hash: $new_hash"
  
  # Create backup if not already created
  if [ ! -f "home.nix.backup.$(date +%Y%m%d)*" ]; then
    cp home.nix "home.nix.backup.$(date +%Y%m%d_%H%M%S)"
  fi
  
  # Update rev and sha256 in home.nix
  sed -i "/${pkg_name} = pkgs-unstable.buildGoModule/,/^  };/ s|rev = \"${current_rev}\"|rev = \"${latest_rev}\"|" home.nix
  info "Updated rev for ${pkg_name}"
  
  sed -i "/${pkg_name} = pkgs-unstable.buildGoModule/,/^  };/ s|sha256 = \"sha256-[A-Za-z0-9+/=]\+\"|sha256 = \"sha256-${new_hash}\"|" home.nix
  info "Updated sha256 for ${pkg_name}"
  
  # Try to get the vendorHash automatically via build
  log "Attempting to build and get correct vendorHash for ${pkg_name}..."
  
  # Try to build (this will fail but show the correct vendorHash)
  local build_output
  build_output=$(nix build .#homeConfigurations.tauraamui.activationPackage 2>&1 || true)
  
  # Extract the vendorHash from the build output
  local correct_vendor_hash
  correct_vendor_hash=$(echo "$build_output" | grep -o "got: sha256-[A-Za-z0-9+/=]\+" | sed 's/got: sha256-//' | head -1)
  
  if [ -n "$correct_vendor_hash" ]; then
    # Update the vendorHash with the correct value
    sed -i "/${pkg_name} = pkgs-unstable.buildGoModule/,/^  };/ s|vendorHash = lib.fakeHash; # Update me|vendorHash = \"sha256-${correct_vendor_hash}\"|" home.nix 2>/dev/null || true
    
    # Verify the update worked by checking if it was found
    if grep -q "vendorHash = \"sha256-${correct_vendor_hash}\"" home.nix; then
      info "Successfully updated vendorHash for ${pkg_name}: sha256-${correct_vendor_hash}"
    else
      # Try alternative sed pattern
      sed -i "/${pkg_name}.*buildGoModule/,/^  };/ s|vendorHash = \"sha256-[A-Za-z0-9+/=]\+\"|vendorHash = \"sha256-${correct_vendor_hash}\"|" home.nix 2>/dev/null || true
      
      if grep -q "vendorHash = \"sha256-${correct_vendor_hash}\"" home.nix; then
        info "Successfully updated vendorHash for ${pkg_name}: sha256-${correct_vendor_hash}"
      else
        warn "Could not automatically update vendorHash for ${pkg_name} in the file."
        warn "Please run 'home-manager switch' to get the correct value."
        warn "Search for 'vendorHash.*${pkg_name}' in the error output."
      fi
    fi
  else
    # Could not extract vendorHash from build output
    info "Could not automatically determine vendorHash for ${pkg_name}."
    info "This may happen if the build fails for other reasons."
    info "You will need to update it manually by running:"
    info "  home-manager switch -b backup --impure --flake ."
    info "Then update the vendorHash value shown in the error output."
  fi
  
  log "Updated ${pkg_name} revision and source hash"
  
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
  commit_sha=$(curl -s ${GITHUB_TOKEN:+-H "Authorization: token $GITHUB_TOKEN"} "https://api.github.com/repos/charmbracelet/crush/git/refs/tags/${latest_tag}" | \
    jq -r '.object.sha // empty')
  
  if [ -z "$commit_sha" ]; then
    error "Could not get commit SHA for tag ${latest_tag}"
    return 1
  fi
  
  # Prefetch
  local new_hash
  new_hash=$(prefetch_github "charmbracelet/crush" "$commit_sha")
  if [ $? -ne 0 ] || [ -z "$new_hash" ]; then
    error "Could not prefetch crush"
    return 1
  fi
  
  # Update (suppress sed warnings if patterns don't match old values)
  sed -i "/crush = pkgs-unstable.buildGoModule rec/,/^  };/ s|version = \"${current_version}\"|version = \"${latest_version}\"|" home.nix 2>/dev/null || true
  sed -i "/crush = pkgs-unstable.buildGoModule rec/,/^  };/ s|rev = \"v[0-9.]\+\"|rev = \"${latest_tag}\"|" home.nix 2>/dev/null || true
  sed -i "/crush = pkgs-unstable.buildGoModule rec/,/^  };/ s|sha256 = \"sha256-[A-Za-z0-9+/=]\+\"|sha256 = \"sha256-${new_hash}\"|" home.nix 2>/dev/null || true
  sed -i "/crush = pkgs-unstable.buildGoModule rec/,/^  };/ s|vendorHash = \"sha256-[A-Za-z0-9+/=]\+\"|vendorHash = lib.fakeHash; # Update me|" home.nix 2>/dev/null || true
  
  # Try to get the vendorHash automatically via build
  log "Attempting to build and get correct vendorHash for crush..."
  
  local build_output
  build_output=$(nix build .#homeConfigurations.tauraamui.activationPackage 2>&1 || true)
  
  local correct_vendor_hash
  correct_vendor_hash=$(echo "$build_output" | grep -o "got: sha256-[A-Za-z0-9+/=]\+" | sed 's/got: sha256-//' | head -1)
  
  if [ -n "$correct_vendor_hash" ]; then
    sed -i "/crush = pkgs-unstable.buildGoModule rec/,/^  };/ s|vendorHash = lib.fakeHash; # Update me|vendorHash = \"sha256-${correct_vendor_hash}\"|" home.nix 2>/dev/null || true
    
    if grep -q "vendorHash = \"sha256-${correct_vendor_hash}\"" home.nix; then
      info "Successfully updated vendorHash for crush: sha256-${correct_vendor_hash}"
    else
      sed -i "/crush.*buildGoModule rec/,/^  };/ s|vendorHash = \"sha256-[A-Za-z0-9+/=]\+\"|vendorHash = \"sha256-${correct_vendor_hash}\"|" home.nix 2>/dev/null || true
      
      if grep -q "vendorHash = \"sha256-${correct_vendor_hash}\"" home.nix; then
        info "Successfully updated vendorHash for crush: sha256-${correct_vendor_hash}"
      else
        warn "Could not automatically update vendorHash for crush"
      fi
    fi
  else
    info "Could not automatically determine vendorHash for crush from build output"
    info "You will need to update it manually by running:"
    info "  home-manager switch -b backup --impure --flake ."
  fi
  
  log "Updated crush version and source hash"
  
  return 0
}

# Main function
main() {
  log "Starting package hash updates..."
  
  # Check dependencies
  check_dependencies
  
  # Check rate limit
  check_rate_limit
  
  # Change to script directory
  cd "$(dirname "$0")"
  
  # Track updates
  UPDATES_MADE=0
  
  # Create backup
  log "Creating backup of home.nix..."
  cp home.nix "home.nix.backup.$(date +%Y%m%d_%H%M%S)"
  
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
    log ""
    log "Next steps:"
    log "1. Review the changes in home.nix"
    log "2. Run: home-manager switch -b backup --impure --flake ."
    log "3. If vendorHash errors occur, update the vendorHash values in home.nix"
    log "   with the values shown in the build output."
    log ""
    log "Backup created: home.nix.backup.*"
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
  echo "Environment variables:"
  echo "  GITHUB_TOKEN   GitHub personal access token (optional but recommended)"
  echo "                 Increases rate limit from 60 to 5000 requests/hour"
  echo ""
  echo "This script will:"
  echo "1. Check for updates to all Go packages in home.nix"
  echo "2. Update rev/tag and source sha256 hashes"
  echo "3. Attempt to automatically update vendorHash via build"
  echo ""
  echo "For any packages where vendorHash cannot be determined automatically,"
  echo "you will need to update it manually by running:"
  echo "  home-manager switch -b backup --impure --flake ."
  echo ""
  echo "The build output will show the correct vendorHash values to use."
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
