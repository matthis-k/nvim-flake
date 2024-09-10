---@class LuaLsOptions
---@field addonManager? boolean # Set the on/off state of the addon manager. Disabling the addon manager prevents it from registering its command. Default is `true`.
---@field completion? LuaLsOptions.Completion # Settings that adjust how autocompletions are provided while typing.
---@field diagnostics? LuaLsOptions.Diagnostics # Settings to adjust the diagnostics.
---@field doc? LuaLsOptions.Doc # Settings for configuring documentation comments.
---@field format? LuaLsOptions.Format # Settings for configuring the built-in code formatter.
---@field hint? LuaLsOptions.Hint # Settings for configuring inline hints.
---@field hover? LuaLsOptions.Hover # Setting for configuring hover tooltips.
---@field misc? LuaLsOptions.Misc # Miscellaneous settings that do not belong to any of the other groups.
---@field runtime? LuaLsOptions.Runtime # Settings for configuring the runtime environment.
---@field semantic? LuaLsOptions.Semantic # The semantic group contains settings for semantic colouring in the editor.
---@field signatureHelp? LuaLsOptions.SignatureHelp # The signatureHelp group contains settings for helping understand signatures.
---@field spell? LuaLsOptions.Spell # The spell group contains settings that help detect typos and misspellings.
---@field telemetry? LuaLsOptions.Telemetry # The telemetry group contains settings for the opt-in telemetry.
---@field type? LuaLsOptions.Type # The type group contains settings for type checking.
---@field window? LuaLsOptions.Window # The window group contains settings that modify the window in VS Code.
---@field workspace? LuaLsOptions.Workspace # The workspace group contains settings for configuring how the workspace diagnosis works.

---@class LuaLsOptions.Completion
---@field autoRequire? boolean # When the input looks like a file name, automatically require the file. Default is `true`.
---@field callSnippet? string # Whether to show call snippets or not. When disabled, only the function name will be completed. When enabled, a "more complete" snippet will be offered. Default is `"Disable"`.
---@field displayContext? integer # When a completion is being suggested, this setting will set the amount of lines around the definition to preview to help you better understand its usage. Setting to 0 will disable this feature. Default is `0`.
---@field enable? boolean # Enable/disable completion. Completion works like any autocompletion you already know of. It helps you type less and get more done. Default is `true`.
---@field keywordSnippet? string # Whether to show a snippet for key words like if, while, etc. When disabled, only the keyword will be completed. When enabled, a "more complete" snippet will be offered. Default is `"Replace"`.
---@field postfix? string # The character to use for triggering a "postfix suggestion". A postfix allows you to write some code and then trigger a snippet after (post) to "fix" the code you have written. Default is `"@"`.
---@field requireSeparator? string # The separator to use when require-ing a file. Default is `"."`.
---@field showParams? boolean # Display a function's parameters in the list of completions. When a function has multiple definitions, they will be displayed separately. Default is `true`.
---@field showWord? string # Show "contextual words" that have to do with Lua but are not suggested based on their usefulness in the current semantic context. Default is `"Fallback"`.
---@field workspaceWord? boolean # Whether words from other files in the workspace should be suggested as "contextual words". This can be useful for completing similar strings. completion.showWord must not be disabled for this to have an effect. Default is `true`.

---@class LuaLsOptions.Diagnostics
---@field disable? string[] # Disable certain diagnostics globally. Default is `[]`.
---@field disableScheme? string[] # Disable diagnosis of Lua files that have the set schemes. Default is `["git"]`.
---@field enable? boolean # Whether all diagnostics should be enabled or not. Default is `true`.
---@field globals? string[] # An array of variable names that will be declared as global. Default is `[]`.
---@field groupFileStatus? table<string, string> # Set the file status required for each diagnostic group. Default is `{}`.
---@field groupSeverity? table<string, string> # Set the severity for each diagnostic group. Default is `{}`.
---@field ignoredFiles? string # Set how files that have been ignored should be diagnosed. Default is `"Opened"`.
---@field libraryFiles? string # Set how files loaded with workspace.library are diagnosed. Default is `"Opened"`.
---@field neededFileStatus? table<string, string> # Define the file status required for each individual diagnostic. Default is `{}`.
---@field severity? table<string, string> # Define the severity for each individual diagnostic. Default is `{}`.
---@field unusedLocalExclude? string[] # Define variable names that will not be reported as an unused local by unused-local. Default is `[]`.
---@field workspaceDelay? integer # Define the delay between diagnoses of the workspace in milliseconds. Default is `3000`.
---@field workspaceEvent? string # Set when the workspace diagnostics should be analyzed. Default is `"OnSave"`.
---@field workspaceRate? integer # Define the rate at which the workspace will be diagnosed as a percentage. Default is `100`.

