#########
######### Define providers 
#########
provider "ovc" {
    server_url = "${var.g8_1_url}"
    client_jwt = "${var.client_jwt}"
    alias = "site_1"
}
provider "ovc" {
    server_url = "${var.g8_2_url}"
    client_jwt = "${var.client_jwt}"
    alias = "site_2"
}
provider "ovc" {
    server_url = "${var.g8_3_url}"
    client_jwt = "${var.client_jwt}"
    alias = "site_3"
}

#########
######### Deploy cloudspaces
#########
resource "ovc_cloudspace" "cs_site_1" {
  account = "${var.g8_1_account}"
  name = "${var.cluster_name}_site_1"
  provider = "ovc.site_1"
  private_network = "192.168.103.0/24"
}
data "ovc_cloudspace" "cs_site_1" {
  provider = "ovc.site_1"
  account = "${var.g8_1_account}"
  name = "${var.cluster_name}_site_1"
  depends_on = ["ovc_cloudspace.cs_site_1"]
}
resource "ovc_cloudspace" "cs_site_2" {
  account = "${var.g8_2_account}"
  name = "${var.cluster_name}_site_2"
  provider = "ovc.site_2"
  private_network = "192.168.104.0/24"
}
data "ovc_cloudspace" "cs_site_2" {
  provider = "ovc.site_2"
  account = "${var.g8_2_account}"
  name = "${var.cluster_name}_site_2"
  depends_on = ["ovc_cloudspace.cs_site_2"]
}
resource "ovc_cloudspace" "cs_site_3" {
  account = "${var.g8_3_account}"
  name = "${var.cluster_name}_site_3"
  provider = "ovc.site_3"
  private_network = "192.168.105.0/24"
}
data "ovc_cloudspace" "cs_site_3" {
  provider = "ovc.site_3"
  account = "${var.g8_3_account}"
  name = "${var.cluster_name}_site_3"
  depends_on = ["ovc_cloudspace.cs_site_3"]
}

#########
######### Deploy ipsec tunnels between cloudspaces
#########
resource "ovc_ipsec" "tunnel_site_1_to_site_2" {
  provider = "ovc.site_1"
  cloudspace_id = "${ovc_cloudspace.cs_site_1.id}"
  remote_public_ip = "${data.ovc_cloudspace.cs_site_2.external_network_ip}"
  remote_private_network = "${data.ovc_cloudspace.cs_site_2.private_network}"
  depends_on = ["ovc_cloudspace.cs_site_1", "ovc_cloudspace.cs_site_2"]
}
resource "ovc_ipsec" "tunnel_site_2_to_site_1" {
  provider = "ovc.site_2"
  cloudspace_id = "${ovc_cloudspace.cs_site_2.id}"
  remote_public_ip = "${data.ovc_cloudspace.cs_site_1.external_network_ip}"
  remote_private_network = "${data.ovc_cloudspace.cs_site_1.private_network}"
  psk = "${ovc_ipsec.tunnel_site_1_to_site_2.psk}"
  depends_on = ["ovc_cloudspace.cs_site_1", "ovc_cloudspace.cs_site_2"]
}
resource "ovc_ipsec" "tunnel_site_1_to_site_3" {
  provider = "ovc.site_1"
  cloudspace_id = "${ovc_cloudspace.cs_site_1.id}"
  remote_public_ip = "${data.ovc_cloudspace.cs_site_3.external_network_ip}"
  remote_private_network = "${data.ovc_cloudspace.cs_site_3.private_network}"
  depends_on = ["ovc_cloudspace.cs_site_1", "ovc_cloudspace.cs_site_3"]
}
resource "ovc_ipsec" "tunnel_site_3_to_site_1" {
  provider = "ovc.site_3"
  cloudspace_id = "${ovc_cloudspace.cs_site_3.id}"
  remote_public_ip = "${data.ovc_cloudspace.cs_site_1.external_network_ip}"
  remote_private_network = "${data.ovc_cloudspace.cs_site_1.private_network}"
  psk = "${ovc_ipsec.tunnel_site_1_to_site_3.psk}"
  depends_on = ["ovc_cloudspace.cs_site_1", "ovc_cloudspace.cs_site_3"]
}
resource "ovc_ipsec" "tunnel_site_2_to_site_3" {
  provider = "ovc.site_2"
  cloudspace_id = "${ovc_cloudspace.cs_site_2.id}"
  remote_public_ip = "${data.ovc_cloudspace.cs_site_3.external_network_ip}"
  remote_private_network = "${data.ovc_cloudspace.cs_site_3.private_network}"
  depends_on = ["ovc_cloudspace.cs_site_2", "ovc_cloudspace.cs_site_3"]
}
resource "ovc_ipsec" "tunnel_site_3_to_site_2" {
  provider = "ovc.site_3"
  cloudspace_id = "${ovc_cloudspace.cs_site_3.id}"
  remote_public_ip = "${data.ovc_cloudspace.cs_site_2.external_network_ip}"
  remote_private_network = "${data.ovc_cloudspace.cs_site_2.private_network}"
  psk = "${ovc_ipsec.tunnel_site_2_to_site_3.psk}"
  depends_on = ["ovc_cloudspace.cs_site_3", "ovc_cloudspace.cs_site_2"]
}

