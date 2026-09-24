local M = {}
M.palette_file = vim.fn.expand("~/.local/state/caelestia/theme/nvim-caelestia.lua")

function M.mtime()
  local stat = vim.uv.fs_stat(M.palette_file)
  return stat and stat.mtime or nil
end

function M.apply()
  local ok, palette = pcall(dofile, M.palette_file)
  if not ok or type(palette) ~= "table" or type(palette.colors) ~= "table" then
    error("Caelestia palette is missing or invalid: " .. M.palette_file)
  end
  local c = palette.colors
  vim.o.termguicolors = true
  vim.o.background = palette.mode == "light" and "light" or "dark"
  vim.cmd.highlight("clear")
  vim.g.colors_name = "caelestia"

  local function hl(group, spec)
    vim.api.nvim_set_hl(0, group, spec)
  end
  local transparent = { fg = c.onSurface, bg = "NONE" }
  for _, group in ipairs({ "Normal", "NormalNC", "NormalFloat", "SnacksDashboardNormal", "SignColumn", "FoldColumn", "EndOfBuffer", "WinBar", "WinBarNC" }) do
    hl(group, transparent)
  end
  hl("FloatBorder", { fg = c.outline, bg = "NONE" })
  hl("FloatTitle", { fg = c.primary, bg = "NONE", bold = true })
  hl("WinSeparator", { fg = c.outlineVariant, bg = "NONE" })
  hl("CursorLine", { bg = c.surfaceContainerLow })
  hl("CursorLineNr", { fg = c.primary, bg = "NONE", bold = true })
  hl("LineNr", { fg = c.outline, bg = "NONE" })
  hl("Visual", { bg = c.primaryContainer })
  hl("Search", { fg = c.onTertiary, bg = c.tertiary })
  hl("IncSearch", { fg = c.onPrimary, bg = c.primary })
  hl("MatchParen", { fg = c.primary, bold = true, underline = true })
  hl("Pmenu", { fg = c.onSurface, bg = c.surfaceContainer })
  hl("PmenuSel", { fg = c.onPrimary, bg = c.primary })
  hl("PmenuSbar", { bg = c.surfaceContainerHigh })
  hl("PmenuThumb", { bg = c.outline })
  hl("StatusLine", { fg = c.onSurface, bg = c.surfaceContainer })
  hl("StatusLineNC", { fg = c.onSurfaceVariant, bg = c.surfaceContainerLow })
  hl("TabLine", { fg = c.onSurfaceVariant, bg = c.surfaceContainerLow })
  hl("TabLineSel", { fg = c.primary, bg = c.surfaceContainer, bold = true })
  hl("Folded", { fg = c.onSurfaceVariant, bg = c.surfaceContainerLow })
  hl("ColorColumn", { bg = c.surfaceContainerLow })
  hl("NonText", { fg = c.outlineVariant, bg = "NONE" })
  hl("SpecialKey", { fg = c.outline, bg = "NONE" })
  hl("Directory", { fg = c.primary, bg = "NONE" })
  hl("Title", { fg = c.primary, bg = "NONE", bold = true })
  hl("Comment", { fg = c.onSurfaceVariant, italic = true })
  hl("Constant", { fg = c.tertiary })
  hl("String", { fg = c.secondary })
  hl("Character", { fg = c.secondary })
  hl("Number", { fg = c.tertiary })
  hl("Boolean", { fg = c.tertiary })
  hl("Identifier", { fg = c.onSurface })
  hl("Function", { fg = c.primary })
  hl("Statement", { fg = c.tertiary })
  hl("Keyword", { fg = c.tertiary, bold = true })
  hl("Operator", { fg = c.onSurfaceVariant })
  hl("PreProc", { fg = c.secondary })
  hl("Type", { fg = c.primary })
  hl("Special", { fg = c.secondary })
  hl("Underlined", { fg = c.primary, underline = true })
  hl("Error", { fg = c.error })
  hl("Todo", { fg = c.onPrimary, bg = c.primary, bold = true })
  hl("@comment", { link = "Comment" })
  hl("@string", { link = "String" })
  hl("@number", { link = "Number" })
  hl("@boolean", { link = "Boolean" })
  hl("@function", { link = "Function" })
  hl("@function.call", { link = "Function" })
  hl("@keyword", { link = "Keyword" })
  hl("@type", { link = "Type" })
  hl("@variable", { fg = c.onSurface })
  hl("@variable.parameter", { fg = c.secondary })
  hl("@property", { fg = c.primary })
  hl("@punctuation", { fg = c.onSurfaceVariant })
  hl("@markup.heading", { fg = c.primary, bold = true })
  hl("@markup.link", { fg = c.secondary, underline = true })
  hl("@markup.raw", { fg = c.secondary })
  for group, color in pairs({ Error = c.error, Warn = c.tertiary, Info = c.primary, Hint = c.secondary, Ok = c.success }) do
    hl("Diagnostic" .. group, { fg = color })
    hl("DiagnosticVirtualText" .. group, { fg = color, bg = "NONE" })
    hl("DiagnosticUnderline" .. group, { sp = color, undercurl = true })
  end
  hl("DiffAdd", { fg = c.success, bg = "NONE" })
  hl("DiffChange", { fg = c.primary, bg = "NONE" })
  hl("DiffDelete", { fg = c.error, bg = "NONE" })
  hl("DiffText", { fg = c.onPrimary, bg = c.primary })
  hl("GitSignsAdd", { fg = c.success, bg = "NONE" })
  hl("GitSignsChange", { fg = c.primary, bg = "NONE" })
  hl("GitSignsDelete", { fg = c.error, bg = "NONE" })
  hl("SnacksDashboardHeader", { fg = c.primary, bg = "NONE", bold = true })
  hl("SnacksDashboardIcon", { fg = c.secondary, bg = "NONE" })
  hl("SnacksDashboardKey", { fg = c.tertiary, bg = "NONE" })
  hl("SnacksDashboardDesc", { fg = c.onSurface, bg = "NONE" })
  hl("SnacksDashboardFooter", { fg = c.onSurfaceVariant, bg = "NONE" })
end

function M.setup_auto_refresh()
  if M.auto_refresh_installed then
    return
  end
  M.auto_refresh_installed = true
  local previous = M.mtime()
  vim.api.nvim_create_autocmd({ "FocusGained", "CursorHold" }, {
    group = vim.api.nvim_create_augroup("caelestia_palette", { clear = true }),
    callback = function()
      local current = M.mtime()
      if not current or (previous and current.sec == previous.sec and current.nsec == previous.nsec) then
        return
      end
      previous = current
      vim.cmd.colorscheme("caelestia")
    end,
  })
end

return M
