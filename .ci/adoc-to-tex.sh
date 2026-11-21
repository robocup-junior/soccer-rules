#!/bin/bash
set -euo pipefail

OUTPUT_FILE=$1

# Sets DRAFT and DRAFT_LISTED for this document
source .ci/draft.sh "$1"

# The season the rules target is set in a single place: the RULES_YEAR file.
RULES_YEAR=$(tr -d '[:space:]' < RULES_YEAR)
if [[ ! $RULES_YEAR =~ ^[0-9]{4}$ ]]; then
  echo "RULES_YEAR must contain a four-digit year, got '$RULES_YEAR'" >&2
  exit 1
fi
# Draft builds (see .ci/draft.sh) show e.g. "Draft 2027" wherever
# {rules-year} is used, including the title.
RULES_YEAR_LABEL=$RULES_YEAR
if [ -n "${DRAFT:-}" ]; then
  RULES_YEAR_LABEL="Draft $RULES_YEAR"
fi
YEAR_ATTRS=(-a "rules-year=$RULES_YEAR_LABEL" -a "previous-rules-year=$((RULES_YEAR - 1))")

cp $1.adoc tmp_$1.adoc
OUTPUT_PREFIX=tmp_$1

cp $OUTPUT_PREFIX.adoc _$OUTPUT_PREFIX.adoc
python3 .ci/criticmarkup_to_adoc.py _$OUTPUT_PREFIX.adoc > $OUTPUT_PREFIX.adoc
rm _$OUTPUT_PREFIX.adoc

# On draft builds, inject docinfo/docinfo{,-footer}.html (watermark and
# banner). The banner links to the official version published from master,
# unless the document is listed in DRAFT_DOCUMENTS and so has none.
DRAFT_ATTRS=()
if [ -n "$DRAFT" ]; then
  OFFICIAL_LINK=""
  if [ -z "$DRAFT_LISTED" ]; then
    OFFICIAL_LINK=". Official rules: <a href=\"https://robocup-junior.github.io/soccer-rules/master/$1.html\">current version</a>"
  fi
  DRAFT_ATTRS=(-a docinfo=shared -a docinfodir=docinfo -a "draft-official-link=$OFFICIAL_LINK")
fi

asciidoctor --failure-level ERROR "${YEAR_ATTRS[@]}" "${DRAFT_ATTRS[@]}" $OUTPUT_PREFIX.adoc
asciidoctor --failure-level ERROR "${YEAR_ATTRS[@]}" -b docbook $OUTPUT_PREFIX.adoc
