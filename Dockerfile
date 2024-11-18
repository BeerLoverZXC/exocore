FROM ubuntu:latest

ENV HOME=/app

WORKDIR /app

RUN apt-get update && \
apt-get upgrade -y && \
apt-get install jq build-essential curl git wget lz4 time bash -y && \
curl -L https://foundry.paradigm.xyz | bash

ENV PATH="$HOME/.foundry/bin:$PATH"

RUN foundryup

ENV GO_VER="1.22.5"

RUN wget "https://golang.org/dl/go$GO_VER.linux-amd64.tar.gz" && \
tar -C /usr/local -xzf "go$GO_VER.linux-amd64.tar.gz" && \
rm "go$GO_VER.linux-amd64.tar.gz" && \
mkdir -p go/bin

ENV PATH="/usr/local/go/bin:/app/go/bin:${PATH}"
ENV WALLET="wallet"
ENV MONIKER="StakeShark"
ENV CHAIN_ID="exocoretestnet_233-6"

RUN wget -O exocored.tar.gz "https://github.com/ExocoreNetwork/exocore/releases/download/v1.0.6/exocore_1.0.6_Linux_amd64.tar.gz" && \
tar -xvzf exocored.tar.gz && \
rm -rf exocored.tar.gz && \
mv bin/exocored $HOME/go/bin/

RUN exocored --home $HOME/.exocored init $MONIKER --chain-id $CHAIN_ID && \
exocored --home $HOME/.exocored config chain-id $CHAIN_ID

ENV SEEDS="5dfa2ddc4ce3535ef98470ffe108e6e12edd1955@seed2t.exocore-restaking.com:26656,4cc9c970fe52be4568942693ecfc2ee2cdb63d44@seed1t.exocore-restaking.com:26656"

RUN sed -i -e "/^\[p2p\]/,/^\[/{s/^[[:space:]]*seeds *=.*/seeds = \"$SEEDS\"/}" $HOME/.exocored/config/config.toml && \
sed -i 's|minimum-gas-prices =.*|minimum-gas-prices = "0.0001hua"|g' $HOME/.exocored/config/app.toml && \
sed -i -e "s/prometheus = false/prometheus = true/" $HOME/.exocored/config/config.toml && \
sed -i -e "s/^indexer *=.*/indexer = \"null\"/" $HOME/.exocored/config/config.toml && \
sed -i -e "s/^pruning *=.*/pruning = \"custom\"/" $HOME/.exocored/config/app.toml && \
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"1000\"/" $HOME/.exocored/config/app.toml && \
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"10\"/" $HOME/.exocored/config/app.toml && \
sed -i -e "s/^external_address *=.*/external_address = \"$(wget -qO- eth0.me):26656\"/" $HOME/.exocored/config/config.toml

RUN wget -O $HOME/.exocored/config/genesis.json https://raw.githubusercontent.com/ExocoreNetwork/testnets/main/genesis/$CHAIN_ID.json

RUN echo '#!/bin/sh' > /app/entrypoint.sh && \
    echo 'sleep 10000' >> /app/entrypoint.sh && \
    chmod +x /app/entrypoint.sh
    
ENTRYPOINT ["/app/entrypoint.sh"]
