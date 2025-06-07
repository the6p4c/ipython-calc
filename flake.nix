{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs = { nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let pkgs = import nixpkgs { inherit system; };
      in with pkgs; {
        packages.default = let
          ipython-calc = writeShellApplication {
            name = "ipython-calc";
            runtimeInputs = [
              (python312.withPackages
                (pp: with pp; [ ipython numpy scipy matplotlib ]))
            ];
            text = "exec ipython --config=${config}/ipython_config.py";
          };
          config = writeTextFile {
            name = "ipython-calc-config";
            text = ''
              c.TerminalIPythonApp.display_banner = False
              c.TerminalInteractiveShell.confirm_exit = False

              c.InteractiveShellApp.exec_lines = [
                """
                  import numpy as np
                  import matplotlib.pyplot as plt

                  def int_formatter(obj, p, cycle):
                    p.text(f'{obj} = {obj:#x}')

                  text_formatter = get_ipython().display_formatter.formatters['text/plain']
                  text_formatter.for_type(int, int_formatter)

                  print('✅ config loaded')

                  pass # suppress output
                """,
              ]
            '';
            # it seems as though this file *must* be named ipython_config.py, otherwise it fails to
            # load.
            destination = "/ipython_config.py";
          };
          desktop = makeDesktopItem {
            name = "ipython-calc-desktop";
            desktopName = "IPython";
            exec = "${ipython-calc}/bin/ipython-calc";
            terminal = true;
          };
        in desktop;
      });
}