#########
######### Define references to virtual machine images in each of the sites
#########
data "ovc_image" "ubuntu_site_1"{
  provider = "ovc.site_1"
  most_recent = true
  name_regex = "${var.image_name}"
}
data "ovc_image" "ubuntu_site_2"{
  provider = "ovc.site_2"
  most_recent = true
  name_regex = "${var.image_name}"
}
data "ovc_image" "ubuntu_site_3"{
  provider = "ovc.site_3"
  most_recent = true
  name_regex = "${var.image_name}"
}

#########
######### Deploy a management virtual machine in site 1 that will be used as bastion host for ansible
#########
resource "ovc_machine" "mgt" {
  provider = "ovc.site_1"
  cloudspace_id = "${ovc_cloudspace.cs_site_1.id}"
  image_id      = "${data.ovc_image.ubuntu_site_1.image_id}"
  memory        = "512"
  vcpus         = "1"
  disksize      = "20"
  name          = "mgt-station"
  description   = "management node"
  userdata      = "users: [{name: ansible, shell: /bin/bash, ssh_authorized_keys: [${var.ssh_key}]}, {name: root, shell: /bin/bash, ssh_authorized_keys: [${var.ssh_key}]}]"
}
output "kube_mgt" {
  value       = "${ovc_port_forwarding.mgt_ssh.public_ip}"
}
resource "ovc_port_forwarding" "mgt_ssh" {
  count = 1
  provider = "ovc.site_1"
  cloudspace_id = "${ovc_cloudspace.cs_site_1.id}"
  public_ip     = "${ovc_cloudspace.cs_site_1.external_network_ip}"
  public_port   = 2222
  machine_id    = "${ovc_machine.mgt.id}"
  local_port    = 22
  protocol      = "tcp"
  depends_on    = ["ovc_cloudspace.cs_site_1"]
}
resource "null_resource" "provision_local" {
  # Ensure connectivity on the management node
  provisioner "remote-exec"{
    inline = ["echo"]
  }
  provisioner "local-exec" {
    command = "ssh-keygen -R [${ovc_port_forwarding.mgt_ssh.public_ip}]:${ovc_port_forwarding.mgt_ssh.public_port} || true"
  }
  provisioner "local-exec" {
    command = "ssh-keyscan -H -p ${ovc_port_forwarding.mgt_ssh.public_port} ${ovc_port_forwarding.mgt_ssh.public_ip} >> ~/.ssh/known_hosts"
  }
  connection {
    type     = "ssh"
    user     = "ansible"
    host     = "${ovc_port_forwarding.mgt_ssh.public_ip}"
    port     = "${ovc_port_forwarding.mgt_ssh.public_port}"
  }
  depends_on = ["ovc_port_forwarding.mgt_ssh"]
}
resource "null_resource" "provision_mgt" {
  # Configure ansible access on master nodes
  provisioner "file" {
    content      = "ansible    ALL=(ALL:ALL) NOPASSWD: ALL"
    destination = "/etc/sudoers.d/90_ansible"
  }
  connection {
    type     = "ssh"
    user     = "root"
    host     = "${ovc_port_forwarding.mgt_ssh.public_ip}"
    port     = "${ovc_port_forwarding.mgt_ssh.public_port}"
  }
  depends_on    = ["ovc_machine.mgt", "null_resource.provision_local", "null_resource.wait_for_network"]
}

