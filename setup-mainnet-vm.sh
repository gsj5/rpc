#!/bin/bash

set -e

RCHAIN_DIR="$1"
RCHAIN_DEV="$2"
RPC_HOST="$(hostname)"
GITHUP_REPO="https://raw.githubusercontent.com/gsj5/rpc/main"
BONDS_FILE="https://raw.githubusercontent.com/r-publishing/mainnet-genesis/ea07eabfc8c6c35f5438401c12e86d7328c7ff54/rpc.validator.bonds.txt"
WALLETS_FILE="https://raw.githubusercontent.com/r-publishing/mainnet-genesis/ea07eabfc8c6c35f5438401c12e86d7328c7ff54/rpc.wallets.txt"

# format & mount the data drive
mkfs.ext4 -m 0 -E lazy_itable_init=0,lazy_journal_init=0 $RCHAIN_DEV
mkdir -p $RCHAIN_DIR 
mount -o defaults $RCHAIN_DEV $RCHAIN_DIR
echo "UUID=`blkid|grep \"^$RCHAIN_DEV\"|cut -d'\"' -f2` $RCHAIN_DIR ext4 defaults,nofail 0 2" >>/etc/fstab

apt update && apt -y upgrade
apt -y install apt -y install python3-pip docker-compose iotop fail2ban git npm

git clone $GITHUP_REPO/$RPC_HOST $RCHAIN_DIR

if [[ $RPC_HOST == "rpc-main-lon" ]]; then
	curl -o $RCHAIN_DIR/node0/rnode/genesis/bonds.txt $BONDS_FILE
	curl -o $RCHAIN_DIR/node0/rnode/genesis/wallets.txt $BONDS_FILE
fi

echo "$0:Script done!"

