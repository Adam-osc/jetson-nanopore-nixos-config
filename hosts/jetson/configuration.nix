{ config, lib, pkgs, ... }:

{
  imports =
    let
      minknowDataDir = "/var/lib/minknow";
      minknowLogDir = "/var/log/minknow";
      doradoSocket = "/tmp/.guppy/5555";
      minknowManagerDockerfile = pkgs.fetchurl {
        url = "https://raw.githubusercontent.com/Adam-osc/minknow-manager-docker/0ea1f6bc571e7df4f9b099099bf9338b72e98b3e/Dockerfile";
        sha256 = "sha256-lA76KByDiCk3hrG2LoM1S5VJ4GtxTkY3Wt6UDBZVsQ8=";
      };
    in
      [
        (builtins.fetchTarball {
          url = "https://github.com/anduril/jetpack-nixos/archive/9ced0c1231f03540a1f31b883c62503f6fc08a21.tar.gz";
          sha256 = "06m0zqq8z973hq9yj8d26hh1hqn5g9avkxlsvdnf509z5z65ci99";
        } + "/modules/default.nix")
        (import ../../services/minknow-manager-docker-compose.nix) {
          name = "minknow-manager";
          version = "6.2.6";
          positionsPortStart = 8000;
          managerPortStart = 9501;
          expose = true;
          inherit minknowDataDir minknowLogDir doradoSocket minknowManagerDockerfile;
        }
        (import ../../services/dorado-service.nix) {
          name = "doradod";
          version = "7.6.7";
          doradoLogDir = "${minknowLogDir}/dorado";
          doradoServer = (import ../../packages/dorado-server.nix { inherit lib pkgs; });
          doradoModels = (import ../../packages/dorado-models.nix { inherit lib pkgs; });
          inherit doradoSocket;
        }
        ./hardware-configuration.nix
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
  networking.firewall.allowedTCPPorts = config.services.openssh.ports ++ [ 8050 ];

  virtualisation.docker = {
    enable = true;
    autoPrune.enable = true;
  };
  virtualisation.oci-containers.backend = "docker";

  virtualisation.docker.package = pkgs.docker_26;
  virtualisation.docker.enableNvidia = true;

  virtualisation.podman.enable = true;
  virtualisation.podman.enableNvidia = true;

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
