self: super: {
  spook = self.callPackage ../packages/spook/default.nix { };
  system-san-francisco-font = self.callPackage ../packages/system-san-francisco-font/default.nix { };
  alacritty = self.callPackage ../packages/alacritty/default.nix { };
}