---@class LuaLsOptions.Doc
---@field packageName? string[] # The pattern used for matching table field names as a package-private field. Default is `[]`.
---@field privateName? string[] # The pattern used for matching table field names as a private field. Default is `[]`.
---@field protectedName? string[] # The pattern used for matching field names as a protected field. Default is `[]`.

---@class LuaLsOptions.Format
---@field defaultConfig? table<string, string> # The default configuration for the formatter. Default is `{}`.
---@field enable? boolean # Whether the built-in formatter should be enabled or not. Default is `true`.

---@class LuaLsOptions.Hint
---@field arrayIndex? string # Whether to show a hint for array indices. Default is `"Auto"`.
---@field await? boolean # If a function has been defined as @async, display an await hint when it is being called. Default is `true`.
---@field enable? boolean # Whether inline hints should be enabled or not. Default is `false`.
---@field paramName? string # Whether parameter names should be hinted on function calls. Default is `"All"`.
---@field paramType? boolean # Show a hint for parameter types at a function definition. Default is `true`.
---@field semicolon? string # Whether to show a hint to add a semicolon to the end of a statement. Default is `"SameLine"`.
---@field setType? boolean # Show a hint to display the type being applied at assignment operations. Default is `false`.

---@class LuaLsOptions.Hover
---@field enable? boolean # Whether to enable hover tooltips or not. Default is `true`.
---@field enumsLimit? integer # When a value has multiple possible types, hovering it will display them. This setting limits how many will be displayed in the tooltip before they are truncated. Default is `5`.
---@field expandAlias? boolean # When hovering a value with an @alias for its type, should the alias be expanded into its values. Default is `true`.
---@field previewFields? integer # When a table is hovered, its fields will be displayed in the tooltip. This setting limits how many fields can be seen in the tooltip. Setting to 0 will disable this feature. Default is `50`.
---@field viewNumber? boolean # Enable hovering a non-decimal value to see its numeric value. Default is `true`.
---@field viewString? boolean # Enable hovering a string that contains an escape character to see its true string value. Default is `true`.
---@field viewStringMax? integer # The maximum number of characters that can be previewed by hovering a string before it is truncated. Default is `1000`.

---@class LuaLsOptions.Misc
---@field parameters? string[] # Command line arguments to be passed along to the server executable when starting through Visual Studio Code. Default is `[]`.
---@field executablePath? string # Manually specify the path for the Lua Language Server executable file. Default is `""`.

---@class LuaLsOptions.Runtime
---@field builtin? table<string, string> # Set whether each of the builtin Lua libraries is available in the current runtime environment. Default is `{}`.
---@field fileEncoding? string # Specify the file encoding to use. Default is `"utf8"`.
---@field meta? string # Specify the template that should be used for naming the folders that contain the generated definitions. Default is `"${version} ${language} ${encoding}"`.
---@field nonstandardSymbol? string[] # Add support for non-standard symbols. Default is `[]`.
---@field path? string[] # Defines the paths to use when using require. Default is `["?.lua", "?/init.lua"]`.
---@field pathStrict? boolean # When enabled, runtime.path will only search the first level of directories. Default is `false`.
---@field plugin? string # The path to the plugin to use. Default is `""`.
---@field pluginArgs? string[] # Additional arguments that will be passed to the active plugin. Default is `[]`.
---@field special? table<string, string> # "Special" variables can be set to be treated as other variables. Default is `{}`.
---@field unicodeName? boolean # Whether unicode characters should be allowed in variable names or not. Default is `false`.
---@field version? string # The Lua runtime version to use in this environment. Default is `"Lua 5.4"`.

---@class LuaLsOptions.Semantic
---@field annotation? boolean # Whether semantic colouring should be enabled for type annotations. Default is `true`.
---@field enable? boolean # Whether semantic colouring should be enabled. Default is `true`.
---@field keyword? boolean # Whether the server should provide semantic colouring of keywords, literals, and operators. Default is `false`.
---@field variable? boolean # Whether the server should provide semantic colouring of variables, fields, and parameters. Default is `true`.

---@class LuaLsOptions.SignatureHelp
---@field enable? boolean # Whether signature help should be enabled or not. Default is `true`.

---@class LuaLsOptions.Spell
---@field dict? string[] # A custom dictionary of words that you know are spelled correctly but are being reported as incorrect. Default is `[]`.

---@class LuaLsOptions.Telemetry
---@field enable? boolean # The language server comes with opt-in telemetry to help improve the language server. Default is `null`.

---@class LuaLsOptions.Type
---@field castNumberToInteger? boolean # Whether casting a number to an integer is allowed. Default is `false`.
---@field weakNilCheck? boolean # Whether it is permitted to assign a union type that contains nil to a variable that does not permit it. Default is `false`.
---@field weakUnionCheck? boolean # Whether it is permitted to assign a union type which only has one matching type to a variable. Default is `false`.

