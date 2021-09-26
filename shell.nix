with (import <nixpkgs> {});

let
  CursesUIGrid = buildPerlPackage {
    pname = "Curses-UI-Grid";
    version = "0.15";
    src = fetchurl {
      url = "mirror://cpan/authors/id/A/AD/ADRIANWIT/Curses-UI-Grid-0.15.tar.gz";
      sha256 = "0820ca4a9fb949ba8faf97af574018baeffb694e980c5087bb6522aa70b9dbec";
    };
    propagatedBuildInputs = with perlPackages; [ CursesUI TestPod TestPodCoverage ];
    meta = {
      description = "Create and manipulate data in grid model";
      license = with lib.licenses; [ artistic1 gpl1Plus ];
    };
  };

  deps = with perlPackages; [
    CursesUI WWWMechanize MojoDOM58 LWPProtocolHttps
  ];

in
mkShell {
 buildInputs = [
   CursesUIGrid deps perl
 ];
}
