# k3s — Kubernetes server (control plane) or agent (worker node).
#
# This module only installs and configures k3s itself. Everything inside the
# cluster is owned by Flux CD; see the separate homek3s repository.
#
# The API server is reachable from other Tailscale devices only. No ports are
# opened on the LAN, so joining an untrusted Wi-Fi network exposes nothing.
# Worker nodes join over the tailnet as well.

{ config, pkgs, lib, ... }:

with lib;

let
  cfg = config.my_services.k3s;
in
{
  options.my_services.k3s = {
    enable = mkEnableOption "k3s";

    role = mkOption {
      type = types.enum [ "server" "agent" ];
      default = "server";
      description = ''
        Whether this node runs the control plane (server) or joins an
        existing cluster as a worker (agent).
      '';
    };

    serverAddr = mkOption {
      type = types.str;
      default = "";
      example = "https://thinkpad-nixos.tailxxxx.ts.net:6443";
      description = ''
        URL of the k3s server to join. Required for agents, ignored on
        servers.
      '';
    };

    tokenFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      example = "/run/secrets/k3s-token";
      description = ''
        File containing the cluster join token (contents of
        /var/lib/rancher/k3s/server/node-token on the server). Required for
        agents.
      '';
    };

    tlsSANs = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "thinkpad-nixos.tailxxxx.ts.net" ];
      description = ''
        Extra Subject Alternative Names for the Kubernetes API certificate.
        Add the Tailscale MagicDNS name here, otherwise kubectl from another
        machine fails with "certificate is valid for ... not ...".
      '';
    };

    nodeLabels = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "node-role.kubernetes.io/worker=" ];
      description = "Labels applied to this node at registration.";
    };

    nodeTaints = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "dedicated=gpu:NoSchedule" ];
      description = "Taints applied to this node at registration.";
    };

    clusterInit = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Initialize a new cluster. Only meaningful on the first server, never
        on an agent.
      '';
    };

    extraFlags = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "--disable=traefik" ];
      description = "Extra flags appended after the module's own k3s flags.";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.role != "agent" || cfg.serverAddr != "";
        message = "my_services.k3s.serverAddr must be set when role = \"agent\".";
      }
      {
        assertion = cfg.role != "agent" || cfg.tokenFile != null;
        message = "my_services.k3s.tokenFile must be set when role = \"agent\".";
      }
      {
        assertion = cfg.role != "agent" || !cfg.clusterInit;
        message = "my_services.k3s.clusterInit cannot be enabled on an agent.";
      }
    ];

    services.k3s = {
      enable = true;
      role = cfg.role;
      serverAddr = cfg.serverAddr;
      tokenFile = cfg.tokenFile;
      nodeLabel = cfg.nodeLabels;
      nodeTaint = cfg.nodeTaints;
      clusterInit = cfg.clusterInit;

      extraFlags =
        # Let kubectl/flux read /etc/rancher/k3s/k3s.yaml as the normal user.
        # Acceptable on a single-user laptop; on a shared host, copy the file
        # into ~/.kube/config with mode 0600 instead. Servers only.
        optional (cfg.role == "server") "--write-kubeconfig-mode=0644"
        ++ optionals (cfg.role == "server") (
          map (san: "--tls-san=${san}") (
            unique ([ "127.0.0.1" "localhost" config.networking.hostName ] ++ cfg.tlsSANs)
          )
        )
        ++ cfg.extraFlags;

      # This machine has an 8.8 GiB swap partition; kubelet refuses to start
      # with swap enabled unless told otherwise.
      extraKubeletConfig.failSwapOn = false;
    };

    # Kernel bits kube-proxy and flannel need.
    boot.kernelModules = [ "br_netfilter" "overlay" ];
    boot.kernel.sysctl = {
      "net.ipv4.ip_forward" = 1;
      "net.bridge.bridge-nf-call-iptables" = 1;
      "net.bridge.bridge-nf-call-ip6tables" = 1;
    };

    networking.firewall = mkMerge [
      # Pod and VXLAN traffic must not be filtered by the host firewall.
      { trustedInterfaces = [ "cni0" "flannel.1" ]; }

      # Reach the API from other tailnet devices, and let nodes talk to each
      # other over the tailnet (kubelet + flannel VXLAN).
      (mkIf config.services.tailscale.enable {
        interfaces."tailscale0".allowedTCPPorts =
          [ 10250 ] ++ optional (cfg.role == "server") 6443;
        interfaces."tailscale0".allowedUDPPorts = [ 8472 ];
      })
    ];

    # Cluster tooling. k3s itself is added to systemPackages by its module.
    environment.systemPackages = mkIf (cfg.role == "server") (
      with pkgs; [
        kubectl
        kubernetes-helm
        fluxcd
        k9s
      ]
    );
  };
}
