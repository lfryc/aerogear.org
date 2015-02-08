#!/bin/bash

# travis - executes command for performing lifecycle of travis build

##### Constants

ACCESS_KEY=$2
OWNER_NAME=`dirname $TRAVIS_REPO_SLUG`
SSH="ssh -i access_key -o StrictHostKeyChecking=no"

##### Functions

function install
{
    bundle install --path vendor
}

function script
{
    echo "baseurl: http://staging-aerogearsite.rhcloud.com/${OWNER_NAME}/${TRAVIS_BRANCH}" >> _config.yml
    cat _config.yml
    bundle exec jekyll build
}


function after_success
{
    sudo apt-get update -q
    sudo apt-get install -y rsync openssh-client
    openssl aes-256-cbc -k "$ACCESS_KEY" -in .staging-access-key.enc -out access-key -d
    chmod 600 access-key
    $SSH 54c626194382ecaadb000076@staging-aerogearsite.rhcloud.com mkdir -p app-root/repo/$OWNER_NAME/$TRAVIS_BRANCH/
    rsync -avzq -e "${SSH}" _site/ 54c626194382ecaadb000076@staging-aerogearsite.rhcloud.com:app-root/repo/$OWNER_NAME/$TRAVIS_BRANCH/
}

##### Main

case $1 in
    install )               install
                            ;;
    script )                script
                            ;;
    after_success )         after_success
                            ;;
esac
