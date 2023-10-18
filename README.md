# cpufreq-userspace-scaler
##### Cpu frequency scaling script for cpufreq userspace governor

## If you're missing ondemand or conservative governors, this script is for you.

## If you encounter Synology DS1223xs+ overheating and auto shutdown during a low to medium load condition, this script is for you.  Synology DS1223xs+ cpu throttling is faulty, it doesn't care about the CPU frequency vs temperature.  There will be a condition that CPU temperature can reach over 100C and auto shutdown will be executed (even when all CPU load is just 50% in total, and it make no sense that the AMD Ryzen V1780B CPU will set the frequency at 3.35GHz).  The Control Panel -> Info Center -> Thermal Status will display over 100C as well.  This script basically throttle and switch the CPU frequency between 1.6GHz to 2.3GHz  (cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_frequencies)

## Note: Synology DS1223xs+ is an excellent NAS, with best-in-class price point & build quality.  Just this simple fault make it totally unusable in production environment.   Consider it has everything you didn't expected like 2 NVME Cache Slot, 10G NIC, 8-bays, and a PCI-e slot too.  I have 2 x 2TB Samsung NVME 980Pro, added 40G Mellanox, 8 x 20TB HGST.  I cannot find other solution as affordable as this.  Only thing missing is a network mount...

This script is scaling cpu frequency according to current average load.
You can set 2 frequency steps : low, mid. This 2 thresholds will automatically set cpu frequency accordingly :
  - the `lowload` threshold will set the cpu to his minimal frequency, unless you force it to `scalingminfreq`
  - the `midload` threshold will set the cpu to approximate mid range cpu frequency, if load goes higher it will scale to max `scalingmaxfreq`

If you set `scalingmaxfreq` and/or `scalingminfreq` the cpu will never override those values.

### Usage :
### Parameters :
Variable name   | Default | Type                        | Comments
----------------|---------|-----------------------------|-----------
lowload         | auto / 30%     | integer between 000 and 999 | 050 = load average : 0.50
midload         | auto / 60%    | integer between 000 and 999 | 065 = load average : 0.65
scalingminfreq  | auto    | integer in hertz            | 800000 = 800 Mhz
scalingmaxfreq  | auto    | integer in hertz            | 2500000 = 2,5 Ghz

### Default commande line :
`./scaling.sh &`

### Custom command line example :
`lowload=100 midload=200 scalingmaxfreq=2000000 scalingminfreq=1500000 ./scaling.sh &`

### Systemd service installer
*for DSM 7.0 and above*

1. If needed, set desired lowload and midload values in `cpufreq-userspace-scaler.service`
2. Launch the installer `./install.sh`
