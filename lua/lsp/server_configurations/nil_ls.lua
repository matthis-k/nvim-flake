return nixCats("lsp.nix") and {
    settings =
    {
        ["nil"] = {
            formatting = {
                command = { "nixfmt" },
            },
            diagnostics = {
                ignored = {},
                excludedFiles = {},
            },
            nix = {
                binary = "nix",
                maxMemoryMB = 2560,
                flake = {
                    autoArchive = true,
                    autoEvalInputs = false,
                    nixpkgsInputName = "nixpkgs",
                },
            },
        },
    },
    on_attach = function (client, bufnr)
        client.server_capabilities.semanticTokensProvider = nil
    end,
}
