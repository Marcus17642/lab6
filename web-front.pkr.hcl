# Define the Packer block to specify required plugins
packer {
  required_plugins {
    amazon = {  # Specify the Amazon plugin
      version = ">= 1.3"  # Require version 1.3 or higher
      source  = "github.com/hashicorp/amazon"  # Source location of the plugin
    }
  }
}

# Define the source block for the Amazon EBS builder
source "amazon-ebs" "ubuntu" {
  ami_name      = "web-nginx-aws"  # Name of the AMI to be created
  instance_type = "t2.micro"  # Instance type for the build
  region        = "us-west-2"  # AWS region where the instance will be launched

  # Filter to select the source AMI
  source_ami_filter {
    filters = {
      name = "ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-20250115"  # AMI name pattern
      root-device-type    = "ebs"  # Use EBS as the root device
      virtualization-type = "hvm"  # Use hardware virtual machine
    }
    most_recent = true  # Use the most recent AMI that matches the filter
    owners      = ["099720109477"]  # AWS account ID of the AMI owner (Canonical)
  }

  ssh_username = "ubuntu"  # SSH username for connecting to the instance
}

# Define the build block to specify the build process
build {
  name = "web-nginx"  # Name of the build
  sources = [
    "source.amazon-ebs.ubuntu"  # Reference to the source block defined above
  ]
  
  # Provisioner block to run shell commands
  provisioner "shell" {
    inline = [
      "echo creating directories",  # Print message to console
      "sudo mkdir -p /web/html",  # Create directory for web content
      "sudo mkdir -p /tmp/web",  # Create temporary directory for web files
      "sudo mkdir -p /etc/nginx/sites-available",  # Create Nginx config directory
      "sudo mkdir -p /etc/nginx/sites-enabled",  # Create Nginx enabled sites directory

      "sudo chown -R ubuntu:ubuntu /tmp/web",  # Change ownership of /tmp/web to ubuntu user
      "sudo chown -R www-data:www-data /web/html",  # Change ownership of /web/html to www-data user
      "sudo chmod -R 755 /web/html"  # Set permissions for /web/html
    ]
  }

  # Provisioner block to upload a file
  provisioner "file" {
    source      = "files/index.html"  # Local path to the source file
    destination = "/tmp/web/index.html"  # Destination path on the instance
  }

  # Another file provisioner block
  provisioner "file" {
    source      = "files/nginx.conf"  # Local path to the Nginx config file
    destination = "/tmp/web/nginx.conf"  # Destination path on the instance
  }
  
  # Provisioner block to run a script
  provisioner "shell" {
    script = "scripts/install-nginx"  # Path to the script that installs Nginx
  }

  # Another shell provisioner block
  provisioner "shell" {
    script = "scripts/setup-nginx"  # Path to the script that sets up Nginx
  }

  # Final shell provisioner block to move the index.html file
  provisioner "shell" {
    inline = [
      "sudo mv /tmp/web/index.html /web/html/index.html"  # Move the index.html to the web directory
    ]
  }
}
