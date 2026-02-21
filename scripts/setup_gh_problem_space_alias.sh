#!/usr/bin/env bash
# setup_gh_problem_space_alias.sh - Add the 'ghps' alias to your shell session
#
# Source this file from your shell profile to install the alias permanently:
#
#   # In ~/.bashrc or ~/.zshrc:
#   source /path/to/tp88.us/scripts/setup_gh_problem_space_alias.sh
#
# Or source it directly for a one-off session:
#   source /path/to/tp88.us/scripts/setup_gh_problem_space_alias.sh
#
# ---------------------------------------------------------------------------
# The alias resolves the script location relative to THIS file, so the
# scripts directory can live anywhere on disk.
# ---------------------------------------------------------------------------
#
# Environment variables consumed by ghps (set these in your profile):
#
#   GH_PAT or GITHUB_TOKEN   GitHub Personal Access Token (required)
#   PROBLEM_SOLVING_DIR      Base directory for workspaces  (default: ~/problem-solving)
#   GH_DEFAULT_REPO          Default repo as owner/repo     (e.g. myorg/myapp)
#
# Usage after sourcing:
#
#   ghps https://github.com/owner/repo/actions/runs/12345
#   ghps https://github.com/owner/repo/issues/42
#   ghps https://github.com/owner/repo/pull/42
#   ghps 42                                        # needs GH_DEFAULT_REPO
#   ghps 42 myorg/myapp                            # explicit repo

# Resolve the directory containing this script, even when sourced.
# Works in bash and zsh.
if [[ -n "${BASH_SOURCE[0]:-}" ]]; then
  _GHPS_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
elif [[ -n "${(%):-%x}" ]] 2>/dev/null; then
  # zsh
  _GHPS_SCRIPT_DIR="$(cd "$(dirname "${(%):-%x}")" && pwd)"
else
  echo "setup_gh_problem_space_alias: WARNING: could not determine script dir; set _GHPS_SCRIPT_DIR manually." >&2
  _GHPS_SCRIPT_DIR="${_GHPS_SCRIPT_DIR:-}"
fi

_GHPS_WORKER="${_GHPS_SCRIPT_DIR}/gh_problem_space.sh"

if [[ ! -x "$_GHPS_WORKER" ]]; then
  echo "setup_gh_problem_space_alias: WARNING: worker script not executable: $_GHPS_WORKER" >&2
  echo "  Run: chmod +x $_GHPS_WORKER" >&2
fi

# ---------------------------------------------------------------------------
# ghps - GitHub Problem Space
#
# Sets up a local workspace for a CI failure or GitHub issue, then cd's
# into it so you can immediately start investigating.
# ---------------------------------------------------------------------------
ghps() {
  if [[ $# -eq 0 ]]; then
    echo "Usage: ghps <actions_url | issue_url | pr_url | issue_number> [owner/repo]"
    echo ""
    echo "Environment:"
    echo "  GH_PAT / GITHUB_TOKEN   GitHub PAT (required)"
    echo "  PROBLEM_SOLVING_DIR     Base workspace directory (default: ~/problem-solving)"
    echo "  GH_DEFAULT_REPO         Default owner/repo for bare numbers"
    echo ""
    echo "Examples:"
    echo "  ghps https://github.com/owner/repo/actions/runs/12345"
    echo "  ghps https://github.com/owner/repo/issues/42"
    echo "  ghps 42                   # needs GH_DEFAULT_REPO set"
    echo "  ghps 42 myorg/myapp"
    return 0
  fi

  local workspace_dir
  workspace_dir="$("$_GHPS_WORKER" "$@")" || {
    echo "ghps: worker script failed." >&2
    return 1
  }

  if [[ -n "$workspace_dir" && -d "$workspace_dir" ]]; then
    cd "$workspace_dir" || return 1
    echo ""
    echo "Changed to workspace: $workspace_dir"
    echo "Cloned repo is at:    $workspace_dir/repo"
  else
    echo "ghps: unexpected output from worker (not a directory): $workspace_dir" >&2
    return 1
  fi
}

echo "ghps alias loaded (worker: $_GHPS_WORKER)"
echo "Run 'ghps' with no arguments for usage."
