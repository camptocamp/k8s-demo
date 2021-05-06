variable "base_domain" {
  description = "The base domain used for Ingresses."
  type        = string
}

variable "flavor_id" {
  description = "Cluster specifications."
  type        = string
}

variable "vpc_id" {
  description = "The ID of the VPC used to create the node."
  type        = string
}

variable "subnet_id" {
  description = "The Network ID of the subnet used to create the node."
  type        = string
}

variable "cluster_version" {
  description = "The K8s version to use."
  type        = string
  default     = "v1.19.8-r0"
}

variable "node_pools" {
  description = "Map of map of node pools to create."
  type        = map(map(any))
  default     = {}
}
