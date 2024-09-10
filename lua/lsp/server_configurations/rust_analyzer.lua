---@class RustAnalyzerOptions
---@field cargoRunner? string|nil Custom cargo runner extension ID.
---@field runnableEnv? table|nil Environment variables passed to the runnable launched using Test or Debug lens or rust-analyzer.run command.
---@field inlayHints? RustAnalyzerOptions.InlayHints Settings for inlay hints.
---@field updates? RustAnalyzerOptions.Updates Settings for updates.
---@field server? RustAnalyzerOptions.Server Settings for the rust-analyzer server.
---@field trace? RustAnalyzerOptions.Trace Settings for tracing.
---@field debug? RustAnalyzerOptions.Debug Settings for debugging.
---@field assist? RustAnalyzerOptions.Assist Settings for assists.
---@field callInfo? RustAnalyzerOptions.CallInfo Settings for call info.
---@field cargo? RustAnalyzerOptions.Cargo Settings for cargo.
---@field checkOnSave? RustAnalyzerOptions.CheckOnSave Settings for checking on save.
---@field completion? RustAnalyzerOptions.Completion Settings for completion.
---@field diagnostics? RustAnalyzerOptions.Diagnostics Settings for diagnostics.
---@field files? RustAnalyzerOptions.Files Settings for files.
---@field hoverActions? RustAnalyzerOptions.HoverActions Settings for hover actions.
---@field lens? RustAnalyzerOptions.Lens Settings for code lenses.
---@field linkedProjects? table|nil Disable project auto-discovery in favor of explicitly specified set of projects.
---@field lruCapacity? number|nil Number of syntax trees rust-analyzer keeps in memory. Defaults to 128.
---@field notifications? RustAnalyzerOptions.Notifications Settings for notifications.
---@field procMacro? RustAnalyzerOptions.ProcMacro Settings for procedural macros.
---@field runnables? RustAnalyzerOptions.Runnables Settings for runnables.
---@field rustcSource? string|nil Path to the rust compiler sources.
---@field rustfmt? RustAnalyzerOptions.Rustfmt Settings for rustfmt.

---@class RustAnalyzerOptions.InlayHints
---@field enable? boolean Whether to show inlay hints. Defaults to true.
---@field chainingHints? boolean Whether to show inlay type hints for method chains. Defaults to true.
---@field maxLength? number|nil Maximum length for inlay hints. Default is unlimited.
---@field parameterHints? boolean Whether to show function parameter name inlay hints at the call site. Defaults to true.
---@field typeHints? boolean Whether to show inlay type hints for variables. Defaults to true.

---@class RustAnalyzerOptions.Updates
---@field channel? string Choose nightly or stable updates. Defaults to 'stable'.
---@field askBeforeDownload? boolean Whether to ask for permission before downloading any files from the Internet. Defaults to true.

---@class RustAnalyzerOptions.Server
---@field path? string|nil Path to rust-analyzer executable.
---@field extraEnv? table|nil Extra environment variables that will be passed to the rust-analyzer executable.

---@class RustAnalyzerOptions.Trace
---@field server? string Trace requests to the rust-analyzer. Defaults to 'off'.
---@field extension? boolean Enable logging of VS Code extensions itself. Defaults to false.

---@class RustAnalyzerOptions.Debug
---@field engine? string Preferred debug engine. Defaults to 'auto'.
---@field sourceFileMap? table Optional source file mappings passed to the debug engine. Defaults to { ["/rustc/<id>"] = "${env:USERPROFILE}/.rustup/toolchains/<toolchain-id>/lib/rustlib/src/rust" }.
---@field openDebugPane? boolean Whether to open up the Debug Panel on debugging start. Defaults to false.
---@field engineSettings? table Optional settings passed to the debug engine. Defaults to {}.

---@class RustAnalyzerOptions.Assist
---@field importMergeBehavior? string The strategy to use when inserting new imports or merging imports. Defaults to 'full'.
---@field importPrefix? string The path structure for newly inserted paths to use. Defaults to 'plain'.

---@class RustAnalyzerOptions.CallInfo
---@field full? boolean Show function name and docs in parameter hints. Defaults to true.

