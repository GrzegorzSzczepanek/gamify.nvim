local M = {}
local logic = require 'gamify.logic'
local storage = require 'gamify.storage'
local utils = require 'gamify.utils'

function M.show_xp_popup(amount)
  local bufnr = vim.api.nvim_get_current_buf()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local line = cursor[1] - 1
  
  local ns_id = vim.api.nvim_create_namespace('gamify_xp')
  local opts = {
    virt_text = {{ "+" .. amount .. " XP", "String" }},
    virt_text_pos = 'eol',
  }
  
  local id = vim.api.nvim_buf_set_extmark(bufnr, ns_id, line, 0, opts)
  
  vim.defer_fn(function()
    if vim.api.nvim_buf_is_valid(bufnr) then
      vim.api.nvim_buf_del_extmark(bufnr, ns_id, id)
    end
  end, 1000)
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
M.center_text = center_text

function M.show_status_window(all_achievements_len)
  local buffer = vim.api.nvim_create_buf(false, true)

  local data = storage.load_data()
  local total_time = data.total_time or 0

  local days = math.floor(total_time / 24)
  local hours = math.floor(total_time % 24)
  local minutes = math.floor((total_time - math.floor(total_time)) * 60)
  local time_message = string.format('You have spent %d days, %d hours, and %d minutes in Neovim!', days, hours, minutes)

  local user_achievements_len = utils.get_table_length(data.achievements)

  local ui_width = 80

  local xp = data.xp or 0
  local level = data.level or 1

  local current_level_xp = logic.xp_for_level(level)
  local next_level_xp = logic.xp_for_level(level + 1)
  local progress = next_level_xp > current_level_xp and (xp - current_level_xp) / (next_level_xp - current_level_xp) or 0
  progress = math.max(0, math.min(1, progress))

  local bar_width = 50
  local filled_width = math.floor(progress * bar_width)
  local bar = string.rep('█', filled_width) .. string.rep('░', bar_width - filled_width)
  local progress_text = string.format('Progress: %s %.1f%%', bar, progress * 100)

  local role = logic.get_role()
  local prestige = data.prestige or 0
  local level_label = 'Level: ' .. level
  if prestige > 0 then
    level_label = level_label .. ('  ✪'):rep(1) .. ' Prestige ' .. prestige
  end

  -- Fixed-width banner: pad every line to the same length and center the whole
  -- block with one shared pad, so the figure never breaks apart across lines.
  local banner = {
    '  ____                  _  __        ',
    " / ___|  __ _ _ __ ___ (_)/ _|_   _  ",
    "| |  _  / _` | '_ ` _ \\| | |_| | | | ",
    '| |_| || (_| | | | | | | |  _| |_| | ',
    ' \\____| \\__,_|_| |_| |_|_|_|  \\__, | ',
    '                              |___/  ',
  }
  local banner_pad = string.rep(' ', math.max(0, math.floor((ui_width - #banner[1]) / 2)))

  local lines = {
    banner_pad .. banner[1],
    banner_pad .. banner[2],
    banner_pad .. banner[3],
    banner_pad .. banner[4],
    banner_pad .. banner[5],
    banner_pad .. banner[6],
    '',
    center_text('🎮 Gamify.nvim Dashboard 🎮', ui_width),
    '',
    center_text('Role: ' .. role, ui_width),
    center_text(level_label, ui_width),
    center_text('XP: ' .. math.floor(xp) .. ' / ' .. math.floor(next_level_xp), ui_width),
    center_text(progress_text, ui_width),
    center_text(require('gamify.focus').status_text(), ui_width),
    '',
    center_text('─── Statistics ───', ui_width),
    center_text('Achievements: ' .. user_achievements_len .. '/' .. all_achievements_len, ui_width),
    center_text('Total lines: ' .. data.lines_written, ui_width),
    center_text('Git commits: ' .. #data.commit_hashes, ui_width),
    center_text('Streak: ' .. data.day_streak .. ' days 🔥', ui_width),
  }

  local nxt = require('gamify.achievements').next_progress()
  if nxt then
    local nb_width = 24
    local nf = math.floor((nxt.percent / 100) * nb_width)
    local nbar = string.rep('█', nf) .. string.rep('░', nb_width - nf)
    table.insert(lines, center_text(string.format('Next: %s  %s %d/%d', nxt.name, nbar, nxt.current, nxt.target), ui_width))
  end

  vim.list_extend(lines, {
    '',
    center_text('─── High Scores ───', ui_width),
    center_text(string.format('Snake: %d pts | Saper: %s | Sudoku: %s',
      data.high_scores.snake or 0,
      data.high_scores.saper and (data.high_scores.saper .. "s") or "N/A",
      data.high_scores.sudoku and (data.high_scores.sudoku .. "s") or "N/A"
    ), ui_width),
    '',
    center_text('─── Daily Quests ───', ui_width),
  })

  local quests = require('gamify.quests').get_active()
  if #quests == 0 then
    table.insert(lines, center_text('No active quests today.', ui_width))
  else
    for _, q in ipairs(quests) do
      local mark = q.done and '✅' or '⬜'
      table.insert(lines, center_text(string.format('%s %s  (%d/%d, +%d XP)', mark, q.description, q.progress, q.target, q.xp), ui_width))
    end
  end

  vim.list_extend(lines, {
    '',
    center_text('─── Menu ───', ui_width),
    center_text('(a) Achievements  (s) Lang Stats  (c) Challenges  (h) Heatmap  (p) Share', ui_width),
    center_text('(g) Snake  (m) Saper  (u) Sudoku  (t) Gomoku  (q) Quit', ui_width),
  })

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

  -- Helper to close dashboard and run action
  local function action(callback)
    return function()
      if vim.api.nvim_win_is_valid(window) then
        vim.api.nvim_win_close(window, true)
      end
      callback()
    end
  end

  vim.keymap.set('n', 'a', action(function() M.show_achievements() end), { buffer = buffer })
  vim.keymap.set('n', 's', action(function() M.show_languages_ui() end), { buffer = buffer })
  vim.keymap.set('n', 'c', action(function() require('gamify.challenges').show_challenges_menu() end), { buffer = buffer })
  vim.keymap.set('n', 'h', action(function() M.show_heatmap() end), { buffer = buffer })
  vim.keymap.set('n', 'p', action(function() M.show_share_card() end), { buffer = buffer })
  vim.keymap.set('n', 'g', action(function() require('gamify.games').start_snake() end), { buffer = buffer })
  vim.keymap.set('n', 'm', action(function() require('gamify.games').start_minesweeper() end), { buffer = buffer })
  vim.keymap.set('n', 'u', action(function() require('gamify.games').start_sudoku() end), { buffer = buffer })
  vim.keymap.set('n', 't', action(function() require('gamify.gomoku').start_local() end), { buffer = buffer })
  vim.keymap.set('n', 'q', action(function() end), { buffer = buffer })
  vim.keymap.set('n', '<Esc>', action(function() end), { buffer = buffer })

  vim.api.nvim_buf_set_option(buffer, 'modifiable', false)
end

local function wrap_text(text, max_width)
  local lines = {}
  for _, line in ipairs(vim.split(text, '\n')) do
    local current_line = ''
    for word in line:gmatch '%S+' do
      if #current_line + #word + 1 <= max_width then
        if current_line == '' then
          current_line = word
        else
          current_line = current_line .. ' ' .. word
        end
      else
        table.insert(lines, current_line)
        current_line = word
      end
    end
    table.insert(lines, current_line)
  end
  return lines
end

function M.show_popup(text, title, corner)
  local width = math.min(50, vim.o.columns - 4)
  local text_lines = wrap_text(text, width - 2)
  local height = #text_lines + 1
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

  local lines = { '🟢 [' .. title .. ']' }
  vim.list_extend(lines, text_lines)

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
  table.insert(ui_lines, center_text('Press (b) to go back | (q) to close.', ui_width))

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

  vim.keymap.set('n', 'b', function()
    vim.api.nvim_win_close(window, true)
    M.show_status_window(require('gamify.achievements').get_achievements_table_length())
  end, { buffer = buffer })

  vim.api.nvim_buf_set_keymap(buffer, 'n', '<Esc>', ':q<CR>', { noremap = true, silent = true })
  vim.api.nvim_buf_set_keymap(buffer, 'n', 'q', ':q<CR>', { noremap = true, silent = true })
  vim.api.nvim_buf_set_option(buffer, 'modifiable', false)
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

  table.insert(lines, center_text('Press (b) to go back | (q) to close', box_width))

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

  vim.keymap.set('n', 'b', function()
    vim.api.nvim_win_close(win, true)
    M.show_status_window(require('gamify.achievements').get_achievements_table_length())
  end, { buffer = buffer })

  vim.api.nvim_buf_set_keymap(buffer, 'n', '<Esc>', ':q<CR>', { noremap = true, silent = true })
  vim.api.nvim_buf_set_keymap(buffer, 'n', 'q', ':q<CR>', { noremap = true, silent = true })
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

local function open_simple_float(lines, width)
  local height = math.min(#lines + 2, vim.o.lines - 4)
  local buffer = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buffer, 0, -1, false, lines)

  local win = vim.api.nvim_open_win(buffer, true, {
    style = 'minimal',
    relative = 'editor',
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    border = 'rounded',
  })

  vim.keymap.set('n', 'b', function()
    vim.api.nvim_win_close(win, true)
    M.show_status_window(require('gamify.achievements').get_achievements_table_length())
  end, { buffer = buffer })
  vim.api.nvim_buf_set_keymap(buffer, 'n', '<Esc>', ':q<CR>', { noremap = true, silent = true })
  vim.api.nvim_buf_set_keymap(buffer, 'n', 'q', ':q<CR>', { noremap = true, silent = true })
  vim.api.nvim_buf_set_option(buffer, 'modifiable', false)
  return buffer, win
end

function M.show_heatmap()
  local data = storage.load_data()
  local daily = data.daily_xp or {}

  local levels = { '·', '░', '▒', '▓', '█' }
  local function cell(xp)
    if xp <= 0 then return levels[1] end
    if xp < 50 then return levels[2] end
    if xp < 150 then return levels[3] end
    if xp < 400 then return levels[4] end
    return levels[5]
  end

  local weeks = 26
  local today_secs = os.time()
  -- align to the most recent Sunday so each column is one week
  local wday = tonumber(os.date('%w', today_secs))
  local grid = {} -- grid[row=0..6][col]
  for r = 0, 6 do grid[r] = {} end

  local total_days = weeks * 7
  local start_secs = today_secs - (total_days - 1 - wday) * 86400
  for i = 0, total_days - 1 do
    local day_secs = start_secs + i * 86400
    if day_secs <= today_secs then
      local key = os.date('%Y-%m-%d', day_secs)
      local col = math.floor(i / 7)
      local row = tonumber(os.date('%w', day_secs))
      grid[row][col + 1] = cell(daily[key] or 0)
    end
  end

  local lines = {
    center_text('📅 Activity Heatmap (last 26 weeks)', weeks + 8),
    '',
  }
  local day_labels = { [1] = 'Mon', [3] = 'Wed', [5] = 'Fri' }
  for r = 0, 6 do
    local row_str = (day_labels[r] or '   ') .. ' '
    for c = 1, weeks do
      row_str = row_str .. (grid[r][c] or ' ')
    end
    table.insert(lines, row_str)
  end
  table.insert(lines, '')
  table.insert(lines, '    Less ' .. table.concat(levels, ' ') .. ' More')
  table.insert(lines, '')

  local active_days, total_xp = 0, 0
  for _, v in pairs(daily) do
    if v > 0 then active_days = active_days + 1 end
    total_xp = total_xp + v
  end
  table.insert(lines, string.format('    Active days: %d   |   Lifetime XP logged: %d', active_days, total_xp))
  table.insert(lines, '')
  table.insert(lines, center_text('Press (b) to go back | (q) to close', weeks + 8))

  open_simple_float(lines, weeks + 12)
end

function M.show_share_card()
  local data = storage.load_data()
  local role = logic.get_role()
  local lvl = data.level or 1
  local prestige = data.prestige or 0
  local achievements_n = utils.get_table_length(data.achievements)
  local total_achievements = require('gamify.achievements').get_achievements_table_length()

  local langs = {}
  for lang, n in pairs(data.lines_written_in_specified_langs or {}) do
    if lang ~= 'Unknown' and n > 0 then
      table.insert(langs, { lang = lang, n = n })
    end
  end
  table.sort(langs, function(a, b) return a.n > b.n end)
  local top = {}
  for i = 1, math.min(3, #langs) do
    table.insert(top, langs[i].lang)
  end
  local top_str = #top > 0 and table.concat(top, ', ') or 'none yet'

  local prestige_str = prestige > 0 and (' ✪' .. prestige) or ''
  local W = 46
  local function row(text)
    local pad = W - 2 - vim.fn.strdisplaywidth(text)
    if pad < 0 then pad = 0 end
    return '┃ ' .. text .. string.rep(' ', pad) .. '┃'
  end

  local card = {
    '┏' .. string.rep('━', W - 1) .. '┓',
    row('🎮 GAMIFY.NVIM CHARACTER CARD'),
    '┣' .. string.rep('━', W - 1) .. '┫',
    row('Role:    ' .. role .. prestige_str),
    row('Level:   ' .. lvl .. '   XP: ' .. math.floor(data.xp or 0)),
    row('Streak:  ' .. (data.day_streak or 1) .. ' days'),
    row('Lines:   ' .. (data.lines_written or 0)),
    row('Commits: ' .. #(data.commit_hashes or {})),
    row('Top:     ' .. top_str),
    row('Trophies:' .. ' ' .. achievements_n .. '/' .. total_achievements),
    '┗' .. string.rep('━', W - 1) .. '┛',
  }

  local lines = { center_text('🪪 Share Card', W + 6), '' }
  vim.list_extend(lines, card)
  table.insert(lines, '')
  table.insert(lines, center_text('(y) yank to clipboard | (b) back | (q) close', W + 6))

  local buffer, win = open_simple_float(lines, W + 6)
  vim.keymap.set('n', 'y', function()
    vim.fn.setreg('+', table.concat(card, '\n'))
    vim.notify('Character card copied to clipboard!', vim.log.levels.INFO, { title = 'Gamify' })
  end, { buffer = buffer })
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
