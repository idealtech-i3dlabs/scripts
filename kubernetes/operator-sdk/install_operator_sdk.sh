#!/bin/bash
## Operator SDK installer
## AUTHOR: MPL (mpl@i3dlabs.com)
## Purpose: Simplify installation of operator-sdk from source
## Assumes: Ubuntu 20.04 minimal, contents will end up in ~/kube-operators
## License: CC Attribution 4.0 International (CC BY 4.0)
set -e

# GLOBALS
VERSION=1.0.2
GOPKG=go1.16.linux-amd64.tar.gz


function checkUser() {
# ROOT NOT ALLOWED, GO WILL FAIL.
if [ "$USER" == "root" ];then
    echo "Sorry, this script must not run as root."
    exit
fi
}
# BASE

function installBase() {
sudo apt-get install -y figlet
figlet base pkgs
sudo apt-get install -y git mercurial bzr build-essential make python3.8 python3-pip sshfs wget curl
sudo ln -sf /usr/bin/pip3 /usr/bin/pip
sudo ln -sf /usr/bin/python3 /usr/bin/python
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo mv kubectl /usr/local/bin/kubectl
sudo chmod +x /usr/local/bin/kubectl
}

function installGo() {
figlet go - install
echo "Downloading $GOPKG from the internet *now*"
cd && mkdir -p pkgs && cd pkgs
[ ! -f ~/pkgs/$GOPKG ] && wget https://golang.org/dl/$GOPKG && sudo tar -C /usr/local -xzf $GOPKG || /bin/true
}

installOperatorSDK() {
echo "export PATH=$PATH:/usr/local/go/bin" >> ~/.bashrc
echo "export PATH=$PATH:/usr/local/go/bin" >> ~/.zshrc
echo "export GOPROXY=\"https://proxy.golang.org|direct\"" >> ~/.bashrc
echo "export GOPROXY=\"https://proxy.golang.org|direct\"" >> ~/.zshrc
echo "alias k=\"kubectl\"" >> ~/.bashrc
echo "alias k=\"kubectl\"" >> ~/.zshrc
source ~/.bashrc 2>/dev/null
source ~/.zshrc 2>/dev/null
go version
cd
[ ! -f ~/operator-sdk ] && git clone https://github.com/operator-framework/operator-sdk || /bin/true &&
cd operator-sdk &&
git checkout master &&
make install &&
sudo cp /home/$USER/go/bin/operator-sdk /usr/local/bin/operator-sdk
}

function installDeps() {
figlet deps
pip install --upgrade ansible
pip install --upgrade ansible-runner
pip install --upgrade ansible-runner-http
}

function prepOperatorScript() {
mkdir -p ~/kube-operators && cd ~/kube-operators

cat > ./create-operator.sh <<EOF
#!/bin/bash
alias go="/usr/local/go/bin/go"
source ~/.bashrc 2>/dev/null
VERSION=$VERSION
figlet OPERATOR SDK $VERSION
echo "Welcome! Time to create a new operator!"
echo
echo "====================================================="
echo "Kind? (MUST START WITH AN UPPERCASE!) : "
echo "====================================================="
read K

mkdir -p ~/kube-operators/\$K && cd ~/kube-operators/\$K
set -v
operator-sdk init --project-version=3 --plugins=ansible #--skip-go-version-check
operator-sdk create api --group cache --version v1alpha1 --kind \$K --generate-role
set +v

echo "Your next steps..."
figlet tutorial go
echo https://sdk.operatorframework.io/docs/building-operators/go/tutorial
echo "NOTE: If you need to use go, change --plugins in the script to \"go\""
echo
figlet tutorial ansible
echo https://sdk.operatorframework.io/docs/building-operators/ansible/tutorial
echo
figlet running
echo operator-sdk run bundle \$BUNDLE_IMG
echo
figlet uninstall operator
echo operator-sdk cleanup $OP

EOF

chmod +x ./create-operator.sh
cd
echo "Installation complete. You can create an operator using:"
echo "cd ~/kube-operators"
echo "./create-operator.sh"

}

if [ -z $1 ];then
    checkUser
    installBase
    installGo
    installOperatorSDK
    installDeps
    prepOperatorScript
elif [ "$1" == "installgo" ];then
    installGo
elif [ "$1" == "installoperatorsdk" ];then
    installOperatorSDK
elif [ "$1" == "installdeps" ];then
    installDeps
elif [ "$1" == "prepoperatorscript" ];then
    prepOperatorScript
fi

figlet my features
echo "IDEMPOTENT,MODULAR,NOERRORALLOWED"
echo "...next time..."
echo "$(basename "$0") installgo / installoperatorsdk / installdeps / prepoperatorscript"

figlet success
