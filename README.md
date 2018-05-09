# kubernetes-bolierplate-nodejs

This repository contains all the configuration and deployments to create a simple NodeJS application
which can be deployed to a Kubernetes cluster.

The current code has been setup for Google Kubernetes Engine, but can easily be adapted for other cloud providers

## Pre Requirements

* Working kubernetes cluster (for remote deployments)
* minikube for local development
* Google cloud project access (if deploying to Google Cloud)
* Configured gcloud/docker/kubectl tools

## Usage

Copy this repository and use is as a base to create a NodeJS application which can be deployed into any
environment which is using Kubernetes

All code in the **src/** folder contains your NodeJS application.  Installed is a demo server application which will reply pong! when a GET
request is made to the endpoint /ping

### Config

#### Env config

Under the project root directory, there will be files prefixed with 'env' and suffixed with the environments i.e. env.dev, env.staging, env.production

These files contain unique information for each deployment.  This is what each value does

```
PROJECT_NAME           - the project name to assign the project
PROJECT_ID             - the gcloud project we will deploy too
GCLOUD_CLUSTER_NAME    - the kubernetes cluster on the project to deploy too
GCLOUD_COMPUTE_ZONE    - the region the kubernetes cluster is default in
DOCKER_BASE_REPO       - the gcr repo we will push the image too
NODE_TEST_COMMAND      - the test command which will run
DOCKER_TAG_PREFIX      - the image full uri
CONTAINER_PORT         - the port the container exposes
EXPOSED_PORT           - the service exposed port
REPLICAS               - min number of replicas the deployment should deploy and maintain
MAX_REPLICAS           - max number of replicas the deployment should deploy
```

### Building

To build the application, from the root, run:

```
bash scripts/build-project.sh -h
build-project - build the project

build-project [options]

options:
-h, --help                      show brief help
-e, --environment=ENVIRONMENT   environment to deploy to [production/staging/dev] - defaults to dev
-t, --image-tag=TAG             tag of the image to apply. Default is 'latest'
-p, --push-image                if set, the image will attempt to push to the configured repo

```

### Testing

To test the build image, from the project root, run:

```
bash scripts/test-project.sh -h
test-project - test the project

test-project [options]

options:
-h, --help                      show brief help
-e, --environment=ENVIRONMENT   environment to deploy to [production/staging/dev] - defaults to dev
-t, --image-tag=TAG             tag of the image to test. Default is 'latest'

```


### Deploying

To deploy the project, from the root run:

```
bash scripts/deploy-project.sh -h
deploy-project - deploy the project to kubernetes

deploy-project [options]

options:
-h, --help                      show brief help
-e, --environment=ENVIRONMENT   environment to deploy to [production/staging/dev] - defaults to dev
-t, --image-tag=TAG                   tag of the image to test. Default is 'latest'
-o, --output-only               dont kubectl apply - just echo it out for testing

```

## Minikube

To run in dev, Minikube has been chosen.

### Install

```
export MINIKUBE_VERSION=v0.26.1

curl -Lo minikube https://storage.googleapis.com/minikube/releases/$MINIKUBE_VERSION/minikube-darwin-amd64 && chmod +x minikube && sudo mv minikube /usr/local/bin/
```

To reuse the docker instance which is part of minikube, run the following first:

```
eval $(minikube docker-env)
```

### Starting

```
minikube start

Starting local Kubernetes v1.8.0 cluster...
Starting VM...
Getting VM IP address...
Moving files into cluster...
Setting up certs...
Connecting to cluster...
Setting up kubeconfig...
Starting cluster components...
Kubectl is now configured to use the cluster.

```
Create the 'dev' namespace:

```
kubectl create namespace dev

```

### Troubleshooting

If you expericence any issues during the setup of minikube, delete all current clusters and redeploy

```
minikube stop
minikube delete
minikube start
```

### Connecting to the exposed service

```
minikube service kubernetes-bolierplate-nodejs -n dev --url
```

returns something like:

```
http://192.168.99.100:31983
```

OR

```
minikube service kubernetes-bolierplate-nodejs -n dev --url
```

then curl the service endpoint

```
curl http://192.168.99.100:31983/ping
{"result":"pong!"}
```

Or, to do it all in one command

```
^_^..<$> curl -i $(minikube service kubernetes-bolierplate-nodejs -n dev --url)/ping
HTTP/1.1 200 OK
X-Powered-By: Express
Content-Type: text/html; charset=utf-8
Content-Length: 18
ETag: W/"12-y3UoF5EGTJ9+vDBa4HN+aKAS0S8"
Date: Wed, 09 May 2018 09:13:38 GMT
Connection: keep-alive

{"result":"pong!"}
```

### Stopping minikube

```
minikube stop

Stopping local Kubernetes cluster...
Machine stopped.
```
