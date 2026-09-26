#!/bin/sh
set -e

RPC_HOST="garage:3901"
GARAGE="garage -c /etc/garage.toml --rpc-host $RPC_HOST"

# Wait until the garage server accepts RPC connections
until $GARAGE status >/dev/null 2>&1; do
  echo "Waiting for garage..."
  sleep 1
done

# Assign this single node its layout only if it has no role yet
NODE_ID=$($GARAGE status | awk '/NO ROLE ASSIGNED/ {print $1; exit}')

if [ -n "$NODE_ID" ]; then
  $GARAGE layout assign -z dc1 -c 1G "$NODE_ID"
  VERSION=$($GARAGE layout show | awk '/Current cluster layout version:/ {print $NF}')
  $GARAGE layout apply --version "$((VERSION + 1))"
fi

$GARAGE bucket create orangerie-dev 2>/dev/null || true

if ! $GARAGE key info loka-dev >/dev/null 2>&1; then
  $GARAGE key create loka-dev
fi

$GARAGE bucket allow --read --write --owner orangerie-dev --key loka-dev
$GARAGE key info loka-dev --show-secret
