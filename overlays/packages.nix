self: super: rec {
  system-san-francisco-font = super.callPackage ../packages/system-san-francisco-font { };
  san-francisco-mono-font = super.callPackage ../packages/san-francisco-mono-font { };
  office-code-pro-font = super.callPackage ../packages/office-code-pro-font { };
  btr-snap = super.callPackage ../packages/btr-snap { };
}
