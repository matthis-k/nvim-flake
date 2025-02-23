{
  description = "A Lua-natic's neovim flake, with extra cats! nixCats!";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/release-24.11";
    nixCats.url = "github:BirdeeHub/nixCats-nvim";

    rust-overlay.url = "github:oxalica/rust-overlay";
    rust-overlay.inputs.nixpkgs.follows = "nixpkgs";
    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";
    neovim-nightly-overlay.inputs.nixpkgs.follows = "nixpkgs";

    nil_ls.url = "github:oxalica/nil";
    nil_ls.inputs.nixpkgs.follows = "nixpkgs";

    care-nvim.url = "github:max397574/care.nvim";

    plugins-lz-n.url = "github:nvim-neorocks/lz.n";
    plugins-lz-n.flake = false;
    plugins-base16-nvim.url = "github:RRethy/base16-nvim";
    plugins-base16-nvim.flake = false;
    plugins-nvim-lspconfig.url = "github:neovim/nvim-lspconfig";
    plugins-nvim-lspconfig.flake = false;
    plugins-lazydev-nvim.url = "github:folke/lazydev.nvim";
    plugins-lazydev-nvim.flake = false;
    plugins-care-cmp.url = "github:max397574/care-cmp";
    plugins-care-cmp.flake = false;
    plugins-nvim-cmp-buffer.url = "github:hrsh7th/cmp-buffer";
    plugins-nvim-cmp-buffer.flake = false;
    plugins-nvim-cmp-spell.url = "github:f3fora/cmp-spell";
    plugins-nvim-cmp-spell.flake = false;
    plugins-resession-nvim.url = "github:stevearc/resession.nvim";
    plugins-resession-nvim.flake = false;
    plugins-resession-telescope-nvim.url = "github:scottmckendry/telescope-resession.nvim";
    plugins-resession-telescope-nvim.flake = false;
    plugins-conform-nvim.url = "github:stevearc/conform.nvim";
    plugins-conform-nvim.flake = false;
    plugins-helpview-nvim.url = "github:OXY2DEV/helpview.nvim";
    plugins-helpview-nvim.flake = false;
    plugins-markview-nvim.url = "github:OXY2DEV/markview.nvim";
    plugins-markview-nvim.flake = false;
    plugins-plenary-nvim.url = "github:nvim-lua/plenary.nvim";
    plugins-plenary-nvim.flake = false;
    plugins-telescope-nvim.url = "github:nvim-telescope/telescope.nvim";
    plugins-telescope-nvim.flake = false;
    plugins-which-key-nvim.url = "github:folke/which-key.nvim";
    plugins-which-key-nvim.flake = false;
    plugins-gitsigns-nvim.url = "github:lewis6991/gitsigns.nvim";
    plugins-gitsigns-nvim.flake = false;
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
      inherit
        (forEachSystem (
          system:
          let
            dependencyOverlays = [
              (utils.sanitizedPluginOverlay inputs)
              inputs.rust-overlay.overlays.default
              inputs.care-nvim.overlays.default
              inputs.nil_ls.overlays.nil
            ];
          in
          {
            inherit dependencyOverlays;
          }
        ))
        dependencyOverlays
        ;
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
            lsp.ccpp = with pkgs; [ clang-tools ];
            lsp.css = with pkgs; [ vscode-langservers-extracted ];
            lsp.json = with pkgs; [ vscode-langservers-extracted ];
            lsp.lua = with pkgs; [
              lua-language-server
              stylua
            ];
            lsp.md = with pkgs; [ marksman ];
            lsp.nix = with pkgs; [
              nixfmt-rfc-style
              nil
            ];
            lsp.rust = with pkgs; [
              rust-analyzer
              (rust-bin.stable.latest.default.override { extensions = [ "rust-src" ]; })
            ];
            lsp.toml = with pkgs; [ taplo ];
            lsp.ts = with pkgs; [ nodePackages_latest.typescript-language-server ];
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
          startupPlugins = with pkgs.neovimPlugins; {
            general = [
              lz-n
              base16-nvim
              which-key-nvim
            ];
            sessions = [ resession-nvim ];
            ui.telescope.resession = [ resession-telescope-nvim ];
            lsp.enabled = [
              nvim-lspconfig
              pkgs.vimPlugins.nvim-treesitter.withAllGrammars
            ];
            lsp.md = [ markview-nvim ];
            lsp.help = [ helpview-nvim ];
            ui.telescope.enabled = [ plenary-nvim ];
            git = [ gitsigns-nvim ];
            completion.care = [
              pkgs.vimPlugins.care-nvim
              care-cmp
              nvim-cmp-buffer
              nvim-cmp-spell
            ];
          };
          optionalPlugins = with pkgs.neovimPlugins; {
            general = [ conform-nvim ];
            lsp.lua = [ lazydev-nvim ];
            ui.telescope.enabled = [ telescope-nvim ];
          };
          sharedLibraries = { };
          environmentVariables = { };
          ui.statusline = with pkgs; [ libgit2 ];
          extraWrapperArgs = { };
          extraPython3Packages = { };
          extraLuaPackages = {
            general = ps: [
              ps.magick
              ps.luautf8
            ];
            completion = ps: [ ps.fzy ];
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
                viAlias = false;
                vimAlias = false;
                extraName = "nixovim";
                withRuby = true;
                withPython3 = true;
                withNodeJs = false;
                withPerl = false;
                configDirName = "nixovim";
                unwrappedCfgPath = null;
                neovim-unwrapped = inputs.neovim-nightly-overlay.packages.${pkgs.system}.default;
                nvimSRC = null;
                suffix-path = false;
                suffix-LD = false;
                disablePythonSafePath = false;
                gem_path = null;
              };
              categories = rec {
                general = true;
                lsp = addEnabledField {
                  ccpp = true;
                  rust = true;
                  lua = true;
                  json = true;
                  css = true;
                  toml = true;
                  nix = true;
                  md = true;
                  ts = true;
                  help = true;
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
                completion.care = true;
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
    // {
      overlays = utils.makeOverlays luaPath {
        inherit nixpkgs dependencyOverlays extra_pkg_config;
      } categoryDefinitions packageDefinitions defaultPackageName;
      nixosModules.default = utils.mkNixosModules {
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
      inherit utils;
      inherit (utils) templates;
    };
}
