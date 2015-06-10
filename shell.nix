{ nixpkgs ? import <nixpkgs> {}, compiler ? "ghc784" }:

let

  inherit (nixpkgs) pkgs;

  f = { mkDerivation, aeson, base, bytestring, classy-prelude
      , classy-prelude-conduit, classy-prelude-yesod, conduit, containers
      , data-default, directory, fast-logger, file-embed, hjsmin, hspec
      , http-conduit, monad-control, monad-logger, persistent
      , persistent-sqlite, persistent-template, resourcet, safe
      , shakespeare, stdenv, template-haskell, text, time, transformers
      , unordered-containers, vector, wai-extra, wai-logger, warp, yaml
      , yesod, yesod-auth, yesod-core, yesod-form, yesod-static
      , yesod-test
      }:
      mkDerivation {
        pname = "Yesod1";
        version = "0.0.0";
        src = ./.;
        isLibrary = true;
        isExecutable = true;
        buildDepends = [
          aeson base bytestring classy-prelude classy-prelude-conduit
          classy-prelude-yesod conduit containers data-default directory
          fast-logger file-embed hjsmin http-conduit monad-control
          monad-logger persistent persistent-sqlite persistent-template safe
          shakespeare template-haskell text time unordered-containers vector
          wai-extra wai-logger warp yaml yesod yesod-auth yesod-core
          yesod-form yesod-static
        ];
        testDepends = [
          base classy-prelude classy-prelude-yesod hspec monad-logger
          persistent persistent-sqlite resourcet shakespeare transformers
          yesod yesod-core yesod-test
        ];
        license = stdenv.lib.licenses.unfree;
      };

  drv = pkgs.haskell.packages.${compiler}.callPackage f {};

in

  if pkgs.lib.inNixShell then drv.env else drv
