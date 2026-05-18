include "root" { 
path = find_in_parent_folders() 
}
terraform { 
source = "../../../modules/gke" 
}
dependency "networking" {
  config_path = "../networking"
  mock_outputs = {
    vpc_id    = "mock-vpc-id"
    subnet_id = "mock-subnet-id"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}
inputs = {
  cluster_name = "taskmanager-cluster"
  vpc_id       = dependency.networking.outputs.vpc_id
  subnet_id    = dependency.networking.outputs.subnet_id
  node_count   = 1
  max_nodes    = 3
  machine_type = "e2-medium"
}
