return {
  'folke/snacks.nvim',
  priority = 1000,
  lazy = false,
  ---@type snacks.Config
  opts = {
    bigfile = { enabled = true },
    indent = { enabled = true },
    input = { enabled = true },
    notifier = {
      enabled = true,
      timeout = 3000,
    },
    terminal = {},
  },
  keys = {
    {
      '<c-/>',
      function()
        Snacks.terminal()
      end,
      desc = 'Toggle Terminal',
    },
  },
}
