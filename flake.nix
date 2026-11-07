{
  description = "Rust development environment and static OCI image";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
  };

  outputs =
    { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = import nixpkgs { inherit system; };

          # Use the static musl toolchain.
          staticPkgs = pkgs.pkgsStatic;

          pname = "my-rust-app";
          binaryName = "hello";

          app = staticPkgs.rustPlatform.buildRustPackage {
            inherit pname;
            version = "0.1.0";
            src = ./.;
            cargoLock.lockFile = ./Cargo.lock;
          };

          # Root filesystem
          rootfs = pkgs.buildEnv {
            name = "${pname}-rootfs";
            paths = [ app ];
            pathsToLink = [ "/bin" ];
          };

          # OCI image
          image = pkgs.dockerTools.buildImage {
            name = pname;
            tag = "latest";
            copyToRoot = rootfs;
            config = {
              Entrypoint = [ "/bin/${binaryName}" ];
            };
          };
        in
        {
          default = app;
          inherit app rootfs image;
        }
      );

      formatter = forAllSystems (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        pkgs.nixfmt
      );

      checks = forAllSystems (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        {
          formatting =
            pkgs.runCommand "flake-format-check"
              {
                nativeBuildInputs = [ pkgs.nixfmt ];
              }
              ''
                nixfmt --check ${./flake.nix}
                touch $out
              '';
        }
      );

      devShells = forAllSystems (
        system:
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
        }
      );
    };
}
