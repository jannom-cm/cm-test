# Configure the Microsoft Azure Provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>2.0"
    }
    random = {
      source  = "registry.terraform.io/hashicorp/random"
      version = "~>2.0"
    }
  }
}
provider "azurerm" {
  features {}
}

# Create a resource group if it doesn't exist
resource "azurerm_resource_group" "myterraformgroup" {
  name     = var.rg_name
  location = var.rg_location

  tags = {
    environment = "Terraform Demo"
  }
}

# Create virtual network
resource "azurerm_virtual_network" "myterraformnetwork" {
  name                = format("%s-%s", var.vm_name, "Vnet")
  address_space       = ["10.0.0.0/16"]
  location            = var.rg_location
  resource_group_name = azurerm_resource_group.myterraformgroup.name

  tags = {
    environment = "Terraform Demo"
  }
}

# Create subnet
resource "azurerm_subnet" "myterraformsubnet" {
  name                 = format("%s-%s", var.vm_name, "Subnet")
  resource_group_name  = azurerm_resource_group.myterraformgroup.name
  virtual_network_name = azurerm_virtual_network.myterraformnetwork.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Create public IPs
resource "azurerm_public_ip" "myterraformpublicip" {
  name                = format("%s-%s", var.vm_name, "PublicIP")
  location            = var.rg_location
  resource_group_name = azurerm_resource_group.myterraformgroup.name
  allocation_method   = "Dynamic"

  tags = {
    environment = "Terraform Demo"
  }
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "myterraformnsg" {
  name                = format("%s-%s", var.vm_name, "SecurityGroup")
  location            = var.rg_location
  resource_group_name = azurerm_resource_group.myterraformgroup.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "prometheus"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "9090"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "grafana"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3000"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    environment = "Terraform Demo"
  }
}

# Create network interface
resource "azurerm_network_interface" "myterraformnic" {
  name                = format("%s-%s", var.vm_name, "NIC")
  location            = var.rg_location
  resource_group_name = azurerm_resource_group.myterraformgroup.name

  ip_configuration {
    name                          = format("%s-%s", var.vm_name, "NicConfiguration")
    subnet_id                     = azurerm_subnet.myterraformsubnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.myterraformpublicip.id
  }

  tags = {
    environment = "Terraform Demo"
  }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "example" {
  network_interface_id      = azurerm_network_interface.myterraformnic.id
  network_security_group_id = azurerm_network_security_group.myterraformnsg.id
}

# Generate random text for a unique storage account name
resource "random_id" "randomId" {
  keepers = {
    # Generate a new ID only when a new resource group is defined
    resource_group = azurerm_resource_group.myterraformgroup.name
  }

  byte_length = 8
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "mystorageaccount" {
  name                     = "diag${random_id.randomId.hex}"
  resource_group_name      = azurerm_resource_group.myterraformgroup.name
  location                 = var.rg_location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = {
    environment = "Terraform Demo"
  }
}

# Create (and display) an SSH key
resource "tls_private_key" "example_ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}
output "tls_private_key" {
  value     = tls_private_key.example_ssh.private_key_pem
  sensitive = true
}

# Create virtual machine
resource "azurerm_linux_virtual_machine" "myterraformvm" {
  name                  = var.vm_name
  location              = var.rg_location
  resource_group_name   = azurerm_resource_group.myterraformgroup.name
  network_interface_ids = [azurerm_network_interface.myterraformnic.id]
  size                  = "Standard_DS1_v2"

  os_disk {
    name                 = format("%s-%s", var.vm_name, "OsDisk")
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts-gen2"
    version   = var.ubuntu_minor_version
  }

  computer_name                   = format("%s-%s", var.vm_name, "vm")
  admin_username                  = "azureuser"
  disable_password_authentication = true

  admin_ssh_key {
    username   = "azureuser"
    public_key = tls_private_key.example_ssh.public_key_openssh
  }

  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.mystorageaccount.primary_blob_endpoint
  }

  tags = {
    environment = "Terraform Demo"
  }
}

resource "local_file" "cloud_pem" {
  filename = "${path.module}/new_vm.pem"
  content  = tls_private_key.example_ssh.private_key_pem
}

resource "null_resource" "example_provisioner" {
  triggers = {
    public_ip = azurerm_linux_virtual_machine.myterraformvm.public_ip_address
  }

  connection {
    type        = "ssh"
    host        = azurerm_linux_virtual_machine.myterraformvm.public_ip_address
    user        = var.ssh_user
    port        = var.ssh_port
    agent       = false
    private_key = file("new_vm.pem")
  }

  ## copy python files 
  provisioner "file" {
    source      = "weatherpython"
    destination = "/home/azureuser"
  }

  ## copy prometh. files 
  provisioner "file" {
    source      = "prometheus"
    destination = "/home/azureuser"
  }

  ## copy grafana files 
  provisioner "file" {
    source      = "grafana"
    destination = "/home/azureuser"
  }

  ## copy bootstrap 
  provisioner "file" {
    source      = "bash"
    destination = "/tmp"
  }

  ## install needed packages
  provisioner "remote-exec" {
    inline = [
      "sudo chmod +x /tmp/bash/*",
      "/tmp/bash/bootstrap.sh",
    ]
  }

  ## replace grafana datasource location with newly created IP
  provisioner "remote-exec" {
    inline = [
      "sed -i 's/replace_me_with_ip/${azurerm_linux_virtual_machine.myterraformvm.public_ip_address}/g' grafana/provisioning/datasources/datasource.yml",
    ]
  }

  ## start python script and send into background
  ## sleep here for case when when provisioner exits too fast for the process to be actually sent into background
  provisioner "remote-exec" {
    inline = [
      "cd weatherpython; nohup  python3 WriteTempEvents.py WriteTempEvents.cfg  &",
      "cd",
      "sleep 5",
    ]
  }

  ## if initial docker-ce install failed, retry
  provisioner "remote-exec" {
    inline = [
      "/tmp/bash/retry_docker_install.sh",
    ]
  }

  ## pull both docker images
  provisioner "remote-exec" {
    inline = [
      "sudo docker pull prom/prometheus",
      "sudo docker pull grafana/grafana",
    ]
  }

  ## start both docker containers
  provisioner "remote-exec" {
    inline = [
      "sudo docker run -d --net=host -p 9090:9090 -v /home/azureuser/prometheus/prometheus.yml:/etc/prometheus/prometheus.yml prom/prometheus --config.file=/etc/prometheus/prometheus.yml",
      "sudo docker run -d -v /home/azureuser/grafana/provisioning:/etc/grafana/provisioning  --name grafana -p 3000:3000 grafana/grafana",
    ]
  }
}

output "new_VM_IP" {
  sensitive = false
  value     = azurerm_linux_virtual_machine.myterraformvm.public_ip_address
}
