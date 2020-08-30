# vault-raft-init

This container will help very unsecurely init a vault, join a raft cluster and unseal the vault.

It works by using an Stateful deployment to start with `vault-0` initialize it, storing the keys in `/vault/keys/keys.json` and then unseal.

`vault-x` instances will join the Raft cluster to gets the configuration and then read the keys from `/vault/keys/keys.json` to unseal.

If anything restarts then it will read the keys from `/vault/keys/keys.json` to unseal.

__**Note:**__ Do not use this in production, as the keys are easily accessible. There are much better options available.

## Build

```bash
docker build . -t vault-raft-init:0.1
```

## k8s

### Deploy

```bash
kubectl apply -f k8s/vault-raft-deploy.yaml
```

### Undeploy

```bash
kubectl delete -f k8s/vault-raft-deploy.yaml
```

### Valid working

```bash
kubectl exec -ti vault-0 -c vault -n hashicorp -- cat /vault/keys/keys.json | jq -r .root_token
kubectl exec -ti vault-0 -c vault -n hashicorp -- vault login
kubectl exec -ti vault-0 -c vault -n hashicorp -- vault operator raft list-peers
```
