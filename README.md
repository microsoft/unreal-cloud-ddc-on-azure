# Unreal Cloud DDC

## Setup

Following the directions provided here to setup a [service principal with a secret](https://github.com/Azure/login#configure-a-service-principal-with-a-secret).
This will be used to deploy the resources for the repository.

## Template Sync
To pull the latest changes from the template, add a new secret GitHub PAT (and include workflow permission to sync all changes).

## Deploy
Use the following command to deploy Unreal Cloud DDC using a parameters file.

```sh
az login
az account set -s <Insert-Subscription-Name-or-ID>
./scripts/deploy.sh configs/studio/template.parameters.json $APP_SECRET
```
