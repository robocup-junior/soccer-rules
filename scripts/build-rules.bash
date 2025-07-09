#!/bin/bash
set -euo pipefail

# Colors
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
BLUE="\033[0;34m"
RESET="\033[0m"

# Variables
SERVER_PORT=12345

# Functions
function print_error {
  echo -e "${RED}[ERROR] $1${RESET}"
}

function print_success {
  echo -e "${GREEN}[SUCCESS] $1${RESET}"
}

function print_info {
  echo -e "${BLUE}[INFO] $1${RESET}"
}

# Check if the first argument is provided
if [[ $# -lt 1 ]]; then
  print_error "No target file specified. Usage: $0 <target-file>"
  print_info "The target file is usually 'rules' or 'superteam_rules'."
  exit 1
fi

TARGET=$1

# Check if the target file exists
if [[ ! -f "$TARGET.adoc" ]]; then
  print_error "Target file '$TARGET.adoc' does not exist."
  exit 1
fi

# Check if dependencies are installed
for cmd in podman python; do
  if ! command -v "$cmd" &>/dev/null; then
    print_error "Dependency '$cmd' is not installed. Please install it and try again."
    exit 1
  fi
done

# Run Podman containers for processing
print_info "Converting Asciidoc to LaTeX..."
podman run -v "$(pwd)":/documents:Z --workdir=/documents docker.io/asciidoctor/docker-asciidoctor bash -c "
set -euo pipefail
OUTPUT_FILE=$TARGET
cp \$OUTPUT_FILE.adoc tmp_\$OUTPUT_FILE.adoc
OUTPUT_PREFIX=tmp_\$OUTPUT_FILE

cp \$OUTPUT_PREFIX.adoc _\$OUTPUT_PREFIX.adoc
python3 .ci/criticmarkup_to_adoc.py _\$OUTPUT_PREFIX.adoc > \$OUTPUT_PREFIX.adoc
rm _\$OUTPUT_PREFIX.adoc

asciidoctor \$OUTPUT_PREFIX.adoc
asciidoctor -b docbook \$OUTPUT_PREFIX.adoc
"
print_success "Asciidoc conversion complete."

print_info "Converting LaTeX to PDF..."
podman run -v "$(pwd)":/documents:Z --workdir=/documents docker.io/mrshu/texlive-dblatex bash -c "
set -euo pipefail
OUTPUT_FILE=$TARGET
OUTPUT_PREFIX=tmp_\$OUTPUT_FILE

# Apply custom styling to DocBook
dblatex -T db2latex \$OUTPUT_PREFIX.xml -t tex --texstyle=./manual.sty -p custom.xsl

# Go through the generated .tex output, find the place where the preamble ends
# (marked by the \mainmatter command) and create a file without it.
cat \$OUTPUT_PREFIX.tex | awk 'f;/\\\\mainmatter/{f=1}'  > \$OUTPUT_PREFIX\"_without_preamble.tex\"
# Concat the standardized preamble with the \"without_preamble\" version of the file
cat preamble.tex \$OUTPUT_PREFIX\"_without_preamble.tex\" > \$OUTPUT_PREFIX.tex
texliveonfly \$OUTPUT_PREFIX.tex
pdflatex \$OUTPUT_PREFIX.tex
pdflatex \$OUTPUT_PREFIX.tex

cp \$OUTPUT_PREFIX.pdf \$OUTPUT_FILE.pdf
cp \$OUTPUT_PREFIX.html \$OUTPUT_FILE.html
"
print_success "PDF conversion complete."

# Serve the files using Python's HTTP server
echo -e "${YELLOW}See the HTML version at: ${BLUE}http://localhost:$SERVER_PORT/tmp_$TARGET.html${RESET}"
echo -e "${YELLOW}See the PDF version at: ${BLUE}http://localhost:$SERVER_PORT/tmp_$TARGET.pdf${RESET}"

print_info "Starting HTTP server on port $SERVER_PORT..."
python -m http.server "$SERVER_PORT"
