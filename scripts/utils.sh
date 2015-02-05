#!/bin/bash
# Bash utilities

# trap for error or exists
trap "ctrl_c" SIGINT
# trap "err_exit line ${LINENO}: Exit Code: $?" ERR
trap "cleanup" EXIT

# useful aliases
alias path='echo -e ${PATH//:/\\n}'
alias copy="cp"
alias del="rm -i"
alias dir="ls"
alias md='mkdir -p'
alias rd='rmdir'
alias rename="mv "
alias quit="exit"
alias iso8601='date -u +"%Y-%m-%dT%H:%M:%SZ"'
alias murder="kill -15"
# Enable aliases to be sudo’ed
alias sudo='sudo '

# error Message
function err_msg () {
  echo -e "[$( iso8601 )]: $@" >&2
}

# log message
function log_msg () {
  echo -e "[$( iso8601 )]: $@" >&1
}

# trap ctrl-c
function ctrl_c () {
  err_exit "CTRL-C detected..."
}

# exit with error
function err_exit () {
    err_msg "ERROR! $@"
    exit 1
}

# overload this empty cleanup function
function cleanup () {
  :
}

# include source file
function include () {
    [[ -f "$1" ]] && source "$1"
}

# check for root
function is_root () {
    if [ "$(id -u)" != "0" ]; then
    echo -e "Script must be run as ROOT."
    exit 1
  fi
}

# Check whether a command exists - returns 0 if it does, 1 if it does not
function cmd_exists () {
  if $(command -v $1 &>/dev/null); then
    return 0
  else
    return 1
  fi
}

# check_distro
function find_distro () {
  # Check the Source Distro
  if [ -f /etc/issue ];then
    if [ "$(grep -i '\(centos\)\|\(red\)\|\(scientific\)' /etc/issue)"  ]; then
      export DISTRO="centos"
    elif [ "$(grep -i '\(fedora\)\|\(amazon\)' /etc/issue)"  ]; then
      export DISTRO="fedora"
    elif [ "$(grep -i '\(debian\)' /etc/issue)" ];then
      export DISTRO="debian"
    elif [ "$(grep -i '\(ubuntu\)' /etc/issue)" ];then
      export DISTRO="ubuntu"
    elif [ "$(grep -i '\(suse\)' /etc/issue)" ];then
      export DISTRO="suse"
    elif [ "$(grep -i '\(arch\)' /etc/issue)" ];then
      export DISTRO="arch"
    else
      export DISTRO="unknown"
    fi
  elif [ -f /etc/gentoo-release ];then
    export DISTRO="gentoo"
  else
    export DISTRO="unknown"
  fi
}

function setup_pkg_managers () {
  if [ -z ${DISTRO:-} ]; then
    find_distro
  fi
  DISTRO=${1:-$DISTRO}
  if [ "$DISTRO" == "debian" ] || [ "$DISTRO" == "ubuntu" ]; then
    alias pkgclean='sudo apt-get -y clean'
    alias pkgpurge='sudo apt-get -y purge'
    alias pkgsearch='sudo apt-get search'
    alias pkginfo=''
    alias pkgupdate='sudo apt-get update'
    alias pkgremove='sudo apt-get -y remove'
    alias pkgupgrade='sudo apt-get -y upgrade'
    alias pkginstall='sudo apt-get -y install'
    alias pkgautoremove='sudo apt-get -y autoremove'
    alias pkgdist-upgrade='sudo apt-get -y dist-upgrade'
  elif [ "$DISTRO" == "centos" ]; then
    alias pkgclean='sudo yum -y clean'
    alias pkgpurge='sudo rpm -e'
    alias pkgsearch='sudo yum search'
    alias pkginfo='sudo yum info'
    alias pkgupdate='sudo yum update'
    alias pkgremove='sudo yum -y remove'
    alias pkgupgrade='sudo yum -y upgrade'
    alias pkginstall='sudo yum -y install'
    alias pkgautoremove='sudo yum -y autoremove'
    alias pkgdist-upgrade=''
  elif [ "$DISTRO" == "suse" ]; then
    alias pkgclean=''
    alias pkgpurge=''
    alias pkgsearch=''
    alias pkgsinfo=''
    alias pkgupdate='sudo zypper ref'
    alias pkgremove='sudo zypper remove'
    alias pkgupgrade='sudo zypper dup'
    alias pkginstall='sudo zypper install'
    alias pkgautoremove=''
    alias pkgdist-upgrade=''
  else
    alias pkgclean=''
    alias pkgpurge=''
    alias pkgsearch=''
    alias pkgsinfo=''
    alias pkgupdate=''
    alias pkgremove=''
    alias pkgupgrade=''
    alias pkginstall=''
    alias pkgautoremove=''
    alias pkgdist-upgrade=''
    err_msg "$DISTRO distro detected. No package managers configured."
fi
}
setup_pkg_managers

