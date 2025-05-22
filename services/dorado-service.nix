{ name
, version
, minknowLogDir
, doradoSocket
, doradoServer
, doradoModels
}:

{ config, lib, pkgs, ... }:

let
  doradoServiceName = "${name}-${version}";
in
{
  systemd.services."${doradoServiceName}-socket-permissions" = {
    after = [ "${doradoServiceName}.service" ];
    requires = [ "${doradoServiceName}.service" ];
    partOf = [ "${doradoServiceName}.service" ];

    serviceConfig = {
      Type = "oneshot";
      ExecStart = ''
        ${pkgs.dash}/bin/dash -c ' \
          sleep 2m; \
          for i in $(seq 1 600); do \
            [ -S ${doradoSocket} ] && break; \
            sleep 1s; \
          done; \
          chmod 0775 ${doradoSocket}; \
        '
      '';
      User = "minknowuser01";
    };
  };
  systemd.services."${doradoServiceName}" =
    {
      after = [ "nvpmodel.service" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "simple";
        ExecStart = ''
            ${doradoServer}/opt/ont/dorado/bin/dorado_basecall_server \
            --log_path "${minknowLogDir}/dorado" \
            --port ${doradoSocket} \
            --dorado_download_path ${doradoModels}/opt/ont/dorado-models \
            --device cuda:all
          '';
        RestartPreventExitStatus = 2;
        Restart = "always";
        RestartSec = 10;
        User = "minknowuser01";
        MemoryHigh = "8G";
      };
    };
}
