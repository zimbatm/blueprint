{
  pname,
  pkgs,
  flake,
}:
let
  formatter = pkgs.writeShellApplication {
    name = pname;

    runtimeInputs = [
      pkgs.deadnix
      pkgs.nixfmt-rfc-style
    ];

    text = ''
      set -euo pipefail
      set -x

      deadnix --no-lambda-pattern-names --edit "$@"

      nixfmt "$@"
    '';

    meta = {
      description = "format your project";
    };
  };

  check =
    pkgs.runCommand "format-check"
      {
        nativeBuildInputs = [
          formatter
          pkgs.git
        ];

        # only check on Linux
        meta.platforms = pkgs.lib.platforms.linux;
      }
      ''
        export HOME=$NIX_BUILD_TOP/home

        # keep timestamps so that treefmt is able to detect mtime changes
        cp --no-preserve=mode --preserve=timestamps -r ${flake} source
        cd source
        git init --quiet
        git add .
        shopt -s globstar
        ${pname} **/*.nix
        if ! git diff --exit-code; then
          echo "-------------------------------"
          echo "aborting due to above changes ^"
          exit 1
        fi
        touch $out
      '';
in
formatter
// {
  passthru = formatter.passthru // {
    tests = {
      check = check;
    };
  };
}
