{ config, lib, pkgs, ... }:

{
  imports =
    [
      (builtins.fetchTarball {
        url = "https://github.com/anduril/jetpack-nixos/archive/9ced0c1231f03540a1f31b883c62503f6fc08a21.tar.gz";
        sha256 = "06m0zqq8z973hq9yj8d26hh1hqn5g9avkxlsvdnf509z5z65ci99";
      } + "/modules/default.nix")
      ./hardware-configuration.nix
      ./ont-minknow-docker-compose.nix
    ];

  hardware.nvidia-jetpack.enable = true;
  hardware.nvidia-jetpack.som = "xavier-nx-emmc";
  hardware.nvidia-jetpack.carrierBoard = "devkit";
  hardware.graphics = {
    enable = true;
  };

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    substituters = [
      "https://cuda-maintainers.cachix.org"
    ];
    trusted-public-keys = [
      "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
    ];
  };

  services.xserver = {
    enable = true;
    displayManager.lightdm.enable = true;
    desktopManager.gnome.enable = true;
  };
  services.displayManager.defaultSession = "gnome";
  services.xrdp = {
    enable = true;
    defaultWindowManager = "${pkgs.icewm}/bin/icewm";
    openFirewall = true;
  };
  
  systemd.targets.sleep.enable = false;
  systemd.targets.suspend.enable = false;
  systemd.targets.hibernate.enable = false;
  systemd.targets.hybrid-sleep.enable = false;

  services.openssh = {
    enable = true;
    ports = [ 22 ];
    settings = {
      PasswordAuthentication = true;
      AllowUsers = [ "xbonisl" ];
      UseDns = true;
      PermitRootLogin = "yes";
    };
  };
  networking.firewall.allowedTCPPorts = config.services.openssh.ports;

  virtualisation.docker = {
    enable = true;
    autoPrune.enable = true;
  };
  virtualisation.oci-containers.backend = "docker";

  virtualisation.docker.package = pkgs.docker_26;
  virtualisation.docker.enableNvidia = true;

  virtualisation.podman.enable = true;
  virtualisation.podman.enableNvidia = true;

  # TODO: put the following into separate modules
  systemd.tmpfiles.rules = [
    "d /var/log/minknow 0775 minknowuser01 minknowuser01 -"
    "d /var/log/minknow/dorado 0775 minknowuser01 minknowuser01 -"
    "d /var/lib/minknow 0775 minknowuser01 minknowuser01 -"
    "d /var/lib/minknow/data 0775 minknowuser01 minknowuser01 -"
    "d /tmp/.guppy 0775 minknowuser01 minknowuser01 -"
  ];

  # TODO: make a dorado module out of this to demonstrate cross-cutting
  systemd.services.doradod-socket-permissions = {
    after = [ "doradod.service" ];
    requires = [ "doradod.service" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = ''
        ${pkgs.dash}/bin/dash -c ' \
          for i in $(seq 1 600); do \
            [ -S /tmp/.guppy/5555 ] && break; \
            sleep 1; \
          done; \
          chmod 0775 /tmp/.guppy/5555; \
        '
      '';
      User = "minknowuser01";
    };
  };
  systemd.services.doradod =
    let
      ont-dorado-server = import ../../packages/dorado-server.nix { inherit lib pkgs; };
      ont-dorado-models = import ../../packages/dorado-models.nix { inherit lib pkgs; };
    in
      {
        after = [ "nvpmodel.service" ];
        wantedBy = [ "multi-user.target" ];

        serviceConfig = {
          Type = "simple";
          ExecStart = ''
            ${ont-dorado-server}/opt/ont/dorado/bin/dorado_basecall_server \
            --log_path /var/log/minknow/dorado \
            --config dna_r10.4.1_e8.2_400bps_fast.cfg \
            --port /tmp/.guppy/5555 \
            --dorado_download_path ${ont-dorado-models}/opt/ont/dorado-models \
            --device cuda:all
          '';
          RestartPreventExitStatus = 2;
          Restart = "always";
          RestartSec = 10;
          User = "minknowuser01";
          MemoryHigh = "8G";
        };
      };

  users.users.xbonisl = {
    isNormalUser = true;
    extraGroups = [ "wheel" "video" "docker" "minknowuser01" ];
  };
  users.users.minknowuser01 = {
    isSystemUser = true;
    group = "minknowuser01";
    extraGroups = [ "video" ];
  };

  users.groups.minknowuser01 = {};

  system.stateVersion = "24.05";
}
