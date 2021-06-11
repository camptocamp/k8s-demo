variable "template_id" {
  description = "The ID of the Compute template to use."
  type        = string
}

variable "base_domain" {
  description = "The base domain used for Ingresses."
  type        = string
}

variable "zone" {
  description = "The name of the zone to deploy the cluster into."
  type        = string
}

variable "bootstrap" {
  description = "Wheter in bootstrap mode or not."
  type        = bool
}

variable "pull_secret" {
  description = "The secret used to pull images."
  type        = string
}

variable "ssh_key" {
  description = "The SSH public key to deploy on instances."
  type        = string
}

variable "worker_groups" {
  description = "The worker groups to create."
  type        = map(any)
}
