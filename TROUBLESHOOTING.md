# Troubleshooting Guide

## GitHub API Rate Limiting

### Problem
If you see errors like:
```
Could not get latest rev for <package>
This may be due to GitHub API rate limiting.
```

Or when running the debug script:
```
{"message":"API rate limit exceeded for <IP>. (But here's the good news: Authenticated requests get a higher rate limit.
```

### Solution

GitHub's API has rate limits:
- **Without authentication**: 60 requests per hour per IP address
- **With authentication**: 5,000 requests per hour per token

The script makes 14 API calls per run (2 per package), so you can quickly hit the 60 request limit.

### Setting up GitHub Authentication

1. **Create a Personal Access Token:**
   - Go to https://github.com/settings/tokens
   - Click "Generate new token (classic)"
   - Give it a name like "dotfiles-update-script"
   - Select the `public_repo` scope (for accessing public repositories)
   - Click "Generate token"
   - **Copy the token immediately** - you won't be able to see it again!

2. **Use the token with the script:**

   **Option A: Export it temporarily**
   ```bash
   export GITHUB_TOKEN=ghp_your_token_here
   ./update-hashes.sh
   ```

   **Option B: Add to your shell profile**
   Add this line to your `~/.bashrc`, `~/.zshrc`, or Fish config:
   ```bash
   export GITHUB_TOKEN=ghp_your_token_here
   ```
   Then reload your shell or run `source ~/.bashrc`

   **Option C: Use a .env file (if you use direnv)**
   Create a `.env` file in your dotfiles directory:
   ```bash
   GITHUB_TOKEN=ghp_your_token_here
   ```

3. **Verify it works:**
   ```bash
   echo $GITHUB_TOKEN  # Should show your token
   ./update-hashes.sh  # Should now work without rate limit errors
   ```

### GitHub Actions Workflow

The GitHub Actions workflow automatically uses the `GITHUB_TOKEN` secret, so it has a 5,000 request/hour limit and won't have rate limiting issues.

### Alternative: Wait

If you don't want to set up a token, you can wait up to an hour for the rate limit to reset. The limit is per-IP address, so if you're on a shared network, someone else may be using up the requests.
