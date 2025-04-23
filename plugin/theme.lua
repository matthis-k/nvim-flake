local base16 = require("base16-colorscheme")
base16.setup("catppuccin-mocha", { telescope_borders = true })

local colors = base16.colors
local hl = base16.highlight

vim.cmd.colorscheme("base16-catppuccin-mocha")

-- for blink.cmp to look clean
hl.PMenuSel                  = {
    guifg = nil,
    guibg = colors.base02,
    gui = nil,
    guisp = nil,
    ctermfg = nil,
    ctermbg =
        colors.cterm02,
}
hl.CmpItemAbbr               = { guifg = nil, guibg = nil, gui = nil, guisp = nil, ctermfg = nil, ctermbg = nil }

hl.TblSectionA               = "StlSectionA"
hl.TblSectionB               = "StlSectionB"
hl.TblSectionC               = "StlSectionC"

hl.TblBufferLabel            = { link = "TblSectionA", gui = "bold" }

hl.TblBuffer                 = { link = "TblSectionB", guibg = colors.base01 }
hl.TblCloseButton            = { guifg = colors.base08, guibg = colors.base01 }
hl.TblFilename               = { link = "TblBuffer", guifg = colors.base05 }

hl.TblCurrentBuffer          = { link = "TblBuffer", guibg = colors.base02 }
hl.TblCurrentFilename        = { guifg = colors.base0D, guibg = colors.base02, gui = "bold" }
hl.TblCurrentCloseButton     = { guifg = colors.base08, guibg = colors.base02 }

hl.TblDiagnosticError        = { guifg = colors.base08, guibg = colors.base01, gui = "bold" }
hl.TblDiagnosticWarn         = { guifg = colors.base09, guibg = colors.base01 }
hl.TblDiagnosticInfo         = { guifg = colors.base0D, guibg = colors.base01 }
hl.TblDiagnosticHint         = { guifg = colors.base0C, guibg = colors.base01 }

hl.TblCurrentDiagnosticError = { guifg = colors.base08, guibg = colors.base02, gui = "bold" }
hl.TblCurrentDiagnosticWarn  = { guifg = colors.base09, guibg = colors.base02 }
hl.TblCurrentDiagnosticInfo  = { guifg = colors.base0D, guibg = colors.base02 }
hl.TblCurrentDiagnosticHint  = { guifg = colors.base0C, guibg = colors.base02 }

hl.TblTabLabel               = { link = "TblSectionA", gui = "bold" }
hl.TblTab                    = { link = "TblSectionB", guibg = colors.base01 }
hl.TblTabCloseButton         = { guifg = colors.base08, guibg = colors.base01 }
hl.TblCurrentTab             = { guifg = colors.base0D, guibg = colors.base02, gui = "bold" }
hl.TblCurrentTabCloseButton  = { guifg = colors.base08, guibg = colors.base02 }

hl.StlSectionA               = { guifg = colors.base0D, guibg = colors.base00, gui = "reverse" }
hl.StlSectionB               = { guibg = colors.base02 }
hl.StlSectionC               = "Normal"

hl.StlModeNormal             = { guifg = colors.base0D, guibg = colors.base00, gui = "reverse,bold" }
hl.StlModeVisual             = { guifg = colors.base0E, guibg = colors.base00, gui = "reverse,bold" }
hl.StlModeInsert             = { guifg = colors.base0B, guibg = colors.base00, gui = "reverse,bold" }
hl.StlModeReplace            = { guifg = colors.base09, guibg = colors.base00, gui = "reverse,bold" }
hl.StlModeCommand            = { guifg = colors.base0A, guibg = colors.base00, gui = "reverse,bold" }
hl.StlModeTerminalInsert     = "StlModeInsert"
hl.StlModeTerminalNormal     = "StlModeNormal"

hl.StlFilename               = "Field"

hl.StlDiagnosticError        = { guifg = colors.base08, guibg = colors.base02, gui = "bold" }
hl.StlDiagnosticWarn         = { guifg = colors.base09, guibg = colors.base02 }
hl.StlDiagnosticInfo         = { guifg = colors.base0D, guibg = colors.base02 }
hl.StlDiagnosticHint         = { guifg = colors.base0C, guibg = colors.base02 }

hl.StlGitBranch              = { guifg = colors.base0D, guibg = colors.base02, gui = "bold" }
hl.StlGitAdded               = { guifg = colors.base0B, guibg = colors.base02 }
hl.StlGitChanged             = { guifg = colors.base0A, guibg = colors.base02 }
hl.StlGitDeleted             = { guifg = colors.base08, guibg = colors.base02 }
hl.StlGitRemoteAhead         = { guifg = colors.base0E, guibg = colors.base02 }
hl.StlGitRemoteBehind        = { guifg = colors.base0E, guibg = colors.base02 }

hl.GitSignsUntracked         = "@method"
hl.GitSignsChange            = "@class"
hl.GitSignsChangedelete      = "@constant"

hl.StcSignColumn             = "SignColumn"
hl.StcFoldColumn             = "FoldColumn"
hl.StcLineNumber             = "LineNr"
hl.StcCurrentLineNumber      = { link = "CursorLine", gui = "bold" }
hl.StcFold                   = { guifg = colors.base03 }
hl.StcFoldCurrent            = { guifg = colors.base03, guibg = colors.base02 }
hl.StcFolded                 = { guifg = colors.base03 }
