#!/bin/bash
# From Gist: https://gist.github.com/damscott/9da8f2e623cac61423bb6a05839b10a9
# Usage: echo '{"service":"api-all", "cluster":"develop", "path_root": ""}' | bash ecs-task-definition.sh

# This script retrieves the container image and task definition revision
# for a given cluster+service. If it can't retrieve it, assume
# this is the initial deployment and default to "initial".
defaultImageTag='initial'

# Exit if any of the intermediate steps fail
set -e

# Get parameters from stdin
eval "$(jq -r '@sh "service=\(.service) cluster=\(.cluster) path_root=\(.path_root)"')"

# Remove extra quotes and backslashes from jsonencoding path_root in terraform
path_root="$(echo $path_root | sed -e 's/^"//' -e 's/"$//' -e 's/\\\\/\\/g')"

taskDefinitionID="$(aws ecs describe-services --service $service --cluster $cluster --region us-east-1 | jq -rc '.services[] | select( .status == "ACTIVE" ) | .taskDefinition')"

registryBasePath="$(aws ecr get-authorization-token --region us-east-1 | jq -r .authorizationData[0].proxyEndpoint)"
registryBasePath=${registryBasePath#"https://"}

# If a task definition is already running in AWS, use the revision and image tag from it
if [[ ! -z "$taskDefinitionID" && "$taskDefinitionID" != "null" ]]; then {
  taskDefinitionRevision="$(echo "$taskDefinitionID" | sed 's/^.*://')"
  taskDefinition="$(aws ecs describe-task-definition --task-definition $taskDefinitionID --region us-east-1)"
  containerImage="$(echo "$taskDefinition" | jq -r .taskDefinition.containerDefinitions[0].image)"
  imageTag="$(echo "$containerImage" | awk -F':' '{print $2}')"
  ddVersion=$(echo "$taskDefinition" | jq -r '(.taskDefinition.containerDefinitions[] | select(.name == "'$service'").environment[]) | select(.name == "DD_VERSION").value')

# Default to "latest" if taskDefinition doesn't exist
# Set revision to 0 so terraform logic uses task definition from terraform
} else {
  imageTag=$defaultImageTag
  taskDefinitionRevision='0'
  containerImage="$registryBasePath/$service:$imageTag"
}
fi

# Generate a JSON object containing the image tag.
jq -n --arg imageTag $imageTag --arg containerImage $containerImage --arg taskDefinitionRevision $taskDefinitionRevision --arg ddVersion ""$ddVersion"" '{image_tag: $imageTag, task_definition_revision: $taskDefinitionRevision, full_image: $containerImage, dd_version: $ddVersion}'

exit 0
