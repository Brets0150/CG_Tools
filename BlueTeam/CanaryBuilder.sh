#!/bin/bash
# This ia a bash script to install opencanary on a fresh install of Ubuntu 22.04

# Define canary username string variable.
username='canary'

# Define functions.

# BEGIN Check if script is run as root.
function check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo "This script must be run as root" 1>&2
        exit 1
    fi
}
# END Check if script is run as root.

# BEGIN function to drop user into opencanary virtual environment.
function drop_into_env() {
    su "$username" -c 'cd ~/ ; . env/bin/activate ;'
    #sudo -u "$username" -i
    # . env/bin/activate
    # opencanaryd --restart

}
# END function to drop user into opencanary virtual environment.

# BEGIN function to start opencanary.
function start_opencanary() {
    su "$username" -c 'cd ~/ ; . env/bin/activate ; sudo /home/canary/env/bin/opencanaryd --start'
}
# END function to start opencanary.

# BEGIN function to restart opencanary.
function restart_opencanary() {
    su "$username" -c 'cd ~/ ; . env/bin/activate ; sudo /home/canary/env/bin/opencanaryd --restart'
}
# END function to restart opencanary.

# BEGIN function to install opencanary.
function install_opencanary() {
    # Install all updates and dependencies.
    apt update && apt -y dist-upgrade && apt autoremove
    apt-get -y install python3-dev python3-pip python3-virtualenv python3-venv python3-scapy libssl-dev libpcap-dev samba jq

    # Create canary user.
    useradd --shell /bin/bash -m -p "$(tr -dc A-Za-z0-9 </dev/urandom | head -c 13 ; echo '')" "$username"
    # Add canary user to sudoers.
    echo 'canary ALL = NOPASSWD: /home/canary/env/bin/opencanaryd --start, /home/canary/env/bin/opencanaryd --restart' > /etc/sudoers.d/canary

    # Install opencanary.
    su "$username" -c 'cd ~/ ; virtualenv env/ ; . env/bin/activate ; python3 -m pip install opencanary scapy pcapy'
    cp /home/"$username"/env/lib/python3.10/site-packages/opencanary/data/settings.json /home/"$username"/env/.opencanary.conf
}

# END function to install opencanary.

