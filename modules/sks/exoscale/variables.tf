variable "base_domain" {
  description = "The base domain used for Ingresses."
  type        = string
  default     = null
}

variable "kubernetes_version" {
  description = "Specify which Kubernetes release to use."
  type        = string
  default     = "1.20.7"
}

variable "zone" {
  description = "The name of the zone to deploy the SKS cluster into."
  type        = string
}

variable "nodepools" {
  description = "The SKS node pools to create."
  type        = map(any)
  default     = null
}

variable "router_nodepool" {
  description = "The node to attach the NLB to."
  type        = string
  default     = null
}
