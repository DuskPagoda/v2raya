#!/usr/bin/env bash

curl() {
  $(type -P curl) -L -q --retry 5 --retry-delay 10 --retry-max-time 60 "$@"
}

# Check if the script is being run as root
check_if_running_as_root() {
  if [[ "$UID" -ne '0' ]]; then
    echo "WARNING: The user currently executing this script is not root. You may encounter insufficient privilege errors."
    read -r -p "Are you sure you want to continue? [y/n] " cont_without_been_root
    if [[ x"${cont_without_been_root:0:1}" != x'y' ]]; then
      echo "Not running with root, exiting..."
      exit 1
    fi
  fi
}

# Identify the operating system and architecture
identify_the_operating_system_and_architecture() {
  if [[ "$(uname)" != 'Linux' ]]; then
    echo "错误：不支持当前操作系统."
    exit 1
  fi

  case "$(uname -m)" in
    'amd64' | 'x86_64')
      MACHINE='x64'
      ;;
    'armv8' | 'aarch64')
      MACHINE='arm64'
      ;;
    *)
      echo "error: 不支持你的系统，请提交问题反馈."
      exit 1
      ;;
  esac

  if [[ ! -f '/etc/os-release' ]]; then
    echo "error: Don't use outdated Linux distributions."
    exit 1
  fi

  if grep -q 'CentOS' /etc/os-release; then
    OS='centos'
  elif grep -q 'Ubuntu\|Debian' /etc/os-release; then
    OS='debian'
  else
    echo "error: 只支持CentOS和Debian/Ubuntu."
    exit 1
  fi

  # Check for systemd
  if [[ ! -d /run/systemd/system ]] && ! grep -q systemd <(ls -l /sbin/init); then
    echo "error: Only Linux distributions using systemd are supported."
    exit 1
  fi
}

# Download and install V2Raya
download_and_install_v2raya() {
  if [[ "$OS" == 'centos' ]]; then
    echo "Installing V2Ray for CentOS $MACHINE..."
    curl -o /usr/bin/v2ray "https://github.com/DuskPagoda/v2raya/raw/main/centos/v2ray-core-v5.17.2"
    chmod +x /usr/bin/v2ray
    yum install -y "https://github.com/DuskPagoda/v2raya/raw/main/centos/installer_redhat_${MACHINE}_2.2.5.8.rpm"
  elif [[ "$OS" == 'debian' ]]; then
    echo "Installing V2Ray for Debian/Ubuntu $MACHINE..."
    TEMP_DEB=$(mktemp)
    curl -L -o "$TEMP_DEB" "https://github.com/DuskPagoda/v2raya/raw/main/debian/installer_debian_${MACHINE}_2.2.5.8.deb"
    sudo dpkg -i "$TEMP_DEB"
    rm -f "$TEMP_DEB"

    TEMP_DEB=$(mktemp)
    curl -L -o "$TEMP_DEB" "https://github.com/DuskPagoda/v2raya/raw/main/debian/xray_1.8.18_${MACHINE}.deb"
    sudo dpkg -i "$TEMP_DEB"
    rm -f "$TEMP_DEB"
  else
    echo "错误：不支持当前操作系统."
    exit 1
  fi
}

# Main execution
check_if_running_as_root
identify_the_operating_system_and_architecture
download_and_install_v2raya
