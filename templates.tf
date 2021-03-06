#
# DEFAULT INSTANCES TEMPLATES
#
resource "template_file" "puppetca" {
  template               = "${file("cloudinit/default.yml")}"

  vars {
    hostname             = "${var.vdc}-puppetca01"
    domain               = "${var.domain}"
    puppet_agent_version = "${var.puppet_agent_version}"
  }
}

resource "template_file" "puppetdb" {
  template               = "${file("cloudinit/default.yml")}"
  count                  = "${length( split( ",", lookup( var.azs, var.region ) ) )}"

  vars {
    hostname             = "${var.vdc}-puppetdb0${count.index+1}"
    domain               = "${var.domain}"
    puppet_agent_version = "${var.puppet_agent_version}"
  }
}

resource "template_file" "jump" {
  template               = "${file("cloudinit/default.yml")}"

  vars {
    hostname             = "${var.vdc}-jump01"
    domain               = "${var.domain}"
    puppet_agent_version = "${var.puppet_agent_version}"
  }
}

#
# PUPPET RELATED TEMPLATES
#
resource "template_file" "server" {
  template                 = "${file("cloudinit/server.bash")}"

  vars {
    git_api_token          = "${var.git_api_token}"
    git_control_project    = "${var.git_control_project}"
    git_encryption_project = "${var.git_encryption_project}"
    git_hostname           = "${var.git_hostname}"
    git_port               = "${var.git_port}"
    git_provider           = "${var.git_provider}"
    git_user               = "${var.git_user}"
    hiera_eyaml_version    = "${var.hiera_eyaml_version}"
    hiera_file_path        = "${var.hiera_file_path}"
    pm_gms_version         = "${var.pm_gms_version}"
    pm_lvm_version         = "${var.pm_lvm_version}"
    pm_r10k_version        = "${var.pm_r10k_version}"
    r10k_version           = "${var.r10k_version}"
    site_file_path         = "${var.site_file_path}"
    encryption_environment = "${var.encryption_environment}"
    control_environment    = "${var.control_environment}"
  }
}

resource "template_file" "agent" {
  template              = "${file("cloudinit/agent.bash")}"

  vars {
    server_name         = "${var.vdc}-puppetca01.${var.domain}"
    control_environment = "${var.control_environment}"
  }
}

#
# AGGREGATED CLOUDINIT TEMPLATES
#
resource "template_cloudinit_config" "puppetca" {
  gzip           = false
  base64_encode  = false

  part {
    content_type = "text/cloud-config"
    content      = "${template_file.puppetca.rendered}"
  }

  part {
    content_type = "text/x-shellscript"
    content      = "${template_file.server.rendered}"
  }
}

resource "template_cloudinit_config" "puppetdb" {
  gzip           = false
  base64_encode  = false

  count          = "${length( split( ",", lookup( var.azs, var.region ) ) )}"

  part {
    content_type = "text/cloud-config"
    content      = "${element(template_file.puppetdb.*.rendered, count.index)}"
  }

  part {
    content_type = "text/x-shellscript"
    content      = "${template_file.agent.rendered}"
  }
}

resource "template_cloudinit_config" "jump" {
  gzip           = false
  base64_encode  = false

  part {
    content_type = "text/cloud-config"
    content      = "${template_file.jump.rendered}"
  }

  part {
    content_type = "text/x-shellscript"
    content      = "${template_file.agent.rendered}"
  }
}
