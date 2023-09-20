# Hasura CLI on GitPod

The Hasura Console launched from the CLI is not designed to be run in web environments. That makes it complicated to setup in web-based IDEs like GitPod. This is an example of how to set that up.

## Failure Cases

Can't reach because CLI api can't be reached.
```
docker-compose up -d graphql
(cd graphql && hasura console --admin-secret password --endpoint https://5000-${GITPOD_WORKSPACE_ID}.${GITPOD_WORKSPACE_CLUSTER_HOST})
```

Can't reach because CLI api can't bind to 443
```
docker-compose up -d graphql
(cd graphql && hasura console --admin-secret password --endpoint https://5000-${GITPOD_WORKSPACE_ID}.${GITPOD_WORKSPACE_CLUSTER_HOST} --api-port 443 --api-host https://9693-${GITPOD_WORKSPACE_ID}.${GITPOD_WORKSPACE_CLUSTER_HOST})
```

## Success Case

1. One CLI instance runs in one container with the appropriate API endpoint specified. It will throw an error re: address bind, but that's okay. This one will just be used for the console UI.
2. Another CLI instance runs in another container, without the address bind. This one will just be used for the API.
3. A Traefik container runs to direct traffic to each container as appropriate.