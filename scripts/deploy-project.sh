#!/bin/bash

package="deploy-project"
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
RUNDIR="$PWD"
THISDIR=$DIR

: "${DOCKER:=docker}"
: "${GCLOUD:=gcloud}"
: "${KUBECTL:=kubectl}"

usage() {
    echo "$package - deploy the project to kubernetes"
    echo " "
    echo "$package [options]"
    echo " "
    echo "options:"
    echo "-h, --help                      show brief help"
    echo "-e, --environment=ENVIRONMENT   environment to deploy to [production/staging/dev] - defaults to dev"
    echo "-t, --image-tag=TAG                   tag of the image to test. Default is 'latest'"
    echo "-o, --output-only               dont kubectl apply - just echo it out for testing"
    echo
}

# Defaults
ENVIRONMENT=dev
TAG=latest
OUTPUT_ONLY=0

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
        -o)
            shift
            OUTPUT_ONLY=1
            shift
            ;;
        --output-only*)
            OUTPUT_ONLY=1
            shift
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
echo

create_service_deployment() {
    SERVICE_DEPLOYMENT_FILE="$RUNDIR/deployments/${ENVIRONMENT}/project-service.yaml"

    SED_PATTERN="s%{PROJECT_NAME}%$PROJECT_NAME%g;s%{ENVIRONMENT}%$ENVIRONMENT%g;s%{CONTAINER_PORT}%$CONTAINER_PORT%g;s%{EXPOSED_PORT}%$EXPOSED_PORT%g"

    if [ $OUTPUT_ONLY -eq 1 ]; then
        echo "Will run $KUBECTL --namespace $ENVIRONMENT apply -f with the following output:"
        sed "$SED_PATTERN" $SERVICE_DEPLOYMENT_FILE
    else
        sed "$SED_PATTERN" $SERVICE_DEPLOYMENT_FILE | $KUBECTL --namespace $ENVIRONMENT apply -f -
    fi

    if [ $? -eq 0 ]; then
        echo "Deployment of $SERVICE_DEPLOYMENT_FILE completed successfully"
    else
        echo "Failed to deploy the service from $SERVICE_DEPLOYMENT_FILE"
        exit 1
    fi
}

create_application_deployment() {
    APP_DEPLOYMENT_FILE="$RUNDIR/deployments/${ENVIRONMENT}/project-deployment.yaml"

    SED_PATTERN="s%{PROJECT_NAME}%$PROJECT_NAME%g;s%{ENVIRONMENT}%$ENVIRONMENT%g;s%{CONTAINER_PORT}%$CONTAINER_PORT%g;s%{REPLICAS}%$REPLICAS%g;s%{DOCKER_IMAGE_TAG}%$DOCKER_IMAGE_TAG%g"

    if [ $OUTPUT_ONLY -eq 1 ]; then
        echo "Will run $KUBECTL --namespace $ENVIRONMENT apply -f with the following output:"
        sed "$SED_PATTERN" $APP_DEPLOYMENT_FILE
    else
        sed "$SED_PATTERN" $APP_DEPLOYMENT_FILE | $KUBECTL --namespace=$ENVIRONMENT apply -f -
    fi

    if [ $? -eq 0 ]; then
        echo "Deployment of application $APP_DEPLOYMENT_FILE completed successfully"
    else
        echo "Failed to deploy the deployment from $APP_DEPLOYMENT_FILE"
        exit 1
    fi
}

create_autoscale_policy() {
    AUTOSCALE_POLICY="$RUNDIR/deployments/${ENVIRONMENT}/project-autoscale-policy.yaml"
    SED_PATTERN="s%{PROJECT_NAME}%$PROJECT_NAME%g;s%{ENVIRONMENT}%$ENVIRONMENT%g;s%{REPLICAS}%$REPLICAS%g;s%{MAX_REPLICAS}%$MAX_REPLICAS%g"

    if [ ! -f "$AUTOSCALE_POLICY" ]; then
        echo "No autoscaling policy deployment template was found!"
        echo "Autoscale policy is only configured for production by default.  To use an autoscale policy in $ENVIRONMENT copy the autoscale-policy to the correct environment folder under the 'deployments' folder"
    else
        echo "Deploying autoscale policy for $ENVIRONMENT"

        if [ $OUTPUT_ONLY -eq 1 ]; then
            echo "Will run $KUBECTL apply -f with the following output:"
            sed "$SED_PATTERN" $AUTOSCALE_POLICY
        else
            sed "$SED_PATTERN" $AUTOSCALE_POLICY | $KUBECTL --namespace=$ENVIRONMENT apply -f -
        fi

        if [ $? -eq 0 ]; then
            echo "Deployment of autoscaling policy $AUTOSCALE_POLICY completed successfully"
        else
            echo "Failed to deploy the autoscale policy from $AUTOSCALE_POLICY"
            exit 1
        fi
    fi
}

create_service_deployment
create_application_deployment
create_autoscale_policy
