include "root" { 
path = find_in_parent_folders() 
}
terraform { 
source = "../../../modules/networking" 
}
inputs = {
  subnet_cidr   = "10.10.0.0/24"
  pods_cidr     = "10.20.0.0/16"
  services_cidr = "10.30.0.0/16"
}
