variable "hosts" {
  type        = any
  description = "The hosts to configure: a map of names to addresses, or to host objects with an address and settings such as host_key."

  validation {
    condition     = can(keys(var.hosts)) && alltrue([for v in values(var.hosts) : can(tostring(v)) || can(tostring(v.address))])
    error_message = "hosts must be a map whose values are addresses, or objects with an address."
  }
}

variable "ssh_user" {
  type        = string
  default     = "root"
  description = "The user to log in as."
}

variable "ssh_port" {
  type        = number
  default     = 22
  description = "The SSH port."
}

variable "ssh_private_key_file" {
  type        = string
  default     = null
  description = "Path to a private key file. When null, Conn3x uses the SSH agent."
}

variable "ssh_known_hosts_file" {
  type        = string
  default     = null
  description = "The known_hosts file to check host keys against. When null, Conn3x uses ~/.ssh/known_hosts."
}

variable "ssh_become" {
  type        = bool
  default     = false
  description = "Run every command as root through sudo. Set this when ssh_user isn't root."
}

variable "users" {
  type = map(object({
    uid    = optional(number)
    shell  = optional(string, "/bin/bash")
    home   = optional(string)
    groups = optional(list(string))
    keys   = optional(list(string), [])
    sudo   = optional(bool, false)
  }))
  description = "The accounts to manage, keyed by login name."

  validation {
    condition     = length(var.users) > 0
    error_message = "users must name at least one account."
  }

  validation {
    condition = alltrue([
      for name, u in var.users :
      can(regex("^[a-z_][a-z0-9_-]{0,31}$", name)) && alltrue([for g in coalesce(u.groups, []) : can(regex("^[a-z_][a-z0-9_-]{0,31}$", g))])
    ])
    error_message = "User and group names start with a lowercase letter or _, followed by up to 31 lowercase letters, digits, - or _."
  }
}
