


data "openstack_images_image_v2" "rhelcos" {
  name = "rhcos41"
  most_recent = true
}

data "openstack_images_image_v2" "centos" {
  name = "CentOS7"
  most_recent = true
}


data "openstack_networking_subnet_v2" "private" {
  name = "private-subnet"
}

data "openstack_networking_subnet_v2" "public" {
  name = "public-subnet"
}


resource "openstack_compute_servergroup_v2" "mysg" {
  name     = "ocpsg"
  policies = ["soft-anti-affinity"]
}

#


resource "openstack_compute_instance_v2" "bootstrap" {
  name = "bootstrap"
  user_data = "${file("${var.install-dir}/bootstrap-append.ign")}"
  flavor_name = "m1.large"
  key_pair = "${var.ssh_key_pair}"
  security_groups = ["${var.security_group}"]
  network {
    name = "${var.network}"
    fixed_ip_v4 = "192.168.122.30"
  }

  block_device {
    uuid                  = "${data.openstack_images_image_v2.rhelcos.id}"
    source_type           = "image"
    destination_type      = "volume"
    volume_size	          = 40
    boot_index            = 0
    delete_on_termination = true
  }
}


resource "openstack_compute_instance_v2" "ocpworkerVM" {
  name = "${element(var.nameworker, count.index)}"
  user_data = "${file("${var.install-dir}/worker.ign")}"
  flavor_name = "m1.large"
  key_pair = "${var.ssh_key_pair}"
  security_groups = ["${var.security_group}"]
  network {
    name = "${var.network}"
    fixed_ip_v4 = "${element(var.ipworker, count.index)}"
  }
  scheduler_hints {
    group = "${openstack_compute_servergroup_v2.mysg.id}"
  }
  block_device {
    uuid                  = "${data.openstack_images_image_v2.rhelcos.id}"
    source_type           = "image"
    destination_type      = "volume"
    volume_size           = 60
    boot_index            = 0
    delete_on_termination = true
  }

  block_device {
    source_type           = "blank"
    destination_type      = "volume"
    volume_size           = 6
    boot_index            = 1
    delete_on_termination = true
  }
  #block_device {
  #  source_type           = "blank"
  #  destination_type      = "volume"
  #  volume_size           = 10
  #  boot_index            = 2
  #  delete_on_termination = true
  #}


  #user_data     = "${data.template_file.script.rendered}\nhostname: ${element(var.name, count.index)}\nfqdn: ${element(var.name, count.index)}.lab.local"

  count = "${length(var.nameworker)}"
}
output "node" {
 value = "${openstack_compute_instance_v2.ocpworkerVM.*.network.0.fixed_ip_v4}"
}
resource "openstack_compute_instance_v2" "ocpmasterVM" {
  name = "${element(var.namemaster, count.index)}"
  user_data = "${file("${var.install-dir}/master.ign")}"
  flavor_name = "m1.large"
  key_pair = "${var.ssh_key_pair}"
  security_groups = ["${var.security_group}"]
  network {
    name = "${var.network}"
    fixed_ip_v4 = "${element(var.ipmaster, count.index)}"
  }
  scheduler_hints {
    group = "${openstack_compute_servergroup_v2.mysg.id}"
  }
  block_device {
    uuid                  = "${data.openstack_images_image_v2.rhelcos.id}"
    source_type           = "image"
    destination_type      = "volume"
    volume_size           = 60
    boot_index            = 0
    delete_on_termination = true
  }

  block_device {
    source_type           = "blank"
    destination_type      = "volume"
    volume_size           = 6
    boot_index            = 1
    delete_on_termination = true
  }
  #block_device {
  #  source_type           = "blank"
  #  destination_type      = "volume"
  #  volume_size           = 10
  #  boot_index            = 2
  #  delete_on_termination = true
  #}


  #user_data     = "${data.template_file.script.rendered}\nhostname: ${element(var.name, count.index)}\nfqdn: ${element(var.name, count.index)}.lab.local"

  count = "${length(var.namemaster)}"
}
