{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    sbt = {
      url = "github:zaninime/sbt-derivation";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    sbt,
  }: let
    allSystems = ["x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin"];

    forAllSystems = f:
      nixpkgs.lib.genAttrs allSystems (system:
        f {
          pkgs = import nixpkgs {inherit system;};
        });
  in {
    packages = forAllSystems ({pkgs}: {
      default = sbt.lib.mkSbtDerivation rec {
        inherit pkgs;

        pname = "eldarica";
        version = "2.2.1";
        src =
          pkgs.fetchFromGitHub
          {
            owner = "uuverifiers";
            repo = "eldarica";
            rev = "v${version}";
            sha256 = "bBbwY/zBGPJQYR+UjTVZP/AHOFiIjG/lzXN7a3DIFcc=";
          };
        depsSha256 = "RR52hrzxK2hv01HnGebTRNLml5Uc9XmX4ptLKb4T6/k=";
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
        };
      };
    });
  };
}
