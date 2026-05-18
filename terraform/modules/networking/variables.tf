variable "project_id" { 
    type = string 
}
variable "region" { 
type = string  
default = "us-central1" 
}
# Node IPs: /24 = 254 IPs (enough for nodes)
variable "subnet_cidr" { 
type = string  
default = "10.10.0.0/24" 
}
# Pod IPs:  /16 = 65534 IPs (many pods per node so needs large range)
variable "pods_cidr" { 
type = string 
default = "10.20.0.0/16" 
}
# Svc IPs:  /16 = 65534 IPs (each K8s Service gets a ClusterIP)
variable "services_cidr" { 
type = string  
default = "10.30.0.0/16" 
}