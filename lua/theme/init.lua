local base16 = require("base16-colorscheme")
base16.setup("catppuccin-mocha", { telescope_borders = true })

local colors = base16.colors
local hl = base16.highlight

-- for blink.cmp to look clean
hl.PMenuSel = { guifg = nil, guibg = colors.base02, gui = nil, guisp = nil, ctermfg = nil, ctermbg = colors.cterm02 }
hl.CmpItemAbbr = { guifg = nil, guibg = nil, gui = nil, guisp = nil, ctermfg = nil, ctermbg = nil }
