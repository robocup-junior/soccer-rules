#!/bin/bash -x

cp $1.adoc _$1.adoc
python .ci/criticmarkup_to_adoc.py _$1.adoc > $1.adoc
docker run -v $TRAVIS_BUILD_DIR:/documents/ asciidoctor/docker-asciidoctor asciidoctor $1.adoc
docker run -v $TRAVIS_BUILD_DIR:/documents/ asciidoctor/docker-asciidoctor asciidoctor -b docbook $1.adoc
dblatex -T db2latex $1.xml -t tex --texstyle=./manual.sty -p custom.xsl
cp $1.tex /tmp/
cat $1.tex | awk 'f;/\\mainmatter/{f=1}'  > $1_without_preamble.tex
cat preamble.tex $1_without_preamble.tex > $1.tex
texliveonfly $1.tex
pdflatex $1.tex
pdflatex $1.tex
