#!/bin/bash -x
# Taken from:
# https://dfm.io/downloads/notebooks/travis-latex.ipynb

# Exit on non-zero return codes
set -e

TEX_DIRECTORY='tex/'
TEX_FILENAME='sample'
COMMIT_USERNAME='Travis the TeX builer'
COMMIT_EMAIL='travis@travis.ai'

# If the commit range does not contain two commits (with '..' in between them),
# do the diff against the previous commit in the history line.
if ! [[ $TRAVIS_COMMIT_RANGE == *..* ]]; then
  TRAVIS_START_COMMIT=$(git rev-parse HEAD~1)
  TRAVIS_FINISH_COMMIT=$(git rev-parse HEAD)
  TRAVIS_COMMIT_RANGE="$TRAVIS_START_COMMIT..$TRAVIS_FINISH_COMMIT"
fi

if git diff --name-only $TRAVIS_COMMIT_RANGE | grep $TEX_DIRECTORY | grep '.tex$'
then
  # Install tectonic using conda
  wget https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh -O miniconda.sh;
  bash miniconda.sh -b -p $HOME/miniconda
  export PATH="$HOME/miniconda/bin:$PATH"
  hash -r
  conda config --set always_yes yes --set changeps1 no
  conda update -q conda
  conda info -a
  conda create --yes -n paper
  source activate paper
  conda install -c conda-forge -c pkgw-forge tectonic pip

  # Build the paper using tectonic
  cd $TEX_DIRECTORY
  tectonic $TEX_FILENAME.tex --print

  # Force push the paper to GitHub
  cd $TRAVIS_BUILD_DIR
  git checkout --orphan $TRAVIS_BRANCH-pdf
  git add -f $TEX_DIRECTORY/$TEX_FILENAME.pdf
  git -c user.name="$COMMIT_USERNAME"\
      -c user.email="$COMMIT_EMAIL"\
      commit -am "Built the tex from $TRAVIS_COMMIT_RANGE"
  git push -q -f https://$GITHUB_USERNAME:$GITHUB_API_KEY@github.com/$TRAVIS_REPO_SLUG $TRAVIS_BRANCH-pdf

  pip install requests travis_bot

  echo "Check the latest version of the built PDF at https://github.com/$TRAVIS_REPO_SLUG/blob/$TRAVIS_BRANCH-pdf/$TEX_FILENAME.pdf" | travis_bot.py
fi
