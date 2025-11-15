{
  pkgs ? import <nixpkgs> { },
}:
let
  buildCli = pkgs.writeShellApplication {
    name = "build";
    text = ''
      cd "$(git rev-parse --show-toplevel)" && mix escript.build
      cd -
    '';
  };
  buildRunHelp = pkgs.writeShellApplication {
    name = "buildRun";
    text = ''
      cd "$(git rev-parse --show-toplevel)" && mix escript.build
      ./bucketixir --help
      cd -
    '';
  };
in

pkgs.mkShell {
  buildInputs = with pkgs; [
    buildCli
    buildRunHelp
    git
    elixir
    erlang
  ];
}
