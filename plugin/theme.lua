local base16 = require("base16-colorscheme")
base16.setup("catppuccin-mocha", {})

local colors = base16.colors
local hl = base16.highlight

vim.cmd.colorscheme("base16-catppuccin-mocha")

local palette                = {
    mantle    = colors.base00,
    crust     = colors.base01,
    base      = colors.base02,
    surface0  = colors.base03,
    surface1  = colors.base04,

    text      = colors.base05,
    subtext1  = colors.base06,
    subtext0  = colors.base07,

    red       = colors.base08,
    peach     = colors.base09,
    yellow    = colors.base0A,
    green     = colors.base0B,
    teal      = colors.base0C,
    blue      = colors.base0D,
    mauve     = colors.base0E,
    rosewater = colors.base0F,
}

local semantic               = {
    diag = {
        error   = palette.red,
        warning = palette.peach,
        info    = palette.yellow,
        hint    = palette.teal,
    },
    git  = {
        added   = palette.green,
        changed = palette.yellow,
        removed = palette.red,
    },
    mode = {
        normal   = palette.blue,
        visual   = palette.mauve,
        insert   = palette.green,
        replace  = palette.peach,
        command  = palette.yellow,
        terminal = palette.green,
    },
}

hl.PMenuSel                  = { guibg = palette.base }
hl.CmpItemAbbr               = {}

hl.TSVariable                = { guifg = palette.yellow }

hl.TblSectionA               = { guifg = palette.mantle, guibg = palette.blue, gui = "reverse" }
hl.TblSectionB               = { guifg = palette.text, guibg = palette.base }
hl.TblSectionC               = { guifg = palette.text, guibg = palette.mantle }

hl.TblBuffer                 = { guifg = palette.text, guibg = palette.crust }
hl.TblCloseButton            = { guifg = semantic.diag.error, guibg = palette.crust }
hl.TblFilename               = { guibg = palette.crust, guifg = palette.text }

hl.TblCurrentBuffer          = { guifg = palette.text, guibg = palette.base }
hl.TblCurrentFilename        = { guifg = palette.blue, guibg = palette.base, gui = "bold" }
hl.TblCurrentCloseButton     = { guifg = semantic.diag.error, guibg = palette.base }

hl.TblDiagnosticError        = { guifg = semantic.diag.error, guibg = palette.crust, gui = "bold" }
hl.TblDiagnosticWarn         = { guifg = semantic.diag.warning, guibg = palette.crust }
hl.TblDiagnosticInfo         = { guifg = semantic.diag.info, guibg = palette.crust }
hl.TblDiagnosticHint         = { guifg = semantic.diag.hint, guibg = palette.crust }

hl.TblCurrentDiagnosticError = { guifg = semantic.diag.error, guibg = palette.base, gui = "bold" }
hl.TblCurrentDiagnosticWarn  = { guifg = semantic.diag.warning, guibg = palette.base }
hl.TblCurrentDiagnosticInfo  = { guifg = semantic.diag.info, guibg = palette.base }
hl.TblCurrentDiagnosticHint  = { guifg = semantic.diag.hint, guibg = palette.base }

hl.TblTab                    = { guifg = palette.text, guibg = palette.crust }
hl.TblTabCloseButton         = { guifg = semantic.diag.error, guibg = palette.crust }
hl.TblCurrentTab             = { guifg = palette.blue, guibg = palette.base, gui = "bold" }
hl.TblCurrentTabCloseButton  = { guifg = semantic.diag.error, guibg = palette.base }

hl.StlSectionA               = { guifg = palette.mantle, guibg = palette.blue, gui = "reverse" }
hl.StlSectionB               = { guifg = palette.text, guibg = palette.base }
hl.StlSectionC               = "Normal"

hl.StlFilename               = "Field"
hl.StlDiagnosticError        = { guifg = semantic.diag.error, guibg = palette.base, gui = "bold" }
hl.StlDiagnosticWarn         = { guifg = semantic.diag.warning, guibg = palette.base }
hl.StlDiagnosticInfo         = { guifg = semantic.diag.info, guibg = palette.base }
hl.StlDiagnosticHint         = { guifg = semantic.diag.hint, guibg = palette.base }

hl.StlGitBranch              = { guifg = palette.blue, guibg = palette.base, gui = "bold" }
hl.StlGitAdded               = { guifg = semantic.git.added, guibg = palette.base }
hl.StlGitChanged             = { guifg = semantic.git.changed, guibg = palette.base }
hl.StlGitDeleted             = { guifg = semantic.git.removed, guibg = palette.base }
hl.StlGitRemoteAhead         = { guifg = palette.mauve, guibg = palette.base }
hl.StlGitRemoteBehind        = { guifg = palette.mauve, guibg = palette.base }

hl.GitSignsUntracked         = "@method"
hl.GitSignsChange            = "@class"
hl.GitSignsChangedelete      = "@constant"

hl.StcSignColumn             = "SignColumn"
hl.StcFoldColumn             = "FoldColumn"
hl.StcLineNumber             = "LineNr"
hl.StcCurrentLineNumber      = { link = "CursorLine", gui = "bold" }
hl.StcFold                   = { guifg = palette.blue }
hl.StcFoldCurrent            = { guifg = palette.blue, guibg = palette.base }
hl.StcFolded                 = { guifg = palette.blue }

hl.StlModeNormal             = { guifg = semantic.mode.normal, guibg = palette.mantle, gui = "reverse,bold" }
hl.StlModeVisual             = { guifg = semantic.mode.visual, guibg = palette.mantle, gui = "reverse,bold" }
hl.StlModeInsert             = { guifg = semantic.mode.insert, guibg = palette.mantle, gui = "reverse,bold" }
hl.StlModeReplace            = { guifg = semantic.mode.replace, guibg = palette.mantle, gui = "reverse,bold" }
hl.StlModeCommand            = { guifg = semantic.mode.command, guibg = palette.mantle, gui = "reverse,bold" }
hl.StlModeTerminalInsert     = { guifg = semantic.mode.terminal, guibg = palette.mantle, gui = "reverse,bold" }
hl.StlModeTerminalNormal     = { guifg = semantic.mode.normal, guibg = palette.mantle, gui = "reverse,bold" }

hl.FloatBorder               = { guifg = palette.blue }
