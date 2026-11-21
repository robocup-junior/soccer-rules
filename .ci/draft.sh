# Sourced by .ci/adoc-to-tex.sh and .ci/tex-to-pdf.sh with the document name
# (e.g. "rules") as $1. Decides whether that document is built as a draft:
#
#   - DRAFT already set: CI sets it for every branch except the published
#     one (see .github/workflows/build.yml), so all documents are drafts there
#   - listed in DRAFT_DOCUMENTS: the document stays a draft even on the
#     published branch
#
# Sets DRAFT (non-empty means draft) and DRAFT_LISTED (non-empty when the
# document is listed in DRAFT_DOCUMENTS, i.e. there is no official version).

DRAFT=${DRAFT:-}
DRAFT_LISTED=

for listed in $(sed -e 's/#.*//' DRAFT_DOCUMENTS 2>/dev/null); do
  if [ ! -f "$listed.adoc" ]; then
    echo "DRAFT_DOCUMENTS lists '$listed', but there is no $listed.adoc" >&2
    exit 1
  fi
  if [ "$listed" = "$1" ]; then
    DRAFT=1
    DRAFT_LISTED=1
  fi
done
