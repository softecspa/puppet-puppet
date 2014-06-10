#!/bin/bash
# Add puppet client to ubuntu host
#
# If the host is managed by scalr it uses /var/cache/scalr/fqdn to
# set hostname, uses `hostname -f` otherwise
#

LOG=/var/log/puppet-bootstrap.log
REGISTRY_URL=http://registry.tools.softecspa.it
CONF_FILE_TEMPLATE=$REGISTRY_URL/files/puppet.conf
APT_SOURCE=$REGISTRY_URL/files/puppetlabs.list
APT_SOURCE_LIST=/etc/apt/sources.list.d/puppetlabs.list

KEYSERVER="hkp://keyserver.ubuntu.com:80"
KEYSIG=4BD6EC30
#use regexp for major release
PUPPET_MAJOR_RELEASE="2\.7.*"
PUPPET_VERSION="2.7.23-1puppetlabs1"
PUPPET_PACKAGES="puppet=$PUPPET_VERSION puppet-common=$PUPPET_VERSION"
PACK="facter=1.7.5-1puppetlabs1 libaugeas-ruby augeas-lenses augeas-tools rubygems ruby1.8-dev"
PUPPET_PATH=/var/lib/puppet/ssl

DISTRIB_CODENAME=$(lsb_release -c -s)

PUPPET_ENV=$1
if [ -z $PUPPET_ENV ]; then
    PUPPET_ENV=production
fi

WAIT_TIME=30
WAIT_COUNTER=6

##########################################################################
### End of config ############################################################
##########################################################################

log() {
    if [ -n "$1" ]; then
        echo "$(date) [$$]: $1" >> $LOG
        echo -e "$(date) [$$]: $1"
    fi
}

log_debug() {
    if [ -n "$1" ]; then
        echo -e "$(date) [$$]: $1"
    fi
}

log_error() {
    if [ -n "$1" ]; then
        echo -e "$(date) [$$]: $1" 1>&2
    fi
}

### End of function definitions #######################################

if [ ! -w $(dirname $LOG) ]; then
    echo "Sorry, I cannot write log in $LOG, cannot continue."
    exit 1
fi

if [ ! -f /etc/lsb-release ]; then
    log_error "Cannot fine /etc/lsb-release, cannot continue."
    exit 1
fi

. /etc/lsb-release

### GET FQDN ###################################################################
if [ -d /etc/scalr ]; then
    log_debug "I'm a scalr host"
    # Start searching for /var/cache/scalr/fqdn, created from cluster-hostname.sh script

    i=0
    while [ ! -f /var/cache/scalr/fqdn ]; do
      log_debug "Waiting $WAIT_TIME sec. for /var/cache/scalr/fqdn"
      sleep $WAIT_TIME
      let i+=1
      if [ $i -eq $WAIT_COUNTER ]; then
        log_debug "Waited too much... I'm doing karakiri"
        shutdown -r now
      fi
    done
    FQDN=$(cat /var/cache/scalr/fqdn)
else
    log_debug "I'm a traditional host, I must have a FQDN in my /etc/hosts"
    FQDN=$(hostname --fqdn)
fi

# In any way, I must have a FQDN now!
if [ -z $FQDN ]; then
  log_error "Cannot find fully-qualified-domain-name for $HOSTNAME"
  exit 2
fi

### SETUP PUPPET ENVIRONMENT ###################################################
CERT_FILE=$PUPPET_PATH/certs/$FQDN.pem
PUBKEY_FILE=$PUPPET_PATH/public_keys/$FQDN.pem
PRIVKEY_FILE=$PUPPET_PATH/private_keys/$FQDN.pem

# 18/06/2012 - Fx - utilizziamo il repository di puppetlabs, non piu' quello di skettler
log "Adding Puppet package from external repository"
case $DISTRIB_CODENAME in
  #hardy)
  #  PUPPET_REPOSITORY="ppa:skettler/puppet"
  #  APT_SOURCE=$REGISTRY_URL/files/puppet.list
  #  KEYSERVER=keyserver.ubuntu.com:11371
  #  KEYSIG=0xC18789EA
  #  gpg --keyserver hkp://$KEYSERVER --recv-key $KEYSIG && gpg -a --export $KEYSIG | sudo apt-key add -  > /dev/null
  #  wget -q -O /etc/apt/sources.list.d/puppet.list $APT_SOURCE 
  #  ;;
  *)
    apt-key adv --keyserver $KEYSERVER --recv $KEYSIG >> $LOG 2>&1 
    wget -q -O $APT_SOURCE_LIST $APT_SOURCE
    sed "s/DISTRIB_CODENAME/$DISTRIB_CODENAME/" -i~ $APT_SOURCE_LIST
    ;;
