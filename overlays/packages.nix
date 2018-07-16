self: super: {
  spook = self.callPackage ../packages/spook { };
  system-san-francisco-font = self.callPackage ../packages/system-san-francisco-font { };
  san-francisco-mono-font = self.callPackage ../packages/san-francisco-mono-font { };
  alacritty = self.callPackage ../packages/alacritty { };
  fire = self.callPackage ../packages/fire { };
  btr-snap = self.callPackage ../packages/btr-snap { };
  notify-osd = self.callPackage ../packages/notify-osd-customizable { };
}
