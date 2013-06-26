FuelWeb-VirtualBox-VBscripts
============================

Fuel-web VirtualBox VBscripts for Windows

Scripts does folowing:
 1. configure VirtualBox environment according to config.vbs
 2. create Fuel-web Master VM and mount fuel web ISO in it
 3. wait for finish of Fuel-web install
 4. create and run slave VMs

In order to successfully run Fuel Web under VirtualBox, you need to:
- download the official release (.iso) and place it under 'iso' directory
- edit "./config.vbs" 
- run "./launch.sh". it will spin up master node and slave nodes

If there are any errors, the script will report them and abort.

If you want to change settings (number of OpenStack nodes, CPU, RAM, HDD), please refer to "config.sh".

Notes

1. Since there is no native ssh client in Windows scripts use plink.exe from Putty to determine finish of Fuel-web install.
2. One cannot name host-only interfaces in Windows. VirtualBox names it like "VirtualBox Host-Only Ethernet Adapter #N"  and you cannot rename it. Scripts determine name of interface created and rewrite it in config.vbs.
3. Windows do not allow IP addresses from range 240.0.0.0/4. You have to change value of host_nic_ip(1) in config.vbs, and change public and floating IPs in FuelWeb Dashboard.
4. Sometimes VBoxManage can't properly configure IP at hostonly interface. You have to check interfaces attributes after its creation. Restart script if interfaces IPs are wrong.