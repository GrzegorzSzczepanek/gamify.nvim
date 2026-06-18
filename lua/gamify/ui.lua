local M = {}
local logic = require 'gamify.logic'
local storage = require 'gamify.storage'
local utils = require 'gamify.utils'

function M.show_xp_popup(amount)
  local bufnr = vim.api.nvim_get_current_buf()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local line = cursor[1] - 1

  local ns_id = vim.api.nvim_create_namespace 'gamify_xp'
  local opts = {
    virt_text = { { '+' .. amount .. ' XP', 'String' } },
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
  local time_message =
    string.format('You have spent %d days, %d hours, and %d minutes in Neovim!', days, hours, minutes)

  local user_achievements_len = utils.get_table_length(data.achievements)

  local ui_width = 80

  local xp = data.xp or 0
  local level = data.level or 1

  local current_level_xp = logic.xp_for_level(level)
  local next_level_xp = logic.xp_for_level(level + 1)
  local progress = next_level_xp > current_level_xp and (xp - current_level_xp) / (next_level_xp - current_level_xp)
    or 0
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
    ' / ___|  __ _ _ __ ___ (_)/ _|_   _  ',
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
    table.insert(
      lines,
      center_text(string.format('Next: %s  %s %d/%d', nxt.name, nbar, nxt.current, nxt.target), ui_width)
    )
  end

  vim.list_extend(lines, {
    '',
    center_text('─── High Scores ───', ui_width),
    center_text(
      string.format(
        'Snake: %d pts | Saper: %s | Sudoku: %s',
        data.high_scores.snake or 0,
        data.high_scores.saper and (data.high_scores.saper .. 's') or 'N/A',
        data.high_scores.sudoku and (data.high_scores.sudoku .. 's') or 'N/A'
      ),
      ui_width
    ),
    '',
    center_text('─── Daily Quests ───', ui_width),
  })

  local quests = require('gamify.quests').get_active()
  if #quests == 0 then
    table.insert(lines, center_text('No active quests today.', ui_width))
  else
    for _, q in ipairs(quests) do
      local mark = q.done and '✅' or '⬜'
      table.insert(
        lines,
        center_text(string.format('%s %s  (%d/%d, +%d XP)', mark, q.description, q.progress, q.target, q.xp), ui_width)
      )
    end
  end

  vim.list_extend(lines, {
    '',
    center_text('─── Menu ───', ui_width),
    center_text('(a) Achievements  (s) Lang Stats  (c) Challenges  (h) Heatmap  (p) Share', ui_width),
    center_text('(g) Snake  (m) Saper  (u) Sudoku  (t) Gomoku  (v) Avatar  (q) Quit', ui_width),
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

  vim.keymap.set(
    'n',
    'a',
    action(function()
      M.show_achievements()
    end),
    { buffer = buffer }
  )
  vim.keymap.set(
    'n',
    's',
    action(function()
      M.show_languages_ui()
    end),
    { buffer = buffer }
  )
  vim.keymap.set(
    'n',
    'c',
    action(function()
      require('gamify.challenges').show_challenges_menu()
    end),
    { buffer = buffer }
  )
  vim.keymap.set(
    'n',
    'h',
    action(function()
      M.show_heatmap()
    end),
    { buffer = buffer }
  )
  vim.keymap.set(
    'n',
    'p',
    action(function()
      M.show_share_card()
    end),
    { buffer = buffer }
  )
  vim.keymap.set(
    'n',
    'g',
    action(function()
      require('gamify.games').start_snake()
    end),
    { buffer = buffer }
  )
  vim.keymap.set(
    'n',
    'm',
    action(function()
      require('gamify.games').start_minesweeper()
    end),
    { buffer = buffer }
  )
  vim.keymap.set(
    'n',
    'u',
    action(function()
      require('gamify.games').start_sudoku()
    end),
    { buffer = buffer }
  )
  vim.keymap.set(
    'n',
    't',
    action(function()
      require('gamify.gomoku').start_local()
    end),
    { buffer = buffer }
  )
  vim.keymap.set(
    'n',
    'v',
    action(function()
      require('gamify.avatar').open_generator()
    end),
    { buffer = buffer }
  )
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

-- A small palette so each language bar gets its own color.
local LANG_COLORS = {
  '#39d353',
  '#58a6ff',
  '#f778ba',
  '#e3b341',
  '#ff7b72',
  '#a371f7',
  '#56d4dd',
  '#ffa657',
  '#7ee787',
  '#d2a8ff',
}

function M.show_languages_ui()
  local data = logic.get_data()
  local lines_per_lang = data.lines_written_in_specified_langs or {}

  local langs = {}
  local total = 0
  for lang, lines in pairs(lines_per_lang) do
    if lang ~= 'Unknown' and lines > 0 then
      table.insert(langs, { lang = lang, lines = lines })
      total = total + lines
    end
  end
  table.sort(langs, function(a, b)
    return a.lines > b.lines
  end)

  local ui_width = 72
  local name_w = 12
  for _, l in ipairs(langs) do
    name_w = math.max(name_w, #l.lang)
  end
  name_w = math.min(name_w, 16)
  local bar_w = ui_width - name_w - 22
  local max_lines = langs[1] and langs[1].lines or 1

  -- define one highlight per palette slot + ensure highlights survive themes
  local function ensure_lang_hl()
    local cmds = {}
    for i, c in ipairs(LANG_COLORS) do
      cmds[#cmds + 1] = string.format('highlight default GamifyLangBar%d guifg=%s', i, c)
    end
    cmds[#cmds + 1] = 'highlight default GamifyLangTitle gui=bold guifg=#58a6ff'
    cmds[#cmds + 1] = 'highlight default GamifyLangTrack guifg=#30363d'
    vim.cmd(table.concat(cmds, '\n'))
  end
  ensure_lang_hl()

  local medals = { '🥇', '🥈', '🥉' }
  local lines = {}
  local marks = {} -- { line0, col0, col1, group }

  table.insert(lines, center_text('📊  Most Used Languages  📊', ui_width))
  marks[#marks + 1] = { #lines - 1, 0, -1, 'GamifyLangTitle' }
  table.insert(lines, center_text(string.format('%d lines across %d languages', total, #langs), ui_width))
  marks[#marks + 1] = { #lines - 1, 0, -1, 'Comment' }
  table.insert(lines, '')

  if #langs == 0 then
    table.insert(lines, center_text('No data available yet — start coding!', ui_width))
  end

  for i, l in ipairs(langs) do
    local filled = math.max(1, math.floor((l.lines / max_lines) * bar_w))
    local pct = total > 0 and (l.lines / total * 100) or 0
    local medal = medals[i] or '  '
    local name = l.lang
    if #name > name_w then
      name = name:sub(1, name_w - 1) .. '…'
    end

    local prefix = string.format('%s %-' .. name_w .. 's ', medal, name)
    local bar = string.rep('█', filled)
    local track = string.rep('░', bar_w - filled)
    local suffix = string.format(' %5d  %4.1f%%', l.lines, pct)
    table.insert(lines, prefix .. bar .. track .. suffix)

    local line0 = #lines - 1
    local bar_start = #prefix
    local color = 'GamifyLangBar' .. (((i - 1) % #LANG_COLORS) + 1)
    marks[#marks + 1] = { line0, bar_start, bar_start + #bar, color }
    marks[#marks + 1] = { line0, bar_start + #bar, bar_start + #bar + #track, 'GamifyLangTrack' }
  end

  table.insert(lines, '')
  table.insert(lines, center_text('Press (b) to go back | (q) to close', ui_width))
  marks[#marks + 1] = { #lines - 1, 0, -1, 'Comment' }

  local height = #lines + 2
  local buffer = vim.api.nvim_create_buf(false, true)
  local window = vim.api.nvim_open_win(buffer, true, {
    style = 'minimal',
    relative = 'editor',
    width = ui_width,
    height = height,
    row = math.floor((vim.o.lines - height) / 2),
    col = math.floor((vim.o.columns - ui_width) / 2),
    border = 'rounded',
    title = ' Language Stats ',
    title_pos = 'center',
  })
  vim.api.nvim_win_set_option(window, 'winhighlight', 'FloatBorder:GamifyLangTitle')
  vim.api.nvim_buf_set_lines(buffer, 0, -1, false, lines)

  local ns = vim.api.nvim_create_namespace 'gamify_lang'
  for _, m in ipairs(marks) do
    vim.api.nvim_buf_add_highlight(buffer, ns, m[4], m[1], m[2], m[3])
  end

  vim.keymap.set('n', 'b', function()
    vim.api.nvim_win_close(window, true)
    M.show_status_window(require('gamify.achievements').get_achievements_table_length())
  end, { buffer = buffer })
  vim.api.nvim_buf_set_keymap(buffer, 'n', '<Esc>', ':q<CR>', { noremap = true, silent = true })
  vim.api.nvim_buf_set_keymap(buffer, 'n', 'q', ':q<CR>', { noremap = true, silent = true })
  vim.api.nvim_buf_set_option(buffer, 'modifiable', false)
end

local ACH_PER_PAGE = 8

-- Achievements: a clean card list showing BOTH unlocked and locked achievements,
-- paginated. Unlocked rows glow gold; locked rows are dimmed with a 🔒.
function M.show_achievements()
  local data = storage.load_data()
  local defs = require('gamify.achievements').definitions
  local unlocked = data.achievements or {}

  -- Build a unified list: unlocked first (by name), then locked.
  local items = {}
  for _, def in ipairs(defs) do
    items[#items + 1] = {
      name = def.name,
      desc = def.description or '',
      xp = def.xp or 0,
      done = unlocked[def.name] ~= nil,
    }
  end
  table.sort(items, function(a, b)
    if a.done ~= b.done then
      return a.done -- unlocked first
    end
    return a.name < b.name
  end)

  local got = 0
  for _, it in ipairs(items) do
    if it.done then
      got = got + 1
    end
  end

  local ui_width = 64
  local inner = ui_width - 6 -- text area inside the card padding
  local total_pages = math.max(1, math.ceil(#items / ACH_PER_PAGE))

  local hl = {} -- { line0, group } applied after the buffer is built

  local function render_page(page)
    local lines = {}
    local function add(s, group)
      lines[#lines + 1] = s
      if group then
        hl[#hl + 1] = { #lines - 1, group }
      end
    end

    add(center_text('🏆  A C H I E V E M E N T S  🏆', ui_width), 'GamifyAchTitle')
    add(center_text(string.format('Unlocked %d / %d', got, #items), ui_width), 'Comment')
    add ''

    local start_i = (page - 1) * ACH_PER_PAGE + 1
    local end_i = math.min(#items, start_i + ACH_PER_PAGE - 1)
    for i = start_i, end_i do
      local it = items[i]
      local icon = it.done and '✓ ' or '🔒'
      local name = it.name
      if vim.fn.strdisplaywidth(name) > inner - 14 then
        name = name:sub(1, inner - 17) .. '…'
      end
      local xp_tag = string.format('+%d XP', it.xp)
      local pad = inner
        - vim.fn.strdisplaywidth(icon)
        - 1
        - vim.fn.strdisplaywidth(name)
        - vim.fn.strdisplaywidth(xp_tag)
      pad = math.max(1, pad)
      local title_row = '  ' .. icon .. ' ' .. name .. string.rep(' ', pad) .. xp_tag
      add(title_row, it.done and 'GamifyAchDone' or 'GamifyAchLocked')

      local desc = it.desc
      if vim.fn.strdisplaywidth(desc) > inner - 4 then
        desc = desc:sub(1, inner - 7) .. '…'
      end
      add('      ' .. desc, it.done and 'GamifyAchDesc' or 'GamifyAchLocked')
    end

    add ''
    add(
      center_text(string.format('Page %d/%d   (h/l) page   (b) back   (q) close', page, total_pages), ui_width),
      'Comment'
    )
    return lines
  end

  local height = ACH_PER_PAGE * 2 + 6
  local buffer = vim.api.nvim_create_buf(false, true)
  local win = vim.api.nvim_open_win(buffer, true, {
    style = 'minimal',
    relative = 'editor',
    width = ui_width,
    height = height,
    row = math.floor((vim.o.lines - height) / 2),
    col = math.floor((vim.o.columns - ui_width) / 2),
    border = 'rounded',
    title = ' Achievements ',
    title_pos = 'center',
  })

  vim.cmd [[
    highlight default GamifyAchTitle  gui=bold guifg=#FFD700
    highlight default GamifyAchDone   gui=bold guifg=#39d353
    highlight default GamifyAchDesc   guifg=#9aa5b1
    highlight default GamifyAchLocked guifg=#5a6270
  ]]
  vim.api.nvim_win_set_option(win, 'winhighlight', 'FloatBorder:GamifyAchTitle')

  local page = 1
  local function draw()
    hl = {}
    local lines = render_page(page)
    vim.api.nvim_buf_set_option(buffer, 'modifiable', true)
    vim.api.nvim_buf_set_lines(buffer, 0, -1, false, lines)
    local ns = vim.api.nvim_create_namespace 'gamify_ach'
    vim.api.nvim_buf_clear_namespace(buffer, ns, 0, -1)
    for _, h in ipairs(hl) do
      vim.api.nvim_buf_add_highlight(buffer, ns, h[2], h[1], 0, -1)
    end
    vim.api.nvim_buf_set_option(buffer, 'modifiable', false)
  end
  draw()

  local function map(lhs, fn)
    vim.keymap.set('n', lhs, fn, { buffer = buffer, nowait = true })
  end
  map('l', function()
    page = page % total_pages + 1
    draw()
  end)
  map('<Right>', function()
    page = page % total_pages + 1
    draw()
  end)
  map('h', function()
    page = (page - 2) % total_pages + 1
    draw()
  end)
  map('<Left>', function()
    page = (page - 2) % total_pages + 1
    draw()
  end)
  map('b', function()
    vim.api.nvim_win_close(win, true)
    M.show_status_window(require('gamify.achievements').get_achievements_table_length())
  end)
  map('q', function()
    vim.api.nvim_win_close(win, true)
  end)
  map('<Esc>', function()
    vim.api.nvim_win_close(win, true)
  end)
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

  -- GitHub-style 5-step green ramp. index 0 == empty.
  local ramp = { '#2d333b', '#0e4429', '#006d32', '#26a641', '#39d353' }
  -- Thresholds tuned so a day where you merely opened Neovim (a few dozen XP)
  -- reads as faint, not as a bright "very active" cell.
  local function level_of(xp)
    if xp <= 0 then
      return 0
    end
    if xp < 100 then
      return 1
    end
    if xp < 300 then
      return 2
    end
    if xp < 700 then
      return 3
    end
    return 4
  end

  local weeks = 26
  local today_secs = os.time()
  -- align so the rightmost column ends on today; each column is one Sun..Sat week
  local wday = tonumber(os.date('%w', today_secs))
  local grid = {} -- grid[row=0..6][col] = level (0..4) or nil for future
  local key_grid = {} -- grid of YYYY-MM-DD keys for the col->month label pass
  for r = 0, 6 do
    grid[r] = {}
    key_grid[r] = {}
  end

  local total_days = weeks * 7
  local start_secs = today_secs - (total_days - 1 - wday) * 86400
  for i = 0, total_days - 1 do
    local day_secs = start_secs + i * 86400
    local col = math.floor(i / 7) + 1
    local row = tonumber(os.date('%w', day_secs))
    if day_secs <= today_secs then
      local key = os.date('%Y-%m-%d', day_secs)
      grid[row][col] = level_of(daily[key] or 0)
      key_grid[row][col] = key
    end
  end

  -- layout geometry
  local label_w = 4 -- "Mon " gutter
  local glyph = '■'
  local cell_w = 2 -- glyph + trailing space
  local left_pad = '    '
  local board_w = label_w + weeks * cell_w
  local ui_width = math.max(board_w, 44) + #left_pad

  -- highlight groups: one per ramp step
  local hl_cmds = {}
  for lvl, color in ipairs(ramp) do
    table.insert(hl_cmds, string.format('highlight GamifyHeat%d guifg=%s', lvl - 1, color))
  end
  vim.cmd(table.concat(hl_cmds, '\n'))

  -- month label row: place each month's name at the column where it first appears,
  -- writing into a fixed-width char buffer so labels stay aligned with the grid.
  local names = { 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec' }
  local month_buf = {}
  for i = 1, #left_pad + label_w + weeks * cell_w do
    month_buf[i] = ' '
  end
  local last_month, last_label_end = nil, 0
  for c = 1, weeks do
    local key = key_grid[0][c] or key_grid[1][c] or key_grid[2][c]
    if key then
      local m = key:sub(6, 7)
      if m ~= last_month then
        last_month = m
        local name = names[tonumber(m)]
        local at = #left_pad + label_w + (c - 1) * cell_w + 1
        if at > last_label_end then -- avoid overlapping the previous label
          for i = 1, #name do
            month_buf[at + i - 1] = name:sub(i, i)
          end
          last_label_end = at + #name
        end
      end
    end
  end
  local month_line = table.concat(month_buf)

  local lines = {
    center_text('📅 Activity Calendar — last 26 weeks', ui_width),
    '',
    month_line,
  }

  -- record where each heat cell sits so we can color it after the buffer is built
  local marks = {} -- { line = idx0, col = byte0, len = bytelen, lvl = n }
  local day_labels = { [1] = 'Mon', [3] = 'Wed', [5] = 'Fri' }
  for r = 0, 6 do
    local row_str = left_pad .. (day_labels[r] or '   ') .. ' '
    for c = 1, weeks do
      local lvl = grid[r][c]
      if lvl ~= nil then
        local col0 = #row_str
        row_str = row_str .. glyph
        table.insert(marks, { line = #lines, col = col0, len = #glyph, lvl = lvl })
        row_str = row_str .. ' '
      else
        row_str = row_str .. '  '
      end
    end
    table.insert(lines, row_str)
  end

  -- legend with colored squares
  table.insert(lines, '')
  local legend = left_pad .. 'Less '
  local legend_marks = {}
  for lvl = 0, 4 do
    local col0 = #legend
    legend = legend .. glyph
    table.insert(legend_marks, { line = #lines, col = col0, len = #glyph, lvl = lvl })
    legend = legend .. ' '
  end
  legend = legend .. 'More'
  table.insert(lines, legend)
  table.insert(lines, '')

  -- stats: active days, lifetime xp, current streak
  local active_days, total_xp = 0, 0
  for _, v in pairs(daily) do
    if v > 0 then
      active_days = active_days + 1
    end
    total_xp = total_xp + v
  end
  local streak = 0
  for d = 0, total_days do
    local key = os.date('%Y-%m-%d', today_secs - d * 86400)
    if (daily[key] or 0) > 0 then
      streak = streak + 1
    elseif d > 0 then
      break -- today may be empty without breaking the streak
    end
  end
  table.insert(lines, string.format('%sActive days: %d   |   Current streak: %d 🔥', left_pad, active_days, streak))
  table.insert(lines, string.format('%sLifetime XP logged: %d', left_pad, total_xp))
  table.insert(lines, '')
  table.insert(lines, center_text('Press (b) to go back | (q) to close', ui_width))

  local buffer = open_simple_float(lines, ui_width)

  -- apply heat colors (highlights work even though the buffer is non-modifiable)
  for _, mk in ipairs(marks) do
    vim.api.nvim_buf_add_highlight(buffer, -1, 'GamifyHeat' .. mk.lvl, mk.line, mk.col, mk.col + mk.len)
  end
  for _, mk in ipairs(legend_marks) do
    vim.api.nvim_buf_add_highlight(buffer, -1, 'GamifyHeat' .. mk.lvl, mk.line, mk.col, mk.col + mk.len)
  end
  vim.api.nvim_buf_add_highlight(buffer, -1, 'Title', 0, 0, -1)
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
  table.sort(langs, function(a, b)
    return a.n > b.n
  end)
  local top = {}
  for i = 1, math.min(3, #langs) do
    table.insert(top, langs[i].lang)
  end
  local top_str = #top > 0 and table.concat(top, ', ') or 'none yet'

  local prestige_str = prestige > 0 and (' ✪' .. prestige) or ''
  local W = 46
  local function row(text)
    local pad = W - 2 - vim.fn.strdisplaywidth(text)
    if pad < 0 then
      pad = 0
    end
    return '┃ ' .. text .. string.rep(' ', pad) .. '┃'
  end

  local card = {
    '┏' .. string.rep('━', W - 1) .. '┓',
    row '🎮 GAMIFY.NVIM CHARACTER CARD',
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
