variable "rg_name" {
  description = "new RG"
  type        = string
  default     = "jannotf"
}

variable "rg_location" {
  description = "location of the new RG"
  type        = string
  default     = "northeurope"
}

variable "vm_name" {
  description = "name of the new VM"
  type        = string
  default     = "jannotf-ubuntu1"
}

variable "ssh_user" {
  description = "ssh user"
  type        = string
  default     = "azureuser"
}

variable "ssh_port" {
  description = "ssh port"
  type        = string
  default     = "22"
}

variable "ubuntu_minor_version" {
  description = "ubuntu 20.04 minor version"
  type        = string
  default     = "20.04.202110260"
}

