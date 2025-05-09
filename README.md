# packet-pid

**Monitor which processes are making network connections — in real time.**  
This tool bridges the gap Wireshark leaves by mapping each TCP stream to the responsible PID and process name using `tshark` + `ss`.

---

## 🔧 Features

- Real-time packet capture using `tshark`
- Correlates IP:port streams to local PIDs using `ss`
- Works with `Ctrl+C` for manual stop, or timed/packet-limited modes
- Supports filtering by interface and flexible capture modes

---

## 🧪 Example Use

```bash
# Run on default interface (eth0) until Ctrl+C
sudo ./packet-pid.sh

# Use a specific interface
sudo ./packet-pid.sh --interface wlan0

# Stop after capturing 300 packets
sudo ./packet-pid.sh --interface eth0 --packets 300

# Stop after 2 minutes
sudo ./packet-pid.sh --interface eth0 --minutes 2

```

## Support

BTC: bc1qtezfajhysn6dut07m60vtg0s33jy8tqcvjqqzk
