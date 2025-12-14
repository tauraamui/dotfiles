## How to use

`home-manager switch -b backup --impure --flake .`

This collection of dot files is managed by [Chezmoi](https://www.chezmoi.io/). Follow the instructions on the homepage if you would like to download and use them. Be aware that this is obviously my own custom setup. Additionally, most of the .tmpl files will generate different output depending on the hostname of the machine you're using. Some files will just not be complete nor working if you don't have any of the matching hostnames which is likely the case. YMMV.

## Automated Package Updates

### Overview
This repository includes automated nightly updates for Go-based packages pinned in [`home.nix`](home.nix). This solves the common problem where `sha256` and `vendorHash` values become stale as packages update.

### How It Works
- **GitHub Actions workflow** runs nightly at 2 AM UTC
- Automatically checks for updates to Go packages (crush, gofumpt, goimports, scc, sqlc, gotestsum, invoice)
- Updates `rev`/`tag`, source `sha256`, and `vendorHash` values
- Creates a pull request with changes if updates are detected
- Tests the build to ensure correctness

### Manual Updates
You can also run updates manually:

```bash
# Run the update script locally
./update-hashes.sh

# Update a specific package (if supported by the script)
./update-hashes.sh crush
```

### Packages Tracked
The automation tracks these Go packages in [`home.nix`](home.nix):
- **charmbracelet/crush** - Release versions (latest tag)
- **mvdan/gofumpt** - Latest master commit
- **golang/tools** - Latest master commit (goimports)
- **boyter/scc** - Latest master commit
- **sqlc-dev/sqlc** - Latest main commit
- **gotestyourself/gotestsum** - Latest main commit
- **maaslalani/invoice** - Latest main commit

### Workflow Trigger
- **Scheduled**: Every night at 2 AM UTC (`.github/workflows/update-hashes.yml`)
- **Manual**: Via GitHub Actions UI (workflow_dispatch)

## Neovim showcase
<img width="835" alt="Screenshot 2023-04-18 at 17 40 36" src="https://user-images.githubusercontent.com/3159648/232846137-036692a4-bb30-48c6-91f5-9ad300cf9c1e.png">

<img width="1169" alt="Screenshot 2023-04-18 at 17 57 35" src="https://user-images.githubusercontent.com/3159648/232850065-4613b635-50d0-4bd6-81f3-a331fe97d1d4.png">

## fish shell prompt (starship) + tmux statusline showcase

<img width="393" alt="Screenshot 2023-04-28 at 10 23 52" src="https://user-images.githubusercontent.com/3159648/235109938-d5628b19-8a67-4571-9ff3-ef17e229bacf.png">
