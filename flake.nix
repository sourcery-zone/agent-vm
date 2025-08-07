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
    in {
      packages.${system} = {
        default = self.packages.${system}.my-microvm;
        my-microvm = self.nixosConfigurations.my-microvm.config.microvm.declaredRunner;
      };

      nixosConfigurations = {
        my-microvm = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = let
            pkgs = import nixpkgs {
              system = "x86_64-linux";
              config.allowUnfree = true;
            };
          in [
            microvm.nixosModules.microvm
            {
              networking.hostName = "my-microvm";
              programs.zsh.enable = true;
              users.users.root.password = "";
              users.users.shahin = {
                isNormalUser = true;
                password = "";
                shell = pkgs.zsh;
                extraGroups = [
                  "wheel"
                ];
              };

              microvm = {
                volumes = [ {
                  mountPoint = "/var";
                  image = "var.img";
                  size = 256;
                } ];
                shares = [ {
                  proto = "9p";
                  tag = "ro-store";
                  source = "/nix/store";
                  mountPoint = "/nix/.ro-store";
                }
                  {
                    proto = "9p";
                    tag = "project";
                    source = ".";
                    mountPoint = "/project";
                  }
                ];

                # "qemu" has 9p built-in!
                hypervisor = "qemu";
                socket = "control.socket";
              }

              environment.systemPackages = with pkgs; [
                git
                claude-code
              ];

              services.getty.autologinUser = "root";
              system.stateVersion = "25.11";
            }
          ];
        };
      };
    };
}
