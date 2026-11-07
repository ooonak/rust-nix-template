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
