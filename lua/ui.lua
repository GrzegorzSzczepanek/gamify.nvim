local M = {}
local logic = require 'gamify.logic'
local storage = require 'gamify.storage'
local utils = require 'gamify.utils'

local function center_text(text, width)
  local padding = math.floor((width - #text) / 2)
  return string.rep(' ', math.max(padding, 0)) .. text
end

function M.show_status_window(all_achievements_len)
  local buffer = vim.api.nvim_create_buf(false, true)

  local data = storage.load_data()
  local total_time = data.total_time or 0

  local days = math.floor(total_time / 24)
  local hours = math.floor(total_time % 24)
  local minutes = math.floor((total_time - math.floor(total_time)) * 60)
  local time_message = string.format('You have spent %d days, %d hours, and %d minutes in Neovim!', days, hours, minutes)

  local user_achievements_len = utils.get_table_length(data.achievements)

  local ui_width = 70

  local lines = {
    center_text('   ____                 _  __       ', ui_width),
    center_text('  / ___| __ _ _ __ ___ (_)/ _|_   _ ', ui_width),
    center_text(" | |  _ / _` | '_ ` _ \\| | |_| | | |", ui_width),
    center_text(' | |_| | (_| | | | | | | |  _| |_| |', ui_width),
    center_text('  \\____|\\__,_|_| |_| |_|_|_|  \\__, |', ui_width),
    center_text('                              |___/ ', ui_width),
    '',
    center_text('🎮 Gamify.nvim Status 🎮', ui_width),
    '',
    center_text('XP: ' .. data.xp, ui_width),
    center_text('Level: ' .. data.level, ui_width),
    center_text('Achievements: ' .. user_achievements_len .. '/' .. all_achievements_len, ui_width),
    center_text('Total lines written: ' .. data.lines_written, ui_width),
    center_text('You made : ' .. #data.commit_hashes .. ' commits to git!', ui_width),
    '',
    center_text(time_message, ui_width),
    '',
    center_text("You're on a " .. data.day_streak .. ' day streak.', ui_width),
    '',
    center_text('Press esc key to close.', ui_width),
  }

  local opts = {
    style = 'minimal',
    relative = 'editor',
    width = ui_width,
    height = #lines + 2,
    row = math.floor((vim.o.lines - (#lines + 2)) / 2),
    col = math.floor((vim.o.columns - ui_width) / 2),
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

  local text_lines = vim.split(text, '\n')

  local lines = { '🟢 [' .. title .. ']' }
  vim.list_extend(lines, text_lines)
  -- table.insert(lines, 'Press any key to dismiss')

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
  end, 5000)
end

function M.show_languages_ui()
  local data = logic.get_data()
  local lines_per_lang = data.lines_written_in_specified_langs or {}

  local lang_lines = {}
  for lang, lines in pairs(lines_per_lang) do
    if lang ~= 'Unknown' and lines > 0 then
      table.insert(lang_lines, { lang = lang, lines = lines })
    end
  end

  table.sort(lang_lines, function(a, b)
    return a.lines > b.lines
  end)

  local ui_width = 100
  local max_bar_length = ui_width - 35
  local max_lines = lang_lines[1] and lang_lines[1].lines or 1

  local max_lang_length = 0
  for _, lang_data in ipairs(lang_lines) do
    max_lang_length = math.max(max_lang_length, #lang_data.lang)
  end

  local ui_lines = {
    center_text('📊 Most Used Languages 📊', ui_width),
    '',
  }

  for _, lang_data in ipairs(lang_lines) do
    local bar_length = math.floor((lang_data.lines / max_lines) * max_bar_length)
    local bar = string.rep('█', bar_length)
    local line_text = string.format('%-' .. max_lang_length .. 's | %s ~ %d lines', lang_data.lang, bar, lang_data.lines)
    table.insert(ui_lines, line_text)
  end

  if #lang_lines == 0 then
    table.insert(ui_lines, center_text('No data available.', ui_width))
  end

  table.insert(ui_lines, '')
  table.insert(ui_lines, center_text('Press esc key to close.', ui_width))

  local buffer = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buffer, 0, -1, false, ui_lines)

  local opts = {
    style = 'minimal',
    relative = 'editor',
    width = ui_width,
    height = #ui_lines + 2,
    row = math.floor((vim.o.lines - (#ui_lines + 2)) / 2),
    col = math.floor((vim.o.columns - ui_width) / 2),
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
  description = description or 'No description available'
  name = name or 'Unnamed Achievement'

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

function M.random_luck_popup()
  local lucky_message = logic.random_luck()
  if lucky_message then
    M.show_popup(lucky_message, 'Just fyi', 'top_right')
  end
end

function M.show_falling_confetti(count, duration_ms)
  local confetti_chars = {
    '✽',
    '✸',
    '✹',
    '*',
    '~',
    '❈',
    '♨',
    '⚬',
    '○',
    '☆',
    '♥',
    '♦',
    '⚛',
    '✧',
    '✦',
  }

  local confetti = {}
  local screen_height = vim.o.lines
  local screen_width = vim.o.columns

  local timer = vim.loop.new_timer()

  local function create_particle()
    local col = math.random(math.floor(screen_width * 0.7), screen_width - 2)
    local row = 1

    local char = confetti_chars[math.random(#confetti_chars)]
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, { char })

    local highlight_group = 'String' -- or define your own highlight
    vim.api.nvim_buf_add_highlight(buf, -1, highlight_group, 0, 0, -1)

    local win_opts = {
      style = 'minimal',
      relative = 'editor',
      width = 2,
      height = 1,
      row = row,
      col = col,
      focusable = false,
      zindex = 300,
    }
    local win = vim.api.nvim_open_win(buf, false, win_opts)

    return {
      buf = buf,
      win = win,
      row = row,
      col = col,
      -- random vertical speed (pixels/step)
      vrow = 0.3 + math.random() * 0.3,
      -- random horizontal drift
      vcol = (math.random() - 0.5) * 0.5,
    }
  end

  -- create multiple pieces
  for _ = 1, count do
    table.insert(confetti, create_particle())
  end

  local start_time = vim.loop.now()

  local function animate()
    vim.schedule(function()
      local now = vim.loop.now()
      local elapsed = now - start_time

      if elapsed > duration_ms then
        for _, c in ipairs(confetti) do
          if vim.api.nvim_win_is_valid(c.win) then
            vim.api.nvim_win_close(c.win, true)
          end
        end
        if not timer:is_closing() then
          timer:stop()
          timer:close()
        end
        return
      end

      for _, c in ipairs(confetti) do
        if vim.api.nvim_win_is_valid(c.win) then
          c.row = c.row + c.vrow
          c.col = c.col + c.vcol

          -- if piece goes below the screen, close it
          if c.row >= (screen_height - 2) then
            vim.api.nvim_win_close(c.win, true)
          else
            -- otherwise update position
            vim.api.nvim_win_set_config(c.win, {
              relative = 'editor',
              row = math.floor(c.row),
              col = math.floor(c.col),
            })
          end
        end
      end
    end)
  end

  timer:start(0, 80, vim.schedule_wrap(animate))
end

function M.show_special_popup(name)
  local data = require('gamify.storage').load_data()
  local description = data.achievements[name]
  if description then
    M.show_popup('Achievement Unlocked: ' .. name .. '\n' .. description, 'Achievement', 'top_right')

    M.show_falling_confetti(20, 2000)
  end
end

return M
