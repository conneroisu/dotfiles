{
  pkgs,
  # inputs,
  ...
}: let
  settingsFormat = pkgs.formats.toml {};

  coderConfig = {
    app = "conneroh-com-coder";
    primary_region = "ord";
    build = {
      image = "ghcr.io/coder/coder:latest";
    };
    http_service = {
      internal_port = 8080;
      force_https = true;
      processes = ["app"];
      auto_stop_machines = "stop";
      auto_start_machines = true;
      min_machines_running = 0;
    };
    vm = [
      {
        memory = "1gb";
        cpu_kind = "shared";
        cpus = 2;
      }
    ];
  };

  CoderToml = settingsFormat.generate "fly.coder.toml" coderConfig;
in
  pkgs.writeShellScriptBin "deploy-coder" ''

    ${pkgs.flyctl}/bin/fly deploy \
      -c "${CoderToml}" \
      -i "$REGISTY:latest" \
  ''
