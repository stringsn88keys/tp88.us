#!/usr/bin/env bash
# gh_problem_space.sh - Set up a problem-solving workspace for GitHub CI failures or issues
#
# Usage:
#   gh_problem_space.sh <input> [owner/repo]
#
# <input> can be:
#   - GitHub Actions run URL:   https://github.com/owner/repo/actions/runs/12345
#   - GitHub issue URL:         https://github.com/owner/repo/issues/42
#   - GitHub PR URL:            https://github.com/owner/repo/pull/42
#   - Bare issue/PR number:     42  (requires GH_DEFAULT_REPO or second arg)
#
# Environment variables:
#   GH_PAT or GITHUB_TOKEN   GitHub Personal Access Token (required)
#   PROBLEM_SOLVING_DIR      Base directory for workspaces (default: ~/problem-solving)
#   GH_DEFAULT_REPO          Default repo as owner/repo (required for bare numbers)
#
# Outputs the workspace directory path to stdout (for alias cd integration).
# All progress/status messages go to stderr.

set -euo pipefail

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

GH_TOKEN="${GH_PAT:-${GITHUB_TOKEN:-}}"
if [[ -z "$GH_TOKEN" ]]; then
  echo "ERROR: Set GH_PAT or GITHUB_TOKEN to a GitHub Personal Access Token." >&2
  exit 1
fi

PROBLEM_SOLVING_DIR="${PROBLEM_SOLVING_DIR:-$HOME/problem-solving}"

INPUT="${1:-}"
if [[ -z "$INPUT" ]]; then
  echo "Usage: $(basename "$0") <actions_url_or_issue_url_or_number> [owner/repo]" >&2
  echo "" >&2
  echo "Environment:" >&2
  echo "  GH_PAT / GITHUB_TOKEN  GitHub PAT (required)" >&2
  echo "  PROBLEM_SOLVING_DIR    Base directory (default: ~/problem-solving)" >&2
  echo "  GH_DEFAULT_REPO        Default owner/repo for bare issue numbers" >&2
  exit 1
fi

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

gh_api() {
  local endpoint="$1"
  local extra_args=("${@:2}")
  curl -sSL \
    -H "Authorization: token $GH_TOKEN" \
    -H "Accept: application/vnd.github.v3+json" \
    "${extra_args[@]}" \
    "https://api.github.com${endpoint}"
}

gh_api_download() {
  local endpoint="$1"
  local output_file="$2"
  curl -sSL \
    -H "Authorization: token $GH_TOKEN" \
    -H "Accept: application/vnd.github.v3+json" \
    -L \
    -o "$output_file" \
    "https://api.github.com${endpoint}"
}

# Extract a JSON field using python3 (no external deps required)
jq_get() {
  local json="$1"
  local expr="$2"
  echo "$json" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    # Support simple dot-notation paths like .foo.bar and array index [0]
    parts = '''$expr'''.lstrip('.').split('.')
    val = d
    for part in parts:
        if '[' in part:
            key, idx = part.rstrip(']').split('[')
            val = val[key][int(idx)]
        elif part:
            val = val[part]
    print(val if val is not None else '')
except (KeyError, IndexError, TypeError, json.JSONDecodeError):
    print('')
"
}

sanitize_name() {
  # Lowercase, replace non-alphanumeric with dash, collapse repeats, trim, limit length
  echo "$1" \
    | tr '[:upper:]' '[:lower:]' \
    | sed 's/[^a-z0-9._-]/-/g' \
    | sed 's/--*/-/g' \
    | sed 's/^-//;s/-$//' \
    | cut -c1-80
}

log() { echo "  $*" >&2; }
header() { echo "" >&2; echo "==> $*" >&2; }

# ---------------------------------------------------------------------------
# Parse input
# ---------------------------------------------------------------------------

OWNER=""
REPO=""
RUN_ID=""
ITEM_NUMBER=""
MODE=""  # "run" | "issue"

