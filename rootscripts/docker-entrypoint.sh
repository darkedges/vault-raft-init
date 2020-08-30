#!/bin/bash -eu
CMD="${1:-init_vault}"
keys=()
hostname=$(hostname)

# This will perform the same as vault init
# It will write the keys unsecurely to /vault/keys/keys.json which is a shared filestore between the node
initialize() {
    echo "initialize"
    INITRESPONSE=$(curl -X PUT -H "Content-Type: application/json" -d '{"secret_shares":5,"secret_threshold":3}' http://localhost:8200/v1/sys/init)
    echo $INITRESPONSE | jq . > /vault/keys/keys.json
}

# This will join a vault instance to the Raft cluster
raft() {
    echo "Need to do a Raft join"
    RAFTRESPONSE=$(curl -X PUT -H "Content-Type: application/json" -d '{"leader_api_addr": "http://vault-0.vault-internal:8200"}' http://localhost:8200/v1/sys/storage/raft/join)
}

# This will go through the keys stored unsecurely in /vault/keys/keys.json to unseal till it has been completely unsealed
unseal() {
    echo "unseal"
    keys=( $(cat /vault/keys/keys.json | jq -r '.keys_base64[]' ) )
    for i in "${keys[@]}"
    do
        UNSEALRESPONSE=$(curl -X PUT -H "Content-Type: application/json" -d "{\"key\":\"$i\"}" http://localhost:8200/v1/sys/unseal)
        SEALSTATUS=$(echo $UNSEALRESPONSE | jq -r '.sealed' )
        if [ $SEALSTATUS == "false" ];
        then
            break;
        fi
    done
}

# This is the director and based on the respsonse code returned from the vault instance will move through the flows
# i.e vault-0 will need to be initialize and unseal
# vault-x will need to join the raft cluster and then unseal
init_vault() {
    while [ true ];
    do
        VAULTSTATUS=$(curl -s -o /dev/null -w "%{http_code}" --head http://localhost:8200/v1/sys/health)
        case $VAULTSTATUS in
            200)
                echo "Vault is initialized and unsealed."
                break
                ;;
            429)
                echo "Vault is unsealed and in standby mode."
                break;
                ;;
            501)
                echo "Vault is not initialized. Initializing and unsealing..."
                if [[ "$hostname" == "vault-0" ]]; then
                    initialize
                else
                    raft
                fi
			    unseal
                ;;
            503)
                echo "Vault is sealed. Unsealing..."
                unseal
                ;;
            *)
                echo "Vault is in an unknown state. Status code:"
                ;;
        esac
        sleep 10
    done;
    tail -f /dev/null
}

case "$CMD" in
init_vault) 
    init_vault
    ;;
*)
    exec "$@"
esac