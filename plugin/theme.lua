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

do
    -- local snacks_bg                    = palette.base
    -- local snacks_panel                 = palette.base
    -- local snacks_alt                   = palette.crust
    -- local snacks_border                = palette.surface1
    -- local snacks_dim                   = palette.subtext0
    --
    -- -- Mirror the old Telescope palette so Snacks renders identically without it.
    hl.SnacksNormal = { guifg = palette.text, guibg = palette.peach }
    -- hl.SnacksNormalNC                  = { guifg = palette.subtext0, guibg = snacks_alt }
    -- hl.SnacksTitle                     = { guifg = palette.blue, guibg = snacks_bg, gui = "bold" }
    -- hl.SnacksFooter                    = { guifg = palette.subtext1, guibg = snacks_bg }
    -- hl.SnacksFooterDesc                = { guifg = snacks_dim, guibg = snacks_bg }
    -- hl.SnacksFooterKey                 = { guifg = palette.yellow, guibg = snacks_bg, gui = "bold" }
    -- hl.SnacksWinBar                    = { guifg = palette.text, guibg = snacks_panel }
    -- hl.SnacksWinBarNC                  = { guifg = palette.subtext0, guibg = snacks_panel }
    -- hl.SnacksWinSeparator              = { guifg = snacks_border }
    -- hl.SnacksWinKey                    = { guifg = palette.yellow, gui = "bold" }
    -- hl.SnacksWinKeyDesc                = { guifg = palette.subtext1 }
    -- hl.SnacksWinKeySep                 = { guifg = snacks_border }
    -- hl.SnacksBackdrop_                 = { guifg = palette.mantle, guibg = palette.mantle }
    --
    -- hl.SnacksDashboardNormal           = { guifg = palette.text, guibg = palette.mantle }
    -- hl.SnacksDashboardHeader           = { guifg = palette.mauve, guibg = palette.mantle, gui = "bold" }
    -- hl.SnacksDashboardDesc             = { guifg = palette.subtext1 }
    -- hl.SnacksDashboardIcon             = { guifg = palette.blue }
    -- hl.SnacksDashboardKey              = { guifg = palette.yellow, gui = "bold" }
    -- hl.SnacksDashboardTitle            = { guifg = palette.blue, gui = "bold" }
    -- hl.SnacksDashboardFooter           = { guifg = palette.subtext0 }
    -- hl.SnacksDashboardFile             = { guifg = palette.text }
    -- hl.SnacksDashboardDir              = { guifg = palette.subtext0 }
    -- hl.SnacksDashboard                 = "SnacksDashboardNormal"
    -- hl.SnacksDashboardTerminal         = { guifg = palette.text, guibg = snacks_bg }
    --
    -- hl.SnacksDim                       = { guifg = snacks_dim }
    -- hl.SnacksDebug                     = { guifg = palette.peach, guibg = snacks_panel }
    -- hl.SnacksDebugIndent               = { guifg = palette.yellow, guibg = snacks_panel }
    -- hl.SnacksDebugPrint                = { guifg = palette.teal }
    --
    -- hl.SnacksScratch                   = { guifg = palette.text, guibg = snacks_panel }
    -- hl.SnacksScratchTitle              = { guifg = palette.blue, guibg = snacks_panel, gui = "bold" }
    --
    -- hl.SnacksStatusColumn              = { guifg = palette.text, guibg = snacks_bg }
    -- hl.SnacksStatusColumnMark          = { guifg = palette.yellow, guibg = snacks_bg }
    --
    -- hl.SnacksZen                       = { guifg = palette.text, guibg = snacks_bg }
    -- hl.SnacksZenIcon                   = { guifg = palette.blue, gui = "bold" }
    --
    -- hl.SnacksImage                     = { guifg = palette.text, guibg = snacks_bg }
    -- hl.SnacksImageAnchor               = { guifg = snacks_dim }
    -- hl.SnacksImageLoading              = { guifg = palette.yellow }
    -- hl.SnacksImageSpinner              = { guifg = palette.blue }
    -- hl.SnacksImageMath                 = { guifg = palette.teal }
    --
    -- hl.SnacksInput                     = { guifg = palette.text, guibg = snacks_panel }
    -- hl.SnacksInputNormal               = { guifg = palette.text, guibg = snacks_panel }
    -- hl.SnacksInputBorder               = { guifg = palette.blue }
    -- hl.SnacksInputTitle                = { guifg = palette.blue, gui = "bold" }
    -- hl.SnacksInputIcon                 = { guifg = palette.yellow }
    --
    -- local notif_bg                     = snacks_alt
    -- hl.SnacksNotifier                  = { guifg = palette.text, guibg = notif_bg }
    -- hl.SnacksNotifierMinimal           = { guifg = palette.text, guibg = snacks_bg }
    -- hl.SnacksNotifierHistory           = { guifg = palette.text, guibg = snacks_panel }
    -- hl.SnacksNotifierHistoryTitle      = { guifg = palette.blue, guibg = snacks_panel, gui = "bold" }
    --
    -- hl.SnacksIndent                    = { guifg = palette.surface1 }
    -- hl.SnacksIndent1                   = { guifg = palette.surface1 }
    -- hl.SnacksIndent2                   = { guifg = palette.surface1 }
    -- hl.SnacksIndent3                   = { guifg = palette.surface1 }
    -- hl.SnacksIndent4                   = { guifg = palette.surface1 }
    -- hl.SnacksIndent5                   = { guifg = palette.surface1 }
    -- hl.SnacksIndent6                   = { guifg = palette.surface1 }
    -- hl.SnacksIndent7                   = { guifg = palette.surface1 }
    -- hl.SnacksIndent8                   = { guifg = palette.surface1 }
    -- hl.SnacksIndentBlank               = { guifg = palette.surface1 }
    -- hl.SnacksIndentScope               = { guifg = palette.blue }
    -- hl.SnacksIndentChunk               = { guifg = palette.blue }
    --
    -- local picker_bg                    = snacks_alt
    -- local picker_panel                 = snacks_panel
    -- hl.SnacksPicker                    = { guifg = palette.text, guibg = picker_bg }
    -- hl.SnacksPickerList                = { guifg = palette.text, guibg = picker_bg }
    -- hl.SnacksPickerPreview             = { guifg = palette.text, guibg = picker_bg }
    -- hl.SnacksPickerListCursorLine      = { guifg = palette.text, guibg = picker_panel, gui = "bold" }
    -- hl.SnacksPickerPreviewCursorLine   = { guifg = palette.text, guibg = picker_panel, gui = "bold" }
    -- hl.SnacksPickerBox                 = { guifg = snacks_border, guibg = picker_bg }
    -- hl.SnacksPickerPrompt              = { guifg = palette.blue, gui = "bold" }
    -- hl.SnacksPickerInput               = { guifg = palette.red, guibg = palette.mantle }
    -- hl.SnacksPickerInputSearch         = { guifg = palette.yellow, gui = "bold" }
    -- hl.SnacksPickerTotals              = { guifg = snacks_dim }
    -- hl.SnacksPickerToggle              = { guifg = palette.peach, gui = "bold" }
    -- hl.SnacksPickerSpinner             = { guifg = palette.blue }
    -- hl.SnacksPickerPickWin             = { guifg = palette.yellow, gui = "bold" }
    -- hl.SnacksPickerSearch              = { guifg = palette.yellow, gui = "bold" }
    -- hl.SnacksPickerMatch               = { guifg = palette.mauve, gui = "bold" }
    -- hl.SnacksPickerLabel               = { guifg = palette.teal, gui = "bold" }
    -- hl.SnacksPickerSelected            = { guifg = palette.text, gui = "bold" }
    -- hl.SnacksPickerUnselected          = { guifg = palette.subtext0 }
    -- hl.SnacksPickerComment             = { guifg = snacks_dim, gui = "italic" }
    -- hl.SnacksPickerDesc                = { guifg = palette.subtext1 }
    -- hl.SnacksPickerDelim               = { guifg = snacks_border }
    -- hl.SnacksPickerDir                 = { guifg = palette.subtext0 }
    -- hl.SnacksPickerDirectory           = { guifg = palette.subtext0 }
    -- hl.SnacksPickerFile                = { guifg = palette.text }
    -- hl.SnacksPickerSpecial             = { guifg = palette.mauve }
    -- hl.SnacksPickerDimmed              = { guifg = snacks_dim }
    -- hl.SnacksPickerFileType            = { guifg = palette.teal }
    -- hl.SnacksPickerPathIgnored         = { guifg = palette.surface1 }
    -- hl.SnacksPickerPathHidden          = { guifg = palette.surface1, gui = "italic" }
    -- hl.SnacksPickerTree                = { guifg = palette.surface1 }
    -- hl.SnacksPickerIdx                 = { guifg = palette.peach }
    -- hl.SnacksPickerRow                 = { guifg = palette.teal }
    -- hl.SnacksPickerCol                 = { guifg = palette.teal }
    -- hl.SnacksPickerRegister            = { guifg = palette.yellow }
    -- hl.SnacksPickerTime                = { guifg = palette.subtext0 }
    -- hl.SnacksPickerNotificationMessage = { guifg = palette.text }
    -- hl.SnacksPickerBufFlags            = { guifg = palette.subtext0 }
    -- hl.SnacksPickerBufNr               = { guifg = palette.yellow }
    -- hl.SnacksPickerBufType             = { guifg = palette.teal }
    -- hl.SnacksPickerCmd                 = { guifg = palette.green }
    -- hl.SnacksPickerCmdBuiltin          = { guifg = palette.blue }
    -- hl.SnacksPickerBold                = { guifg = palette.text, gui = "bold" }
    -- hl.SnacksPickerItalic              = { guifg = palette.subtext1, gui = "italic" }
    -- hl.SnacksPickerCode                = { guifg = palette.peach }
    -- hl.SnacksPickerRule                = { guifg = snacks_border }
    -- hl.SnacksPickerAuPattern           = { guifg = palette.green }
    -- hl.SnacksPickerAuEvent             = { guifg = palette.peach }
    -- hl.SnacksPickerAuGroup             = { guifg = palette.blue }
    -- hl.SnacksPickerDiagnosticCode      = { guifg = palette.mauve }
    -- hl.SnacksPickerDiagnosticSource    = { guifg = snacks_dim }
    -- hl.SnacksPickerManPage             = { guifg = palette.blue }
    -- hl.SnacksPickerManSection          = { guifg = palette.teal }
    -- hl.SnacksPickerManDesc             = { guifg = palette.subtext1 }
    -- hl.SnacksPickerKeymapMode          = { guifg = palette.peach }
    -- hl.SnacksPickerKeymapLhs           = { guifg = palette.teal }
    -- hl.SnacksPickerKeymapRhs           = { guifg = palette.text }
    -- hl.SnacksPickerKeymapNowait        = { guifg = palette.yellow }
    -- hl.SnacksPickerLink                = { guifg = palette.teal, gui = "underline" }
    -- hl.SnacksPickerLinkBroken          = { guifg = semantic.diag.error, gui = "underline" }
    -- hl.SnacksPickerUndoAdded           = { guifg = semantic.git.added }
    -- hl.SnacksPickerUndoRemoved         = { guifg = semantic.git.removed }
    -- hl.SnacksPickerUndoCurrent         = { guifg = palette.blue, gui = "bold" }
    -- hl.SnacksPickerUndoSaved           = { guifg = palette.subtext1 }
    -- hl.SnacksPickerIcon                = { guifg = palette.yellow }
    -- hl.SnacksPickerIconSource          = { guifg = palette.teal }
    -- hl.SnacksPickerIconCategory        = { guifg = palette.mauve }
    -- hl.SnacksPickerIconName            = { guifg = palette.text }
    -- hl.SnacksPickerLspEnabled          = { guifg = palette.green }
    -- hl.SnacksPickerLspDisabled         = { guifg = semantic.diag.warning }
    -- hl.SnacksPickerLspAttached         = { guifg = palette.blue }
    -- hl.SnacksPickerLspAttachedBuf      = { guifg = palette.teal }
    -- hl.SnacksPickerLspUnavailable      = { guifg = semantic.diag.error }
    --
    -- hl.SnacksPickerGit                 = { guifg = palette.blue }
    -- hl.SnacksPickerGitStatus           = { guifg = snacks_dim }
    -- hl.SnacksPickerGitAuthor           = { guifg = palette.text }
    -- hl.SnacksPickerGitCommit           = { guifg = palette.teal }
    -- hl.SnacksPickerGitDate             = { guifg = palette.subtext0 }
    -- hl.SnacksPickerGitIssue            = { guifg = palette.text }
    -- hl.SnacksPickerGitMsg              = { guifg = palette.text }
    -- hl.SnacksPickerGitScope            = { guifg = palette.teal }
    -- hl.SnacksPickerGitType             = { guifg = palette.mauve }
    -- hl.SnacksPickerGitBranch           = { guifg = palette.blue }
    -- hl.SnacksPickerGitBranchCurrent    = { guifg = palette.blue, gui = "bold" }
    -- hl.SnacksPickerGitBreaking         = { guifg = semantic.diag.error, gui = "bold" }
    -- hl.SnacksPickerGitDetached         = { guifg = semantic.diag.warning }
    -- hl.SnacksPickerGitStatusAdded      = { guifg = semantic.git.added }
    -- hl.SnacksPickerGitStatusModified   = { guifg = semantic.git.changed }
    -- hl.SnacksPickerGitStatusDeleted    = { guifg = semantic.git.removed }
    -- hl.SnacksPickerGitStatusRenamed    = { guifg = palette.yellow }
    -- hl.SnacksPickerGitStatusCopied     = { guifg = palette.mauve }
    -- hl.SnacksPickerGitStatusStaged     = { guifg = palette.blue }
    -- hl.SnacksPickerGitStatusUnmerged   = { guifg = semantic.diag.error }
    -- hl.SnacksPickerGitStatusUntracked  = { guifg = snacks_dim }
    --
    -- hl.SnacksDiffAdd                   = { guifg = semantic.git.added }
    -- hl.SnacksDiffDelete                = { guifg = semantic.git.removed }
    -- hl.SnacksDiffContext               = { guifg = palette.subtext1 }
    -- hl.SnacksDiffHeader                = { guifg = palette.blue, gui = "bold" }
    -- hl.SnacksDiffConflict              = { guifg = semantic.diag.warning, gui = "bold" }
    -- hl.SnacksDiffLabel                 = { guifg = palette.mauve }
    --
    -- hl.SnacksGh                        = { guifg = palette.text, guibg = snacks_bg }
    -- hl.SnacksGhNormal                  = { guifg = palette.text, guibg = snacks_bg }
    -- hl.SnacksGhNormalFloat             = { guifg = palette.text, guibg = snacks_bg }
    -- hl.SnacksGhBorder                  = { guifg = snacks_border }
    -- hl.SnacksGhTitle                   = { guifg = palette.blue, gui = "bold" }
    -- hl.SnacksGhFooter                  = { guifg = palette.subtext0 }
    -- hl.SnacksGhGray                    = { guifg = palette.subtext0 }
    -- hl.SnacksGhGreen                   = { guifg = palette.green }
    -- hl.SnacksGhRed                     = { guifg = palette.red }
    -- hl.SnacksGhPurple                  = { guifg = palette.mauve }
    -- hl.SnacksGhStat                    = { guifg = palette.blue }
    -- hl.SnacksGhAdditions               = { guifg = semantic.git.added }
    -- hl.SnacksGhDeletions               = { guifg = semantic.git.removed }
    -- hl.SnacksGhCommentAction           = { guifg = palette.yellow }
    -- hl.SnacksGhLabel                   = { guifg = palette.mauve }
    -- hl.SnacksGhBranch                  = { guifg = palette.blue }
    -- hl.SnacksGhCheck                   = { guifg = palette.green }
    -- hl.SnacksGhDelim                   = { guifg = snacks_border }
    -- hl.SnacksGhPr                      = { guifg = palette.text }
    -- hl.SnacksGhPrClean                 = { guifg = palette.green }
    -- hl.SnacksGhPrDirty                 = { guifg = palette.peach }
    -- hl.SnacksGhReview                  = { guifg = palette.blue }
    -- hl.SnacksGhStatBadge               = { guifg = palette.mantle, guibg = palette.blue, gui = "bold" }
    -- hl.SnacksGhAssocBadge              = { guifg = palette.mantle, guibg = palette.blue, gui = "bold" }
    -- hl.SnacksGhAuthorBadge             = { guifg = palette.mantle, guibg = palette.teal, gui = "bold" }
    -- hl.SnacksGhBotBadge                = { guifg = palette.mantle, guibg = palette.surface1, gui = "bold" }
    -- hl.SnacksGhOwnerBadge              = { guifg = palette.mantle, guibg = palette.mauve, gui = "bold" }
    -- hl.SnacksGhUserBadge               = { guifg = palette.mantle, guibg = palette.blue, gui = "bold" }
    -- hl.SnacksGhReactionBadge           = { guifg = palette.mantle, guibg = palette.yellow, gui = "bold" }
    -- hl.SnacksGhSuggestionBadge         = { guifg = palette.mantle, guibg = palette.green, gui = "bold" }
    -- hl.SnacksGhScratchBorder           = { guifg = snacks_border }
    -- hl.SnacksGhScratchTitle            = { guifg = palette.blue, gui = "bold" }
    --
    -- hl.SnacksBadge_                    = { guifg = palette.mantle, guibg = palette.blue, gui = "bold" }
    --
    -- hl.SnacksProfiler                  = { guifg = palette.text, guibg = snacks_panel }
    -- hl.SnacksProfilerBadge             = { guifg = palette.mantle, guibg = palette.blue, gui = "bold" }
    -- hl.SnacksProfilerBadgeInfo         = { guifg = palette.mantle, guibg = palette.teal, gui = "bold" }
    -- hl.SnacksProfilerBadgeTrace        = { guifg = palette.mantle, guibg = palette.mauve, gui = "bold" }
    -- hl.SnacksProfilerHot               = { guifg = palette.peach, gui = "bold" }
    -- hl.SnacksProfilerIcon              = { guifg = palette.blue }
    -- hl.SnacksProfilerIconInfo          = { guifg = palette.teal }
    -- hl.SnacksProfilerLoaded            = { guifg = palette.teal }
    -- hl.SnacksProfilerStarted           = { guifg = palette.green }
    -- hl.SnacksProfilerStopped           = { guifg = palette.red }
end
