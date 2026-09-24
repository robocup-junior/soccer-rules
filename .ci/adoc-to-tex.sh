#!/bin/bash
set -euo pipefail

OUTPUT_FILE=$1

# The season the rules target is set in a single place: the RULES_YEAR file.
RULES_YEAR=$(tr -d '[:space:]' < RULES_YEAR)
if [[ ! $RULES_YEAR =~ ^[0-9]{4}$ ]]; then
  echo "RULES_YEAR must contain a four-digit year, got '$RULES_YEAR'" >&2
  exit 1
fi
YEAR_ATTRS=(-a "rules-year=$RULES_YEAR" -a "previous-rules-year=$((RULES_YEAR - 1))")

cp $1.adoc tmp_$1.adoc
OUTPUT_PREFIX=tmp_$1

cp $OUTPUT_PREFIX.adoc _$OUTPUT_PREFIX.adoc
python3 .ci/criticmarkup_to_adoc.py _$OUTPUT_PREFIX.adoc > $OUTPUT_PREFIX.adoc
rm _$OUTPUT_PREFIX.adoc

asciidoctor --failure-level ERROR "${YEAR_ATTRS[@]}" $OUTPUT_PREFIX.adoc
asciidoctor --failure-level ERROR "${YEAR_ATTRS[@]}" -b docbook $OUTPUT_PREFIX.adoc
