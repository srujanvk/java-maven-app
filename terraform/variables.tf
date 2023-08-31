variable vpc_cidr_block {
    default = "10.0.0.0/16"
}
variable subnet_cidr_block {
    default = "10.0.10.0/24"
}
variable avail_zone {
    default = "us-east-1a"
}
variable env_prefix {
    default = "dev"
}
variable instance_type {
    default = "t2.micro"
}

/*variable jenkins_ip {
    default = "137.184.15.251"
}*/

variable region {
    default = "us-east-1"
}