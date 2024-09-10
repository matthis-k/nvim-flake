return nixCats("lsp.nix")
    and {
        settings = {
            nixd = {
                nixpkgs = {
                    expr = "import <nixpkgs> { }",
                },
                formatting = {
                    command = { "nixfmt" },
                },
                options = {
                    nixos = {
                        expr = vim.env.SYS_FLAKE_HOST
                            and '(builtins.getFlake ("git+file://" + toString ./.)).nixosConfigurations.'
                            .. vim.env.SYS_FLAKE_HOST
                            .. ".options",
                    },
                    home_manager = {
                        expr = vim.env.USER
                            and vim.env.SYS_FLAKE_HOST
                            and 'builtins.getFlake ("git+file://" + toString ./.)).homeConfigurations."'
                            .. vim.env.USER
                            .. "@"
                            .. vim.env.SYS_FLAKE_HOST
                            .. '".options',
                    },
                },
            },
        },
    }
