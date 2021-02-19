#!/usr/bin/env bash

# pi-conf 1.0.0
#
# Prepares Raspberry Pi SD card before first boot and configures:
#
#   * Hostname
#   * Hosts
#   * Keyboard Layout
#   * Timezone
#   * Static IP for eth0 or wlan0
#   * SSH Server
#   * SSH Public Key Auth
#
# Each modified file will be backed up with suffix ".piconf.bak"
# Triggering script multiple times will first restore files from backup before modifying

set -e

[ "$(id -u)" != "0" ] && echo "must be run as root" && exit 1

# ----------------------------------------------------------------------------------------------------------------------

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

# ----------------------------------------------------------------------------------------------------------------------

[ ! -d "${c_boot}" ]     && echo "\"${c_boot}\" not found" && exit 1
[ ! -d "${c_root}" ]     && echo "\"${c_root}\" not found" && exit 1

fbak () {
  [ -f "$1.piconf.bak" ] && cp -p "$1.piconf.bak" "$1" && return
  cp -p "$1" "$1.piconf.bak"
}

fbak "${c_root}/etc/hostname"
echo "${c_hostname}" > "${c_root}/etc/hostname"

fbak "${c_root}/etc/hosts"
sed -i "s/raspberrypi/${c_hostname}/g" "${c_root}/etc/hosts"

fbak "${c_root}/etc/timezone"
echo "${c_timezone}" > "${c_root}/etc/timezone"

fbak "${c_root}/etc/default/keyboard"
sed -i "s/XKBLAYOUT=\"gb\"/XKBLAYOUT=\"${c_keyboard,,}\"/g" "${c_root}/etc/default/keyboard"

touch "${c_boot}/ssh"
chown -R 1000:1000 "${c_boot}/ssh"

if [ -f "${c_ssh_pub}" ]; then
  mkdir -p "${c_root}/home/pi/.ssh"
  cat "${c_ssh_pub}" > "${c_root}/home/pi/.ssh/authorized_keys"
  chown -R 1000:1000 "${c_root}/home/pi/.ssh"
else
  rm -rf "${c_root}/home/pi/.ssh"
fi

[ "${c_net_type}" == "eth0" ] && rm -f "${c_boot}/wpa_supplicant.conf"
if [ "${c_net_type}" == "wlan0" ]; then
  echo "ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev"  >  "${c_boot}/wpa_supplicant.conf"
  echo "update_config=1"                                          >> "${c_boot}/wpa_supplicant.conf"
  echo "country=${c_net_locale^^}"                                >> "${c_boot}/wpa_supplicant.conf"
  echo ""                                                         >> "${c_boot}/wpa_supplicant.conf"
  echo "network={"                                                >> "${c_boot}/wpa_supplicant.conf"
  echo "  ssid=\"${c_net_ssid}\""                                 >> "${c_boot}/wpa_supplicant.conf"
  echo "  psk=\"${c_net_passwd}\""                                >> "${c_boot}/wpa_supplicant.conf"
  echo "}"                                                        >> "${c_boot}/wpa_supplicant.conf"
  chown -R 1000:1000 "${c_boot}/wpa_supplicant.conf"
fi

fbak "${c_root}/etc/dhcpcd.conf"
echo ""                                         >> "${c_root}/etc/dhcpcd.conf"
echo "interface ${c_net_type}"                  >> "${c_root}/etc/dhcpcd.conf"
echo "static ip_address=${c_net_cidr}"          >> "${c_root}/etc/dhcpcd.conf"
echo "static routers=${c_net_gate}"             >> "${c_root}/etc/dhcpcd.conf"
echo "static domain_name_servers=${c_net_dns}"  >> "${c_root}/etc/dhcpcd.conf"

exit 0
