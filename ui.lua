local M = {}
local logic = require 'gamify.logic'

function M.show_status_window()
  local buffer = vim.api.nvim_create_buf(false, true)

  local data = logic.get_data()
  local lines = {
    '🎮 Gamify.nvim Status 🎮',
    '',
    'XP: ' .. data.xp,
    'Achievements:',
  }

  if #data.achievements > 0 then
    for _, achievement in ipairs(data.achievements) do
      table.insert(lines, '- ' .. achievement)
    end
  else
    table.insert(lines, 'None yet.')
  end

  table.insert(lines, '')
  table.insert(lines, 'Goals:')
  if #data.goals > 0 then
    for _, goal in ipairs(data.goals) do
      table.insert(lines, '- ' .. goal.description .. ' (Deadline: ' .. goal.deadline .. ')')
    end
  else
    table.insert(lines, 'No goals set.')
  end

  table.insert(lines, '')
  table.insert(lines, 'Press esc key to close.')

  local opts = {
    style = 'minimal',
    relative = 'editor',
    width = 50,
    height = #lines + 2,
    row = math.floor((vim.o.lines - (#lines + 2)) / 2),
    col = math.floor((vim.o.columns - 50) / 2),
    border = 'rounded',
  }

  local window = vim.api.nvim_open_win(buffer, true, opts)
  vim.api.nvim_buf_set_lines(buffer, 0, -1, false, lines)
  vim.api.nvim_buf_set_keymap(buffer, 'n', '<Esc>', ':q<CR>', { noremap = true, silent = true })
  vim.api.nvim_buf_set_option(buffer, 'modifiable', false)
end

return M
