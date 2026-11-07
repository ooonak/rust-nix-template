# rust-nix-template

A minimal Rust application template with a Nix development environment and a
statically linked Linux container image.

## Develop

Install [Nix with flakes enabled](https://nixos.org/download/), then enter the
development environment:

```sh
nix develop
```

From the project directory, build and run the app or run its checks:

```sh
cargo run
cargo fmt --check
cargo clippy --all-targets --all-features -- -D warnings
cargo test --all-features
cargo build --release
```

The flake targets `x86_64-linux`. To build the application or container image:

```sh
nix build .#app
nix build .#image
```

## Use the image

Run the published image with Docker:

```sh
docker run --rm ghcr.io/ooonak/rust-nix-template:latest

# or

$ ./scripts/hardened-run.sh ghcr.io/ooonak/rust-nix-template:latest
Starting hardened one-shot container: ghcr.io/ooonak/rust-nix-template:latest
Hello, world!
```

It prints:

```text
Hello, world!
```

To run a locally built image, load the archive created by `nix build .#image`,
then run its `rust-nix-template:latest` tag:

```sh
docker load < result
docker run --rm rust-nix-template:latest
```
