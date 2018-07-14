self: super: {
  spook = self.callPackage ../packages/spook/default.nix { };
  system-san-francisco-font = self.callPackage ../packages/system-san-francisco-font/default.nix { };
  san-francisco-mono-font = self.callPackage ../packages/san-francisco-mono-font/default.nix { };
  alacritty = self.callPackage ../packages/alacritty/default.nix { };
  fire = self.callPackage ../packages/fire/default.nix { };
  btr-snap = self.callPackage ../packages/btr-snap/default.nix { };
}
