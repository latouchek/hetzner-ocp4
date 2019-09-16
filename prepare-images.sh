####prepare bastion's image####
wget https://download.fedoraproject.org/pub/fedora/linux/releases/30/Cloud/x86_64/images/Fedora-Cloud-Base-30-1.2.x86_64.qcow2 -O f30.qcow2

##create preseed script###
cat << EOF > preseed-fedora.sh
sed -i 's/[#]*PasswordAuthentication yes/PasswordAuthentication yes/g' /etc/ssh/sshd_config
sed -i 's/PermitRootLogin no/PermitRootLogin yes/g' /etc/ssh/sshd_config
sed -i 's/^#   StrictHostKeyChecking ask/StrictHostKeyChecking no/g' /etc/ssh/ssh_config
echo "UserKnownHostsFile=/dev/null" | sudo tee -a /etc/ssh/ssh_config > /dev/null
sed -i 's/#UseDNS yes/UseDNS no/g' /etc/ssh/sshd_config
dnf install python3-pyOpenSSL python3-openstackclient socat tmux wget  bash-completion git net-tools bind-utils bind  ansible httpd-tools podman jq  -y
mkdir -p /opt/registry/{auth,certs,data}
dnf update -y
EOF
###apply preseed to image###
export LIBGUESTFS_DEBUG=1 LIBGUESTFS_TRACE=1
sudo virt-customize -a f30.qcow2 --run preseed-fedora.sh --selinux-relabel

#### convert image to raw format ###
qemu-img convert -f qcow2 -O raw  f30.qcow2  f30.raw
####Create glance image based on new generated raw image####
openstack image create --public --disk-format raw --container-format bare --file f30.raw f30

####grab last rhcos openstack imagge###


openstack image create --public --disk-format raw --container-format bare --file rhcos42.raw rhcos42