# BEGIN function logo.
function logo() {
    echo '''
    |[0mO[0mO[0mO[0mO[0mO[0mO[0mO[0mO[0mO[0mO[0mO[0mO[0mO[0mO[0mO[0mO[0mO[0mO[0mO[0mO[0mO[0mO[0mO[0mO[0mO[0mO[0mO[0mO[0mO[0mO[0mO[0mO[0mO[0mO[0mO[0mO[0mO[0mO[0mO[0mO[0mO[0mO[0mO[0mO[0mO[0mO[0mO[0mO[0mO[0mO[0mO[0mO[0mO[0mO[0mO[0mO[0mO[0mO[0mO[0mO[0mO[0mO[0mO[0mO[0mO[0mO[0mO[0mO[0mO[0mO[0mO[0mO[0mO[0m[37mk[0m[31md[0m[31ml[0m[31ml[0m[31md[0m[37mk[0m|
    |[0mk[0mk[0mk[0mk[0mk[0mk[0mk[0mk[0mk[0mk[0mk[0mk[0mk[0mk[0mk[0mk[0mk[0mk[0mk[0mk[0mk[0mk[0mk[0mk[0mk[0mk[0mk[0mk[0mk[0mk[0mk[0mk[0mk[0mk[0mk[0mk[0mk[0mk[0mk[0mk[0mk[0mk[0mk[0mk[0mk[0mk[0mk[0mk[0mk[0mk[0mk[0mk[0mk[0mk[0mk[0mk[0mk[0mk[0mk[0mk[0mk[0mk[0mk[0mk[0mk[0mk[0mk[0mk[0mk[0mk[0mk[0mk[0m[37mk[0m[31ml[0m[31mc[0m[31mc[0m[31mc[0m[31mc[0m[31ml[0m|
    |[0mk[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0mk[0m[31mx[0m[31mc[0m[31mc[0m[31mc[0m[31mc[0m[31mc[0m[31ml[0m|
    |[0mk[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0mk[0m[31mx[0m[31md[0m[31mo[0m[31mo[0m[31md[0m[37mk[0m|
    |[0mk[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32mx[0m[32mx[0m[32mx[0mO[0mO[0m|
    |[0mk[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0mO[0mO[0m|
    |[0mk[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0mO[0mO[0m|
    |[0mk[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0mO[0mO[0m|
    |[0mk[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0mO[0mO[0m|
    |[0mk[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32mx[0m[32mx[0m[32mk[0m[32mk[0m[32mx[0m[32mx[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32mO[0m[32mK[0mN[0mN[0mN[0m[32mx[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0mO[0mO[0m|
    |[0mk[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32mO[0m[32m0[0mX[0mN[0mN[0mN[0mX[0mX[0m[32mX[0m[32mX[0mX[0mX[0mN[0mN[0mN[0mX[0m[32m0[0m[32mO[0m[32mK[0mW[0m[32mX[0m[32mO[0m[32mx[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0mO[0mO[0m|
    |[0mk[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32mx[0m[32m0[0mN[0mW[0m[32mX[0m[32mO[0m[32mk[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32mk[0m[32mK[0mM[0mM[0mW[0m[32m0[0m[32mx[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0mO[0mO[0m|
    |[0mk[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32mk[0mN[0mW[0m[32mK[0m[32mk[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0mX[0mW[0m[32mx[0m[32mk[0m[32mK[0mW[0mN[0m[32mO[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0mO[0mO[0m|
    |[0mk[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32mk[0mN[0mW[0m[32m0[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0mM[0mN[0m[32md[0m[32md[0m[32md[0m[32md[0m[32m0[0mW[0mN[0m[32mk[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32mK[0m[32mK[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0mO[0mO[0m|
    |[0mk[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32m0[0mM[0m[32mK[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0mX[0mW[0m[32mx[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32mK[0mM[0m[32mK[0m[32md[0m[32md[0m[32md[0m[32md[0m[32mk[0mM[0m[32mK[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0mO[0mO[0m|
    |[0mk[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0mX[0mM[0m[32mO[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32mx[0mN[0mW[0m[32mk[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32mO[0mM[0mX[0m[32md[0m[32md[0m[32m0[0mW[0m[32mX[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0mO[0mO[0m|
    |[0mk[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32mK[0mM[0m[32mO[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32m0[0mW[0mN[0m[32m0[0m[32mk[0m[32mx[0m[32mx[0m[32mx[0m[32m0[0mM[0mN[0mW[0mN[0m[32mk[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0mO[0mO[0m|
    |[0mk[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32mk[0mM[0m[32mK[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32mk[0m[32m0[0m[32mK[0mX[0mN[0mN[0mX[0mN[0mM[0m[32mO[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0mO[0mO[0m|
    |[0mk[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0mX[0mM[0m[32mx[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32mx[0mM[0mX[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32mx[0mO[0mO[0m|
    |[0mO[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0mW[0mW[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0mN[0mW[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32mx[0mO[0mO[0m|
    |[0mO[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0mW[0mN[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0mN[0mM[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32mx[0mO[0mO[0m|
    |[0mO[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0mN[0mW[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0mW[0mN[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32mx[0mO[0mO[0m|
    |[0mO[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32m0[0m[37mM[0m[32mO[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32mO[0mM[0m[32m0[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32mx[0mO[0mO[0m|
    |[0mO[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0mN[0mW[0m[32mx[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0mW[0mW[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32mx[0mO[0mO[0m|
    |[0mO[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32mx[0mW[0mN[0m[32mx[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0mN[0mW[0m[32mk[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32mx[0mO[0mO[0m|
    |[0mO[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32mx[0mW[0mN[0m[32mk[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32mx[0mN[0mW[0m[32mk[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32mx[0mO[0mO[0m|
    |[0mO[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32mK[0mM[0m[32mK[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32mK[0mM[0m[32mK[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32mx[0mO[0mO[0m|
    |[0mO[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32mk[0mX[0mW[0m[32mK[0m[32mx[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32mx[0m[32mK[0mW[0mX[0m[32mk[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32mx[0mO[0mO[0m|
    |[0mO[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32mx[0m[32mK[0mW[0mN[0m[32m0[0m[32mk[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32mk[0m[32m0[0mN[0mW[0m[32mK[0m[32mx[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32mx[0mO[0mO[0m|
    |[0mO[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32mk[0m[32m0[0mX[0mW[0mN[0m[32mK[0m[32m0[0m[32mO[0m[32mO[0m[32mk[0m[32mk[0m[32mk[0m[32mk[0m[32mO[0m[32mO[0m[32m0[0m[32mK[0mN[0mW[0mX[0m[32m0[0m[32mk[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32mx[0mO[0mO[0m|
    |[0mO[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32mx[0m[32mk[0m[32mO[0m[32m0[0m[32mK[0m[32mK[0m[32mK[0m[32mK[0m[32mK[0m[32mK[0m[32m0[0m[32mO[0m[32mk[0m[32mx[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32mx[0mO[0mO[0m|
    |[0mO[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32mx[0mO[0mO[0m|
    |[0mO[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32mx[0mO[0mO[0m|
    |[0mO[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32mx[0mO[0mO[0m|
    |[0mO[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32mx[0mO[0mO[0m|
    |[0mO[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32mx[0mO[0mO[0m|
    |[0mO[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32mx[0mO[0mO[0m|
    |[0mO[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32mx[0mO[0mO[0m|
    |[0mO[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32md[0m[32mx[0mO[0mO[0m|
    |[0mO[0mO[0mO[0mO[0mO[0mO[0mO[0mO[0mO[0mO[0mO[0mO[0mO[0mO[0mO[0mO[0mO[0mO[0mO[0mO[0mO[0mO[0mO[0mO[0mO[0mO[0mO[0mO[0mO[0mO[0mO[0mO[0mO[0mO[0mO[0mO[0mO[0mO[0mO[0mO[0mO[0mO[0mO[0mO[0mO[0mO[0mO[0mO[0mO[0mO[0mO[0mO[0mO[0mO[0mO[0mO[0mO[0mO[0mO[0mO[0mO[0mO[0mO[0mO[0mO[0mO[0mO[0mO[0mO[0mO[0mO[0mO[0mO[0mO[0mO[0mO[0mO[0mO[0mO[0m|
    '''
}
# End function logo.

# Function to print the help message.
function help {
    echo "Usage: $0 [OPTION]..."
    echo " -i, --install  install OpenCanary"
    echo " -d to drop into openCanary shell"
    echo " -s to start openCanary service"
    echo " -r to restart openCanary service"
    echo " -h, --help     display this help and exit"
}

# Begin function Test function.
function test_opencanary() {
    clear
    logo
    echo "Testing OpenCanary..."
}
# End function Test function.

# run check root function
check_root

# run logo function
clear
logo

# Check what command line flags are set.
while getopts "idsrth" opt; do
    case $opt in
        i)
            install_opencanary
            exit 0
            ;;
        d)
            drop_into_env
            exit 0
            ;;
        s)
            start_opencanary
            exit 0
            ;;
        r)
            restart_opencanary
            exit 0
            ;;
        t)
            test_opencanary
            exit 0
            ;;
        h)
            help
            exit 0
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            exit 1
            ;;
    esac
done

exit 0