variable "k3os_version" {
  description = "The K3os version to use"
  type        = string
  default     = "v0.20.6-k3s1r0"
}

variable "server_memory" {
  description = "Server RAM"
  type        = number
  default     = 2048
}

variable "agent_memory" {
  description = "Agent RAM"
  type        = number
  default     = 2048
}
