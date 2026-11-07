
{
  description = "Rust development environment and static OCI image";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
  };

  outputs = { self, nixpkgs }:
    let
      systems = [
        "x86_64-linux"
      ];

      forAllSystems = nixpkgs.lib.genAttrs systems;

    in
    {
      packages = forAllSystems (system:
        let
          pkgs = import nixpkgs { inherit system; };

          # Use the static musl toolchain.
          staticPkgs = pkgs.pkgsStatic;

          pname = "my-rust-app";

          app = staticPkgs.rustPlatform.buildRustPackage {
            inherit pname;

            version = "0.1.0";

            src = ./.;

            cargoLock.lockFile = ./Cargo.lock;
          };

          # Create a minimal root filesystem.
          rootfs = pkgs.buildEnv {
            name = "${pname}-rootfs";
            paths = [ app ];
            pathsToLink = [ "/bin" ];
          };

          # Build a base-image-free OCI image.
          image = pkgs.dockerTools.buildLayeredImage {
            name = pname;
            tag = "latest";

            contents = [
              app
            ];

            config = {
              Entrypoint = [
                "${app}/bin/my-rust-app"
              ];
            };
          };

        in
        {
          default = app;

          inherit app image;
        });

      devShells = forAllSystems (system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        {
          default = pkgs.mkShell {
            packages = with pkgs; [
              rustc
              cargo
              rustfmt
              clippy
              rust-analyzer
              cargo-audit
              pkg-config
            ];

            RUST_SRC_PATH = "${pkgs.rustPlatform.rustLibSrc}";
          };
        });
    };
}
