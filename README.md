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
bash scripts/build-project.sh -t [TAG_OF_THE_IMAGE] -e [ENVIRONMENT]

```

### Testing

To test the build image, from the project root, run:

```
bash scripts/test-project.sh -t [TAG_OF_THE_IMAGE] -e [ENVIRONMENT]
```


### Deploying

To deploy the project, from the root run:

```
bash scripts/deploy-project.sh -t [TAG_OF_THE_IMAGE] -e [ENVIRONMENT] -o (if set, just show what kubectl would do. Omit this to run kubectl)
```

## Minikube

To run in dev, Minikube has been chosen.  Ensure you have a working copy of minikube installed prior to continuing.

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
kubectl create namespace dev          # only needs running on creation of the minikube cluster

```

### Internal registry

For more info on the below, see [https://blog.hasura.io/sharing-a-local-registry-for-minikube-37c7240d0615](https://blog.hasura.io/sharing-a-local-registry-for-minikube-37c7240d0615)

```
kubectl create -f https://gist.githubusercontent.com/alexjones1103/0630332d2b8f36d9ee3791c24b894891/raw/24c9867ae3f76e7943d0ee450fdc12889a639559/minikube-docker-repo.yaml
kubectl port-forward --namespace kube-system $(kubectl get po -n kube-system | grep kube-registry-v0 | \
awk '{print $1;}') 5000:5000
```

### Connecting to the exposed service

```
minikube service -n dev --url kubernetes-boilerplate-nodejs
```

returns something like:

```
http://192.168.99.100:31983
```

then curl the service endpoint

```
curl http://192.168.99.100:31983/ping
{"result":"pong!"}
```

### Stopping minikube

```
minikube stop

Stopping local Kubernetes cluster...
Machine stopped.
```
