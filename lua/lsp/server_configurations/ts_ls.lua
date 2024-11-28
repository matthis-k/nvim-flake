return nixCats("lsp.ts") and {
    init_options = {
        plugins = {
            {
                name = "@vue/typescript-plugin",
                location = "/usr/local/lib/node_modules/@vue/typescript-plugin",
                languages = { "javascript", "typescript", "vue" },
            },
        },
    },
    filetypes = {
        "javascript",
        "typescript",
        "typescriptreact",
        "vue",
    },
}
