#!/bin/bash
#
# Common setup for ALL SERVERS (Control Plane and Nodes)
# will run on Ubuntu Server 22.04 LTS
# If you see some warning at certificates, RUN AGAIN

#set -euxo pipefail
sudo apt-get update -y
# Variable Declaration

sudo KUBERNETES_VERSION="1.26.1-00"

# disable swap
echo ""
echo  "\033[4mDisabling Swap Memory.\033[0m"
echo ""
sudo swapoff -a
sudo sed -e '/swap/s/^/#/g' -i /etc/fstab

# Install CRI-O Runtime
echo ""
echo  "\033[4mInstalling CRI-O runtime.\033[0m"
echo ""
sudo OS="xUbuntu_22.04"

VERSION="1.23"

# Create the .conf file to load the modules at bootup
sudo cat <<EOF | sudo tee /etc/modules-load.d/crio.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

# Set up required sysctl params, these persist across reboots.
sudo cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

sudo sysctl --system

sudo cat <<EOF | sudo tee /etc/apt/sources.list.d/devel:kubic:libcontainers:stable.list
deb https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/$OS/ /
EOF
sudo cat <<EOF | sudo tee /etc/apt/sources.list.d/devel:kubic:libcontainers:stable:cri-o:$VERSION.list
deb http://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable:/cri-o:/$VERSION/$OS/ /
EOF

sudo curl -L https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable:cri-o:$VERSION/$OS/Release.key | sudo apt-key --keyring /etc/apt/trusted.gpg.d/libcontainers.gpg add -
sudo curl -L https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/$OS/Release.key | sudo apt-key --keyring /etc/apt/trusted.gpg.d/libcontainers.gpg add -

sudo apt-get update -y
sudo apt-get install cri-o cri-o-runc -y

sudo systemctl daemon-reload
sudo systemctl enable crio --now
echo ""
echo  "\033[4mConfiguring CRI-O to use dockerhub.\033[0m"
echo ""
sudo cat <<EOF | sudo tee /etc/crio/crio.conf
registries = [
"docker.io"
]
EOF

sudo systemctl restart crio
echo ""
echo  "\033[4mCRI-O installed and configured.\033[0m"
echo ""
echo  "\033[4mSetting nameservers.\033[0m"
echo ""
sudo apt install resolvconf -y
sudo systemctl start resolvconf.service
sudo systemctl enable resolvconf.service
sudo cat <<EOF | sudo tee /etc/resolvconf/resolv.conf.d/head
nameserver 8.8.8.8
nameserver 8.8.4.4
EOF

sudo systemctl restart resolvconf.service
sudo systemctl restart systemd-resolved.service

echo ""
# Install kubelet, kubectl and Kubeadm
echo ""
echo  "\033[4mNOW, installing kubelet, kubectl and kubeadm.\033[0m"
echo ""
sudo apt-get install -y apt-transport-https ca-certificates curl
#sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
# 93 changed to line below
sudo curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add
sudo echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" > /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update -y
sudo apt-get install -y kubelet="$KUBERNETES_VERSION" kubectl="$KUBERNETES_VERSION" kubeadm="$KUBERNETES_VERSION"
sudo apt-mark hold kubelet kubeadm kubectl
# sudo apt-get update -y
sudo apt-get install -y jq

sudo local_ip="$(ip --json a s | jq -r '.[] | if .ifname == "eth1" then .addr_info[] | if .family == "inet" then .local else empty end else empty end')"
sudo cat > /etc/default/kubelet << EOF
KUBELET_EXTRA_ARGS=--node-ip=$local_ip
EOF

#setting IP in /etc/hosts and hostname" ####
sudo echo "10.0.1.100 manager" >> /etc/hosts
sudo echo "10.0.2.101 nodeone" >> /etc/hosts
sudo echo "10.0.2.102 nodetwo" >> /etc/hosts
sudo hostnamectl set-hostname nodeone



echo "===="
echo "Generate token on manager using"
echo "==="
echo "kubeadm token create --print-join-command"
echo ""
echo ""
echo "REBOOTING in 10 seconds"
sleep 10
reboot
