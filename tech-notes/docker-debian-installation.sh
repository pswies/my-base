#!/bin/bash

# guide taken from: https://www.digitalocean.com/community/tutorials/how-to-install-and-use-docker-on-ubuntu-18-04

sudo apt update

# Next, install a few prerequisite packages which let apt use packages over HTTPS:

sudo apt install apt-transport-https ca-certificates curl software-properties-common -y

# Then add the GPG key for the official Docker repository to your system:

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

# Add the Docker repository to APT sources:

sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic stable"

# Next, update the package database with the Docker packages from the newly added repo:

sudo apt update

# Make sure you are about to install from the Docker repo instead of the default Ubuntu repo:

apt-cache policy docker-ce

# You’ll see output like this, although the version number for Docker may be different:
# Output of apt-cache policy docker-ce

# docker-ce:
#   Installed: (none)
#   Candidate: 18.03.1~ce~3-0~ubuntu
#   Version table:
#      18.03.1~ce~3-0~ubuntu 500
#         500 https://download.docker.com/linux/ubuntu bionic/stable amd64 Packages

# Notice that docker-ce is not installed, but the candidate for installation is from the Docker repository for Ubuntu 18.04 (bionic).

# Finally, install Docker:

sudo apt install docker-ce -y

# If you want to avoid typing sudo whenever you run the docker command, add your username to the docker group:

sudo usermod -aG docker ${USER}

# To apply the new group membership, log out of the server and back in, or type the following:

su - ${USER}

# check status:

sudo systemctl status docker
