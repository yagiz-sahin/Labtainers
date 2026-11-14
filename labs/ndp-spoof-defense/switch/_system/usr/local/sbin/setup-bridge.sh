#!/bin/bash
set -euo pipefail

BRIDGE=br0

# Find an interface by its configured IPv4 address.
find_interface() {
    ip -o -4 addr show | awk -v target="$1" '
        $3 == "inet" {
            split($4, address, "/")
            if (address[1] == target) {
                sub(/@.*/, "", $2)
                print $2
                exit
            }
        }
    '
}

if ! ip link show "$BRIDGE" >/dev/null 2>&1; then
    ip link add name "$BRIDGE" type bridge
fi

# Allow IPv6 Neighbor Discovery multicast to pass.
ip link set dev "$BRIDGE" type bridge mcast_snooping 0

for address in \
    10.240.11.2 \
    10.240.12.2 \
    10.240.13.2 \
    10.240.14.2
do
    iface=$(find_interface "$address")

    if [ -z "$iface" ]; then
        echo "ERROR: No interface found for $address" >&2
        exit 1
    fi

    echo "Attaching $iface ($address) to $BRIDGE"
    ip link set dev "$iface" master "$BRIDGE"
    ip link set dev "$iface" up
done

ip link set dev "$BRIDGE" up
echo "Bridge $BRIDGE configured successfully."