---@class RustAnalyzerOptions.Cargo
---@field autoreload? boolean Automatically refresh project info via cargo metadata on Cargo.toml changes. Defaults to true.
---@field allFeatures? boolean Activate all available features. Defaults to false.
---@field features? table List of features to activate. Defaults to [].
---@field loadOutDirsFromCheck? boolean Run cargo check on startup to get the correct value for package OUT_DIRs. Defaults to false.
---@field noDefaultFeatures? boolean Do not activate the default feature. Defaults to false.
---@field target? string|nil Compilation target.
---@field noSysroot? boolean Internal config for debugging, disables loading of sysroot crates. Defaults to false.

---@class RustAnalyzerOptions.CheckOnSave
---@field enable? boolean Run specified cargo check command for diagnostics on save. Defaults to true.
---@field allFeatures? boolean|nil Check with all features. Defaults to RustAnalyzerOptions.Cargo.allFeatures.
---@field allTargets? boolean Check all targets and tests. Defaults to true.
---@field command? string Cargo command to use for cargo check. Defaults to 'check'.
---@field noDefaultFeatures? boolean|nil Do not activate the default feature.
---@field target? string|nil Check for a specific target.
---@field extraArgs? table Extra arguments for cargo check. Defaults to [].
---@field features? table|nil List of features to activate.
---@field overrideCommand? table|nil Fully override the command rust-analyzer uses for checking.

---@class RustAnalyzerOptions.Completion
---@field addCallArgumentSnippets? boolean Whether to add argument snippets when completing functions. Defaults to true.
---@field addCallParenthesis? boolean Whether to add parenthesis when completing functions. Defaults to true.
---@field postfix? RustAnalyzerOptions.Completion.Postfix Settings for postfix snippets.
---@field autoimport? boolean Toggles the additional completions that automatically add imports when completed. Defaults to true.

---@class RustAnalyzerOptions.Completion.Postfix
---@field enable? boolean Whether to show postfix snippets like dbg, if, not, etc. Defaults to true.

---@class RustAnalyzerOptions.Diagnostics
---@field enable? boolean Whether to show native rust-analyzer diagnostics. Defaults to true.
---@field enableExperimental? boolean Whether to show experimental rust-analyzer diagnostics. Defaults to true.
---@field disabled? table List of rust-analyzer diagnostics to disable. Defaults to [].
---@field warningsAsHint? table List of warnings that should be displayed with info severity. Defaults to [].
---@field warningsAsInfo? table List of warnings that should be displayed with hint severity. Defaults to [].

---@class RustAnalyzerOptions.Files
---@field watcher? string Controls file watching implementation. Defaults to 'client'.
---@field excludeDirs? table Directories ignored by rust-analyzer. Defaults to [].

---@class RustAnalyzerOptions.HoverActions
---@field debug? boolean Whether to show Debug action. Defaults to true.
---@field enable? boolean Whether to show HoverActions in Rust files. Defaults to true.
---@field gotoTypeDef? boolean Whether to show Go to Type Definition action. Defaults to true.
---@field implementations? boolean Whether to show Implementations action. Defaults to true.
---@field run? boolean Whether to show Run action. Defaults to true.
---@field linksInHover? boolean Use markdown syntax for links in hover. Defaults to true.

---@class RustAnalyzerOptions.Lens
---@field debug? boolean Whether to show Debug lens. Defaults to true.
---@field enable? boolean Whether to show CodeLens in Rust files. Defaults to true.
---@field implementations? boolean Whether to show Implementations lens. Defaults to true.
---@field run? boolean Whether to show Run lens. Defaults to true.
---@field methodReferences? boolean Whether to show Method References lens. Defaults to false.
---@field references? boolean Whether to show References lens. Defaults to false.

---@class RustAnalyzerOptions.Notifications
---@field cargoTomlNotFound? boolean Whether to show can't find Cargo.toml error message. Defaults to true.

---@class RustAnalyzerOptions.ProcMacro
---@field enable? boolean Enable Proc macro support. Defaults to false.
---@field server? string|nil Path to proc-macro server executable.

---@class RustAnalyzerOptions.Runnables
---@field overrideCargo? string|nil Command to be executed instead of 'cargo' for runnables.
---@field cargoExtraArgs? table Additional arguments to be passed to cargo for runnables. Defaults to [].

---@class RustAnalyzerOptions.Rustfmt
---@field extraArgs? table Additional arguments to rustfmt. Defaults to [].
---@field overrideCommand? table|nil Fully override the command rust-analyzer uses for formatting.

return nixCats("lsp.rust")
    and {
        settings = {
            ---@type RustAnalyzerOptions
            ["rust-analyzer"] = {
                diagnostics = {
                    enable = true,
                },
            },
        },
    }
