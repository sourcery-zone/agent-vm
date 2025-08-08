{
  description = "NixOS in MicroVMs";

  nixConfig = {
    extra-substituters = [ "https://microvm.cachix.org" ];
    extra-trusted-public-keys = [ "microvm.cachix.org-1:oXnBc6hRE3eX5rSYdRyMYXnfzcCxC7yKPTbZXALsqys=" ];
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    microvm = {
      url = "github:microvm-nix/microvm.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, microvm }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
    in {
      packages.${system} = {
        default = self.packages.${system}.agent-vm;
        agent-vm = self.nixosConfigurations.agent-vm.config.microvm.declaredRunner;

        run-vm = pkgs.writeShellApplication {
          name = "run-vm";
          runtimeInputs = with pkgs; [
            tmux
            virtiofsd
          ];

          text = ''
            #!/usr/bin/env bash
            set -euo pipefail

            SESSION_NAME="agent"

            # Start tmux session with the virtiofsd command
            tmux new-session -d -s "$SESSION_NAME" -n virtiofsd bash -c "
            virtiofsd \
               --socket-path=agent-vm-virtiofs-project.sock \
               --socket-group=kvm \
               --shared-dir=$(pwd) \
               --thread-pool-size $(nproc) \
               --posix-acl --xattr
           "

           # Wait a few seconds before starting the second command
           sleep 3

           # Add second window to run nix command
           tmux new-window -t "$SESSION_NAME" -n microvm bash -c "
             nix run .#agent-vm
           "

           # Attach to the session
           tmux attach-session -t "$SESSION_NAME"
          '';
        };
      };

      devShells.${system}.default = pkgs.mkShell {
        name = "agent";

        packages = [
          pkgs.tmux
          self.packages.${system}.run-vm
        ];
      };

      nixosConfigurations = {
        agent-vm = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            microvm.nixosModules.microvm
            {
              networking.hostName = "agent-vm";
              networking.useDHCP = true;

              programs.zsh.enable = true;

              users.users.root.password = "";
              users.users.agent = {
                isNormalUser = true;
                uid = 1000;
              };

              security.sudo.extraRules = [
                {
                  users = [ "agent" ];
                  commands = [
                    {
                      command = "/run/current-system/sw/bin/shutdown";
                      options = [ "NOPASSWD" ];
                    }
                  ];
                }
              ];

              microvm = {
                hypervisor = "qemu";
                socket = "control.socket";

                volumes = [{
                  mountPoint = "/var";
                  image = "var.img";
                  size = 256;
                }];

                shares = [
                  {
                    proto = "9p";
                    tag = "ro-store";
                    source = "/nix/store";
                    mountPoint = "/nix/.ro-store";
                  }
                  {
                    proto = "virtiofs";
                    tag = "project";
                    source = ".";
                    mountPoint = "/home/agent/project";
                  }
                ];

                interfaces = [
                  {
                    type = "user";
                    id = "net0";
                    mac = "52:54:00:12:34:56";
                  }
                ];
              };

              networking.firewall.enable = true;
              networking.firewall.allowedTCPPorts = [ 443 ];

              environment.systemPackages = with pkgs; [
                git
                claude-code
                gemini-cli
              ];

              services.getty.autologinUser = "agent";
              system.stateVersion = "25.11";
            }
          ];
        };
      };
    };
}
