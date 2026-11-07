# Host setup

Install Nix.

```bash
curl --proto '=https' --tlsv1.2 -sSf -L \
  https://install.determinate.systems/nix | sh -s -- install
```

Setup.

```bash
$ nix profile add nixpkgs#direnv nixpkgs#nix-direnv

# And also add to .bashrc
eval "$(direnv hook bash)"
```

Now in project root

```bash
$ echo "use flake" > .envrc
$ direnv allow
```

## Nix trix

```bash
$ nix flake check --no-build
```

## One Statically linked binary in OCI container

```bash
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

$ nix build .#rootfs -o result-rootfs
$ nix build .#app -o result-app
$ nix build .#image -o result-image

$ find -L result-rootfs -maxdepth 3 -type f
result-rootfs/bin/hello

$ ldd result-rootfs/bin/hello
        statically linked

$ ls -lhH result-rootfs/bin/hello
-r-xr-xr-x 1 root root 623K jan  1  1970 result-rootfs/bin/hello

$ ./result-rootfs/bin/hello
Hello, world!
```

Inspect the image filesystem

```
$ nix build .#image

$ docker image rm --force my-rust-app:latest 
Untagged: my-rust-app:latest
Deleted: sha256:5c12cab6a8993f7610240c63c76e4ab1c3be2b784b15238177f82e487d626786

$ docker load < result
984c5ab106ea: Loading layer [==================================================>]  645.1kB/645.1kB
Loaded image: my-rust-app:latest

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

Load and run the OCI image

```bash
$ nix build .#image
$ docker load < result
$ docker run --rm my-rust-app:latest
Hello, world!

$ docker image ls | grep my-rust-app
my-rust-app:latest                                                                                     2d9722575d2a        637kB             0B 
```