# pip install
alias pipinstall='pip install'

# add path to PATH variable
function add_path () {
  echo "PATH=$PATH:$1" >> /etc/environment
  source /etc/environment
}

# make directory and change directory
function take_dir () {
  mkdir -p $1
  cd $1
}

function tmp () {
  python -c "import os, tempfile; print os.path.abspath(tempfile.mkdtemp())"
}

# download file
function download() {
  if $(cmd_exists wget); then
    wget -Nq --no-check-certificate $1 -O $2
  elif $(cmd_exists curl); then
    curl --insecure -o $2 $1
  fi
}

# clone git repository url
function clone_repo () {
  local REPO_URL="$1"
  local REPO_URL=${REPO_URL%/} # Remove trailing slash, if any
  local REPO_NAME=${REPO_URL##*/} # Extract Repository name
  local REPO_USER=${REPO_URL%/*} # Extract Repository user
  local REPO_DIR=/webapp/$REPO_NAME-master

  if $(cmd_exists git); then
    log "Cloning ${REPO_NAME} Repository..."
    git clone $REPO_URL $REPO_NAME-master
  elif $(cmd_exists wget) && $(cmd_exists tar); then
    log "Downloading ${REPO_NAME} tarball..."
    download $REPO_URL/archive/master.tar.gz /webapp/$REPO_NAME.tar.gz
    log "Extracting ${REPO_NAME} tarball..."
    extract $REPO_NAME.tar.gz
  else
      log "Installing installed packages: wget, tar"
      pkginstall wget tar
      clone_repo
  fi
}

function extract () {
  local remove_archive
  local success
  local file_name
  local extract_dir
  if (( $# == 0 ))
  then
    echo "Usage: extract [-option] [file ...]"
    echo
    echo Options:
    echo "    -r, --remove    Remove archive."
  fi
  remove_archive=1
  if [[ "$1" = "-r" ]] || [[ "$1" = "--remove" ]]
  then
    remove_archive=0
    shift
  fi
  while (( $# > 0 ))
  do
    if [[ ! -f "$1" ]]
    then
      err_msg "extract: '$1' is not a valid file" >&2
      shift
      continue
    fi
    success=0
    file_name="$( basename "$1" )"
    extract_dir="$( echo "$file_name" | sed "s/\.${1##*.}//g" )"
    case "$1" in
      (*.tar.gz|*.tgz) [ -z $commands[pigz] ] && tar zxvf "$1" || pigz -dc "$1" | tar xv ;;
      (*.tar.bz2|*.tbz|*.tbz2) tar xvjf "$1" ;;
      (*.tar.xz|*.txz) tar --xz --help &> /dev/null && tar --xz -xvf "$1" || xzcat "$1" | tar xvf - ;;
      (*.tar.zma|*.tlz) tar --lzma --help &> /dev/null && tar --lzma -xvf "$1" || lzcat "$1" | tar xvf - ;;
      (*.tar) tar xvf "$1" ;;
      (*.gz) [ -z $commands[pigz] ] && gunzip "$1" || pigz -d "$1" ;;
      (*.bz2) bunzip2 "$1" ;;
      (*.xz) unxz "$1" ;;
      (*.lzma) unlzma "$1" ;;
      (*.Z) uncompress "$1" ;;
      (*.zip|*.war|*.jar|*.sublime-package) unzip "$1" -d $extract_dir ;;
      (*.rar) unrar x -ad "$1" ;;
      (*.7z) 7za x "$1" ;;
      (*.deb) mkdir -p "$extract_dir/control"
        mkdir -p "$extract_dir/data"
        cd "$extract_dir"
        ar vx "../${1}" > /dev/null
        cd control
        tar xzvf ../control.tar.gz
        cd ../data
        tar xzvf ../data.tar.gz
        cd ..
        rm -i *.tar.gz debian-binary
        cd .. ;;
      (*) err_msg "extract: '$1' cannot be extracted" >&2
        success=1  ;;
    esac
    (( success = $success > 0 ? $success : $? ))
    (( $success == 0 )) && (( $remove_archive == 0 )) && rm -i "$1"
    shift
  done
}

# compress files
# e.g. compress archive.tar.gz /folder
function squash () {
  if [ $# -ge 2 ]
  then
    case $1 in
      (*.tar.bz|*.tbz|*.tar.bz2|*.tbz2) tar cvjf ${@:1} ;;
      (*.tar.gz|*.tgz) tar cvzf ${@:1} ;;
      (*.bz|*bz2) bzip2 ${@:1} ;;
      (*.rar) rar ${@:1} ;;
      (*.gz) gzip -c ${@:2} $1 ;;
      (*.tar) tar cvf ${@:1} ;;
      (*.zip) zip -r ${@:1} ;;
      (*.Z) compress ${@:1} ;;
      (*.7z) 7z x ${@:1} ;;
      (*) err_msg "don't know how to ->squash<- '$1'..." ;;
    esac
  else
    err_msg "needs at least two arguments!"
  fi
}

function backup () {
  # copies appends .bak extension to the file
  # usage: backup <files...>
  for i in $@
  do
    cp -r $i{,.$(date +%Y%m%d_%H%M%S).bak}
  done
}

# Tar pipe
function tarpipe() {
  (cd $1 && tar -cf - .) | (cd $2 && tar -xpf -)
}

# encryption functions
alias rot13="tr 'A-Za-z' 'N-ZA-Mn-za-m'"
alias rot47="tr '\!-~' 'P-~\!-O'"

if [ -z "\${which openssl}" ]; then
  function md5-dgst() {
    openssl dgst -md5 $@
  }

  function sha1-dgst() {
    openssl dgst -sha1 $@
  }

  function sha256-dgst() {
    openssl dgst -sha256 $@
  }

  function sha512-dgst() {
    openssl dgst -sha512 $@
  }

  function b64encode() {
    openssl enc -base64 $@
  }

  function b64decode() {
    openssl enc -base64 -d $@
  }
  function encrypt() {
    # encrypts a aes256+base64 encoded file
    if [ -d $1 ]; then
      tar -cf - $1 | openssl enc -aes-256-cbc -a -salt -out $1.tar.aes
    els
      openssl enc -aes-256-cbc -a -salt -in $1 -out $1.aes
    fi
  }
  # decrypts a aes256+base64 encoded file
  function decrypt() {
    outfile=${1%.aes}
    openssl enc -d -aes-256-cbc -a -in $1 -out $outfile
  }

  function passwd-gen() {
    # generate a passwd-style hash
    openssl passwd -1 $@
  }

  function isprime() {
    # test is number is prime
    openssl prime $@
  }

  function prime-gen() {
    # generate a sequence of primes
    local aquo=$1
    local adquem=$2
    for n in $(seq $aquo $adquem)
    do
      openssl prime $n | awk '/is prime/ {print "ibase=16;"$1}' | bc
    done
  }
fi



if $(cmd_exists rsync); then
  alias rsync-copy="rsync -avz --progress -h"
  alias rsync-move="rsync -avz --progress -h --remove-source-files"
  alias rsync-update="rsync -avzu --progress -h"
  alias rsync-synchronize="rsync -avzu --delete --progress -h"
fi

# list contents of directories in a tree-like format
if [ -z "\${which tree}" ]; then
  tree () {
    find $@ -print | sed -e 's;[^/]*/;|____;g;s;____|; |;g'
  }
fi

# gather external ip address
ip_external() {
  curl http://ifconfig.me
}

# determine local IP address
ip_internal() {
  ifconfig  | grep 'inet addr:'| grep -v '127.0.0.1' | cut -d: -f2 | awk '{ print $1}'
}

function ssh_key_to_pem() {
  if (( $# == 0 ))
  then
    err_exit "Usage: ssh_key_to_pem PATH_TO_FILE"
  fi
  openssl req -x509 -key $1 -nodes -days 365 -newkey rsa:2048 -out $1.pem
}
