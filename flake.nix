{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    systems.url = "github:nix-systems/default";
    sbt = {
      url = "github:zaninime/sbt-derivation";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    systems,
    sbt,
  }: let
    forAllSystems = f:
      nixpkgs.lib.genAttrs (import systems) (system:
        f {
          pkgs = import nixpkgs {inherit system;};
        });
  in {
    packages = forAllSystems ({pkgs}: rec {
      eldarica = sbt.lib.mkSbtDerivation rec {
        inherit pkgs;

        pname = "eldarica";
        version = "2.3";
        src =
          pkgs.fetchFromGitHub
          {
            owner = "uuverifiers";
            repo = "eldarica";
            rev = "v${version}";
            sha256 = "KZWAgsDptNoolD5LHDSd49BKOYk4JrggZc7+6UIE7PE=";
          };
        depsSha256 = "ivZ/sgb9DcvxXkNwBUOPwaXIdgFhbcRsCocITUZUoFQ=";
        nativeBuildInputs = [pkgs.makeWrapper];
        buildPhase = ''
          sbt assembly
        '';

        installPhase = ''
          mkdir -p $out/bin
          mkdir -p $out/share/java

          cp target/scala-2.*/*.jar $out/share/java

          makeWrapper ${pkgs.jdk8_headless}/bin/java $out/bin/eld \
            --add-flags "-jar $out/share/java/Eldarica-assembly-${version}.jar"
        '';

        meta = with pkgs.lib; {
          description = "The Eldarica model checker";
          homepage = "https://github.com/uuverifiers/eldarica";
          license = licenses.bsd2;
          platforms = platforms.unix;
          mainProgram = "eld";
        };
      };
      default = eldarica;
    });
  };
}
