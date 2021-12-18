#AxuL Java 17 Repo install script by LocalghostFI

GREEN="\e[32m"
ENDCOLOR="\e[0m"

echo "${GREEN}Updating and installing gnupg and curl${ENDCOLOR}"
sudo apt-get -q update
sudo apt-get -yq install gnupg curl 
echo " "
echo "${GREEN}Add key${ENDCOLOR}"
sudo apt-key adv \
  --keyserver hkp://keyserver.ubuntu.com:80 \
  --recv-keys 0xB1998361219BD9C9
echo " "
echo "${GREEN}Start downloading package..${ENDCOLOR}"
curl -O https://cdn.azul.com/zulu/bin/zulu-repo_1.0.0-3_all.deb
echo " "
echo "${GREEN}Start installing package${ENDCOLOR}"
echo " "
sudo apt-get install ./zulu-repo_1.0.0-3_all.deb
echo " "
sudo apt-get update
echo " "
echo "${GREEN}Installing Azul Zulu JDK 17${ENDCOLOR}"
# install Azul Zulu JDK 17
sudo apt-get -y install zulu17-jdk
echo " "
sudo rm -r ./zulu-repo_1.0.0-3_all.deb
echo "${GREEN}Installation complete! Your Java version is:${ENDCOLOR}"

sudo java -version