#########
######### Deploy mongo host virtual machines in the cloudspaces
#########
resource "ovc_machine" "mongo_site_1" {
  provider      = "ovc.site_1"
  cloudspace_id = "${ovc_cloudspace.cs_site_1.id}"
  image_id      = "${data.ovc_image.ubuntu_site_1.image_id}"
  memory        = "${var.mongo_memory}"
  vcpus         = "${var.mongo_vcpus}"
  disksize      = "${var.mongo_boot_disk_size}"
  name          = "mongo-site-1"
  description   = "MongoDB server in site 1"
  userdata      = "users: [{name: ansible, shell: /bin/bash, ssh_authorized_keys: [${var.ssh_key}]}, {name: root, shell: /bin/bash, ssh_authorized_keys: [${var.ssh_key}]}]"
  depends_on    = ["ovc_cloudspace.cs_site_1"]
}
resource "ovc_machine" "mongo_site_2" {
  provider      = "ovc.site_2"
  cloudspace_id = "${ovc_cloudspace.cs_site_2.id}"
  image_id      = "${data.ovc_image.ubuntu_site_2.image_id}"
  memory        = "${var.mongo_memory}"
  vcpus         = "${var.mongo_vcpus}"
  disksize      = "${var.mongo_boot_disk_size}"
  name          = "mongo-site-2"
  description   = "MongoDB server in site 2"
  userdata      = "users: [{name: ansible, shell: /bin/bash, ssh_authorized_keys: [${var.ssh_key}]}, {name: root, shell: /bin/bash, ssh_authorized_keys: [${var.ssh_key}]}]"
  depends_on    = ["ovc_cloudspace.cs_site_2"]
}
resource "ovc_machine" "mongo_site_3" {
  provider      = "ovc.site_3"
  cloudspace_id = "${ovc_cloudspace.cs_site_3.id}"
  image_id      = "${data.ovc_image.ubuntu_site_3.image_id}"
  memory        = "${var.mongo_memory}"
  vcpus         = "${var.mongo_vcpus}"
  disksize      = "${var.mongo_boot_disk_size}"
  name          = "mongo-site-3"
  description   = "MongoDB server in site 3"
  userdata      = "users: [{name: ansible, shell: /bin/bash, ssh_authorized_keys: [${var.ssh_key}]}, {name: root, shell: /bin/bash, ssh_authorized_keys: [${var.ssh_key}]}]"
  depends_on    = ["ovc_cloudspace.cs_site_3"]
}
resource "ovc_disk" "mongo_disk_site_1" {
  provider      = "ovc.site_1"
  machine_id    = "${ovc_machine.mongo_site_1.id}"
  disk_name     = "data_mongo_${ovc_cloudspace.cs_site_1.location}"
  description   = "Disk created by terraform"
  size          = "${var.mongo_data_disk_size}"
  type          = "D"
  iops          = "${var.mongo_iops}"
  depends_on    = ["ovc_machine.mongo_site_1"]
}
resource "ovc_disk" "mongo_disk_site_2" {
  provider      = "ovc.site_2"
  machine_id    = "${ovc_machine.mongo_site_2.id}"
  disk_name     = "data_mongo_${ovc_cloudspace.cs_site_2.location}"
  description   = "Disk created by terraform"
  size          = "${var.mongo_data_disk_size}"
  type          = "D"
  iops          = "${var.mongo_iops}"
  depends_on    = ["ovc_machine.mongo_site_2"]
}
resource "ovc_disk" "mongo_disk_site_3" {
  provider      = "ovc.site_3"
  machine_id    = "${ovc_machine.mongo_site_3.id}"
  disk_name     = "data_mongo_${ovc_cloudspace.cs_site_3.location}"
  description   = "Disk created by terraform"
  size          = "${var.mongo_data_disk_size}"
  type          = "D"
  iops          = "${var.mongo_iops}"
  depends_on    = ["ovc_machine.mongo_site_3"]
}

#########
######### Wait until the ipsec bridges are working
#########
resource "null_resource" "wait_for_network" {
  provisioner "remote-exec"{
    inline = ["while :; do if ! ping -c 1 ${ovc_machine.mongo_site_1.ip_address}; then continue; fi; if ! ping -c 1 ${ovc_machine.mongo_site_1.ip_address}; then continue; fi; if ! ping -c 1 ${ovc_machine.mongo_site_1.ip_address}; then continue; fi; break; done"]
  }
  connection {
    type     = "ssh"
    user     = "ansible"
    host     = "${ovc_port_forwarding.mgt_ssh.public_ip}"
    port     = "${ovc_port_forwarding.mgt_ssh.public_port}"
  }
  depends_on    = ["null_resource.provision_local"]
}

