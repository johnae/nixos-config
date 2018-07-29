self: super: {
  spook = super.callPackage ../packages/spook { };
  system-san-francisco-font = super.callPackage ../packages/system-san-francisco-font { };
  san-francisco-mono-font = super.callPackage ../packages/san-francisco-mono-font { };
  alacritty = super.callPackage ../packages/alacritty { };
  fire = super.callPackage ../packages/fire { };
  btr-snap = super.callPackage ../packages/btr-snap { };
  notify-osd = super.callPackage ../packages/notify-osd-customizable { };
}
