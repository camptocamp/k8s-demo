module "cluster" {
  source = "../../../modules/cce/opentelekomcloud"

  cluster_name = "test"
  base_domain  = var.base_domain

  repo_url        = var.repo_url
  target_revision = var.target_revision

  subnet_id = var.subnet_id
  flavor_id = "cce.s2.small"
  vpc_id    = var.vpc_id

  node_pools = {
    "worker-01" = {
      flavor             = "s2.xlarge.2"
      initial_node_count = 1
      availability_zone  = "eu-de-01"
      key_pair           = var.key_pair
      postinstall        = var.postinstall
    },
    "worker-02" = {
      flavor             = "s2.xlarge.2"
      initial_node_count = 1
      availability_zone  = "eu-de-02"
      key_pair           = var.key_pair
      postinstall        = var.postinstall
    },
    "worker-03" = {
      flavor             = "s2.xlarge.2"
      initial_node_count = 1
      availability_zone  = "eu-de-03"
      key_pair           = var.key_pair
      postinstall        = var.postinstall
    },
  }
}