#########
######### Configure ansible user access on worker nodes & move /var to /dev/vdb
#########
resource "null_resource" "provision_mongo_site_1" {
  provisioner "file" {
    content     = "ansible    ALL=(ALL:ALL) NOPASSWD: ALL"
    destination = "/etc/sudoers.d/90_ansible"
  }
  depends_on    = ["ovc_disk.mongo_disk_site_1", "null_resource.provision_local", "null_resource.wait_for_network"]
  provisioner "remote-exec" {
    inline = [
      "mkdir -p /home/ansible/scripts",
      "cd /home/ansible/scripts && curl -O https://raw.githubusercontent.com/gig-tech/tutorial-help-scripts/master/kubernetes-cluster-deployment/move-var.sh",
      "sudo -S bash /home/ansible/scripts/move-var.sh",
    ]
  }
  connection {
    type     = "ssh"
    user     = "root"
    host     = "${ovc_machine.mongo_site_1.ip_address}"
    bastion_user     = "ansible"
    bastion_host     = "${ovc_port_forwarding.mgt_ssh.public_ip}"
    bastion_port     = "${ovc_port_forwarding.mgt_ssh.public_port}"
  }
}
resource "null_resource" "provision_mongo_site_2" {
  provisioner "file" {
    content      = "ansible    ALL=(ALL:ALL) NOPASSWD: ALL"
    destination = "/etc/sudoers.d/90_ansible"
  }
  depends_on    = ["ovc_disk.mongo_disk_site_2", "null_resource.provision_local", "null_resource.wait_for_network"]
  provisioner "remote-exec" {
    inline = [
      "mkdir -p /home/ansible/scripts",
      "cd /home/ansible/scripts && curl -O https://raw.githubusercontent.com/gig-tech/tutorial-help-scripts/master/kubernetes-cluster-deployment/move-var.sh",
      "sudo -S bash /home/ansible/scripts/move-var.sh",
    ]
  }
  connection {
    type     = "ssh"
    user     = "root"
    host     = "${ovc_machine.mongo_site_2.ip_address}"
    bastion_user     = "ansible"
    bastion_host     = "${ovc_port_forwarding.mgt_ssh.public_ip}"
    bastion_port     = "${ovc_port_forwarding.mgt_ssh.public_port}"
  }
}
resource "null_resource" "provision_mongo_site_3" {
  provisioner "file" {
    content      = "ansible    ALL=(ALL:ALL) NOPASSWD: ALL"
    destination = "/etc/sudoers.d/90_ansible"
  }
  depends_on    = ["ovc_disk.mongo_disk_site_3", "null_resource.provision_local", "null_resource.wait_for_network"]
  provisioner "remote-exec" {
    inline = [
      "mkdir -p /home/ansible/scripts",
      "cd /home/ansible/scripts && curl -O https://raw.githubusercontent.com/gig-tech/tutorial-help-scripts/master/kubernetes-cluster-deployment/move-var.sh",
      "sudo -S bash /home/ansible/scripts/move-var.sh",
    ]
  }
  connection {
    type     = "ssh"
    user     = "root"
    host     = "${ovc_machine.mongo_site_3.ip_address}"
    bastion_user     = "ansible"
    bastion_host     = "${ovc_port_forwarding.mgt_ssh.public_ip}"
    bastion_port     = "${ovc_port_forwarding.mgt_ssh.public_port}"
  }
}

#########
######### Generate ansible inventory
#########
resource "ansible_group" "mgt" {
  inventory_group_name = "mgt"
}
resource "ansible_group" "mongo-hosts" {
  inventory_group_name = "mongo-hosts"
  vars {
    ansible_ssh_common_args="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ProxyCommand='ssh -W %h:%p -p ${ovc_port_forwarding.mgt_ssh.public_port} -q ansible@${ovc_port_forwarding.mgt_ssh.public_ip}'"
  }
}
resource "ansible_host" "kube-mgt" {
    inventory_hostname = "${ovc_machine.mgt.name}"
    groups = ["${ansible_group.mgt.inventory_group_name}"]
    vars {
        ansible_user = "ansible"
        ansible_host = "${ovc_port_forwarding.mgt_ssh.public_ip}"
        ansible_port = "${ovc_port_forwarding.mgt_ssh.public_port}"
        ansible_python_interpreter = "/usr/bin/python3"
    }
}
resource "ansible_host" "kube_mongo_site_1" {
    groups = ["${ansible_group.mongo-hosts.inventory_group_name}"]
    inventory_hostname = "${ovc_machine.mongo_site_1.name}"
    vars {
        ansible_user = "ansible"
        ansible_host = "${ovc_machine.mongo_site_1.ip_address}"
        ansible_python_interpreter = "/usr/bin/python3"
    }
    depends_on = ["ovc_machine.mongo_site_1"]
}
resource "ansible_host" "kube_mongo_site_2" {
    groups = ["${ansible_group.mongo-hosts.inventory_group_name}"]
    inventory_hostname = "${ovc_machine.mongo_site_2.name}"
    vars {
        ansible_user = "ansible"
        ansible_host = "${ovc_machine.mongo_site_2.ip_address}"
        ansible_python_interpreter = "/usr/bin/python3"
    }
    depends_on = ["ovc_machine.mongo_site_2"]
}
resource "ansible_host" "kube_mongo_site_3" {
    groups = ["${ansible_group.mongo-hosts.inventory_group_name}"]
    inventory_hostname = "${ovc_machine.mongo_site_3.name}"
    vars {
        ansible_user = "ansible"
        ansible_host = "${ovc_machine.mongo_site_3.ip_address}"
        ansible_python_interpreter = "/usr/bin/python3"
    }
    depends_on = ["ovc_machine.mongo_site_3"]
}
