{ stdenv, fetchgit, pkgconfig, autoconf, automake111x, libtool_1_5, file, glib, gdk_pixbuf, libwnck3, libnotify, dbus-glib, makeWrapper, gnome3 }:

stdenv.mkDerivation rec {
  name = "notify-osd-${version}";
  version = "0.9.35-1";

  src = fetchgit {
    url = https://github.com/khurshid-alam/Notify-OSD;
    rev = "6ad49ae6fe1c48f4bc7bf5a4bc9ca4f00187e5c3";
    sha256 = "0l4yckpic6h0aglxbd9h78xifsw53g343w8cas8gv60fvy6g2gwh";
    fetchSubmodules = false;
  };

  nativeBuildInputs = [
    pkgconfig
    autoconf
    automake111x
    libtool_1_5
    file
  ];
  buildInputs = [
    glib libwnck3 libnotify dbus-glib makeWrapper
    gnome3.gsettings-desktop-schemas
    gnome3.gnome-common
    gnome3.librsvg
    gdk_pixbuf
  ];
  preConfigure = ''
    ${stdenv.shell} ./autogen.sh
  '';
  configureFlags = "--libexecdir=$(out)/bin";
  preFixup = ''
    cat ./configure
    wrapProgram "$out/bin/notify-osd" \
      --prefix XDG_DATA_DIRS : "$GSETTINGS_SCHEMAS_PATH" \
      --prefix GDK_PIXBUF_MODULE_FILE : "${gnome3.librsvg}/lib/gdk-pixbuf-2.0/2.10.0/loaders.cache"
  '';
  meta = with stdenv.lib; {
    description = "Daemon that displays passive pop-up notifications - customized version";
    homepage = https://launchpad.net/~leolik/+archive/ubuntu/leolik;
    license = licenses.gpl3;
    platforms = platforms.linux;
  };
}
