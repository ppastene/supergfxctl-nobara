#!/bin/bash

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'


echo -e "${BLUE}==================================================${NC}"
echo -e "${BLUE}    SUPERGFXCTL - DOCKER COMPILER AND INSTALLER   ${NC}"
echo -e "${BLUE}==================================================${NC}"
echo -e "${YELLOW}NOTE: This script uses Docker to compile. Make sure Docker is running beforehand.${NC}"
echo -e "${YELLOW}NOTE: Docker runs as root; files generated in ./bin will be automatically reassigned to your user ($USER).${NC}"
echo -e "${YELLOW}[!] This script requires administrative privileges to manage files and Docker permissions.${NC}"
if ! sudo -v; then
    echo -e "${RED}Error: Proper sudo privileges are required to run this script.${NC}"
    exit 1
fi

keep_sudo_alive() {
    while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
}
keep_sudo_alive
echo -e "Select option:"
echo -e "1) ${GREEN}Compile${NC}"
echo -e "2) ${GREEN}Compile and install${NC}"
echo -e "3) ${RED}Uninstall${NC}"
echo -e "4) Exit"
read -p "Option [1-4]: " OPTION

if [ "$OPTION" == "3" ]; then
    echo -e "\n${RED}[!] Uninstalling supergfxctl...${NC}"
    
    sudo systemctl stop supergfxd 2>/dev/null
    sudo systemctl disable supergfxd 2>/dev/null
    
    echo -e "${YELLOW}Deleting files and configurations...${NC}"
    sudo rm -f /usr/bin/supergfxd \
               /usr/bin/supergfxctl \
               /usr/lib/systemd/system/supergfxd.service \
               /usr/lib/systemd/system-preset/supergfxd.preset \
               /usr/share/dbus-1/system.d/org.supergfxctl.Daemon.conf \
               /usr/share/X11/xorg.conf.d/90-nvidia-screen-G05.conf \
               /usr/lib/udev/rules.d/90-supergfxd-nvidia-pm.rules
    
    sudo systemctl daemon-reload
    echo -e "${GREEN}Uninstall complete.${NC}"
    exit 0
fi

if [[ "$OPTION" != "1" && "$OPTION" != "2" ]]; then
    echo "Quitting..."
    exit 0
fi

if ! command -v docker &> /dev/null; then
    echo -e "${RED}[!] Error: Docker is not installed.${NC}"
    exit 1
fi

if ! docker ps &> /dev/null; then
    echo -e "${RED}[!] Error: The docker service is not running or your user doesn't have permissions.${NC}"
    echo -e "${YELLOW}Tip: Try with 'sudo systemctl start docker' or check your group permissions.${NC}"
    exit 1
fi

echo -e "\n${BLUE}[1/3] Creating temporal dockerfile...${NC}"
cat <<EOF > Dockerfile.tmp
FROM fedora:43
RUN dnf upgrade -y && dnf install -y curl gcc git make systemd-devel && dnf clean all
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/root/.cargo/bin:\${PATH}"
RUN git clone https://gitlab.com/asus-linux/supergfxctl.git
WORKDIR /supergfxctl
RUN make
EOF

echo -e "${BLUE}[2/3] Building and compiling (this takes time)...${NC}"
docker build -t supergfxctl-build -f Dockerfile.tmp .

if [ $? -ne 0 ]; then
    echo -e "${RED}Error: Compile failed.${NC}"
    rm Dockerfile.tmp
    exit 1
fi

echo -e "${BLUE}[3/3] Extracting binaries...${NC}"
mkdir -p ./bin
docker run --rm -v $(pwd)/bin:/output supergfxctl-build cp -r /supergfxctl/target/release/supergfxctl /supergfxctl/target/release/supergfxd /supergfxctl/data /output/

echo -e "${YELLOW}[!] Reclaiming file ownership from Docker (root) to $USER...${NC}"
sudo chown -R $USER:$USER ./bin

if [ "$OPTION" == "2" ]; then
    echo -e "${YELLOW}Installing to system...${NC}"
    sudo install -D -m 0755 ./bin/supergfxd /usr/bin/supergfxd
    sudo install -D -m 0755 ./bin/supergfxctl /usr/bin/supergfxctl
    sudo install -D -m 0644 ./bin/data/supergfxd.service /usr/lib/systemd/system/supergfxd.service
    sudo install -D -m 0644 ./bin/data/supergfxd.preset /usr/lib/systemd/system-preset/supergfxd.preset
    sudo install -D -m 0644 ./bin/data/org.supergfxctl.Daemon.conf /usr/share/dbus-1/system.d/org.supergfxctl.Daemon.conf
    sudo install -D -m 0644 ./bin/data/90-nvidia-screen-G05.conf /usr/share/X11/xorg.conf.d/90-nvidia-screen-G05.conf
    sudo install -D -m 0644 ./bin/data/90-supergfxd-nvidia-pm.rules /usr/lib/udev/rules.d/90-supergfxd-nvidia-pm.rules
    
    sudo systemctl daemon-reload
    sudo systemctl enable --now supergfxd
    echo -e "${GREEN}Installation complete!${NC}"
fi

docker rmi supergfxctl-build
rm Dockerfile.tmp
echo -e "${GREEN}Process finished.${NC}"