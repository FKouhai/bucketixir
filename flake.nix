{
  description = "Bucketixir - CLI tool for S3 API";

  inputs = {
    systems.url = "github:nix-systems/default";
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    git-hooks.url = "github:cachix/git-hooks.nix";
  };

  outputs =
    {
      self,
      systems,
      nixpkgs,
      git-hooks,
      ...
    }:
    let
      forEachSystem = nixpkgs.lib.genAttrs (import systems);
    in
    {
      # Run the hooks with `nix fmt`.
      formatter = forEachSystem (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          inherit (self.checks.${system}.pre-commit-check) config;
          inherit (config) package configFile;
          script = ''
            ${pkgs.lib.getExe package} run --all-files --config ${configFile}
          '';
        in
        pkgs.writeShellScriptBin "pre-commit-run" script
      );

      # Run the hooks in a sandbox with `nix flake check`.
      checks = forEachSystem (system: {
        pre-commit-check = git-hooks.lib.${system}.run {
          src = ./.;
          hooks = {
            # Nix
            statix.enable = true;
            nixfmt-rfc-style.enable = true;
            # Elixir
            mix-format.enable = true;
            credo.enable = true;
            # Git
            convco.enable = true;
          };
        };
      });

      # Build the Elixir escript
      packages = forEachSystem (system: {
        default =
          let
            pkgs = nixpkgs.legacyPackages.${system};
            beamPkgs = pkgs.beamPackages;
          in
          beamPkgs.buildMix {
            name = "bucketixir";
            version = "0.1.0";
            src = ./.;
            buildPhase = "mix escript.build";
            installPhase = "mkdir -p $out/bin && cp bucketixir $out/bin/";
          };
      });

      # Enter a development shell with `nix develop`.
      devShells = forEachSystem (system: {
        default =
          let
            pkgs = nixpkgs.legacyPackages.${system};
            shellFromNix = import ./shell.nix { inherit pkgs; };
            inherit (self.checks.${system}.pre-commit-check) shellHook enabledPackages;
          in
          shellFromNix.overrideAttrs (old: {
            inherit shellHook;
            buildInputs = old.buildInputs ++ enabledPackages;
          });
      });
    };
}
