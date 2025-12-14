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
  
  if [ -n "${GITHUB_TOKEN:-}" ]; then
    # Use authenticated request for higher rate limits
    nix-prefetch-github "$owner" "$pkg_name" --rev "${rev}" --github-access-token "$GITHUB_TOKEN" 2>/dev/null | \
      jq -r '.hash' | sed 's/^sha256-//'
  else
    nix-prefetch-github "$owner" "$pkg_name" --rev "${rev}" 2>/dev/null | \
      jq -r '.hash' | sed 's/^sha256-//'
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
  
  if [ -z "$new_hash" ]; then
    error "Could not prefetch ${pkg_name}"
    return 1
  fi
  
  # Create backup if not already created
  if [ ! -f "home.nix.backup.$(date +%Y%m%d)*" ]; then
    cp home.nix "home.nix.backup.$(date +%Y%m%d_%H%M%S)"
  fi
  
  # Update rev and sha256 in home.nix
  sed -i "/${pkg_name} = pkgs-unstable.buildGoModule/,/^  };/ s|rev = \"${current_rev}\"|rev = \"${latest_rev}\"|" home.nix
  sed -i "/${pkg_name} = pkgs-unstable.buildGoModule/,/^  };/ s|sha256 = \"sha256-[A-Za-z0-9+/=]\+\"|sha256 = \"sha256-${new_hash}\"|" home.nix
  
  # Set vendorHash to fakeHash temporarily
  sed -i "/${pkg_name} = pkgs-unstable.buildGoModule/,/^  };/ s|vendorHash = \"sha256-[A-Za-z0-9+/=]\+\"|vendorHash = lib.fakeHash; # Update me|" home.nix
  sed -i "/${pkg_name} = pkgs-unstable.buildGoModule/,/^  };/ s|vendorHash = null|vendorHash = lib.fakeHash; # Update me|" home.nix
  
  log "Updated ${pkg_name} revision and source hash"
  log "Remember to run: home-manager switch -b backup --impure --flake ."
  log "Then update the vendorHash with the value shown in the error output."
  
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
  log "Remember to run: home-manager switch -b backup --impure --flake ."
  log "Then update the vendorHash with the value shown in the error output."
  
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
  echo "3. Set vendorHash to lib.fakeHash (must be updated manually)"
  echo ""
  echo "After running this script:"
  echo "  home-manager switch -b backup --impure --flake ."
  echo ""
  echo "The build will show the correct vendorHash values to use."
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
