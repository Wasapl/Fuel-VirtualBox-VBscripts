FuelWeb-VirtualBox-VBscripts
============================

Scripts helps you to deploy FuelWeb and OpenStack PoC on VirtualBox for Windows.
It works using a host machine with a minimum of 8GB of RAM, but 16GB works better. 
See http://fuel.mirantis.com for additional information.

Scripts does folowing:
 1.  configure VirtualBox environment according to config.vbs
 2.  create Fuel-web Master VM and mount fuel web ISO in it
 3.  wait for finish of Fuel-web install
 4.  create and run slave VMs

In order to successfully run FuelWeb under VirtualBox, you need to:
 1.  install latest version of *VirtualBox* for windows and install VirtualBox *Extension Pack*
 2.  download the FuelWeb official release (.iso) and place it under 'iso' directory
 3.  edit `./config.vbs`
 4.  run `cscript ./launch.vbs`. it will spin up master node and slave nodes.

If there are any errors, the script will report them and abort.

If you want to change settings (number of OpenStack nodes, CPU, RAM, HDD), please refer to `config.vbs`.

#### Scripts structure

1.  In *functions* directory there is a vbscript modules with functions to comunicate with VirtualBox. 
You can use this functions in your own scripts.
2.  In *actions* directory there is scripts performing preparing VirtualBox environment and creating VMs for FuelWeb.
3.  In *iso* directory you should put FuelWeb.iso file.
4.  `launch.vbs` is the main script which executes actions in particular order to deploy FuelWeb.
5.  `config.vbs` initialazes variables that shapes FuelWeb VMs. Please look it through before running `launch.vbs`

If you need only part of all actions to be done comment unnecessary actions in `launch.vbs`. 
For example you have already configured VirtualBox, network interfaces and installed master node. 
Only thing you need is to create slave nodes. Edit "launch.vbs" and comment lines:  
```
 ' Import ".\actions\clean-previous-installation.vbs"
 ' Import ".\actions\create-interfaces.vbs"
 ' Import ".\actions\master-node-create-and-install.vbs"
```
Do not comment line `Import ".\actions\prepare-environment.vbs"` Otherwise script will fail.

#### Notes
1.  Windows Script Host have two script interpreters: `Wscript` for Window UI and `Cscript` for command line UI. 
Since scripts does a lot of output its beter to run it with `Cscript` interpreter.
2.  Since there is no native ssh client in Windows scripts use `plink.exe` from **Putty** to determine finish
of Fuel-web install.
3.  One cannot name host-only interfaces in Windows. VirtualBox names it like 
`VirtualBox Host-Only Ethernet Adapter #N` and you cannot rename it. Scripts determine name of interface
created and rewrite it in `config.vbs`.
4.  Windows do not allow IP addresses from range 240.0.0.0/4. You have to change value of `host_nic_ip(1)` in
`config.vbs`, and change public and floating IPs in **FuelWeb Dashboard** when scripts finished its work.
5.  Sometimes VBoxManage can't properly configure IP at hostonly interface. You have to check interfaces 
attributes after its creation. Restart script if interfaces IPs are wrong.
