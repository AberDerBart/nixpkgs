{ lib, stdenv
, python, cmake, meson, vim, ruby
, which, fetchFromGitHub, fetchgit, fetchurl, fetchzip, fetchpatch
, llvmPackages, rustPlatform
, pkgconfig, curl, openssl, libgit2, libiconv
, xkb-switch, fzf, skim, stylish-haskell
, python3, boost, icu, ncurses
, ycmd, rake
, gobject-introspection, glib, wrapGAppsHook
, substituteAll
, languagetool
, Cocoa, CoreFoundation, CoreServices
, buildVimPluginFrom2Nix
, nodePackages
, dasht

# coc-go dependency
, go

# deoplete-khard dependency
, khard

# vim-go dependencies
, asmfmt, delve, errcheck, godef, golint
, gomodifytags, gotags, gotools, go-motion
, gnused, reftools, gogetdoc, golangci-lint
, impl, iferr, gocode, gocode-gomod, go-tools
, gopls

# direnv-vim dependencies
, direnv

# vCoolor dependency
, gnome3

# fruzzy dependency
, nim
}:

self: super: {

  vim2nix = buildVimPluginFrom2Nix {
    pname = "vim2nix";
    version = "1.0";
    src = ./vim2nix;
    dependencies = with super; [ vim-addon-manager ];
  };

  # Mainly used as a dependency for fzf-vim. Wraps the fzf program as a vim
  # plugin, since part of the fzf vim plugin is included in the main fzf
  # program.
  fzfWrapper = buildVimPluginFrom2Nix {
    pname = "fzf";
    version = fzf.version;
    src = fzf.src;
  };

  skim = buildVimPluginFrom2Nix {
    pname = "skim";
    version = skim.version;
    src = skim.vim;
  };

  LanguageClient-neovim = let
    version = "0.1.158";
    LanguageClient-neovim-src = fetchFromGitHub {
      owner = "autozimu";
      repo = "LanguageClient-neovim";
      rev = version;
      sha256 = "14xggdgp5qw4yj4gdsgr8s2nxm098m88q8rx6fzd2j20njv308ki";
    };
    LanguageClient-neovim-bin = rustPlatform.buildRustPackage {
      name = "LanguageClient-neovim-bin";
      src = LanguageClient-neovim-src;

      cargoSha256 = "0nin1gydf6q4mmxljm2xbd1jfl3wpzx3pvlqwspahblv9j2bf5ck";
      buildInputs = stdenv.lib.optionals stdenv.isDarwin [ CoreServices ];

      # FIXME: Use impure version of CoreFoundation because of missing symbols.
      #   Undefined symbols for architecture x86_64: "_CFURLResourceIsReachable"
      preConfigure = stdenv.lib.optionalString stdenv.isDarwin ''
        export NIX_LDFLAGS="-F${CoreFoundation}/Library/Frameworks -framework CoreFoundation $NIX_LDFLAGS"
      '';
    };
  in buildVimPluginFrom2Nix {
    pname = "LanguageClient-neovim";
    inherit version;
    src = LanguageClient-neovim-src;

    propagatedBuildInputs = [ LanguageClient-neovim-bin ];

    preFixup = ''
      substituteInPlace "$out"/share/vim-plugins/LanguageClient-neovim/autoload/LanguageClient.vim \
        --replace "let l:path = s:root . '/bin/'" "let l:path = '${LanguageClient-neovim-bin}' . '/bin/'"
    '';
  };

  clang_complete = super.clang_complete.overrideAttrs(old: {
    # In addition to the arguments you pass to your compiler, you also need to
    # specify the path of the C++ std header (if you are using C++).
    # These usually implicitly set by cc-wrapper around clang (pkgs/build-support/cc-wrapper).
    # The linked ruby code shows generates the required '.clang_complete' for cmake based projects
    # https://gist.github.com/Mic92/135e83803ed29162817fce4098dec144
    preFixup = ''
      substituteInPlace "$out"/share/vim-plugins/clang_complete/plugin/clang_complete.vim \
        --replace "let g:clang_library_path = '' + "''" + ''" "let g:clang_library_path='${llvmPackages.clang.cc.lib}/lib/libclang.so'"

      substituteInPlace "$out"/share/vim-plugins/clang_complete/plugin/libclang.py \
        --replace "/usr/lib/clang" "${llvmPackages.clang.cc}/lib/clang"
    '';
  });

  direnv-vim = super.direnv-vim.overrideAttrs(oa: {
    preFixup = oa.preFixup or "" + ''
      substituteInPlace $out/share/vim-plugins/direnv-vim/autoload/direnv.vim \
        --replace "let s:direnv_cmd = get(g:, 'direnv_cmd', 'direnv')" \
          "let s:direnv_cmd = get(g:, 'direnv_cmd', '${lib.getBin direnv}/bin/direnv')"
    '';
  });

  clighter8 = super.clighter8.overrideAttrs(old: {
    preFixup = ''
      sed "/^let g:clighter8_libclang_path/s|')$|${llvmPackages.clang.cc.lib}/lib/libclang.so')|" \
        -i "$out"/share/vim-plugins/clighter8/plugin/clighter8.vim
    '';
  });

  coc-go = super.coc-go.overrideAttrs(old: {
    preFixup = ''
      substituteInPlace "$out"/share/vim-plugins/coc-go/src/utils/tools.ts \
        --replace 'const cmd = `GOPATH=''${gopath}; go ''${args}`' 'const cmd = `GOPATH=''${gopath}; ${go}/bin/go ''${args}`'
    '';
  });

  coc-css = buildVimPluginFrom2Nix {
    pname = "coc-css";
    version = nodePackages.coc-css.version;
    src = "${nodePackages.coc-css}/lib/node_modules/coc-css";
  };

  coc-emmet = buildVimPluginFrom2Nix {
    pname = "coc-emmet";
    version = nodePackages.coc-emmet.version;
    src = "${nodePackages.coc-emmet}/lib/node_modules/coc-emmet";
  };

  coc-eslint = buildVimPluginFrom2Nix {
    pname = "coc-eslint";
    version = nodePackages.coc-eslint.version;
    src = "${nodePackages.coc-eslint}/lib/node_modules/coc-eslint";
  };

  coc-git = buildVimPluginFrom2Nix {
    pname = "coc-git";
    version = nodePackages.coc-git.version;
    src = "${nodePackages.coc-git}/lib/node_modules/coc-git";
  };

  coc-highlight = buildVimPluginFrom2Nix {
    pname = "coc-highlight";
    version = nodePackages.coc-highlight.version;
    src = "${nodePackages.coc-highlight}/lib/node_modules/coc-highlight";
  };

  coc-html = buildVimPluginFrom2Nix {
    pname = "coc-html";
    version = nodePackages.coc-html.version;
    src = "${nodePackages.coc-html}/lib/node_modules/coc-html";
  };

  coc-imselect = buildVimPluginFrom2Nix {
    pname = "coc-imselect";
    version = nodePackages.coc-imselect.version;
    src = "${nodePackages.coc-imselect}/lib/node_modules/coc-imselect";
  };

  coc-java = buildVimPluginFrom2Nix {
    pname = "coc-java";
    version = nodePackages.coc-java.version;
    src = "${nodePackages.coc-java}/lib/node_modules/coc-java";
  };

  coc-jest = buildVimPluginFrom2Nix {
    pname = "coc-jest";
    version = nodePackages.coc-jest.version;
    src = "${nodePackages.coc-jest}/lib/node_modules/coc-jest";
  };

  coc-json = buildVimPluginFrom2Nix {
    pname = "coc-json";
    version = nodePackages.coc-json.version;
    src = "${nodePackages.coc-json}/lib/node_modules/coc-json";
  };

  coc-lists = buildVimPluginFrom2Nix {
    pname = "coc-lists";
    version = nodePackages.coc-lists.version;
    src = "${nodePackages.coc-lists}/lib/node_modules/coc-lists";
  };

  coc-metals = buildVimPluginFrom2Nix {
    pname = "coc-metals";
    version = nodePackages.coc-metals.version;
    src = "${nodePackages.coc-metals}/lib/node_modules/coc-metals";
  };

  coc-pairs = buildVimPluginFrom2Nix {
    pname = "coc-pairs";
    version = nodePackages.coc-pairs.version;
    src = "${nodePackages.coc-pairs}/lib/node_modules/coc-pairs";
  };

  coc-prettier = buildVimPluginFrom2Nix {
    pname = "coc-prettier";
    version = nodePackages.coc-prettier.version;
    src = "${nodePackages.coc-prettier}/lib/node_modules/coc-prettier";
  };

  coc-python = buildVimPluginFrom2Nix {
    pname = "coc-python";
    version = nodePackages.coc-python.version;
    src = "${nodePackages.coc-python}/lib/node_modules/coc-python";
  };

  coc-r-lsp = buildVimPluginFrom2Nix {
    pname = "coc-r-lsp";
    version = nodePackages.coc-r-lsp.version;
    src = "${nodePackages.coc-r-lsp}/lib/node_modules/coc-r-lsp";
  };

  coc-rls = buildVimPluginFrom2Nix {
    pname = "coc-rls";
    version = nodePackages.coc-rls.version;
    src = "${nodePackages.coc-rls}/lib/node_modules/coc-rls";
  };

  coc-rust-analyzer = buildVimPluginFrom2Nix {
    pname = "coc-rust-analyzer";
    version = nodePackages.coc-rust-analyzer.version;
    src = "${nodePackages.coc-rust-analyzer}/lib/node_modules/coc-rust-analyzer";
  };

  coc-smartf = buildVimPluginFrom2Nix {
    pname = "coc-smartf";
    version = nodePackages.coc-smartf.version;
    src = "${nodePackages.coc-smartf}/lib/node_modules/coc-smartf";
  };

  coc-snippets = buildVimPluginFrom2Nix {
    pname = "coc-snippets";
    version = nodePackages.coc-snippets.version;
    src = "${nodePackages.coc-snippets}/lib/node_modules/coc-snippets";
  };

  coc-solargraph = buildVimPluginFrom2Nix {
    pname = "coc-solargraph";
    version = nodePackages.coc-solargraph.version;
    src = "${nodePackages.coc-solargraph}/lib/node_modules/coc-solargraph";
  };

  coc-stylelint = buildVimPluginFrom2Nix {
    pname = "coc-stylelint";
    version = nodePackages.coc-stylelint.version;
    src = "${nodePackages.coc-stylelint}/lib/node_modules/coc-stylelint";
  };

  coc-tabnine = buildVimPluginFrom2Nix {
    pname = "coc-tabnine";
    version = nodePackages.coc-tabnine.version;
    src = "${nodePackages.coc-tabnine}/lib/node_modules/coc-tabnine";
  };

  coc-tslint = buildVimPluginFrom2Nix {
    pname = "coc-tslint";
    version = nodePackages.coc-tslint.version;
    src = "${nodePackages.coc-tslint}/lib/node_modules/coc-tslint";
  };

  coc-tslint-plugin = buildVimPluginFrom2Nix {
    pname = "coc-tslint-plugin";
    version = nodePackages.coc-tslint-plugin.version;
    src = "${nodePackages.coc-tslint-plugin}/lib/node_modules/coc-tslint-plugin";
  };

  coc-tsserver = buildVimPluginFrom2Nix {
    pname = "coc-tsserver";
    version = nodePackages.coc-tsserver.version;
    src = "${nodePackages.coc-tsserver}/lib/node_modules/coc-tsserver";
  };

  coc-vetur = buildVimPluginFrom2Nix {
    pname = "coc-vetur";
    version = nodePackages.coc-vetur.version;
    src = "${nodePackages.coc-vetur}/lib/node_modules/coc-vetur";
  };

  coc-vimtex = buildVimPluginFrom2Nix {
    pname = "coc-vimtex";
    version = nodePackages.coc-vimtex.version;
    src = "${nodePackages.coc-vimtex}/lib/node_modules/coc-vimtex";
  };

  coc-wxml = buildVimPluginFrom2Nix {
    pname = "coc-wxml";
    version = nodePackages.coc-wxml.version;
    src = "${nodePackages.coc-wxml}/lib/node_modules/coc-wxml";
  };

  coc-yaml = buildVimPluginFrom2Nix {
    pname = "coc-yaml";
    version = nodePackages.coc-yaml.version;
    src = "${nodePackages.coc-yaml}/lib/node_modules/coc-yaml";
  };

  coc-yank = buildVimPluginFrom2Nix {
    pname = "coc-yank";
    version = nodePackages.coc-yank.version;
    src = "${nodePackages.coc-yank}/lib/node_modules/coc-yank";
  };

  command-t = super.command-t.overrideAttrs(old: {
    buildInputs = [ ruby rake ];
    buildPhase = ''
      rake make
      rm ruby/command-t/ext/command-t/*.o
    '';
  });

  cpsm = super.cpsm.overrideAttrs(old: {
    buildInputs = [
      python3
      stdenv
      cmake
      boost
      icu
      ncurses
    ];
    buildPhase = ''
      patchShebangs .
      export PY3=ON
      ./install.sh
    '';
  });

  ctrlp-cmatcher = super.ctrlp-cmatcher.overrideAttrs(old: {
    buildInputs = [ python ];
    buildPhase = ''
      patchShebangs .
      ./install.sh
    '';
  });

  defx-nvim = super.defx-nvim.overrideAttrs(old: {
    dependencies = with super; [ nvim-yarp ];
  });

  deoplete-fish = super.deoplete-fish.overrideAttrs(old: {
    dependencies = with super; [ deoplete-nvim vim-fish ];
  });

  deoplete-go = super.deoplete-go.overrideAttrs(old: {
    buildInputs = [ python3 ];
    buildPhase = ''
      pushd ./rplugin/python3/deoplete/ujson
      python3 setup.py build --build-base=$PWD/build --build-lib=$PWD/build
      popd
      find ./rplugin/ -name "ujson*.so" -exec mv -v {} ./rplugin/python3/ \;
   '';
  });

  deoplete-khard = super.deoplete-khard.overrideAttrs(old: {
    dependencies = [ self.deoplete-nvim ];
    passthru.python3Dependencies = ps: [ (ps.toPythonModule khard) ];
    meta = {
      description = "Address-completion for khard via deoplete";
      homepage = "https://github.com/nicoe/deoplete-khard";
      license = stdenv.lib.licenses.mit;
      maintainers = with stdenv.lib.maintainers; [ jorsn ];
    };
  });

  ensime-vim = super.ensime-vim.overrideAttrs(old: {
    passthru.python3Dependencies = ps: with ps; [ sexpdata websocket_client ];
    dependencies = with super; [ vimproc-vim vimshell-vim super.self forms ];
  });

  forms = super.forms.overrideAttrs(old: {
    dependencies = with super; [ super.self ];
  });

  fruzzy = let # until https://github.com/NixOS/nixpkgs/pull/67878 is merged, there's no better way to install nim libraries with nix
    nimpy = fetchFromGitHub {
      owner = "yglukhov";
      repo = "nimpy";
      rev = "4840d1e438985af759ddf0923e7a9250fd8ea0da";
      sha256 = "0qqklvaajjqnlqm3rkk36pwwnn7x942mbca7nf2cvryh36yg4q5k";
    };
    binaryheap = fetchFromGitHub {
      owner = "bluenote10";
      repo = "nim-heap";
      rev = "c38039309cb11391112571aa332df9c55f625b54";
      sha256 = "05xdy13vm5n8dw2i366ppbznc4cfhq23rdcklisbaklz2jhdx352";
    };
  in super.fruzzy.overrideAttrs(old: {
    buildInputs = [ nim ];
    patches = [
      (substituteAll {
        src = ./patches/fruzzy/get_version.patch;
        version = old.version;
      })
    ];
    configurePhase = ''
      substituteInPlace Makefile \
        --replace \
          "nim c" \
          "nim c --nimcache:$TMP --path:${nimpy} --path:${binaryheap}"
    '';
    buildPhase = ''
      make build
    '';
  });

  ghcid = super.ghcid.overrideAttrs(old: {
    configurePhase = "cd plugins/nvim";
  });

  vim-gist = super.vim-gist.overrideAttrs(old: {
    dependencies = with super; [ webapi-vim ];
  });

  meson = buildVimPluginFrom2Nix {
    inherit (meson) pname version src;
    preInstall = "cd data/syntax-highlighting/vim";
    meta.maintainers = with stdenv.lib.maintainers; [ vcunat ];
  };

  ncm2 = super.ncm2.overrideAttrs(old: {
    dependencies = with super; [ nvim-yarp ];
  });

  ncm2-jedi = super.ncm2-jedi.overrideAttrs(old: {
    dependencies = with super; [ nvim-yarp ncm2 ];
    passthru.python3Dependencies = ps: with ps; [ jedi ];
  });

  ncm2-neoinclude = super.ncm2-neoinclude.overrideAttrs(old: {
    dependencies = with super; [ neoinclude-vim ];
  });

  ncm2-neosnippet = super.ncm2-neosnippet.overrideAttrs(old: {
    dependencies = with super; [ neosnippet-vim ];
  });

  ncm2-syntax = super.ncm2-syntax.overrideAttrs(old: {
    dependencies = with super; [ neco-syntax ];
  });

  ncm2-ultisnips = super.ncm2-ultisnips.overrideAttrs(old: {
    dependencies = with super; [ ultisnips ];
  });

  fzf-vim = super.fzf-vim.overrideAttrs(old: {
    dependencies = [ self.fzfWrapper ];
  });

  skim-vim = super.skim-vim.overrideAttrs(old: {
    dependencies = [ self.skim ];
  });

  sved = let
    # we put the script in its own derivation to benefit the magic of wrapGAppsHook
    svedbackend = stdenv.mkDerivation {
      name = "svedbackend-${super.sved.name}";
      inherit (super.sved) src;
      nativeBuildInputs = [ wrapGAppsHook ];
      buildInputs = [
        gobject-introspection
        glib
        (python3.withPackages(ps: with ps; [ pygobject3 pynvim dbus-python ]))
      ];
      preferLocalBuild = true;
      installPhase = ''
        install -Dt $out/bin ftplugin/evinceSync.py
      '';
    };
  in
    super.sved.overrideAttrs(old: {
      preferLocalBuild = true;
      postPatch = ''
        rm ftplugin/evinceSync.py
        ln -s ${svedbackend}/bin/evinceSync.py ftplugin/evinceSync.py
      '';
      meta = {
        description = "synctex support between vim/neovim and evince";
      };
    });

  vimacs = super.vimacs.overrideAttrs(old: {
    buildPhase = ''
      substituteInPlace bin/vim \
        --replace '/usr/bin/vim' 'vim' \
        --replace '/usr/bin/gvim' 'gvim'
      # remove unnecessary duplicated bin wrapper script
      rm -r plugin/vimacs
    '';
    meta = with stdenv.lib; {
      description = "Vim-Improved eMACS: Emacs emulation plugin for Vim";
      homepage = "http://algorithm.com.au/code/vimacs";
      license = licenses.gpl2Plus;
      maintainers = with stdenv.lib.maintainers; [ millerjason ];
    };
  });

  vimshell-vim = super.vimshell-vim.overrideAttrs(old: {
    dependencies = with super; [ vimproc-vim ];
  });

  vim-addon-manager = super.vim-addon-manager.overrideAttrs(old: {
    buildInputs = stdenv.lib.optional stdenv.isDarwin Cocoa;
  });

  vim-addon-actions = super.vim-addon-actions.overrideAttrs(old: {
    dependencies = with super; [ vim-addon-mw-utils tlib_vim ];
  });

  vim-addon-async = super.vim-addon-async.overrideAttrs(old: {
    dependencies = with super; [ vim-addon-signs ];
  });

  vim-addon-background-cmd = super.vim-addon-background-cmd.overrideAttrs(old: {
    dependencies = with super; [ vim-addon-mw-utils ];
  });

  vim-addon-completion = super.vim-addon-completion.overrideAttrs(old: {
    dependencies = with super; [ tlib_vim ];
  });

  vim-addon-goto-thing-at-cursor = super.vim-addon-goto-thing-at-cursor.overrideAttrs(old: {
    dependencies = with super; [ tlib_vim ];
  });

  vim-addon-mru = super.vim-addon-mru.overrideAttrs(old: {
    dependencies = with super; [ vim-addon-other vim-addon-mw-utils ];
  });

  vim-addon-nix = super.vim-addon-nix.overrideAttrs(old: {
    dependencies = with super; [
      vim-addon-completion
      vim-addon-goto-thing-at-cursor
      vim-addon-errorformats
      vim-addon-actions
      vim-addon-mw-utils tlib_vim
    ];
  });

  vim-addon-sql = super.vim-addon-sql.overrideAttrs(old: {
    dependencies = with super; [ vim-addon-completion vim-addon-background-cmd tlib_vim ];
  });

  vim-addon-syntax-checker = super.vim-addon-syntax-checker.overrideAttrs(old: {
    dependencies = with super; [ vim-addon-mw-utils tlib_vim ];
  });

  vim-addon-toggle-buffer = super.vim-addon-toggle-buffer.overrideAttrs(old: {
    dependencies = with super; [ vim-addon-mw-utils tlib_vim ];
  });

  vim-addon-xdebug = super.vim-addon-xdebug.overrideAttrs(old: {
    dependencies = with super; [ webapi-vim vim-addon-mw-utils vim-addon-signs vim-addon-async ];
  });

  vim-bazel = super.vim-bazel.overrideAttrs(old: {
    dependencies = with super; [ vim-maktaba ];
  });

  vim-beancount = super.vim-beancount.overrideAttrs(old: {
    passthru.python3Dependencies = ps: with ps; [ beancount ];
  });

  vim-codefmt = super.vim-codefmt.overrideAttrs(old: {
    dependencies = with super; [ vim-maktaba ];
  });

  vim-dasht = super.vim-dasht.overrideAttrs(old: {
    preFixup = ''
      substituteInPlace $out/share/vim-plugins/vim-dasht/autoload/dasht.vim \
        --replace "['dasht']" "['${dasht}/bin/dasht']"
    '';
  });

  vim-easytags = super.vim-easytags.overrideAttrs(old: {
    dependencies = with super; [ vim-misc ];
    patches = [
      (fetchpatch { # https://github.com/xolox/vim-easytags/pull/170 fix version detection for universal-ctags
        url = "https://github.com/xolox/vim-easytags/commit/46e4709500ba3b8e6cf3e90aeb95736b19e49be9.patch";
        sha256 = "0x0xabb56xkgdqrg1mpvhbi3yw4d829n73lsnnyj5yrxjffy4ax4";
      })
    ];
  });

  # change the go_bin_path to point to a path in the nix store. See the code in
  # fatih/vim-go here
  # https://github.com/fatih/vim-go/blob/155836d47052ea9c9bac81ba3e937f6f22c8e384/autoload/go/path.vim#L154-L159
  vim-go = super.vim-go.overrideAttrs(old: let
    binPath = lib.makeBinPath [
      asmfmt
      delve
      errcheck
      go-motion
      go-tools
      gocode
      gocode-gomod
      godef
      gogetdoc
      golint
      golangci-lint
      gomodifytags
      gopls
      gotags
      gotools
      iferr
      impl
      reftools
    ];
    in {
    postPatch = ''
      ${gnused}/bin/sed \
        -Ee 's@"go_bin_path", ""@"go_bin_path", "${binPath}"@g' \
        -i autoload/go/config.vim
    '';
  });

  vim-grammarous = super.vim-grammarous.overrideAttrs(old: {
    # use `:GrammarousCheck` to initialize checking
    # In neovim, you also want to use set
    #   let g:grammarous#show_first_error = 1
    # see https://github.com/rhysd/vim-grammarous/issues/39
    patches = [
      (substituteAll {
        src = ./patches/vim-grammarous/set_default_languagetool.patch;
        inherit languagetool;
      })
    ];
  });

  vim-hier = super.vim-hier.overrideAttrs(old: {
    buildInputs = [ vim ];
  });

  vim-isort = super.vim-isort.overrideAttrs(old: {
    postPatch = ''
      substituteInPlace ftplugin/python_vimisort.vim \
        --replace 'import vim' 'import vim; import sys; sys.path.append("${python.pkgs.isort}/${python.sitePackages}")'
    '';
  });

  vim-metamath = super.vim-metamath.overrideAttrs(old: {
    preInstall = "cd vim";
  });

  vim-snipmate = super.vim-snipmate.overrideAttrs(old: {
    dependencies = with super; [ vim-addon-mw-utils tlib_vim ];
  });


  vim-wakatime = super.vim-wakatime.overrideAttrs(old: {
    buildInputs = [ python ];
  });

  vim-xdebug = super.vim-xdebug.overrideAttrs(old: {
    postInstall = false;
  });

  vim-xkbswitch = super.vim-xkbswitch.overrideAttrs(old: {
    patchPhase = ''
      substituteInPlace plugin/xkbswitch.vim \
        --replace /usr/local/lib/libxkbswitch.so ${xkb-switch}/lib/libxkbswitch.so
    '';
    buildInputs = [ xkb-switch ];
  });

  vim-yapf = super.vim-yapf.overrideAttrs(old: {
    buildPhase = ''
      substituteInPlace ftplugin/python_yapf.vim \
        --replace '"yapf"' '"${python3.pkgs.yapf}/bin/yapf"'
    '';
  });

  vimproc-vim = super.vimproc-vim.overrideAttrs(old: {
    buildInputs = [ which ];

    buildPhase = ''
      substituteInPlace autoload/vimproc.vim \
        --replace vimproc_mac.so vimproc_unix.so \
        --replace vimproc_linux64.so vimproc_unix.so \
        --replace vimproc_linux32.so vimproc_unix.so
      make -f make_unix.mak
    '';
  });

  YankRing-vim = super.YankRing-vim.overrideAttrs(old: {
    sourceRoot = ".";
  });

  YouCompleteMe = super.YouCompleteMe.overrideAttrs(old: {
    buildPhase = ''
      substituteInPlace plugin/youcompleteme.vim \
        --replace "'ycm_path_to_python_interpreter', '''" \
        "'ycm_path_to_python_interpreter', '${python3}/bin/python3'"

      rm -r third_party/ycmd
      ln -s ${ycmd}/lib/ycmd third_party
    '';

    meta = with stdenv.lib; {
      description = "A code-completion engine for Vim";
      homepage = "https://github.com/Valloric/YouCompleteMe";
      license = licenses.gpl3;
      maintainers = with maintainers; [ marcweber jagajaga ];
      platforms = platforms.unix;
    };
  });

  jedi-vim = super.jedi-vim.overrideAttrs(old: {
    # checking for python3 support in vim would be neat, too, but nobody else seems to care
    buildInputs = [ python3.pkgs.jedi ];
    meta = {
      description = "code-completion for python using python-jedi";
      license = stdenv.lib.licenses.mit;
    };
  });

  lf-vim = super.lf-vim.overrideAttrs(old: {
    dependencies = with super; [ bclose-vim ];
  });

  vim-stylish-haskell = super.vim-stylish-haskell.overrideAttrs (old: {
    postPatch = old.postPatch or "" + ''
      substituteInPlace ftplugin/haskell/stylish-haskell.vim --replace \
        'g:stylish_haskell_command = "stylish-haskell"' \
        'g:stylish_haskell_command = "${stylish-haskell}/bin/stylish-haskell"'
    '';
  });

  vCoolor-vim = super.vCoolor-vim.overrideAttrs(old: {
    # on linux can use either Zenity or Yad.
    propagatedBuildInputs = [ gnome3.zenity ];
    meta = {
      description = "Simple color selector/picker plugin";
      license = stdenv.lib.licenses.publicDomain;
    };
  });

  unicode-vim = let
    unicode-data = fetchurl {
      url = "http://www.unicode.org/Public/UNIDATA/UnicodeData.txt";
      sha256 = "16b0jzvvzarnlxdvs2izd5ia0ipbd87md143dc6lv6xpdqcs75s9";
    };
  in super.unicode-vim.overrideAttrs(old: {

      # redirect to /dev/null else changes terminal color
      buildPhase = ''
        cp "${unicode-data}" autoload/unicode/UnicodeData.txt
        echo "Building unicode cache"
        ${vim}/bin/vim --cmd ":set rtp^=$PWD" -c 'ru plugin/unicode.vim' -c 'UnicodeCache' -c ':echohl Normal' -c ':q' > /dev/null
      '';
  });

  vim-clap = super.vim-clap.overrideAttrs(old: {
    preFixup = let
      maple-bin = rustPlatform.buildRustPackage {
        name = "maple";
        src = old.src;

        nativeBuildInputs = [
          pkgconfig
        ];

        buildInputs = [
          openssl
        ] ++ stdenv.lib.optionals stdenv.isDarwin [
          CoreServices
          curl
          libgit2
          libiconv
        ];

        cargoSha256 = "0qqys51slz85rnx6knjyivnmyq4rj6rrnz7w72kqcl8da8zjbx7b";
      };
    in ''
      ln -s ${maple-bin}/bin/maple $target/bin/maple
    '';
  });
}
