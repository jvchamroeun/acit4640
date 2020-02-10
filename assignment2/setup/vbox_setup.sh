#!/bin/bash

# This is a shortcut function that makes it shorter and more readable
vbmg () { /mnt/c/Program\ Files/Oracle/VirtualBox/VBoxManage.exe "$@"; }

NET_NAME="NET_4640"
VM_NAME="T0D0"
SSH_PORT="12022"
WEB_PORT="12080"
FILE="T040_VDI"

# This function will clean the NAT network and the virtual machine
clean_all () {
    echo "Cleaning up network . . ."
    vbmg natnetwork remove --netname "$NET_NAME"
    echo "Cleaning up Virtual Machines . . ."
    vbmg unregistervm "$VM_NAME" --delete
}

create_network () {
    vbmg natnetwork add --netname "$NET_NAME" --network "192.168.230.0/24" \
    			--dhcp off --ipv6 off \
    			--port-forward-4 "Rule 1:tcp:[127.0.0.1]:12022:[192.168.230.10]:22" \
    			--port-forward-4 "Rule 2:tcp:[127.0.0.1]:12080:[192.168.230.10]:80" \
			--port-forward-4 "Rule 3:tcp:[127.0.0.1]:12222:[192.168.230.200]:22"
}

create_vm () {
    vbmg createvm --name "$VM_NAME" --ostype "RedHat_64" --register
    vbmg modifyvm "$VM_NAME" --memory 1512 --vram 16 --nic1 natnetwork \
    			     --nat-network1 "$NET_NAME" --audio none \
                     --boot1 disk --boot2 net --boot3 none --boot4 none

    SED_PROGRAM="/^Config file:/ { s/^.*:\s\+\(\S\+\)/\1/; s|\\\\|/|gp }"
    VBOX_FILE=$(vbmg showvminfo "$VM_NAME" | sed -ne "$SED_PROGRAM")
    VM_DIR=$(dirname "$VBOX_FILE")

    vbmg createmedium disk --filename "$VM_DIR"'/'"$FILE".vdi --size 10240

    vbmg storagectl "$VM_NAME" --name "IDE" --add ide
    vbmg storagectl "$VM_NAME" --name "SATA" --add sata

    vbmg storageattach "$VM_NAME" --storagectl "SATA" --medium "$VM_DIR"'/'"$FILE".vdi --port 1 --type hdd
}

echo "Starting script..."

clean_all
create_network
create_vm

echo "DONE!"
