{ lib, fetchPypi, buildPythonPackage, python, pkg-config, libX11
, SDL2, SDL2_image, SDL2_mixer, SDL2_ttf, libpng, libjpeg, portmidi, freetype
}:

buildPythonPackage rec {
  pname = "pygame2";
  version = "2.0.0.dev10";

  src = fetchPypi {
    pname = "pygame";
    inherit version;
    sha256 = "12p0zagrhd0z1f28c5ia8yp7xjp8yw9l6jiw3qgkmrymqfh7shy4";
  };

  nativeBuildInputs = [
    pkg-config SDL2
  ];

  buildInputs = [
    SDL2 SDL2_image SDL2_mixer SDL2_ttf libpng libjpeg
    portmidi libX11 freetype
  ];

  # Tests fail because of no audio device and display.
  doCheck = false;

  preConfigure = ''
    sed \
      -e "s/origincdirs = .*/origincdirs = []/" \
      -e "s/origlibdirs = .*/origlibdirs = []/" \
      -e "/'\/lib\/i386-linux-gnu', '\/lib\/x86_64-linux-gnu'/d" \
      -e "/'\/lib\/arm-linux-gnueabihf\/', '\/lib\/aarch64-linux-gnu\/']/d" \
      -e "/'\/lib\/aarch64-linux-gnu\/']/d" \
      -e "/\/include\/smpeg/d" \
      -i buildconfig/config_unix.py
    ${lib.concatMapStrings (dep: ''
      sed \
        -e "/origincdirs =/a\        origincdirs += ['${lib.getDev dep}/include']" \
        -e "/origlibdirs =/a\        origlibdirs += ['${lib.getLib dep}/lib']" \
        -i buildconfig/config_unix.py
      '') buildInputs
    }
    LOCALBASE=/ ${python.interpreter} buildconfig/config.py
  '';

  meta = with lib; {
    description = "Python library for games";
    homepage = http://www.pygame.org/;
    license = licenses.lgpl21Plus;
    platforms = platforms.linux;
  };
}

