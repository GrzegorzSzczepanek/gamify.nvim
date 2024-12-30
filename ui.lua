local M = {}
local logic = require 'gamify.logic'
local storage = require 'gamify.storage'
local utils = require 'gamify.utils'
local config = require 'gamify.config'

function M.show_status_window()
  local buffer = vim.api.nvim_create_buf(false, true)

  local data = logic.get_data()
  local all_achievements_len = utils.get_table_length(config.all_achievements)
  local user_achievements_len = utils.get_table_length(data.achievements)
  local lines = {
    '🎮 Gamify.nvim Status 🎮',
    '',
    'XP: ' .. data.xp,
    'Achievements: ' .. user_achievements_len .. '/' .. all_achievements_len,
    'Total lines written: ' .. data.lines_written,
    'Total errors fixed: ' .. data.errors_fixed,
    "You're on " .. data.day_streak .. ' day streak.',
  }

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
  local max_bar_length = 50
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
    width = 80,
    height = #ui_lines + 2,
    row = math.floor((vim.o.lines - (#ui_lines + 2)) / 2),
    col = math.floor((vim.o.columns - 80) / 2),
    border = 'rounded',
  }

  local window = vim.api.nvim_open_win(buffer, true, opts)

  vim.api.nvim_buf_set_keymap(buffer, 'n', '<Esc>', ':q<CR>', { noremap = true, silent = true })
  vim.api.nvim_buf_set_option(buffer, 'modifiable', false)
end

local function center_text(text, total_width)
  local text_len = vim.fn.strdisplaywidth(text)
  if text_len >= total_width then
    return text
  end
  local left_spaces = math.floor((total_width - text_len) / 2)
  local right_spaces = total_width - text_len - left_spaces
  return string.rep(' ', left_spaces) .. text .. string.rep(' ', right_spaces)
end

local function create_achievement_box(name, description, box_width)
  -- Ensure description and name are not nil to avoid formatting errors
  description = description or 'No description available'
  name = name or 'Unnamed Achievement'

  -- Corrected format string with two placeholders
  local content = string.format('%s : %s', name, description)
  content = center_text(content, box_width - 2) -- minus 2 for the box edges

  local top = '╭' .. string.rep('─', box_width - 2) .. '╮'
  local middle = '│' .. content .. '│'
  local bottom = '╰' .. string.rep('─', box_width - 2) .. '╯'

  return { top, middle, bottom }
end

function M.show_achievements()
  local data = storage.load_data()

  local max_len = 0
  if next(data.achievements) then
    for name, description in pairs(data.achievements) do
      local line = string.format('%s : %s', name, description)
      local display_len = vim.fn.strdisplaywidth(line)
      if display_len > max_len then
        max_len = display_len
      end
    end
  else
    max_len = #'None yet. Keep coding to unlock achievements!'
  end

  local box_width = max_len + 10

  local lines = {}

  local heading = '🏆🏆🏆   A C H I E V E M E N T S   🏆🏆🏆'
  heading = center_text(heading, box_width)
  table.insert(lines, heading)
  table.insert(lines, '')

  if next(data.achievements) then
    for name, description in pairs(data.achievements) do
      local box_lines = create_achievement_box(name, description, box_width)
      vim.list_extend(lines, box_lines)
      table.insert(lines, '')
    end
  else
    table.insert(lines, center_text('None yet. Keep coding to unlock achievements!', box_width))
    table.insert(lines, '')
  end

  table.insert(lines, center_text('Press Esc to close', box_width))

  local width = box_width + 8
  local height = #lines + 2
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  local buffer = vim.api.nvim_create_buf(false, true)
  local final_lines = {}
  local left_padding = math.floor((width - box_width) / 2)

  for _, line_text in ipairs(lines) do
    local indented_line = string.rep(' ', left_padding) .. line_text
    table.insert(final_lines, indented_line)
  end

  vim.api.nvim_buf_set_lines(buffer, 0, -1, false, final_lines)

  local win = vim.api.nvim_open_win(buffer, true, {
    style = 'minimal',
    relative = 'editor',
    width = width,
    height = height,
    row = row,
    col = col,
    border = 'rounded',
  })

  vim.cmd [[
    highlight AchievementTitle    gui=bold guifg=#FFD700
    highlight AchievementBorder   guifg=#FFD700
    highlight AchievementBoxBorder guifg=#FFD700
    highlight AchievementBoxText  guifg=#FFFFFF
  ]]

  vim.api.nvim_win_set_option(win, 'winhighlight', 'FloatBorder:AchievementBorder')

  vim.api.nvim_buf_add_highlight(buffer, -1, 'AchievementTitle', 0, left_padding, -1)

  local border_chars = { '╭', '╮', '╰', '╯', '─', '│' }
  for i, line_text in ipairs(final_lines) do
    if line_text:match '^[%s]*[╭╰│]' then
      local start_col = 0
      for col = 0, #line_text - 1 do
        local c = line_text:sub(col + 1, col + 1)
        if vim.tbl_contains(border_chars, c) then
          vim.api.nvim_buf_add_highlight(buffer, -1, 'AchievementBoxBorder', i - 1, col, col + 1)
        elseif c ~= ' ' then
          vim.api.nvim_buf_add_highlight(buffer, -1, 'AchievementBoxText', i - 1, col, col + 1)
        end
      end
    end
  end

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

function M.show_achievement_popup(name)
  local description = storage.load_data().achievements[name]
  if description then
    M.show_popup('Achievement Unlocked: ' .. name .. '\n' .. description, 'top_right')
  end
end

return M
