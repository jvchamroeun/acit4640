#!/bin/bash
vbmg () { /mnt/c/Program\ Files/Oracle/VirtualBox/VBoxManage.exe "$@"; }

PXE="PXE4640"
NET_NAME="NET_4640"
VM_NAME="T0D0"

# calls script in setup folder to create network and virtual machine
initial_setup () {
    bash ./setup/vbox_setup.sh
}

#sets up pxe server and transfer requried files
initialize_pxe_server () {
	vbmg modifyvm "$PXE" --nat-network1 "$NET_NAME"
	vbmg startvm "$PXE"

	while /bin/true; do
        ssh -i ~/.ssh/acit_admin_id_rsa -p 12222 \
            -o ConnectTimeout=2 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
            -q admin@localhost exit
        if [ $? -ne 0 ]; then
                echo "PXE server is not up, sleeping..."
                sleep 3
        else
                break
        fi
	done

	scp ./setup/authorized_keys pxe:/home/admin
	scp ./setup/ks.cfg pxe:/home/admin
    ssh pxe "sudo mv /home/admin/authorized_keys /var/www/lighttpd/files"
    ssh pxe "sudo mv /home/admin/ks.cfg /var/www/lighttpd/files/"

}

# starts newly created virtual machine in initial setup and calls script in setup folder to setup services in the newly created vm
vm_setup () {
	vbmg startvm "$VM_NAME"

	while /bin/true; do
		ssh -i ~/.ssh/acit_admin_id_rsa -p 12022 \
            -o ConnectTimeout=2 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
            -q admin@localhost exit
        if [ $? -ne 0 ]; then
                echo "Todoapp server is not up, sleeping..."
                sleep 2
        else
                vbmg controlvm $PXE poweroff
                break
        fi
	done

	bash ./setup/vm_setup.sh
}

initial_setup
initialize_pxe_server
vm_setup



