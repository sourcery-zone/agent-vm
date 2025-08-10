# AI Agent Sandbox

This project provides a secure and compartmentalized environment for
running AI agents. It utilizes
[microvm.nix](https://github.com/microvm-nix/microvm.nix) to create a
lightweight NixOS-based virtual machine.

The primary goal is to enable developers to safely run AI agents without
compromising the security of their host system. The agent operates within a
MicroVM and only has access to its own home directory, which is created
alongside the machine. Project directories from the host can be selectively
mounted into this home directory, making them accessible to the agent in a
controlled manner.

> [!TIP]
> There is nothing special about this VM to make it particularly
> limited to AI agent use-cases. These machines can be used for
> compartmentalizing other applications as well.

> [!WARNING]
> I'm not a security expert, and this is designed around my understanding
> of potential risks of running AI agents. Use it with caution.

## Table of Contents

- [Features](#features)
- [Getting Started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Quick Start](#quick-start)
  - [Building the VM](#building-the-vm)
  - [Running the VM](#running-the-vm)
- [Usage](#usage)
  - [Mounting Host Directories](#mounting-host-directories)
  - [Gemini Authentication](#gemini-authentication)
- [Technical Details](#technical-details)
- [Troubleshooting](#troubleshooting)
- [Future Work](#future-work)
- [Contributing](#contributing)

## Features

- **Secure Environment:** Run AI agents in a lightweight, isolated MicroVM.
- **Controlled Access:** Selectively mount host directories into the agent's
  home directory.
- **NixOS-based:** Leverage the power and reproducibility of NixOS.
- **Easy to Use:** Get started quickly with a single command.

## Getting Started

These instructions will guide you through building and running the
MicroVM on your local machine.

### Prerequisites

- [Nix](https://nixos.org/download.html) installed on your system.
- An x86_64 Linux system.
- [microvm.nix](https://github.com/microvm-nix/microvm.nix) installed.
- `virtufsd` kernel module is enabled.

### Quick Start

To run this machine, without any customization, you can use the
following:

```sh
sudo microvm -f https://github.com/sourcery-zone/agent-vm -c agent-vm
```

### Building the VM

To build the virtual machine, clone it, and then run the following
command in the project's root directory:

```bash
nix build .#nixosConfigurations.agent-vm.config.microvm.declaredRunner
```

This command will create the VM runner in the `result/bin/` directory. The
resulting commands can be used to run the local build directly.

> [!NOTE]
> You need to run `result/bin/virtiofsd-reload` before
> starting the vm using `result/bin/microvm-run`.

### Running the VM

To run the VM, execute the following command:

```bash
sudo systemctl start microvm@agent-vm.service
```

This will start the MicroVM. You can then SSH into the VM using the
forwarded port:

```bash
ssh -p 2222 agent@localhost
```

## Usage

### Mounting Host Directories

The home directory of agent is created at
`/var/lib/microvms/agent-home/` (if it's not created, and causes agent
to fail, build it manually). To make any of your host directories,
accessible via `agent-vm`, you can simply, mount them to a directory,
inside this path:

```sh
sudo mount --bind $(pwd) /var/lib/microvms/agent-home/project/
```

### Gemini Authentication

Add your [Gemini
Token](https://ai.google.dev/gemini-api/docs/api-key), to
`/var/lib/microvms/agent-home/.profile` as follows:

```sh
echo "export GEMINI_API_KEY=XXXXXXXXXXXXXXXXXXXXXXXXXXXX" >> /var/lib/microvms/agent-home/.profile
```

## Technical Details

- **Hypervisor:** QEMU
- **Memory:** 4096 MB
- **vCPUs:** 3
- **Base Image:** NixOS Unstable
- **Networking:** User-mode networking with port forwarding (host port 2222 to
  guest port 22 for SSH).

## Troubleshooting

### `microvm` installation fails

If the `microvm` command fails, it might be because it needs `sudo` to
access the `/nix/var/nix/gcroots/microvm/` directory. Without it, it'll
install a broken vm, which `systemd` won't be able to run.

To fix this, first remove the broken installation:

```sh
sudo rm -rf /var/lib/microvms/agent-vm/
```

Then, try installing it again with `sudo`:

```sh
sudo microvm -f https://github.com/sourcery-zone/agent-vm -c agent-vm
```

## Future Work

This project is under active development, and there are several areas
where it could be extended and improved. Some of the planned features
include:

- **Greater Configurability:** Allowing users to easily customize VM
  settings such as memory, vCPUs, and base image.
- **non-x86 Compatibility:** ¯\_(ツ)_/¯

We welcome contributions and suggestions from the community. If you have
an idea for a new feature or improvement, please open an issue on
GitHub.

## Contributing

Contributions are welcome! Please read the [CONTRIBUTING.md](CONTRIBUTING.md)
file for details on how to contribute to this project.
