#!/bin/bash -x
# Taken from:
# https://dfm.io/downloads/notebooks/travis-latex.ipynb

TEX_DIRECTORY='tex/'
COMMIT_USERNAME='Travis the TeX builer'
COMMIT_EMAIL='travis@travis.ai'

# If the commit range does not contain two commits (with '..' in between them),
# assume master as the comparison point.
if ! [[ $TRAVIS_COMMIT_RANGE == *..* ]];
  TRAVIS_COMMIT_RANGE="master..$TRAVIS_COMMIT_RANGE"
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
  conda install -c conda-forge -c pkgw-forge tectonic

  # Build the paper using tectonic
  cd $TEX_DIRECTORY
  tectonic *.tex --print

  # Force push the paper to GitHub
  cd $TRAVIS_BUILD_DIR
  git checkout $TRAVIS_BRANCH
  git add $TEX_DIRECTORY/*.tex
  git -c user.name="$COMMIT_USERNAME"\
      -c user.email="$COMMIT_EMAIL"\
      commit -am "Built the tex from $TRAVIS_COMMIT_RANGE"
  git push -q -f https://$GITHUB_USERNAME:$GITHUB_API_KEY@github.com/$TRAVIS_REPO_SLUG $TRAVIS_BRANCH
fi
