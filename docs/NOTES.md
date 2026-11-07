# Development and image notes

This document records the host setup, Nix commands, and OCI image inspection
steps used with this project.

## Set up the host

Install Nix. The following uses the Determinate Systems installer:

```bash
curl --proto '=https' --tlsv1.2 -sSf -L \
  https://install.determinate.systems/nix | sh -s -- install
```

Install `direnv` and `nix-direnv` with Nix:

```bash
nix profile add nixpkgs#direnv nixpkgs#nix-direnv
```

For Bash, add the direnv hook to `~/.bashrc`:

```bash
eval "$(direnv hook bash)"
```

In the project root, configure direnv to use the flake and allow it:

```bash
echo "use flake" > .envrc
direnv allow
```

## Check the flake

Run the flake checks without building their outputs:

```bash
nix flake check --no-build
```

List the flake's development shell and packages:

```text
$ nix flake show
warning: Git tree '/home/swu/git/rust-nix-template' has uncommitted changes
git+file:///home/swu/git/rust-nix-template
├───devShells
│   └───x86_64-linux
│       └───default: development environment
└───packages
    └───x86_64-linux
        ├───app: package
        ├───default: package
        ├───image: package
        └───rootfs: package
```

The warning above is sample output; it appears when the flake is evaluated from
a Git tree with uncommitted changes.

## Build and inspect the static binary

Build the root filesystem, application package, and OCI image. The `-o`
arguments give each build result a descriptive local name:

```bash
nix build .#rootfs -o result-rootfs
nix build .#app -o result-app
nix build .#image -o result-image
```

The root filesystem contains the `hello` executable:

```text
$ find -L result-rootfs -maxdepth 3 -type f
result-rootfs/bin/hello
```

Check that it is statically linked and inspect its size:

```text
$ ldd result-rootfs/bin/hello
        statically linked

$ ls -lhH result-rootfs/bin/hello
-r-xr-xr-x 1 root root 623K jan  1  1970 result-rootfs/bin/hello
```

Run it directly:

```text
$ ./result-rootfs/bin/hello
Hello, world!
```

## Inspect the OCI image filesystem

Build and load the image. If an old `my-rust-app:latest` image is present, it
can be removed first:

```text
$ nix build .#image -o result-image
$ docker image rm --force my-rust-app:latest
Untagged: my-rust-app:latest
Deleted: sha256:5c12cab6a8993f7610240c63c76e4ab1c3be2b784b15238177f82e487d626786

$ docker load < result-image
984c5ab106ea: Loading layer [==================================================>]  645.1kB/645.1kB
Loaded image: my-rust-app:latest
```

The load output above is an example from a prior build; image IDs and layer
sizes may differ. Create a container without starting it, then export its
filesystem listing:

```text
$ CID=$(docker create my-rust-app:latest)
$ docker export "$CID" | tar -tvf -
-rwxr-xr-x 0/0               0 2026-11-07 23:15 .dockerenv
dr-xr-xr-x 0/0               0 1980-01-01 01:00 bin/
lrwxrwxrwx 0/0               0 1980-01-01 01:00 bin/hello -> /nix/store/w9ixm0fysnzh3dk34dxp6g9mvh85j802-my-rust-app-static-x86_64-unknown-linux-musl-0.1.0/bin/hello
drwxr-xr-x 0/0               0 2026-11-07 23:15 dev/
-rwxr-xr-x 0/0               0 2026-11-07 23:15 dev/console
drwxr-xr-x 0/0               0 2026-11-07 23:15 dev/pts/
drwxr-xr-x 0/0               0 2026-11-07 23:15 dev/shm/
drwxr-xr-x 0/0               0 2026-11-07 23:15 etc/
-rwxr-xr-x 0/0               0 2026-11-07 23:15 etc/hostname
-rwxr-xr-x 0/0               0 2026-11-07 23:15 etc/hosts
lrwxrwxrwx 0/0               0 2026-11-07 23:15 etc/mtab -> /proc/mounts
-rwxr-xr-x 0/0               0 2026-11-07 23:15 etc/resolv.conf
dr-xr-xr-x 0/0               0 1980-01-01 01:00 nix/
dr-xr-xr-x 0/0               0 1980-01-01 01:00 nix/store/
dr-xr-xr-x 0/0               0 1980-01-01 01:00 nix/store/w9ixm0fysnzh3dk34dxp6g9mvh85j802-my-rust-app-static-x86_64-unknown-linux-musl-0.1.0/
dr-xr-xr-x 0/0               0 1980-01-01 01:00 nix/store/w9ixm0fysnzh3dk34dxp6g9mvh85j802-my-rust-app-static-x86_64-unknown-linux-musl-0.1.0/bin/
-r-xr-xr-x 0/0          637344 1980-01-01 01:00 nix/store/w9ixm0fysnzh3dk34dxp6g9mvh85j802-my-rust-app-static-x86_64-unknown-linux-musl-0.1.0/bin/hello
drwxr-xr-x 0/0               0 2026-11-07 23:15 proc/
drwxr-xr-x 0/0               0 2026-11-07 23:15 sys/
```

The listing shows the `hello` entry under `/bin` pointing into the Nix store;
the executable in this example is 637344 bytes.

## Run the OCI image

Load the built image, run it, and optionally check the local image listing:

```text
$ nix build .#image -o result-image
$ docker load < result-image
$ docker run --rm my-rust-app:latest
Hello, world!

$ docker image ls | grep my-rust-app
my-rust-app:latest                                                                                     2d9722575d2a        637kB             0B
```
