local generated_theme = vim.fn.expand("~/.local/state/caelestia/theme/nvim.lua")

local function load_caelestia_palette()
  local ok, theme = pcall(dofile, generated_theme)
  if not ok or type(theme) ~= "table" or type(theme.colors) ~= "table" then
    vim.schedule(function()
      vim.notify(
        "Caelestia Neovim theme has not been generated yet: " .. generated_theme,
        vim.log.levels.WARN
      )
    end)
    return nil
  end
  return theme
end

return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    opts = function(_, opts)
      local theme = load_caelestia_palette()
      if not theme then
        return opts
      end

      opts.flavour = theme.flavour
      opts.background = {
        light = "latte",
        dark = "mocha",
      }
      -- Keep the generated Material You values exact. Catppuccin otherwise
      -- offsets every blue channel when TERM happens to report xterm-kitty.
      opts.kitty = false
      opts.color_overrides = opts.color_overrides or {}
      opts.color_overrides[theme.flavour] = theme.colors
      return opts
    end,
  },
  {
    "LazyVim/LazyVim",
    opts = {
      -- Using a function ensures Catppuccin applies the generated palette after
      -- lazy.nvim has run the plugin's setup function (and compiled its cache).
      colorscheme = function()
        local theme = load_caelestia_palette()
        require("catppuccin").load(theme and theme.flavour or nil)
      end,
    },
  },
}
