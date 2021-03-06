#!/bin/bash

echo $@ > /tmp/args.txt

ORION_VERSION=$1
ORION_DOWNLOAD_URL=$2
ORION_NODE_IP=$3
ORION_CLIENT_IP=$4
# We arent using private IPs because the vpc arent peered. The public IPs act like real world use cases for us anyway
#ORION_CLIENT_IP=`curl http://169.254.169.254/latest/meta-data/local-ipv4`
SCRIPTS_DIR="/home/ubuntu/orion"

sed -i "s/PARAM_ORION_VERSION/$ORION_VERSION/g" $SCRIPTS_DIR/orion_bootnode.yml
sed -i "s/PARAM_ORION_NODE_IP/$ORION_NODE_IP/g" $SCRIPTS_DIR/orion_bootnode.yml
sed -i "s/PARAM_ORION_CLIENT_IP/$ORION_CLIENT_IP/g" $SCRIPTS_DIR/orion_bootnode.yml
sed -i 's#PARAM_ORION_DOWNLOAD_URL#'"$ORION_DOWNLOAD_URL"'#g' $SCRIPTS_DIR/orion_bootnode.yml

mv $SCRIPTS_DIR/log4j /opt/
chown -R ubuntu:ubuntu /opt/log4j/
mkdir /data

cd $SCRIPTS_DIR
virtualenv --python=python3 $SCRIPTS_DIR/env
. $SCRIPTS_DIR/env/bin/activate
pip install wheel
pip install -r requirements.txt

# 2x becuase I keep seeing git timeouts when download the roles
ansible-galaxy install -r requirements.yml --force --ignore-errors
ansible-galaxy install -r requirements.yml --force --ignore-errors

# start in stopped state so paths and config are created
ansible-playbook -v orion_bootnode.yml --extra-vars="orion_systemd_state=stopped"

# copy keys across & set anything else up
cp -r /home/ubuntu/keys/* /etc/orion/
chown -R orion:orion /etc/orion/

# fire up the service
systemctl start orion.service
