{ callPackage, fetchurl, fetchpatch, stdenv
, ocamlPackages, coqPackages, rubber, hevea, emacs }:

stdenv.mkDerivation {
  pname = "why3";
  version = "1.3.1";

  src = fetchurl {
    url = "https://gforge.inria.fr/frs/download.php/file/38291/why3-1.3.1.tar.gz";
    sha256 = "16zcrc60zz2j3gd3ww93z2z9x2jkxb3kr57y8i5rcgmacy7mw3bv";
  };

  buildInputs = with ocamlPackages; [
    ocaml findlib ocamlgraph zarith menhir
    # Compressed Sessions
    # Emacs compilation of why3.el
    emacs
    # Documentation
    rubber hevea
    # GUI
    lablgtk
    # WebIDE
    js_of_ocaml js_of_ocaml-ppx
    # Coq Support
    coqPackages.coq coqPackages.flocq ocamlPackages.camlp5
  ];

  propagatedBuildInputs = with ocamlPackages; [ camlzip num ];

  enableParallelBuilding = true;

  postPatch = ''
    substituteInPlace Makefile.in --replace js_of_ocaml.ppx js_of_ocaml-ppx
  '';

  configureFlags = [ "--enable-verbose-make" ];

  installTargets = [ "install" "install-lib" ];

  passthru.withProvers = callPackage ./with-provers.nix {};

  meta = with stdenv.lib; {
    description = "A platform for deductive program verification";
    homepage    = "http://why3.lri.fr/";
    license     = licenses.lgpl21;
    platforms   = platforms.unix;
    maintainers = with maintainers; [ thoughtpolice vbgl ];
  };
}
