variable "host_os" {
  type    = string
  default = "windows"
}

variable "location" {
  type    = string
  default = "uksouth"
}

variable "DefaultName" {
  type    = string
  default = "DanH"
}

variable "Environment" {
  type    = string
  default = "Dev"
}

variable "network" {
  type    = list(any)
  default = ["10.0.0.0/23"]
}
variable "subnet-1" {
  type    = list(any)
  default = ["10.0.0.0/24"]
}
variable "subnet-2" {
  type    = list(any)
  default = ["10.0.1.0/24"]
}

variable "AdminUser" {
  type    = string
  sensitive = true
}

variable "PublicKeyFN" {
  type = string
  sensitive = true
}
variable "VM-Size-1" {
  type    = string
  default = "Standard_B1s"
}
