#!/bin/bash

# Default values
INTERFACE="eth0"
PACKETS=""
DURATION=""
TMP_PACKET_LOG="/tmp/packet_log.txt"
TMP_STREAM_MAP="/tmp/stream_pid_map.txt"

# Usage info
usage() {
    echo "Usage: $0 [--interface eth0] [--packets 1000] [--minutes 5]"
    echo "If --packets and --minutes are not provided, capture runs until Ctrl+C."
    exit 1
}

# Parse args
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --interface) INTERFACE="$2"; shift ;;
        --packets) PACKETS="$2"; shift ;;
        --minutes) DURATION="$2"; shift ;;
        -h|--help) usage ;;
        *) echo "Unknown parameter passed: $1"; usage ;;
    esac
    shift
done

# Cleanup handler
cleanup() {
    echo -e "\n[*] Stopping tshark and analyzing..."
    kill "$TSHARK_PID" 2>/dev/null
    wait "$TSHARK_PID" 2>/dev/null
    parse_packets
    exit 0
}

# Packet parser
parse_packets() {
    > "$TMP_STREAM_MAP"
    while IFS=$'\t' read -r time src_ip src_port dst_ip dst_port; do
        stream_id="${src_ip}:${src_port} -> ${dst_ip}:${dst_port}"
        if ! grep -q "$stream_id" "$TMP_STREAM_MAP"; then
            match=$(ss -ptn | grep "${src_ip}:${src_port}" | grep "${dst_ip}:${dst_port}" | head -n 1)
            if [[ "$match" =~ pid=([0-9]+),fd=.* ]]; then
                pid="${BASH_REMATCH[1]}"
                procname=$(ps -p "$pid" -o comm=)
                echo -e "$stream_id\tPID: $pid\tProcess: $procname" >> "$TMP_STREAM_MAP"
            else
                echo -e "$stream_id\tPID: Unknown\tProcess: -" >> "$TMP_STREAM_MAP"
            fi
        fi
    done < "$TMP_PACKET_LOG"

    echo -e "\n[*] Final Results:"
    cat "$TMP_STREAM_MAP"
}

# Ctrl+C trap
trap cleanup SIGINT

# Start tshark
echo "[*] Starting capture on interface $INTERFACE..."
if [[ -n "$PACKETS" ]]; then
    tshark -i "$INTERFACE" -c "$PACKETS" -T fields \
        -e frame.time_epoch -e ip.src -e tcp.srcport -e ip.dst -e tcp.dstport \
        -Y "tcp" > "$TMP_PACKET_LOG" &
    TSHARK_PID=$!
    wait "$TSHARK_PID"
    cleanup
elif [[ -n "$DURATION" ]]; then
    tshark -i "$INTERFACE" -T fields \
        -e frame.time_epoch -e ip.src -e tcp.srcport -e ip.dst -e tcp.dstport \
        -Y "tcp" > "$TMP_PACKET_LOG" &
    TSHARK_PID=$!
    sleep "$((DURATION * 60))"
    cleanup
else
    # Ctrl+C mode (no packet or minute limit)
    echo "[*] Capture running... press Ctrl+C to stop."
    tshark -i "$INTERFACE" -T fields \
        -e frame.time_epoch -e ip.src -e tcp.srcport -e ip.dst -e tcp.dstport \
        -Y "tcp" > "$TMP_PACKET_LOG" &
    TSHARK_PID=$!
    wait "$TSHARK_PID"
fi