esac

##################################################################################

log "Updating packages info..."
aptitude -q update >> /dev/null

log "Installing ruby related packages: $PACK ..."
aptitude -q -y install $PACK

if [[ `dpkg -l | grep puppet-common | awk '{print $3}'` =~ $PUPPET_MAJOR_RELEASE ]]; then
    log "Puppet already installed..."
else
    log "Installing puppet packages: $PUPPET_PACKAGES ..."
    aptitude -q -y install $PUPPET_PACKAGES
fi

if [ ! -f /etc/default/puppet ]; then
  log_error "Cannot find /etc/default/puppet on $HOSTNAME"
  exit 3
fi
log "Setting START=no in /etc/default/puppet (not needed)"
sed 's/START=yes/START=no/' -i~ /etc/default/puppet

# Puppet config file
log "Downloading puppet conf from $CONF_FILE_TEMPLATE ..."
wget -q -O - $CONF_FILE_TEMPLATE > /etc/puppet/puppet.conf
if [ ! -f /etc/puppet/puppet.conf ]; then
        log_error "Cannot create puppet config file $CONF_FILE"
        exit 4
fi
log "Updating FQDN with my '$FQDN' in /etc/puppet/puppet.conf"
sed "s/FQDN/${FQDN}/" -i~ /etc/puppet/puppet.conf

if [ -n "$PUPPET_ENV" ]; then
    sed "s/environment=.*/environment=$PUPPET_ENV/" -i~ /etc/puppet/puppet.conf
    log "Customizing Puppet environment: set $PUPPET_ENV"
fi

# creating dir for certificates and keys
mkdir -p $PUPPET_PATH/{public_keys,private_keys,certs}
chown -R puppet $PUPPET_PATH 

### CALL SOFTEC REGISTRY #######################################################
log "Requesting keys and signed certificate generation for $FQDN..."
wget --no-verbose --spider $REGISTRY_URL/${FQDN}/gen >> $LOG

# Per WAIT_COUNTER volte provero' a richiedere i file al registry
# aspettando WAIT_TIME ogni volta, fino a che non mi arrivano tutti
# e 3 e sono tutti con dimensione non nulla
OK_FILES=0
i=0
while [ $OK_FILES -lt 3 ]; do
    OK_FILES=0

    if [ $i -gt 1 ]; then
        log_debug "Waiting $WAIT_TIME sec. for file generation"
        sleep $WAIT_TIME
    fi

    wget --no-verbose -O - $REGISTRY_URL/${FQDN}/get/cert > $CERT_FILE
    # certificate verification
    openssl x509 -in $CERT_FILE -text -noout &> /dev/null
    if [ ! $? ]; then
        log_error "Error, invalid file $CERT_FILE"
        rm $CERT_FILE
    else
        log "Got $CERT_FILE"
        OK_FILES=$((OK_FILES + 1))
    fi

    wget --no-verbose -O - $REGISTRY_URL/${FQDN}/get/public_key > $PUBKEY_FILE 
    if [ ! -s $PUBKEY_FILE ]; then
        log_error "zero-sized $PUBKEY_FILE"
        rm $PUBKEY_FILE
    else
        log "Got $PUBKEY_FILE"
        OK_FILES=$((OK_FILES + 1))
    fi

    wget --no-verbose -O - $REGISTRY_URL/${FQDN}/get/private_key > $PRIVKEY_FILE
    # privkey verification
    openssl rsa -in $PRIVKEY_FILE -check &> /dev/null
    if [ ! $? ]; then
        log_error "Error, invalid file $PRIVKEY_FILE"
        rm $PRIVKEY_FILE
    else
        log "Got $PRIVKEY_FILE"
        OK_FILES=$((OK_FILES + 1))
    fi

    let i=$i+1
    if [ $i -eq $WAIT_COUNTER ]; then
        log_debug "Waited too much... I'm doing karakiri"
        shutdown -r now
        exit 1
    fi
done

chown puppet $CERT_FILE $PUBKEY_FILE $PRIVKEY_FILE >> $LOG
chmod 600 $PRIVKEY_FILE >> $LOG

log "Puppet setup successfully done, start playing with your recipes..."
exit 0
