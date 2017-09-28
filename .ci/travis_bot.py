#!/usr/bin/env python
"""
Comments stdin to the GitHub PR that triggered the travis build.
Taken from https://raw.githubusercontent.com/koddsson/travis-github-pr-bot/master/travis_bot/travis_bot.py

Usage:
    flake8 | python travis_bot.py

Notes:
    The following enviromental variables need to be set:
    - TRAVIS_PULL_REQUEST
    - TRAVIS_REPO_SLUG
    - TRAVIS_BOT_GITHUB_TOKEN

    Moreover, TRAVIS_PULL_REQUEST needs to be set to the pull request's number
    and not 'false', which happens when a build is not a PR build.
"""

from __future__ import print_function

import os
import sys
import json
import requests

GITHUB_API_URL = 'https://api.github.com'


def comment_on_pull_request(pr_number, slug, token, comment):
    """ Comment message on a given GitHub pull request. """
    url = '{api_url}/repos/{slug}/issues/{number}/comments'.format(
        api_url=GITHUB_API_URL, slug=slug, number=pr_number)
    response = requests.post(url, data=json.dumps({'body': comment}),
                             headers={'Authorization': 'token ' + token})
    return response.json()


if __name__ == '__main__':
    PR_NUMBER = os.environ.get('TRAVIS_PULL_REQUEST')
    REPO_SLUG = os.environ.get('TRAVIS_REPO_SLUG')
    TOKEN = os.environ.get('TRAVIS_BOT_GITHUB_TOKEN')
    MESSAGE = os.environ.get('TRAVIS_BOT_NO_RESULTS_MSG', None)

    output = sys.stdin.read().strip()
    comment = (
        """
{output}
        """).format(output=output)

    if all([PR_NUMBER, REPO_SLUG, TOKEN]):
        if PR_NUMBER == "false":
            print("TRAVIS_PULL_REQUEST is set to 'false'. " +
                  "Make sure you run travis_bot.py on a pull request build.")
            sys.exit(0)

        if output:
            comment_on_pull_request(PR_NUMBER, REPO_SLUG, TOKEN, comment)
        elif MESSAGE:
            comment_on_pull_request(PR_NUMBER, REPO_SLUG, TOKEN, MESSAGE)
    else:
        print('Not all neccesary variables are present')
