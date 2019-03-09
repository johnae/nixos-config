{ stdenv, fetchFromGitHub, autoconf, automake, gettext, intltool
, libtool, pkgconfig, wrapGAppsHook, wrapPython, gobjectIntrospection
, gtk3, python, pygobject3, hicolor-icon-theme, pyxdg

, withRandr ? stdenv.isLinux, libxcb
, withDrm ? stdenv.isLinux, libdrm
, withWayland ? stdenv.isLinux, wayland, wayland-protocols
, withGeoclue ? stdenv.isLinux, geoclue }:

stdenv.mkDerivation rec {
  name = "redshift-${version}";
  version = "1.12";

  src = fetchFromGitHub {
    owner = "minus7";
    repo = "redshift";
    rev = "420d0d534c9f03abc4d634a7d3d7629caf29b4b6";
    sha256 = "12dwb96i4pbny5s64k6k4f8k936xa41zvcjhv54wv0ax471ymls7";
  };

  patches = [
    # https://github.com/jonls/redshift/pull/575
    ./575.patch
  ];

  nativeBuildInputs = [
    autoconf
    automake
    gettext
    intltool
    libtool
    pkgconfig
    wrapGAppsHook
    wrapPython
  ];

  configureFlags = [
    "--enable-randr=no"
    "--enable-geoclue2=${if withGeoclue then "yes" else "no"}"
    "--enable-drm=${if withDrm then "yes" else "no"}"
    "--enable-quartz=no"
    "--enable-corelocation=no"
    "--enable-wayland=${if withWayland then "yes" else "no"}"
  ];

  buildInputs = [
    gobjectIntrospection
    gtk3
    python
    hicolor-icon-theme
  ] ++ stdenv.lib.optional  withRandr        libxcb
    ++ stdenv.lib.optional  withGeoclue      geoclue
    ++ stdenv.lib.optional  withDrm          libdrm
    ++ stdenv.lib.optional  withWayland      [ wayland wayland-protocols ]
    ;

  pythonPath = [ pygobject3 pyxdg ];

  preConfigure = "./bootstrap";

  postFixup = "wrapPythonPrograms";

  # the geoclue agent may inspect these paths and expect them to be
  # valid without having the correct $PATH set
  postInstall = ''
    substituteInPlace $out/share/applications/redshift.desktop \
      --replace 'Exec=redshift' "Exec=$out/bin/redshift"
    substituteInPlace $out/share/applications/redshift.desktop \
      --replace 'Exec=redshift-gtk' "Exec=$out/bin/redshift-gtk"
  '';

  enableParallelBuilding = true;

  meta = with stdenv.lib; {
    description = "Screen color temperature manager";
    longDescription = ''
      Redshift adjusts the color temperature according to the position
      of the sun. A different color temperature is set during night and
      daytime. During twilight and early morning, the color temperature
      transitions smoothly from night to daytime temperature to allow
      your eyes to slowly adapt. At night the color temperature should
      be set to match the lamps in your room.
    '';
    license = licenses.gpl3Plus;
    homepage = http://jonls.dk/redshift;
    platforms = platforms.unix;
    maintainers = with maintainers; [ yegortimoshenko ];
  };
}
