local M = {}

local ui = require 'gamify.ui'
local logic = require 'gamify.logic'

vim.api.nvim_create_user_command('Gamify', function()
  ui.show_status_window()
end, {})

vim.api.nvim_create_autocmd('BufReadPost', {
  callback = function()
    logic.add_xp(5)
  end,
})

return M
