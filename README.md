# SUPERGFXCTL NOBARA COMPILER AND INSTALLER
If you are using Nobara Linux, and:
1. have a laptop that can't suspend its dGPU
2. need an easy way to use vfio
3. want to monitor the dGPU status
4. want to try using hotplug and/or ASUS ROG dgpu_disable
5. have an ASUS with an eGPU and need to switch to it

You will require [supergfxctl](https://gitlab.com/asus-linux/supergfxctl), but the tool is not bundled with the OS and is not availalbe in the repository. So the best option is to download the code and compile it by yourself but if you don't wanna mess with the Rust Programming language I coded this script which uses Docker to compile supergfxctl and install it for you, also it provide the binaries if you wanna share it or even the option to uninstall it from your OS

## Requirements
- Docker: Must be installed and the service must be running (sudo systemctl start docker).
- Permissions: While it's best practice to add your user to the docker group, this script uses sudo docker internally to ensure compatibility regardless of your post-install configuration.

## Usage
The script requires root privileges to move binaries to system folders and manage services. It will ask for your password at the beginning to ensure a smooth, unattended compilation and installation process. You will have the following options:
- Compile: Compiles supergfxctl inside a container and extracts the binaries to a ./bin folder, reassigning ownership to your current user.
- Compile and install: Performs the compilation and then automatically installs the binaries, service files, and DBUS configurations to their respective system paths.
- Uninstall: Safely stops the service and removes all files related to supergfxctl from your OS.

After compile the script will stop and delete the docker container.

## Quick Start
1. Clone this repository
2. Run the script ```sh ./run.sh```

Don't forget to check the [supergfxctl](https://gitlab.com/asus-linux/supergfxctl) repository for updates 