---@class LuaLsOptions.Window
---@field progressBar? boolean # Show a progress bar in the bottom status bar that shows how the workspace loading is progressing. Default is `true`.
---@field statusBar? boolean # Show a Lua 😺 entry in the bottom status bar that can be clicked to manually perform a workspace diagnosis. Default is `true`.

---@class LuaLsOptions.Workspace
---@field checkThirdParty? string # Whether addons can be automatically detected and the user can be prompted to enable them. Default is `"Ask"`.
---@field ignoreDir? string[] # An array of paths that will be ignored and not included in the workspace diagnosis. Default is `[".vscode"]`.
---@field ignoreSubmodules? boolean # Whether git submodules should be ignored and not included in the workspace diagnosis. Default is `true`.
---@field library? string[] # Used to add library implementation code and definition files to the workspace scope. Default is `[]`.
---@field maxPreload? integer # The maximum amount of files that can be diagnosed. More files will require more RAM. Default is `5000`.
---@field preloadFileSize? integer # Files larger than this value (in KB) will be skipped when loading for workspace diagnosis. Default is `500`.
---@field useGitIgnore? boolean # Whether files that are in .gitignore should be ignored by the language server when performing workspace diagnosis. Default is `true`.
---@field userThirdParty? string[] # An array of paths to custom addons. Default is `[]`.

return nixCats("lsp.lua")
    and {
        on_init = function (client)
            local path = client.workspace_folders[1].name
            if vim.loop.fs_stat(path .. "/.luarc.json") or vim.loop.fs_stat(path .. "/.luarc.jsonc") then
                return
            end
        end,
        settings = {
            --- @type LuaLsOptions
            Lua = {
                format = {
                    enable = true,
                    defaultConfig = {
                        align_array_table = "true",
                        align_call_args = "false",
                        align_chain_expr = "none",
                        align_continuous_assign_statement = "true",
                        align_continuous_inline_comment = "true",
                        align_continuous_line_space = "2",
                        align_continuous_rect_table_field = "true",
                        align_continuous_similar_call_args = "false",
                        align_function_params = "true",
                        align_if_branch = "false",
                        allow_non_indented_comments = "false",
                        auto_collapse_lines = "false",
                        break_all_list_when_line_exceed = "false",
                        break_before_braces = "false",
                        call_arg_parentheses = "keep",
                        continuation_indent = "4",
                        detect_end_of_line = "false",
                        end_of_line = "unset",
                        end_statement_with_semicolon = "keep",
                        ignore_space_after_colon = "false",
                        ignore_spaces_inside_function_call = "false",
                        indent_size = "4",
                        indent_style = "space",
                        insert_final_newline = "true",
                        keep_indents_on_empty_lines = "false",
                        line_space_after_comment = "keep",
                        line_space_after_do_statement = "keep",
                        line_space_after_expression_statement = "keep",
                        line_space_after_for_statement = "keep",
                        line_space_after_function_statement = "fixed(2)",
                        line_space_after_if_statement = "keep",
                        line_space_after_local_or_assign_statement = "keep",
                        line_space_after_repeat_statement = "keep",
                        line_space_after_while_statement = "keep",
                        line_space_around_block = "fixed(1)",
                        max_line_length = "120",
                        never_indent_before_if_condition = "false",
                        never_indent_comment_on_if_branch = "false",
                        quote_style = "double",
                        remove_call_expression_list_finish_comma = "false",
                        space_after_comma = "true",
                        space_after_comma_in_for_statement = "true",
                        space_after_comment_dash = "false",
                        space_around_assign_operator = "true",
                        space_around_concat_operator = "true",
                        space_around_logical_operator = "true",
                        space_around_math_operator = "true",
                        space_around_table_append_operator = "false",
                        space_around_table_field_list = "true",
                        space_before_attribute = "true",
                        space_before_closure_open_parenthesis = "true",
                        space_before_function_call_open_parenthesis = "false",
                        space_before_function_call_single_arg = "always",
                        space_before_function_open_parenthesis = "false",
                        space_before_inline_comment = "1",
                        space_before_open_square_bracket = "false",
                        space_inside_function_call_parentheses = "false",
                        space_inside_function_param_list_parentheses = "false",
                        space_inside_square_brackets = "false",
                        tab_width = "4",
                        table_separator_style = "comma",
                        trailing_table_separator = "smart",
                    },
                },
                runtime = {
                    version = "LuaJIT",
                },
                diagnostics = {
                    globals = { "vim", "nixCats" },
                },
                workspace = {
                    checkThirdParty = "Apply",
                    library = {
                        unpack(vim.api.nvim_get_runtime_file("", true)),
                        "${3rd}/luv/library",
                        "${3rd}/busted/library",
                    },
                },
                hint = {
                    enable = false,
                    arrayIndex = "Auto",
                    await = true,
                    paramName = "All",
                    paramType = true,
                    semicolon = "All",
                    setType = true,
                },
            },
        },
    }
