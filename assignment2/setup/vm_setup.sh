#!/bin/bash

VM_USER=todoapp

#install required packages
install_packages () {
	echo "Packages downloading now . . ."
	ssh $VM_USER 'sudo yum install git -y'
	ssh $VM_USER 'curl -sL https://rpm.nodesource.com/setup_10.x | sudo bash -'
    ssh $VM_USER 'sudo yum install nodejs -y'
	ssh $VM_USER 'sudo yum install mongodb-server -y'
	echo "Enabling and Starting mongod now . . ."
	ssh $VM_USER 'sudo systemctl enable mongod && sudo systemctl start mongod'
}

#add new user and set password
new_user () {
	echo 'Adding new user . . .'
	ssh $VM_USER 'sudo adduser todoapp'
	ssh $VM_USER 'echo todoapp:P@ssw0rd | sudo chpasswd'
}

#clone repo in new user app folder and install application
install_app () {
	echo "Installing application . . ."
	ssh $VM_USER 'sudo chmod 755 /home/todoapp/'
	ssh $VM_USER 'cd ~todoapp/; sudo mkdir app'
	ssh $VM_USER 'cd ~todoapp/app/; sudo git clone https://github.com/timoguic/ACIT4640-todo-app.git'
	ssh $VM_USER 'cd ~todoapp/app/ACIT4640-todo-app/; sudo npm install'
	echo "Transfering database configuration file now . . ."
	ssh $VM_USER 'cd ~todoapp/app/ACIT4640-todo-app/config; sudo rm database.js'
	scp ./setup/database.js todoapp:/home/admin
	ssh $VM_USER 'sudo mv database.js ~todoapp/app/ACIT4640-todo-app/config'
	ssh $VM_USER 'sudo chown -R todoapp /home/todoapp/app'
}


#install nginx and modifying nginx.conf
production_setup () {
	echo "Running nginx service now . . ."
	ssh $VM_USER 'sudo yum install nginx -y'
	ssh $VM_USER 'sudo systemctl enable nginx; sudo systemctl start nginx'
	echo "Transfering nginx configuration now . . ."
	ssh $VM_USER 'sudo rm /etc/nginx/nginx.conf'
	scp ./setup/nginx.conf todoapp:/home/admin
	ssh $VM_USER 'sudo mv nginx.conf /etc/nginx'
	ssh $VM_USER 'sudo yum install psmisc -y; sudo fuser -k 80/tcp'
	ssh $VM_USER 'sudo systemctl restart nginx'

}

#Running Nodejs as a daemon with systemd
service_setup () {
	echo 'Running service setup now . . .'
	ssh $VM_USER 'sudo rm /etc/systemd/system/todoapp.service'
	scp ./setup/todoapp.service todoapp:/home/admin
	ssh $VM_USER 'sudo mv todoapp.service /etc/systemd/system'
	ssh $VM_USER 'sudo systemctl daemon-reload; sudo systemctl enable todoapp; sudo systemctl start todoapp'
}

install_packages
new_user
install_app
production_setup
service_setup

echo "DONE!"

