#!/bin/bash -x
# Taken from:
# https://dfm.io/downloads/notebooks/travis-latex.ipynb

# Exit on non-zero return codes
set -e

TEX_DIRECTORY='tex/'
TEX_FILENAME='rules'
COMMIT_USERNAME='Travis the AsciiDoc builder'
COMMIT_EMAIL='travis@travis.ai'

# # If the commit range does not contain two commits (with '..' in between them),
# # do the diff against the previous commit in the history line.
# if ! [[ $TRAVIS_COMMIT_RANGE == *..* ]]; then
#   TRAVIS_START_COMMIT=$(git rev-parse HEAD~1)
#   TRAVIS_FINISH_COMMIT=$(git rev-parse HEAD)
#   TRAVIS_COMMIT_RANGE="$TRAVIS_START_COMMIT..$TRAVIS_FINISH_COMMIT"
# fi

if [[ $TRAVIS_PULL_REQUEST == "false" ]]; then
  echo "Well, we should build just on master, but let's do so on other branches too..."
else
  if [[ $GITHUB_USERNAME == "" ]]; then
     echo "Seems like this PR came from a fork. For security reasons no code will be executed."
     exit 0;
  fi
  # override the TRAIVS_BRANCH to the one from which the PR originates
  export TRAVIS_BRANCH="$TRAVIS_PULL_REQUEST_BRANCH"
fi


git clone https://github.com/$TRAVIS_REPO_SLUG.git --single-branch --branch gh-pages $TRAVIS_BUILD_DIR/gh-pages

cd $TRAVIS_BUILD_DIR/gh-pages
mkdir -p $TRAVIS_BRANCH/
cp -R ../media ../*.html ../*.pdf $TRAVIS_BRANCH/

git config user.name "$COMMIT_USERNAME"
git config user.email "$COMMIT_EMAIL"

git add -f $TRAVIS_BRANCH
git commit -m "Update GitHub Pages $TRAVIS_COMMIT_RANGE"
git push -q -f "https://$GITHUB_USERNAME:$GITHUB_API_KEY@github.com/$TRAVIS_REPO_SLUG" gh-pages

pip install requests
echo "See what the rules would look like in [the last draft](https://robocupjuniortc.github.io/soccer-rules/$TRAVIS_BRANCH/rules.html)!" | python ../.ci/travis_bot.py
