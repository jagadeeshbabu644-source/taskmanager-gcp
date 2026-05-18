variable "project_id" { 
type = string 
}
variable "cluster_name" { 
type = string  
default = "taskmanager-cluster" 
}
variable "zone" { 
type = string  
default = "us-central1-a" 
}
variable "vpc_id" { 
type = string 
}
variable "subnet_id" { 
type = string 
}
variable "node_count" { 
type = number  
default = 1 
}
variable "max_nodes" { 
type = number  
default = 3 
}
variable "machine_type" { 
type = string  
default = "e2-medium" 
}
variable "environment" { 
type = string  
default = "prod" 
}
