{ fetchurl, perlPackages, shortenPerlShebang }:

perlPackages.buildPerlPackage {
  pname = "ariel-dl";
  version = "v0.1";

  src = fetchurl {
    url = "https://github.com/heph2/ariel-dl/releases/download/v0.1/ariel-dl.tar.gz";
    sha256 = "0anpgsgya4w1kpli4zqzfmq6s4i47da29dwmxf7shl4yz8mf9nkg";
  };

  propagatedBuildInputs = with perlPackages; [
    WWWMechanize MojoDOM58 LWPProtocolHttps ];

  buildInputs = [shortenPerlShebang];

  preBuild = ''
   patchShebangs script/atlas
 '';       

  postInstall = ''
   shortenPerlShebang $out/bin/atlas
  '';

}
