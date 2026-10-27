variable "port" {
  type    = number
  default = 2222
}

module "users" {
  source = "../.."

  hosts                = { box = "127.0.0.1" }
  ssh_port             = var.port
  ssh_private_key_file = "./id_ed25519"
  ssh_known_hosts_file = "./known_hosts"

  users = {
    # alice logs in with the key up.sh made, and has passwordless sudo.
    # The check lets conn3x validate run before up.sh has made the key.
    alice = {
      groups = ["developers"]
      keys   = fileexists("./id_ed25519.pub") ? [file("./id_ed25519.pub")] : []
      sudo   = true
    }
    bob = {
      shell = "/bin/sh"
    }
  }
}
