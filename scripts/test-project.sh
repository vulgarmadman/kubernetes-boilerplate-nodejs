#!/bin/bash

package="test-project"
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
TOPDIR="$DIR/.."
THISDIR=$DIR
RUNDIR=$PWD

: "${DOCKER:=docker}"
: "${GCLOUD:=gcloud}"
: "${KUBECTL:=kubectl}"

usage() {
    echo "$package - test the project"
    echo " "
    echo "$package [options]"
    echo " "
    echo "options:"
    echo "-h, --help                      show brief help"
    echo "-e, --environment=ENVIRONMENT   environment to deploy to [production/staging/dev] - defaults to dev"
    echo "-t, --image-tag=TAG             tag of the image to test. Default is 'latest'"
    echo

}

# Defaults
ENVIRONMENT=dev
TAG=latest
PUSH=0

while test $# -gt 0; do
    case "$1" in
        -h|--help)
            usage
            exit 0
            ;;
        -e)
            shift
            if test $# -gt 0; then
                ENVIRONMENT=$1
            fi
            shift
            ;;
        --environment*)
            ENVIRONMENT=$(echo $1 | sed -e 's/^[^=]*=//g')
            shift
            ;;
        -t)
            shift
            if test $# -gt 0; then
                TAG=$1
            fi
            shift
            ;;
        --tag*)
            TAG=$(echo $1 | sed -e 's/^[^=]*=//g')
            shift
            ;;
        *)
            echo "Your making up option!"
            usage
            exit 1
            break
            ;;
    esac
done

: "${ENVIRONMENT:?must be set}"
: "${TAG:?must be set}"

###############################################################################
# Here we load the env.$ENVIRONMENT file from the project root                #
###############################################################################

if [ ! -f "$RUNDIR/env.$ENVIRONMENT" ]; then
    echo "Cannot load environment file $RUNDIR/env.$ENVIRONMENT"
    exit 1
else
    echo "Sourcing the environment file $RUNDIR/env.$ENVIRONMENT"
    source "$RUNDIR/env.$ENVIRONMENT"
fi

DOCKER_IMAGE_TAG="$DOCKER_TAG_PREFIX:$TAG"
echo "Docker Image Tag: $DOCKER_IMAGE_TAG"

test_docker_image() {
    echo "Running the command $NODE_TEST_COMMAND on the docker image $DOCKER_IMAGE_TAG"
    $DOCKER run -it $DOCKER_IMAGE_TAG $NODE_TEST_COMMAND

    if [ $? -eq 1 ]; then
        echo "Testing of the build has failed.  Please fix the above errors and retry the test"
        exit 1
    else
        echo "Testing has completed without errror"
        exit 0
    fi
}

echo "Starting the testing of $DOCKER_IMAGE_TAG"
test_docker_image
