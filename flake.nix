{
  description = "A Lua-natic's neovim flake, with extra cats! nixCats!";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nixCats.url = "github:BirdeeHub/nixCats-nvim";

    rust-overlay.url = "github:oxalica/rust-overlay";
    rust-overlay.inputs.nixpkgs.follows = "nixpkgs";
    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";
    neovim-nightly-overlay.inputs.nixpkgs.follows = "nixpkgs";

    nil-ls.url = "github:oxalica/nil/577d160da311cc7f5042038456a0713e9863d09e";
    nil-ls.inputs.nixpkgs.follows = "nixpkgs";
    nil-ls.inputs.rust-overlay.follows = "rust-overlay";

    plugins-resession-telescope-nvim.url = "github:scottmckendry/telescope-resession.nvim";
    plugins-resession-telescope-nvim.flake = false;
  };
  outputs =
    {
      self,
      nixpkgs,
      nixCats,
      ...
    }@inputs:
    let
      inherit (nixCats) utils;
      luaPath = "${./.}";
      forEachSystem = utils.eachSystem nixpkgs.lib.platforms.all;
      extra_pkg_config = { };
      dependencyOverlays = [
        (utils.sanitizedPluginOverlay inputs)
        inputs.rust-overlay.overlays.default
        inputs.nil-ls.overlays.nil
      ];
      categoryDefinitions =
        {
          pkgs,
          settings,
          categories,
          name,
          ...
        }@packageDef:
        {
          propagatedBuildInputs = { };
          lspsAndRuntimeDeps = {
            lsp = {
              ccpp = with pkgs; [ clang-tools ];
              css = with pkgs; [ vscode-langservers-extracted ];
              json = with pkgs; [ vscode-langservers-extracted ];
              lua = with pkgs; [
                lua-language-server
                stylua
              ];
              md = with pkgs; [ marksman ];
              nix = with pkgs; [
                nixfmt-rfc-style
                nil
              ];
              qml = with pkgs; [ kdePackages.qtdeclarative ];
              rust = with pkgs; [
                rust-analyzer
                (rust-bin.stable.latest.default.override { extensions = [ "rust-src" ]; })
              ];
              toml = with pkgs; [ taplo ];
              ts = with pkgs; [ nodePackages_latest.typescript-language-server ];
              xml = with pkgs; [ lemminx ];
            };
            general = with pkgs; [
              curl
              fd
              fzf
              imagemagick
              luarocks
              lua5_1
              ripgrep
            ];
          };
          startupPlugins = with pkgs.vimPlugins; {
            general = [
              lz-n
              base16-nvim
              which-key-nvim
              nvim-web-devicons
              nui-nvim
            ];
            sessions = [ resession-nvim ];
            ui = {
              telescope.resession = [ pkgs.neovimPlugins.resession-telescope-nvim ];
            };
            lsp = {
              enabled = [
                nvim-lspconfig
                pkgs.vimPlugins.nvim-treesitter.withAllGrammars
              ];
              md = [ markview-nvim ];
              help = [ helpview-nvim ];
            };
            git = [ gitsigns-nvim ];
            completion.enabled = [
              blink-cmp
              lazydev-nvim
            ];
          };
          optionalPlugins = with pkgs.vimPlugins; {
            general = [ conform-nvim ];
            ui.telescope.enabled = [ telescope-nvim ];
          };
          sharedLibraries = {
            general = with pkgs; [ libgit2 ];
            ui.statusline = with pkgs; [ libgit2 ];
          };
          environmentVariables = { };
          extraWrapperArgs = { };
          python3.libraries = { };
          extraLuaPackages = {
            general = ps: [
              ps.magick
              ps.luautf8
            ];
            ui.telescope.enabled = ps: [ ps.fzy ];
          };
        };
      packageDefinitions =
        let
          addEnabledField =
            attrs:
            let
              hasTruthyValue = builtins.any (v: v) (builtins.attrValues attrs);
            in
            attrs // { enabled = hasTruthyValue; };
          defaultConfig =
            { pkgs, ... }:
            { wrapped }:
            {
              settings = {
                wrapRc = wrapped;
                aliases = [
                  "vi"
                  "vim"
                ];
                extraName = "nixovim";
                hosts.ruby.enable = true;
                hosts.python3.enable = true;
                hosts.node.enable = true;
                hosts.perl.enable = true;
                configDirName = "nixovim";
                unwrappedCfgPath = "/home/matthisk/nvim-flake";
                neovim-unwrapped = inputs.neovim-nightly-overlay.packages.${pkgs.system}.default;
                nvimSRC = null;
                suffix-path = false;
                suffix-LD = false;
                disablePythonSafePath = false;
              };
              categories = rec {
                general = true;
                lsp = addEnabledField {
                  ccpp = true;
                  css = true;
                  help = true;
                  json = true;
                  lua = true;
                  md = true;
                  nix = true;
                  qml = true;
                  rust = true;
                  toml = true;
                  ts = true;
                  xml = true;
                };
                git = true;
                sessions = true;
                ui = addEnabledField {
                  telescope = addEnabledField {
                    resession = sessions && ui.telescope.enabled;
                    fileFinder = true;
                    liveSearch = true;
                    buffers = true;
                  };
                  statusline = true;
                  tabline = true;
                  statuscolumn = true;
                };
                completion.enabled = true;
              };
            };
        in
        {
          nvimdev = args: defaultConfig args { wrapped = false; };
          nvim = args: defaultConfig args { wrapped = true; };
        };
      defaultPackageName = "nvim";
    in
    forEachSystem (
      system:
      let
        nixCatsBuilder = utils.baseBuilder luaPath {
          inherit
            nixpkgs
            system
            dependencyOverlays
            extra_pkg_config
            ;
        } categoryDefinitions packageDefinitions;
        defaultPackage = nixCatsBuilder defaultPackageName;
        pkgs = import nixpkgs { inherit system; };
      in
      {
        packages = utils.mkAllWithDefault defaultPackage;
        devShells = {
          default = pkgs.mkShell {
            name = defaultPackageName;
            packages = [ defaultPackage ];
            inputsFrom = [ ];
            shellHook = '''';
          };
        };
      }
    )
    // (
      let
        nixosModule = utils.mkNixosModules {
          moduleNamespace = [ defaultPackageName ];
          inherit
            defaultPackageName
            dependencyOverlays
            luaPath
            categoryDefinitions
            packageDefinitions
            extra_pkg_config
            nixpkgs
            ;
        };
        homeModule = utils.mkHomeModules {
          moduleNamespace = [ defaultPackageName ];
          inherit
            defaultPackageName
            dependencyOverlays
            luaPath
            categoryDefinitions
            packageDefinitions
            extra_pkg_config
            nixpkgs
            ;
        };
      in
      {
        overlays = utils.makeOverlays luaPath {
          inherit nixpkgs dependencyOverlays extra_pkg_config;
        } categoryDefinitions packageDefinitions defaultPackageName;

        nixosModules.default = nixosModule;
        homeModules.default = homeModule;

        inherit utils nixosModule homeModule;
        inherit (utils) templates;
      }
    );
}
