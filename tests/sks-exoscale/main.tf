module "cluster" {
  source = "../../modules/sks/exoscale"

  cluster_name = "devops-stack-example"
  zone         = "de-fra-1"
}
