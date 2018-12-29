{
  hostName = "<HOSTNAME>";
  consoleFont = "Lat2-Terminus16";
  consoleKeyMap = "sv-latin1";
  defaultLocale = "en_US.UTF-8";
  timeZone = "Europe/Stockholm";
  userName = "john";
  userDescription = "John Axel Eriksson";
  userPassword = "<PASSWORD>"; # mkpasswd -m sha-512 -s <<< the-password-here
  backupDestination = "user@some.example.com";
  backupPort = "12345";
  backupSshKey = "/path/to/id_rsa";
  knownHosts = [ { hostNames = [ "[some.example.com]:12345" "[10.10.10.11]:12345" ]; publicKey = "ssh-rsa AAAAB3NzaC1yc2VeryLongKeyHereFollowsAllTheWayUntilTheEnd"; } ];
  kernelParams = []; ## for example [ "btusb.enable_auto_suspend=0" ] is useful on some machines where bluetooth would otherwise die on sleep and never come back up;
  # videoDrivers = [ "modesetting" ];
  sysctl = {
      "vm.dirty_writeback_centisecs" = 1500;
      "vm.laptop_mode" = 5;
      "vm.swappiness" = 1;
  };
}
