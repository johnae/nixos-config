self: super: rec {
  system-san-francisco-font = super.callPackage ../packages/system-san-francisco-font { };
  san-francisco-mono-font = super.callPackage ../packages/san-francisco-mono-font { };
  office-code-pro-font = super.callPackage ../packages/office-code-pro-font { };
  btr-snap = super.callPackage ../packages/btr-snap { };
  redshiftwl = with super.pkgs; super.callPackage ../packages/redshift {
    inherit (python3Packages) python pygobject3 pyxdg wrapPython;
    inherit (darwin.apple_sdk.frameworks) CoreLocation ApplicationServices Foundation Cocoa;
    geoclue = geoclue2;
  };
}
