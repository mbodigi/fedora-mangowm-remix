# Net-install: packages come from the same repos the installed system uses.
# Repo names must not match the installer's own repos (updates, fedora-cisco-openh264), or it drops them.
url --metalink=https://mirrors.fedoraproject.org/metalink?repo=fedora-44&arch=x86_64
repo --name=shell-updates --metalink=https://mirrors.fedoraproject.org/metalink?repo=updates-released-f44&arch=x86_64
repo --name=shell-openh264 --metalink=https://mirrors.fedoraproject.org/metalink?repo=fedora-cisco-openh264-44&arch=x86_64
repo --name=rpmfusion-free --metalink=https://mirrors.rpmfusion.org/metalink?repo=free-fedora-44&arch=x86_64
repo --name=rpmfusion-free-updates --metalink=https://mirrors.rpmfusion.org/metalink?repo=free-fedora-updates-released-44&arch=x86_64
repo --name=rpmfusion-nonfree --metalink=https://mirrors.rpmfusion.org/metalink?repo=nonfree-fedora-44&arch=x86_64
repo --name=rpmfusion-nonfree-updates --metalink=https://mirrors.rpmfusion.org/metalink?repo=nonfree-fedora-updates-released-44&arch=x86_64
repo --name=terra --metalink=https://tetsudou.fyralabs.com/metalink?repo=terra44&arch=x86_64
repo --name=quickshell --baseurl=https://download.copr.fedorainfracloud.org/results/errornointernet/quickshell/fedora-44-x86_64/
repo --name=brave-browser --baseurl=https://brave-browser-rpm-release.s3.brave.com/x86_64
repo --name=librewolf --baseurl=https://repo.librewolf.net
