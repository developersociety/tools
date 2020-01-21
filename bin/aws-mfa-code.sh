#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# Helper script which interacts with aws-vault to determine if an existing session for a profile
# is still available with 2 factor authentication.

if [ $# -ne 2 ]; then
    echo 1>&2 "Usage: $0 VAULT_PROFILE YUBIKEY_OATH_NAME"
    exit 1
fi

VAULT_PROFILE="$1"
YUBIKEY_OATH_NAME="$2"
ENCODED_PROFILE=$(echo -n "$VAULT_PROFILE" | base64)

# We do a full list first (and ignore the output) - which will remove expired sessions
aws-vault list >/dev/null

SESSION_COUNT=$(aws-vault list --sessions | grep -c "^session,$ENCODED_PROFILE,[A-Za-z0-9]" || true)

if (( "$SESSION_COUNT" > 0 )); then
    # A session exists already, just return a dummy code
    MFA_CODE="123456"
else
    # A session does not exist - get a fresh code from the Yubikey
    MFA_CODE=$(ykman oath code --single "$YUBIKEY_OATH_NAME")
fi

echo "$MFA_CODE"
