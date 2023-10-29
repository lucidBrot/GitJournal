#!/usr/bin/env bash

# SPDX-FileCopyrightText: 2019-2021 Vishesh Handa <me@vhanda.in>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

set -eu

cd "$(dirname "$0")"

ID=$(awk '{print $1}' secrets/poeditor-api-key.txt)
TOKEN=$(awk '{print $2}' secrets/poeditor-api-key.txt)

curl -X POST https://api.poeditor.com/v2/projects/upload \
    -F api_token="$TOKEN" \
    -F id="$ID" \
    -F updating="terms_translations" \
    -F file=@"../lib/l10n/app_en.arb" \
    -F language=en \
    -F overwrite=1 \
    -F fuzzy_trigger=1 \
    -F overwrite=1 \
    -F sync_terms=1