if [[ "$INPUT" =~ ^https://github\.com/([^/]+)/([^/]+)/actions/runs/([0-9]+) ]]; then
  OWNER="${BASH_REMATCH[1]}"
  REPO="${BASH_REMATCH[2]}"
  RUN_ID="${BASH_REMATCH[3]}"
  MODE="run"

elif [[ "$INPUT" =~ ^https://github\.com/([^/]+)/([^/]+)/(issues|pull)/([0-9]+) ]]; then
  OWNER="${BASH_REMATCH[1]}"
  REPO="${BASH_REMATCH[2]}"
  ITEM_NUMBER="${BASH_REMATCH[4]}"
  MODE="issue"

elif [[ "$INPUT" =~ ^[0-9]+$ ]]; then
  ITEM_NUMBER="$INPUT"
  MODE="issue"
  OVERRIDE_REPO="${2:-${GH_DEFAULT_REPO:-}}"
  if [[ -z "$OVERRIDE_REPO" ]]; then
    echo "ERROR: Provide owner/repo as second argument or set GH_DEFAULT_REPO." >&2
    exit 1
  fi
  OWNER="${OVERRIDE_REPO%%/*}"
  REPO="${OVERRIDE_REPO##*/}"

else
  echo "ERROR: Unrecognized input: $INPUT" >&2
  echo "Expected a GitHub Actions run URL, issue/PR URL, or bare issue number." >&2
  exit 1
fi

# ---------------------------------------------------------------------------
# Collect metadata based on mode
# ---------------------------------------------------------------------------

WORKSPACE_LABEL=""
BRANCH=""
WORKFLOW_ID=""

header "Fetching metadata from github.com/$OWNER/$REPO"

if [[ "$MODE" == "run" ]]; then
  log "Getting run #$RUN_ID details..."
  RUN_DATA=$(gh_api "/repos/$OWNER/$REPO/actions/runs/$RUN_ID")

  RUN_CONCLUSION=$(jq_get "$RUN_DATA" "conclusion")
  RUN_STATUS=$(jq_get "$RUN_DATA" "status")
  BRANCH=$(jq_get "$RUN_DATA" "head_branch")
  HEAD_SHA=$(jq_get "$RUN_DATA" "head_sha")
  WORKFLOW_ID=$(jq_get "$RUN_DATA" "workflow_id")
  WORKFLOW_NAME=$(jq_get "$RUN_DATA" "name")

  log "Run status: $RUN_STATUS / conclusion: $RUN_CONCLUSION"
  log "Branch: $BRANCH  SHA: ${HEAD_SHA:0:8}"
  log "Workflow: $WORKFLOW_NAME (id: $WORKFLOW_ID)"

  # Try to find associated PR for a better workspace name
  log "Looking for associated PR on branch $BRANCH..."
  PR_LIST=$(gh_api "/repos/$OWNER/$REPO/pulls?head=$OWNER:$BRANCH&state=all&per_page=1")
  PR_TITLE=$(echo "$PR_LIST" | python3 -c "
import sys, json
prs = json.load(sys.stdin)
print(prs[0]['title'] if prs else '')
" 2>/dev/null || true)

  if [[ -n "$PR_TITLE" ]]; then
    log "Associated PR: $PR_TITLE"
    WORKSPACE_LABEL=$(sanitize_name "$PR_TITLE")
  else
    WORKSPACE_LABEL=$(sanitize_name "run-${RUN_ID}-${BRANCH}")
  fi

elif [[ "$MODE" == "issue" ]]; then
  log "Getting issue/PR #$ITEM_NUMBER details..."
  # Try as PR first (richer data), fall back to issue
  PR_DATA=$(gh_api "/repos/$OWNER/$REPO/pulls/$ITEM_NUMBER" 2>/dev/null || true)
  IS_PR=false
  if echo "$PR_DATA" | python3 -c "import sys,json; d=json.load(sys.stdin); exit(0 if 'number' in d else 1)" 2>/dev/null; then
    IS_PR=true
    ITEM_TITLE=$(jq_get "$PR_DATA" "title")
    BRANCH=$(jq_get "$PR_DATA" "head.ref")
    log "It's a PR: $ITEM_TITLE"
    log "Branch: $BRANCH"
  fi

  ISSUE_DATA=$(gh_api "/repos/$OWNER/$REPO/issues/$ITEM_NUMBER")
  ITEM_TITLE=$(jq_get "$ISSUE_DATA" "title")
  log "Title: $ITEM_TITLE"

  if [[ "$IS_PR" == "false" ]]; then
    # Check if it's a PR masquerading as an issue
    HAS_PR=$(jq_get "$ISSUE_DATA" "pull_request.url")
    if [[ -n "$HAS_PR" ]]; then
      IS_PR=true
      PR_DATA=$(gh_api "/repos/$OWNER/$REPO/pulls/$ITEM_NUMBER")
      BRANCH=$(jq_get "$PR_DATA" "head.ref")
      log "Branch: $BRANCH"
    fi
  fi

  WORKSPACE_LABEL=$(sanitize_name "$ITEM_TITLE")

  # For issues with an associated PR, find the latest CI run
  if [[ "$IS_PR" == "true" && -n "$BRANCH" ]]; then
    log "Finding CI runs for branch $BRANCH..."
    RUNS_DATA=$(gh_api "/repos/$OWNER/$REPO/actions/runs?branch=$BRANCH&per_page=20")
    FAILING_RUN=$(echo "$RUNS_DATA" | python3 -c "
import sys, json
d = json.load(sys.stdin)
runs = d.get('workflow_runs', [])
for r in runs:
    if r.get('conclusion') in ('failure', 'timed_out', 'cancelled'):
        print(r['id'], r.get('workflow_id', ''), r.get('name', ''))
        break
" 2>/dev/null || true)

    if [[ -n "$FAILING_RUN" ]]; then
      RUN_ID=$(echo "$FAILING_RUN" | awk '{print $1}')
      WORKFLOW_ID=$(echo "$FAILING_RUN" | awk '{print $2}')
      log "Found failing CI run: $RUN_ID"
      RUN_DATA=$(gh_api "/repos/$OWNER/$REPO/actions/runs/$RUN_ID")
    fi
  fi
fi

# ---------------------------------------------------------------------------
# Create workspace
# ---------------------------------------------------------------------------

header "Setting up workspace"

mkdir -p "$PROBLEM_SOLVING_DIR"
WORKSPACE="$PROBLEM_SOLVING_DIR/$WORKSPACE_LABEL"
mkdir -p "$WORKSPACE"
log "Workspace: $WORKSPACE"

LOGS_DIR="$WORKSPACE/logs"
mkdir -p "$LOGS_DIR"

# ---------------------------------------------------------------------------
# Download failing run logs
# ---------------------------------------------------------------------------

if [[ -n "$RUN_ID" ]]; then
  header "Downloading logs for failing run #$RUN_ID"

  # Save run JSON details
  if [[ -n "${RUN_DATA:-}" ]]; then
    echo "$RUN_DATA" > "$WORKSPACE/failing-run-details.json"
    log "Saved run details -> failing-run-details.json"
  fi

  FAILING_LOGS_ZIP="$LOGS_DIR/failing-run.zip"
  FAILING_LOGS_DIR="$LOGS_DIR/failing-run"
  mkdir -p "$FAILING_LOGS_DIR"

  log "Downloading log archive..."
  HTTP_CODE=$(curl -sSL \
    -H "Authorization: token $GH_TOKEN" \
    -H "Accept: application/vnd.github.v3+json" \
    -L \
    -o "$FAILING_LOGS_ZIP" \
    -w "%{http_code}" \
    "https://api.github.com/repos/$OWNER/$REPO/actions/runs/$RUN_ID/logs" || echo "000")

  if [[ -f "$FAILING_LOGS_ZIP" && -s "$FAILING_LOGS_ZIP" ]]; then
    unzip -q -o "$FAILING_LOGS_ZIP" -d "$FAILING_LOGS_DIR/" 2>/dev/null || true
    FILE_COUNT=$(find "$FAILING_LOGS_DIR" -type f | wc -l)
    log "Expanded $FILE_COUNT log file(s) -> logs/failing-run/"
  else
    log "WARNING: Could not download logs for run $RUN_ID (HTTP $HTTP_CODE)"
  fi

  # ---------------------------------------------------------------------------
  # Find and download the last successful run on the same workflow
  # ---------------------------------------------------------------------------

  if [[ -n "${WORKFLOW_ID:-}" ]]; then
    header "Finding last successful run for workflow $WORKFLOW_ID"

    LAST_GOOD_DATA=$(gh_api "/repos/$OWNER/$REPO/actions/workflows/$WORKFLOW_ID/runs?status=success&per_page=1")
    LAST_GOOD_ID=$(echo "$LAST_GOOD_DATA" | python3 -c "
import sys, json
d = json.load(sys.stdin)
runs = d.get('workflow_runs', [])
print(runs[0]['id'] if runs else '')
" 2>/dev/null || true)

    if [[ -n "$LAST_GOOD_ID" ]]; then
      log "Last good run: $LAST_GOOD_ID"

      LAST_GOOD_RUN_DATA=$(gh_api "/repos/$OWNER/$REPO/actions/runs/$LAST_GOOD_ID")
      echo "$LAST_GOOD_RUN_DATA" > "$WORKSPACE/last-good-run-details.json"
      log "Saved run details -> last-good-run-details.json"

      LAST_GOOD_ZIP="$LOGS_DIR/last-good-run.zip"
      LAST_GOOD_DIR="$LOGS_DIR/last-good-run"
      mkdir -p "$LAST_GOOD_DIR"

      log "Downloading last good run log archive..."
      HTTP_CODE=$(curl -sSL \
        -H "Authorization: token $GH_TOKEN" \
        -H "Accept: application/vnd.github.v3+json" \
        -L \
        -o "$LAST_GOOD_ZIP" \
        -w "%{http_code}" \
        "https://api.github.com/repos/$OWNER/$REPO/actions/runs/$LAST_GOOD_ID/logs" || echo "000")

      if [[ -f "$LAST_GOOD_ZIP" && -s "$LAST_GOOD_ZIP" ]]; then
        unzip -q -o "$LAST_GOOD_ZIP" -d "$LAST_GOOD_DIR/" 2>/dev/null || true
        FILE_COUNT=$(find "$LAST_GOOD_DIR" -type f | wc -l)
        log "Expanded $FILE_COUNT log file(s) -> logs/last-good-run/"
      else
        log "WARNING: Could not download last good run logs (HTTP $HTTP_CODE)"
      fi
    else
      log "No successful runs found for workflow $WORKFLOW_ID."
    fi
  fi
fi

# Save issue details if in issue mode
if [[ "$MODE" == "issue" && -n "${ISSUE_DATA:-}" ]]; then
  echo "$ISSUE_DATA" > "$WORKSPACE/issue-details.json"
  log "Saved issue details -> issue-details.json"
  if [[ -n "${PR_DATA:-}" ]]; then
    echo "$PR_DATA" > "$WORKSPACE/pr-details.json"
    log "Saved PR details -> pr-details.json"
  fi
fi

# ---------------------------------------------------------------------------
# Clone repository and checkout branch
# ---------------------------------------------------------------------------

header "Cloning github.com/$OWNER/$REPO"

CLONE_DIR="$WORKSPACE/repo"
CLONE_URL="https://x-access-token:${GH_TOKEN}@github.com/${OWNER}/${REPO}.git"

if [[ -d "$CLONE_DIR/.git" ]]; then
  log "Repo already cloned, fetching latest..."
  git -C "$CLONE_DIR" fetch --quiet origin 2>/dev/null || true
else
  log "Cloning into $CLONE_DIR..."
  git clone --quiet "$CLONE_URL" "$CLONE_DIR"
fi

if [[ -n "${BRANCH:-}" ]]; then
  log "Checking out branch: $BRANCH"
  (
    cd "$CLONE_DIR"
    git fetch --quiet origin "$BRANCH" 2>/dev/null || true
    if git show-ref --verify --quiet "refs/remotes/origin/$BRANCH"; then
      git checkout --quiet -B "$BRANCH" "origin/$BRANCH" 2>/dev/null || \
        git checkout --quiet "$BRANCH" 2>/dev/null || \
        log "WARNING: Could not switch to branch $BRANCH"
    else
      log "WARNING: Branch $BRANCH not found on remote."
    fi
  )
fi

# ---------------------------------------------------------------------------
# Write a README summarising the workspace
# ---------------------------------------------------------------------------

{
  echo "# Problem Space: $WORKSPACE_LABEL"
  echo ""
  echo "Generated: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
  echo "Repo: https://github.com/$OWNER/$REPO"
  [[ -n "${BRANCH:-}" ]] && echo "Branch: $BRANCH"
  [[ -n "$RUN_ID" ]]     && echo "Failing run: https://github.com/$OWNER/$REPO/actions/runs/$RUN_ID"
  [[ -n "${LAST_GOOD_ID:-}" ]] && echo "Last good run: https://github.com/$OWNER/$REPO/actions/runs/$LAST_GOOD_ID"
  echo ""
  echo "## Layout"
  echo ""
  echo "  repo/                  Cloned repository (branch: ${BRANCH:-default})"
  echo "  logs/failing-run/      Expanded logs from the failing CI run"
  echo "  logs/last-good-run/    Expanded logs from the last successful CI run"
  echo "  failing-run-details.json"
  echo "  last-good-run-details.json"
  echo "  issue-details.json / pr-details.json"
} > "$WORKSPACE/README.md"

# ---------------------------------------------------------------------------
# Done - emit workspace path for the alias wrapper to cd into
# ---------------------------------------------------------------------------

header "Workspace ready"
log "$(ls "$WORKSPACE")"
echo ""
log "Cloned repo is on branch: ${BRANCH:-(default)}"
log "cd into repo: $CLONE_DIR"

# Print workspace path to stdout for the alias to capture
printf '%s\n' "$WORKSPACE"
