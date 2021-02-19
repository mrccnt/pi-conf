# Pi-Conf

Preconfigure a Raspberry Pi SD card before first boot.

After creating an image of Raspian OS (buster), before first start of your Raspberry Pi, you can preconfigure some
settings to make the process of getting started much faster. I am too lazy to spend too much time configuring things
each time a RPi comes up for the first time. So here is 5-Minute-Script solution for that.

## What it does

 * Configure hostname (and therefore hosts)
 * Set keyboard language layout (via locale)
 * Set the timezone
 * Configure a static IP for either eth0 or wlan0
 * Enable SSH server
 * Inject your public key as authorized keys

## Usage

As I said, 5-Minute-Script solution. Insert SD card into you local machine so that "boot" and "rootfs" mounts are
available. Then open up the script and configure variables as needed. As paths are configurable it should work on
most linux machines:

```shell
c_hostname="yourhostname"
c_timezone="Europe/Zurich"
c_keyboard="de"

c_net_type="eth0" # One of: eth0|wlan0
c_net_cidr="192.168.1.71/24"    # Setting static IP to 192.168.1.71 in this example
c_net_gate="192.168.1.1"
c_net_dns="192.168.1.1 1.1.1.1" # Multiple entries seperated by space

c_net_ssid="MyWifiSSID"           # Leave empty if net type is eth0
c_net_passwd="my-secret-password" # Leave empty if net type is eth0
c_net_locale="CH"                 # Leave empty if net type is eth0

# Basically do not touch, but override
# manually if this does not work for you:
#
c_ssh_pub="/home/${SUDO_USER}/.ssh/id_rsa.pub" # Leave empty if not desired
c_boot="/media/${SUDO_USER}/boot"
c_root="/media/${SUDO_USER}/rootfs"
```

Finaly trigger as `root`:

```shell
sudo ./pi-conf.sh
```

Eject SD card, put into RPi and start up. You should be able to directly connect via `ssh pi@<configured ip>` or
`ssh pi@<configured hostname>`.

## TODO

 * Set password for "pi"
 * Generate locales (e.g. en_US.UTF-8)
