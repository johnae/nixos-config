{
  hostName = "<HOSTNAME>";
  consoleFont = "Lat2-Terminus16";
  lightdmExtraConfig = "";
  dmBackground = "/home/shared/backgrounds/dark-mountains.png";
  userName = "john";
  userDescription = "John Axel Eriksson";
  userIcon = "/var/lib/AccountsService/icons/earth.png";
  userPassword = "<PASSWORD>"; # mkpasswd -m sha-512 -s <<< the-password-here
  backupDestination = "user@some.example.com";
  backupPort = "12345";
  backupSshKey = "/path/to/id_rsa";
  knownHosts = [ { hostNames = [ "[some.example.com]:12345" "[10.10.10.11]:12345" ]; publicKey = "ssh-rsa AAAAB3NzaC1yc2VeryLongKeyHereFollowsAllTheWayUntilTheEnd"; } ];
}
