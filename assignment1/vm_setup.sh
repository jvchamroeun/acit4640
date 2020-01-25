#!/bin/bash

#install required packages
install_packages () {
	echo "Packages downloading now . . ."
	ssh todoapp 'echo y | sudo yum install git'
	ssh todoapp 'curl -sL https://rpm.nodesource.com/setup_10.x | sudo bash -'
        ssh todoapp 'echo y | sudo yum install nodejs'
	ssh todoapp 'echo y | sudo yum install mongodb-server'
	echo "Enabling and Starting mongod now . . ."
	ssh todoapp 'sudo systemctl enable mongod && sudo systemctl start mongod'
}

#add new user and set password
new_user () {
	echo 'Adding new user . . .'
	ssh todoapp 'sudo adduser todoapp'
	ssh todoapp 'echo todoapp:P@ssw0rd | sudo chpasswd'
}

#clone repo in new user app folder and install application
install_app () {
	echo "Installing application . . ."
	ssh todoapp 'sudo chmod 755 /home/todoapp/'
	ssh todoapp 'cd ~todoapp/; sudo mkdir app'
	ssh todoapp 'cd ~todoapp/app/; sudo git clone https://github.com/timoguic/ACIT4640-todo-app.git'
	ssh todoapp 'cd ~todoapp/app/ACIT4640-todo-app/; sudo npm install'
	echo "Transfering database configuration file now . . ."
	ssh todoapp 'cd ~todoapp/app/ACIT4640-todo-app/config; sudo rm database.js'
	scp ./setup/database.js todoapp:/home/admin
	ssh todoapp 'sudo mv database.js ~todoapp/app/ACIT4640-todo-app/config'
	ssh todoapp 'sudo chown -R todoapp /home/todoapp/app'
}


#install nginx and modifying nginx.conf
production_setup () {
	echo "Running nginx service now . . ."
	ssh todoapp 'echo y | sudo yum install nginx'
	ssh todoapp 'sudo systemctl enable nginx; sudo systemctl start nginx'
	echo "Transfering nginx configuration now . . ."
	ssh todoapp 'sudo rm /etc/nginx/nginx.conf'
	scp ./setup/nginx.conf todoapp:/home/admin
	ssh todoapp 'sudo mv nginx.conf /etc/nginx'
	ssh todoapp 'sudo systemctl restart nginx'

}

#Running Nodejs as a daemon with systemd
service_setup () {
	echo 'Running service setup now . . .'
	ssh todoapp 'sudo rm /etc/systemd/system/todoapp.service'
	scp ./setup/todoapp.service todoapp:/home/admin
	ssh todoapp 'sudo mv todoapp.service /etc/systemd/system'
	ssh todoapp 'sudo systemctl daemon-reload; sudo systemctl enable todoapp; sudo systemctl start todoapp'
}

install_packages
new_user
install_app
production_setup
service_setup

echo "DONE!"

