#!/bin/bash
set -euo pipefail

DOCKER_COMMAND=docker
VOLUME_SUFFIX=
PODMAN_BUILD=${PODMAN_BUILD:-no}

if [[ $PODMAN_BUILD == "yes" ]]; then
        DOCKER_COMMAND="podman"
        VOLUME_SUFFIX=":Z"
fi

OUTPUT_FILE=$1
cp $1.adoc tmp_$1.adoc
OUTPUT_PREFIX=tmp_$1

cp $OUTPUT_PREFIX.adoc _$OUTPUT_PREFIX.adoc
python .ci/criticmarkup_to_adoc.py _$OUTPUT_PREFIX.adoc > $OUTPUT_PREFIX.adoc
$DOCKER_COMMAND run -v $TRAVIS_BUILD_DIR:/documents/$VOLUME_SUFFIX asciidoctor/docker-asciidoctor asciidoctor $OUTPUT_PREFIX.adoc
$DOCKER_COMMAND run -v $TRAVIS_BUILD_DIR:/documents/$VOLUME_SUFFIX asciidoctor/docker-asciidoctor asciidoctor -b docbook $OUTPUT_PREFIX.adoc
dblatex -T db2latex $OUTPUT_PREFIX.xml -t tex --texstyle=./manual.sty -p custom.xsl

# Go through the generated .tex output, find the place where the preamble ends
# (marked by the \mainmatter command) and create a file without it.
cat $OUTPUT_PREFIX.tex | awk 'f;/\\mainmatter/{f=1}'  > $OUTPUT_PREFIX"_without_preamble.tex"
# Concat the standardized preamble with the "without_preamble" version of the file
cat preamble.tex $OUTPUT_PREFIX"_without_preamble.tex" > $OUTPUT_PREFIX.tex
texliveonfly $OUTPUT_PREFIX.tex
pdflatex $OUTPUT_PREFIX.tex
pdflatex $OUTPUT_PREFIX.tex

cp $OUTPUT_PREFIX.pdf $OUTPUT_FILE.pdf
