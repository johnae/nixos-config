#let stdenv = [ stdenv.cc stdenv.cc.binutils ] ++ stdenv.initialPath; in

pkgs: with pkgs; [
  # man pages
  man-pages

  dropbox

  # media
  spotify
  mpv
  vlc
  libreoffice
  abiword
  gnome3.gedit
  gimp
  inkscape
  evince
  imagemagick

  # X11 stuff
  xss-lock
  xsel
  xclip
  xdotool
  compton
  xorg.xev
  xorg.xprop
  arandr

  # CLI tools
  ii
  direnv
  bmon
  iftop
  file
  python2Packages.docker_compose

  iw
  mosh
  openssl
  curl
  pass
  gnupg
  pinentry
  pinentry_gnome
  lsof
  usbutils
  mkpasswd
  glib
  python2Full
  powertop
  socat
  nmap
  iptables
  bridge-utils
  dnsmasq
  dhcpcd
  dhcp
  bind
  pciutils
  awscli
  peco
  fzf
  stunnel
  ncdu
  nix-repl
  zip
  wget
  unzip
  hdparm
  libsysfs
  htop
  jq
  binutils
  psmisc
  tree
  ripgrep
  emacs
  vim
  git
  zsh
  tmux
  nix-prefetch-scripts
  ctags
  global
  rtags
  stack

  gtk2
  gnome3.defaultIconTheme
  hicolor_icon_theme
  tango-icon-theme
  shared_mime_info
  arc-theme
  arc-icon-theme
  gnome3.nautilus
  lxappearance
  feh

  blueman
  pavucontrol
  bluez
  bluez-tools
  fd
  unrar

  spook
  alacritty
]
