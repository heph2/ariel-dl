{ pkgs ? import <nixpkgs> {} }:

let
  nur = import (builtins.fetchTarball "https://github.com/nix-community/NUR/archive/master.tar.gz") {
    inherit pkgs;
  };
in
pkgs.dockerTools.buildImage {
  name = "ariel-dl";
  tag = "nix";
  contents = [ nur.repos.heph2.ariel-dl ];
  config = {
    Entrypoint = [ "${nur.repos.heph2.ariel-dl}/bin/ariel-dl" ];
  };
}
