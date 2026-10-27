locals {
  groups = toset(flatten([for u in var.users : coalesce(u.groups, [])]))

  # Keys are keyed by user and a hash of the key, so reordering a list
  # changes nothing on the host.
  keys = merge([
    for name, u in var.users : {
      for k in u.keys : "${name}:${substr(sha256(trimspace(k)), 0, 12)}" => { user = name, key = trimspace(k) }
    }
  ]...)

  sudoers = toset([for name, u in var.users : name if u.sudo])
}

circuit "users" {
  hosts = var.hosts

  ssh {
    user             = var.ssh_user
    port             = var.ssh_port
    private_key_file = var.ssh_private_key_file
    known_hosts_file = var.ssh_known_hosts_file
    become           = var.ssh_become
  }

  step "group" {
    for_each = local.groups
    group {
      name = item.value
    }
  }

  step "account" {
    for_each = var.users
    user {
      name   = item.key
      uid    = item.value.uid
      shell  = item.value.shell
      home   = item.value.home
      groups = item.value.groups
    }
  }

  step "key" {
    for_each = local.keys
    authorized_key {
      user = item.value.user
      key  = item.value.key
    }
  }

  step "sudo_package" {
    for_each = length(local.sudoers) > 0 ? { sudo = true } : {}
    package {
      name = "sudo"
    }
  }

  # One drop-in per user, removed again when sudo is turned off. The content
  # is built only from names the users variable has already checked, so it
  # can't be a sudoers syntax error.
  step "sudoers" {
    for_each = local.sudoers
    file {
      path      = "/etc/sudoers.d/${item.value}"
      content   = "${item.value} ALL=(ALL) NOPASSWD: ALL\n"
      mode      = "0440"
      owner     = "root"
      group     = "root"
      on_remove = "delete"
    }
  }
}
