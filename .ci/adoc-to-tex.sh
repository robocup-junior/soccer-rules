#!/bin/bash
set -euo pipefail

OUTPUT_FILE=$1
cp $1.adoc tmp_$1.adoc
OUTPUT_PREFIX=tmp_$1

cp $OUTPUT_PREFIX.adoc _$OUTPUT_PREFIX.adoc
python3 .ci/criticmarkup_to_adoc.py _$OUTPUT_PREFIX.adoc > $OUTPUT_PREFIX.adoc
rm _$OUTPUT_PREFIX.adoc

asciidoctor $OUTPUT_PREFIX.adoc
asciidoctor -b docbook $OUTPUT_PREFIX.adoc
