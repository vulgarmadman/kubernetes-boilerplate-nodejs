#!/bin/bash

package="build-project"
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
TOPDIR="$DIR/.."
RUNDIR="$PWD"
THISDIR=$DIR

: "${DOCKER:=docker}"

usage() {
    echo "$package - build the project"
    echo " "
    echo "$package [options]"
    echo " "
    echo "options:"
    echo "-h, --help                      show brief help"
    echo "-e, --environment=ENVIRONMENT   environment to deploy to [production/staging/dev] - defaults to dev"
    echo "-t, --image-tag=TAG             tag of the image to apply. Default is 'latest'"
    echo "-p, --push-image                if set, the image will attempt to push to the configured repo"
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
        --image-tag*)
            TAG=$(echo $1 | sed -e 's/^[^=]*=//g')
            shift
            ;;
        -p)
            shift
            PUSH=1
            ;;
        --push-image)
            shift
            PUSH=1
            ;;
        *)
            echo "Your making up option!"
            echo
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

build_image() {
    $DOCKER build --rm=false -t $DOCKER_IMAGE_TAG -f Dockerfile .

    if [ $? -eq 1 ]; then
        echo "Failed to build $DOCKER_IMAGE_TAG"
        echo "Check the above output for further errors"
        exit 1
    fi
}

push_image() {
    if [ "$PUSH" -eq 1 ]; then
        $DOCKER push $DOCKER_IMAGE_TAG
    else
        echo "Pushing of the image $DOCKER_IMAGE_TAG is not enabled on this build"
        echo "To push the image after a build pass the -p or --push-image parameter"
    fi
}

build_image
push_image
