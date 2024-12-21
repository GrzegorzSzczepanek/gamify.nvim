local M = {}
local logic = require 'gamify.logic'

-- TODO add popups showing that user got exp for something
-- TODO mineraft-like popups with achievements

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

function M.show_popup(text, title, corner)
  local width = math.min(50, vim.o.columns - 4)
  local height = 4
  local row, col

  if corner == 'top_left' then
    row, col = 1, 1
  elseif corner == 'top_right' then
    row, col = 1, vim.o.columns - width - 1
  elseif corner == 'bottom_left' then
    row, col = vim.o.lines - height - 1, 1
  elseif corner == 'bottom_right' then
    row, col = vim.o.lines - height - 1, vim.o.columns - width - 1
  else
    row, col = vim.o.lines - height - 1, vim.o.columns - width - 1
  end

  local buf = vim.api.nvim_create_buf(false, true)

  local lines = {
    '🟢 [' .. title .. ']',
    text,
    'Press any key to dismiss',
  }
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  local opts = {
    relative = 'editor',
    width = width,
    height = #lines,
    col = col,
    row = row,
    style = 'minimal',
    border = 'rounded',
    noautocmd = true,
  }

  local win = vim.api.nvim_open_win(buf, false, opts)

  vim.cmd [[
  highlight NormalFloat  guibg=NONE
  highlight FloatBorder  guifg=#5f87af guibg=NONE
  ]]
  -- Make the float’s border and background match highlight groups
  vim.api.nvim_win_set_option(win, 'winhighlight', 'Normal:NormalFloat,FloatBorder:FloatBorder')

  vim.api.nvim_buf_add_highlight(buf, -1, 'WarningMsg', 0, 0, -1) -- Title line
  vim.api.nvim_buf_add_highlight(buf, -1, 'Normal', 1, 0, -1) -- Message line
  vim.api.nvim_buf_add_highlight(buf, -1, 'Comment', 2, 0, -1) -- Footer line

  vim.keymap.set('n', '<Esc>', function()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end, { buffer = buf, nowait = true, noremap = true, silent = true })

  vim.defer_fn(function()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end, 3000)
end

function M.show_languages_ui()
  local data = logic.get_data()
  local lines_per_lang = data.lines_written_in_specified_langs or {}

  -- Convert the table to an array of key-value pairs for sorting
  local lang_lines = {}
  for lang, lines in pairs(lines_per_lang) do
    table.insert(lang_lines, { lang = lang, lines = lines })
  end

  -- sort the array by the number of lines in descending order
  table.sort(lang_lines, function(a, b)
    return a.lines > b.lines
  end)

  local ui_lines = { '📊 Language Stats 📊', '', 'Most Used Languages:' }
  local max_bar_length = 30
  local max_lines = lang_lines[1] and lang_lines[1].lines or 1

  for _, lang_data in ipairs(lang_lines) do
    local bar_length = math.floor((lang_data.lines / max_lines) * max_bar_length)
    local bar = string.rep('█', bar_length) .. string.rep(' ', max_bar_length - bar_length)
    table.insert(ui_lines, string.format('%-10s | %s ~%d lines', lang_data.lang, bar, lang_data.lines))
  end

  if #ui_lines == 3 then
    table.insert(ui_lines, 'No data available.')
  end

  table.insert(ui_lines, '')
  table.insert(ui_lines, 'Press esc key to close.')

  local buffer = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buffer, 0, -1, false, ui_lines)

  local opts = {
    style = 'minimal',
    relative = 'editor',
    width = 50,
    height = #ui_lines + 2,
    row = math.floor((vim.o.lines - (#ui_lines + 2)) / 2),
    col = math.floor((vim.o.columns - 50) / 2),
    border = 'rounded',
  }

  local window = vim.api.nvim_open_win(buffer, true, opts)

  vim.api.nvim_buf_set_keymap(buffer, 'n', '<Esc>', ':q<CR>', { noremap = true, silent = true })
  vim.api.nvim_buf_set_option(buffer, 'modifiable', false)
end

-- 25% chance for displaying popup with random compliment and giving 25exp
function M.random_luck_popup()
  local lucky_message = logic.random_luck()
  if lucky_message then
    M.show_popup(lucky_message, 'Just fyi', 'top_right')
  end
end

return M
