#!/bin/bash

# Update the OS to begin with to catch up to the latest packages.
sudo apt update -y
sudo apt upgrade -y
sudo apt autoremove -y
sudo apt install -y xfsprogs

BITCOIN_PATH="/opt/bitcoin"
DATA_PATH="$BITCOIN_PATH/data"

# Create tron directory
sudo mkdir $BITCOIN_PATH

IFS='
';for device in $(sudo lsblk --raw | awk '$6 == "disk" { print $1 }'); do

    # check if the device ${device} has an associate ID, therefore, partitioned
    if [ "$(sudo blkid /dev/${device})" == "" ]; then

        # create a xfs partition in ${device}
        sudo mkfs -t xfs /dev/${device}

        id=$(sudo blkid /dev/${device} | awk '{ print $2 }' | grep -o -E "UUID=.*+" | awk -F\= '{print $2}' | tr -d '"')

        # create a persistent register of devices mounting
        sudo sh -c 'echo "UUID=$id       $DATA_PATH xfs     defaults,nofail  0  2" >> /etc/fstab'

        sudo mkdir -p $DATA_PATH

        echo "Mounting device ${device} to path $DATA_PATH"
        sudo mount -t xfs /dev/${device} $DATA_PATH
    fi
done


# fixes data folder permissions
sudo useradd bitcoin -d $BITCOIN_PATH
sudo chown bitcoin:bitcoin -R $BITCOIN_PATH/

### java-tron.service deployment and configuration
(cd /etc/systemd/system && sudo curl -LO https://raw.githubusercontent.com/TronWallet/blockbook-bitcoin-deployment/master/bitcoind.service)
sudo systemctl daemon-reload
sudo systemctl enable bitcoind
sudo systemctl start bitcoind
