# OpenClaw On NixOS: What Was Broken, What Fixed It

This repo (`/home/dustin/Code/nixosconfig`) is the declarative NixOS + Home Manager setup for OpenClaw on this machine.

This file exists because the system got into a messy state (multiple gateway services, broken packaging), and later changes can look "weird" unless you know the failure mode.

## Goal

- OpenClaw works cleanly after `sudo nixos-rebuild switch --flake /home/dustin/Code/nixosconfig#default`.
- Start minimal (local gateway only), then add channels/plugins later.

## Symptoms We Saw

- `openclaw doctor` spammed many lines like:
  - `plugin manifest not found: .../dist/extensions/<name>/openclaw.plugin.json`
- `openclaw onboard` failed with:
  - `Error: LINE runtime not initialized - plugin not registered`
- Sometimes the gateway refused to start because config was missing:
  - `gateway.mode` (OpenClaw blocks start when unset).
- Interactive commands failed with:
  - `OPENCLAW_GATEWAY_TOKEN` missing (shell env vs service env mismatch).

## Root Causes

### 1) Two gateways were running (system + user)

Historically the machine had both:

- a system daemon (`systemctl status openclaw-gateway`) with `/etc/openclaw/openclaw.json`
- a user daemon (`systemctl --user status openclaw-gateway`) with `~/.openclaw/openclaw.json`

That creates port/config/state conflicts and makes the system feel "random".

Fix direction:

- Use nix-openclaw's recommended approach on Linux: Home Manager managed systemd *user* service.
- Remove/stop the legacy system service.

Note: On NixOS, `/etc/systemd/system/...` is managed by Nix; it's normal for manual `rm` attempts to fail with "read-only file system".

### 2) nix-openclaw packaging bug: plugin manifests missing

OpenClaw gateway discovers bundled plugins by reading per-extension manifests:

- expected at runtime:
  - `$out/lib/openclaw/dist/extensions/*/openclaw.plugin.json`

The pinned OpenClaw rev (`823a09ac...`) uses this manifest system.

However, nix-openclaw's `gateway-install.sh` (at the time of this setup) copied:

- `dist/`, `node_modules/`, `package.json`, and `extensions/` into `$out/lib/openclaw/`

...but did *not* copy `extensions/*/openclaw.plugin.json` into `dist/extensions/*/`.
Result:

- the gateway ran, but no channel plugins registered; doctor spammed "plugin manifest not found".

Upstream tracked this as:

- `openclaw/nix-openclaw#83` / `#84` / `#82`
- PR `openclaw/nix-openclaw#81` proposes the fix (copy manifests into `dist/extensions`).

Local fix implemented here:

- `flake.nix` overlays `pkgs.openclaw-gateway` to copy manifests during `installPhase`.

### 3) Another packaging bug: bundled skills missing

Doctor also reported:

- `[skills] Bundled skills directory could not be resolved; built-in skills may be missing.`

The gateway expects a `skills/` directory next to `package.json` under the package root.

Local fix implemented here:

- The same overlay copies `skills/` from the OpenClaw source into `$out/lib/openclaw/skills`.

### 4) Wrapper/store-path pinning: service ran the old broken gateway even after building the fix

Even after the overlay produced a new fixed store path, the running service was still executing the old gateway output.

Evidence was in `/tmp/openclaw/openclaw-YYYY-MM-DD.log`, which referenced the old store path.

Fix direction:

- Force OpenClaw to use the gateway package directly so the `openclaw` wrapper points at the patched gateway output.

Implemented in `home.nix`:

- `programs.openclaw.package = pkgs.openclaw-gateway;`
- `programs.openclaw.instances.default.package = pkgs.openclaw-gateway;`

This ensures:

- `openclaw` resolves to `/nix/store/<fixed-hash>-openclaw-gateway-unstable-823a09ac/bin/openclaw`
- the gateway uses the same fixed hash.

### 5) `OPENCLAW_GATEWAY_TOKEN` env mismatch (service vs shell)

- The systemd user service loads the token from an EnvironmentFile.
- Interactive `openclaw` commands do not automatically read that EnvironmentFile.

We generate a token file once and source it in bash:

- `~/.config/openclaw/openclaw.env` contains `OPENCLAW_GATEWAY_TOKEN=...`
- `home.nix` adds a bash init snippet to source it.

If your shell is not bash, you may need to source it manually:

```sh
set -a
. ~/.config/openclaw/openclaw.env
set +a
```

## Workspace Docs: EROFS (read-only) When Writing SOUL.md

OpenClaw agents may update workspace documents (notably `SOUL.md`).

The nix-openclaw Home Manager module can optionally manage workspace documents via `programs.openclaw.documents`.
When enabled, it *symlinks* `AGENTS.md`/`SOUL.md`/`TOOLS.md` into the workspace from the Nix store.

That makes those files read-only at runtime and causes errors like:

- `EROFS (read-only file system)` when OpenClaw tries to write `SOUL.md`.

Fix implemented here:

- Disable nix-managed documents: `programs.openclaw.documents = null;`
- Seed initial doc templates as *regular files* under `~/.openclaw/workspace/` via a Home Manager activation step.

Result:

- `~/.openclaw/workspace/SOUL.md` is writable and OpenClaw can update it.

### 6) LINE plugin error after manifests fix

After manifests were present, `openclaw onboard` still errored:

- `LINE runtime not initialized - plugin not registered`

Reason:

- The LINE plugin existed but was disabled by default.
- `openclaw onboard` expects it to be registered (even if you don't intend to use LINE).

Fix implemented in `home.nix` minimal config:

- Enable LINE explicitly:
  - `plugins.entries.line.enabled = true`

This makes `openclaw plugins inspect line` show `Status: loaded` and avoids the onboarding crash.

## Where The Important Bits Live

- `flake.nix`
  - overlay `openclaw-gateway` to:
    - copy `extensions/*/openclaw.plugin.json` -> `dist/extensions/*/openclaw.plugin.json`
    - copy `skills/` into `$out/lib/openclaw/skills`
- `home.nix`
  - configures `programs.openclaw` (nix-openclaw Home Manager module)
  - runs gateway locally (loopback) on port `18789`
  - uses token auth: `gateway.auth.token = "${OPENCLAW_GATEWAY_TOKEN}"`
  - sets EnvironmentFile for systemd user service
  - ensures token file exists
  - forces package to `pkgs.openclaw-gateway`
  - enables LINE plugin to prevent onboard crash
  - disables Nix-managed workspace docs and seeds writable templates

## Operational Notes

- Logs:
  - `/tmp/openclaw/openclaw-YYYY-MM-DD.log` (gateway + CLI)
  - `/tmp/openclaw/openclaw-gateway.log`
- If you change packaging, rotate logs to avoid "old" errors confusing doctor.
- NixOS warning about dirty git tree is harmless; the system build uses the working tree.
