{ config, lib, pkgs, inputs, ... }:

with lib;

let
  cfg = config.services.openclaw;
  openclawConfig = pkgs.writeText "openclaw.json5" ''
    {
      "models": {
        "providers": {
          "ollama": {
            "endpoint": "${cfg.ollamaEndpoint}",
            "apiKey": "ollama"
          }
        },
        "default": "ollama:${cfg.ollamaModel}"
      }
    }
  '';
in {
  options.services.openclaw = {
    enable = mkEnableOption "OpenClaw AI agent gateway";

    package = mkOption {
      type = types.package;
      default = (import inputs.nixpkgs-unstable {
        inherit (pkgs.stdenv.hostPlatform) system;
        config.permittedInsecurePackages = [ "openclaw-2026.4.21" ];
      }).openclaw;
      defaultText = literalExpression "pkgs.openclaw from nixpkgs-unstable";
      description = "OpenClaw package to use.";
    };

    ollama.enable = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to enable Ollama service automatically.";
    };

    ollamaEndpoint = mkOption {
      type = types.str;
      default = "http://localhost:11434";
      description = "Ollama API endpoint.";
    };

    ollamaModel = mkOption {
      type = types.str;
      default = "llama3.2";
      description = "Default Ollama model to use.";
    };

    extraEnvironment = mkOption {
      type = with types; attrsOf str;
      default = {};
      description = "Extra environment variables for OpenClaw.";
    };

    stateDir = mkOption {
      type = types.str;
      default = "/var/lib/openclaw";
      description = "State directory for OpenClaw.";
    };
  };

  config = mkIf cfg.enable {
    services.ollama.enable = mkIf cfg.ollama.enable true;

    systemd.tmpfiles.rules = [
      "d ${cfg.stateDir} 0755 openclaw openclaw -"
    ];

    users.users.openclaw = {
      isSystemUser = true;
      group = "openclaw";
      description = "OpenClaw service user";
    };
    users.groups.openclaw = {};

    environment.systemPackages = [ cfg.package ];

    systemd.services.openclaw = {
      description = "OpenClaw AI Agent Gateway";
      after = [ "network.target" ] ++ optional cfg.ollama.enable "ollama.service";
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "simple";
        User = "openclaw";
        Group = "openclaw";
        ExecStart = "${cfg.package}/bin/openclaw gateway start";
        Restart = "on-failure";
        RestartSec = "5s";
        WorkingDirectory = cfg.stateDir;
        Environment = [
          "OPENCLAW_STATE_DIR=${cfg.stateDir}"
          "OPENCLAW_CONFIG_PATH=${openclawConfig}"
        ] ++ mapAttrsToList (k: v: "${k}=${v}") cfg.extraEnvironment;
      };
    };
  };
}
