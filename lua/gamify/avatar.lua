-- Avatar / character generator and corner companion with idle animations.
--
-- Persisted under data.avatar: { name, parts = { hat, face, body, pet },
-- enabled, animations, corner }.

local M = {}

local storage = require 'gamify.storage'
local config = require 'gamify.config'

local function ensure_highlights()
  vim.cmd [[
    highlight default GamifyAvatarFace gui=bold guifg=#ffcb6b
    highlight default GamifyAvatarHat  gui=bold guifg=#f778ba
    highlight default GamifyAvatarBody guifg=#58a6ff
    highlight GamifyAvatarBg guibg=NONE ctermbg=NONE
  ]]
end
ensure_highlights()
vim.api.nvim_create_autocmd('ColorScheme', { callback = ensure_highlights })

-- The figure is a fixed 5-char-wide grid (hat, head, face, base, body) drawn
-- with ASCII only: ambiguous-width glyphs render as 1 or 2 cells depending on
-- the terminal and break the alignment. Emoji pets go on the caption instead.
M.parts = {
  -- hats: exactly 5 chars wide, ASCII/narrow only
  hat = {
    { name = 'None', line = '     ' },
    { name = 'Cap', line = ' /-\\ ' },
    { name = 'Beanie', line = ' [#] ' },
    { name = 'Crown', line = ' vvv ' },
    { name = 'Wizard', line = '  ^  ' },
    { name = 'Halo', line = ' (o) ' },
    { name = 'Antenna', line = '  i  ' },
    { name = 'Punk', line = ' \\|/ ' },
  },
  -- faces: the EYE strip is exactly 3 chars, placed between the parens (EYE)
  face = {
    { name = 'Happy', open = 'o.o', blink = '-.-' },
    { name = 'Cute', open = '^.^', blink = '-.-' },
    { name = 'Wink', open = 'o.~', blink = '-.~' },
    { name = 'Sleepy', open = 'u.u', blink = '_._' },
    { name = 'Robot', open = '0_0', blink = '___' },
    { name = 'Star', open = '*.*', blink = '-.-' },
    { name = 'Cool', open = 'B.B', blink = '-.-' },
    { name = 'Surprised', open = 'O.O', blink = '-.-' },
  },
  -- bodies: torso is exactly 3 chars, framed by arms => 5 chars total
  body = {
    { name = 'Tee', torso = '[T]' },
    { name = 'Hoodie', torso = '[H]' },
    { name = 'Suit', torso = '[#]' },
    { name = 'Coder', torso = '<#>' },
    { name = 'Armor', torso = '{#}' },
    { name = 'Hero', torso = '[S]' },
  },
  -- pets: emoji, shown on the caption line only (never inside the figure grid)
  pet = {
    { name = 'None', glyph = '' },
    { name = 'Cat', glyph = '🐱' },
    { name = 'Dog', glyph = '🐶' },
    { name = 'Slime', glyph = '🟢' },
    { name = 'Ghost', glyph = '👻' },
    { name = 'Bug', glyph = '🐛' },
    { name = 'Duck', glyph = '🦆' },
  },
}

M.part_order = { 'hat', 'face', 'body', 'pet' }

local corners = { 'top_left', 'top_right', 'bottom_left', 'bottom_right' }

-- ── Persistence helpers ───────────────────────────────────────────────────

local function default_avatar()
  return {
    name = 'Pixel',
    parts = { hat = 1, face = 1, body = 1, pet = 1 },
    enabled = false,
    animations = true,
    corner = 'bottom_right',
  }
end

function M.get()
  local data = storage.load_data()
  local av = data.avatar
  if type(av) ~= 'table' then
    av = default_avatar()
  end
  -- backfill any missing fields so older saves keep working
  local d = default_avatar()
  for k, v in pairs(d) do
    if av[k] == nil then
      av[k] = v
    end
  end
  av.parts = av.parts or {}
  for _, p in ipairs(M.part_order) do
    av.parts[p] = av.parts[p] or 1
  end
  return av
end

function M.save(av)
  local data = storage.load_data()
  data.avatar = av
  storage.save_data(data)
end

-- Render the figure for the given pose ('idle', 'blink', 'wave').
-- Returns (lines, width, face_row); the pet emoji is fetched via pet_glyph.
function M.render(av, frame)
  av = av or M.get()
  frame = frame or 'idle'

  local hat = M.parts.hat[av.parts.hat or 1].line
  local face_def = M.parts.face[av.parts.face or 1]
  local eyes = (frame == 'blink') and face_def.blink or face_def.open
  local torso = M.parts.body[av.parts.body or 1].torso

  local larm = (frame == 'wave') and 'o' or '\\'
  local rarm = '/'

  local figure = {
    hat,
    ' ___ ',
    '(' .. eyes .. ')',
    " '-' ",
    larm .. torso .. rarm,
  }
  local face_row = 2

  local w = 5
  local out = {}
  for _, l in ipairs(figure) do
    if #l < w then
      l = l .. string.rep(' ', w - #l)
    end
    out[#out + 1] = l
  end
  return out, w, face_row
end

function M.pet_glyph(av)
  av = av or M.get()
  return M.parts.pet[av.parts.pet or 1].glyph
end

-- ── Corner companion (the floating, optionally-animated avatar) ────────────

local companion = {
  win = nil,
  buf = nil,
  timer = nil,
  base_row = 0, -- top-left anchor when not bouncing
  base_col = 0,
  tick = 0,
}

local function close_timer()
  if companion.timer and not companion.timer:is_closing() then
    companion.timer:stop()
    companion.timer:close()
  end
  companion.timer = nil
end

function M.is_shown()
  return companion.win ~= nil and vim.api.nvim_win_is_valid(companion.win)
end

local function compute_anchor(corner, width, height)
  local row, col
  if corner == 'top_left' then
    row, col = 1, 1
  elseif corner == 'top_right' then
    row, col = 1, vim.o.columns - width - 1
  elseif corner == 'bottom_left' then
    row, col = vim.o.lines - height - 2, 1
  else -- bottom_right (default)
    row, col = vim.o.lines - height - 2, vim.o.columns - width - 1
  end
  return math.max(0, row), math.max(0, col)
end

local function paint(frame, row_offset)
  if not M.is_shown() then
    return
  end
  local av = M.get()
  local lines, _, face_row = M.render(av, frame)
  -- name caption under the figure, with the pet emoji beside it (if any)
  local pet = M.pet_glyph(av)
  local caption = pet ~= '' and (pet .. ' ' .. av.name) or av.name
  table.insert(lines, caption)

  vim.api.nvim_buf_set_option(companion.buf, 'modifiable', true)
  vim.api.nvim_buf_set_lines(companion.buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(companion.buf, 'modifiable', false)

  -- color: head outline, face row, body, and dimmed name
  local ns = vim.api.nvim_create_namespace 'gamify_avatar'
  vim.api.nvim_buf_clear_namespace(companion.buf, ns, 0, -1)
  vim.api.nvim_buf_add_highlight(companion.buf, ns, 'GamifyAvatarHat', 0, 0, -1)
  vim.api.nvim_buf_add_highlight(companion.buf, ns, 'GamifyAvatarFace', face_row, 0, -1)
  vim.api.nvim_buf_add_highlight(companion.buf, ns, 'GamifyAvatarBody', #lines - 2, 0, -1)
  vim.api.nvim_buf_add_highlight(companion.buf, ns, 'Comment', #lines - 1, 0, -1)

  if vim.api.nvim_win_is_valid(companion.win) then
    vim.api.nvim_win_set_config(companion.win, {
      relative = 'editor',
      row = companion.base_row + (row_offset or 0),
      col = companion.base_col,
    })
  end
end

-- The idle animation loop: blinks, a gentle bounce, and occasional waves.
local function animate()
  vim.schedule(function()
    if not M.is_shown() then
      close_timer()
      return
    end
    companion.tick = companion.tick + 1
    local t = companion.tick

    -- bounce: hop up one row every ~8 ticks for a single tick
    local bounce = (t % 8 == 0) and -1 or 0
    -- frames: wave every ~14 ticks, blink every ~10, else idle
    local frame = 'idle'
    if t % 14 == 0 then
      frame = 'wave'
    elseif t % 10 == 0 then
      frame = 'blink'
    end

    paint(frame, bounce)
  end)
end

-- Show the companion. Reads enabled/corner/animations from saved avatar unless
-- forced. Safe to call repeatedly (re-anchors / restarts).
function M.show_companion(opts)
  opts = opts or {}
  local av = M.get()

  M.hide_companion() -- clean slate

  local lines, width = M.render(av, 'idle')
  local height = #lines + 1 -- +1 for name caption
  local pet = M.pet_glyph(av)
  local caption_w = vim.fn.strdisplaywidth((pet ~= '' and (pet .. ' ') or '') .. av.name)
  width = math.max(width, caption_w)

  companion.buf = vim.api.nvim_create_buf(false, true)
  companion.base_row, companion.base_col = compute_anchor(av.corner, width, height)

  companion.win = vim.api.nvim_open_win(companion.buf, false, {
    style = 'minimal',
    relative = 'editor',
    width = width + 1,
    height = height,
    row = companion.base_row,
    col = companion.base_col,
    focusable = false,
    border = 'none',
    zindex = 50,
  })

  -- Transparent background: map the float's Normal/EndOfLine to a bg=NONE group
  -- so it blends into whatever is behind Neovim (shows the wallpaper on a
  -- transparent terminal). Falls back to the normal float bg when disabled.
  local transparent = config.get().avatar.transparent
  if transparent ~= false then
    vim.api.nvim_win_set_option(
      companion.win,
      'winhighlight',
      'Normal:GamifyAvatarBg,NormalNC:GamifyAvatarBg,EndOfLine:GamifyAvatarBg,FloatBorder:GamifyAvatarBg'
    )
    vim.api.nvim_win_set_option(companion.win, 'winblend', 0)
  end

  companion.tick = 0
  paint('idle', 0)

  local animate_on = opts.animations
  if animate_on == nil then
    animate_on = av.animations
  end
  if animate_on and config.get().ui.popups ~= false then
    close_timer()
    companion.timer = vim.loop.new_timer()
    companion.timer:start(600, 600, vim.schedule_wrap(animate))
  end
end

function M.hide_companion()
  close_timer()
  if companion.win and vim.api.nvim_win_is_valid(companion.win) then
    vim.api.nvim_win_close(companion.win, true)
  end
  if companion.buf and vim.api.nvim_buf_is_valid(companion.buf) then
    vim.api.nvim_buf_delete(companion.buf, { force = true })
  end
  companion.win, companion.buf = nil, nil
end

-- Persist enabled/disabled and reflect it on screen immediately.
function M.set_enabled(on)
  local av = M.get()
  av.enabled = on and true or false
  M.save(av)
  if av.enabled then
    M.show_companion()
  else
    M.hide_companion()
  end
end

function M.toggle()
  local av = M.get()
  M.set_enabled(not av.enabled)
  return M.get().enabled
end

function M.set_animations(on)
  local av = M.get()
  av.animations = on and true or false
  M.save(av)
  if av.enabled then
    M.show_companion() -- restart with new setting
  end
end

function M.set_corner(corner)
  local valid = false
  for _, c in ipairs(corners) do
    if c == corner then
      valid = true
    end
  end
  if not valid then
    vim.notify(
      'Unknown corner: ' .. tostring(corner) .. ' (use ' .. table.concat(corners, '/') .. ')',
      vim.log.levels.WARN,
      { title = 'Gamify' }
    )
    return
  end
  local av = M.get()
  av.corner = corner
  M.save(av)
  if av.enabled then
    M.show_companion()
  end
end

-- Call from setup() so the companion reappears across sessions if enabled.
function M.restore()
  local av = M.get()
  if av.enabled then
    -- defer so the UI is ready and dimensions are known
    vim.defer_fn(function()
      M.show_companion()
    end, 200)
  end
end

-- ── Character generator (interactive builder) ──────────────────────────────

local builder = { buf = nil, win = nil, sel = 1, av = nil }

local function builder_lines()
  local av = builder.av
  local preview = M.render(av, 'idle')
  local lines = {
    '  🎨 Character Generator',
    '',
  }
  -- preview block, indented
  for _, l in ipairs(preview) do
    table.insert(lines, '        ' .. l)
  end
  local pet = M.pet_glyph(av)
  local caption = pet ~= '' and (pet .. ' ' .. av.name) or av.name
  table.insert(lines, '        ' .. caption)
  table.insert(lines, '')
  table.insert(lines, '  ── Customize (←/→ or h/l to change) ──')

  -- one editable row per part, plus a Name row
  builder.rows = {}
  for _, p in ipairs(M.part_order) do
    local opt = M.parts[p][av.parts[p]]
    table.insert(builder.rows, { kind = 'part', part = p })
    local marker = (#builder.rows == builder.sel) and '▶ ' or '  '
    local label = p:gsub('^%l', string.upper)
    table.insert(lines, string.format('  %s%-7s %s  (%d/%d)', marker, label, opt.name, av.parts[p], #M.parts[p]))
  end

  table.insert(builder.rows, { kind = 'name' })
  local marker = (#builder.rows == builder.sel) and '▶ ' or '  '
  table.insert(lines, string.format('  %s%-7s %s  (press (r) to rename)', marker, 'Name', av.name))

  table.insert(builder.rows, { kind = 'corner' })
  marker = (#builder.rows == builder.sel) and '▶ ' or '  '
  table.insert(lines, string.format('  %s%-7s %s', marker, 'Corner', av.corner))

  table.insert(builder.rows, { kind = 'animations' })
  marker = (#builder.rows == builder.sel) and '▶ ' or '  '
  table.insert(lines, string.format('  %s%-7s %s', marker, 'Anim', av.animations and 'on' or 'off'))

  table.insert(lines, '')
  table.insert(lines, '  (j/k) move   (h/l) change   (r) rename')
  table.insert(lines, '  (<CR>) save & show in corner   (x) save (hidden)   (q) cancel')
  return lines
end

local function builder_redraw()
  if not (builder.buf and vim.api.nvim_buf_is_valid(builder.buf)) then
    return
  end
  local lines = builder_lines()
  vim.api.nvim_buf_set_option(builder.buf, 'modifiable', true)
  vim.api.nvim_buf_set_lines(builder.buf, 0, -1, false, lines)
  -- preview figure starts at buffer line 2 (after title + blank). Within the
  -- 5-line figure: hat=row0, face=row2, body=row4.
  local fig0 = 2
  local ns = vim.api.nvim_create_namespace 'gamify_avatar_builder'
  vim.api.nvim_buf_clear_namespace(builder.buf, ns, 0, -1)
  vim.api.nvim_buf_add_highlight(builder.buf, ns, 'Title', 0, 0, -1)
  vim.api.nvim_buf_add_highlight(builder.buf, ns, 'GamifyAvatarHat', fig0, 0, -1)
  vim.api.nvim_buf_add_highlight(builder.buf, ns, 'GamifyAvatarFace', fig0 + 2, 0, -1)
  vim.api.nvim_buf_add_highlight(builder.buf, ns, 'GamifyAvatarBody', fig0 + 4, 0, -1)
  vim.api.nvim_buf_set_option(builder.buf, 'modifiable', false)
end

local function builder_change(dir)
  local row = builder.rows[builder.sel]
  if not row then
    return
  end
  local av = builder.av
  if row.kind == 'part' then
    local n = #M.parts[row.part]
    av.parts[row.part] = ((av.parts[row.part] - 1 + dir) % n) + 1
  elseif row.kind == 'corner' then
    local idx = 1
    for i, c in ipairs(corners) do
      if c == av.corner then
        idx = i
      end
    end
    av.corner = corners[((idx - 1 + dir) % #corners) + 1]
  elseif row.kind == 'animations' then
    av.animations = not av.animations
  end
  builder_redraw()
end

function M.open_generator()
  builder.av = vim.deepcopy(M.get())
  builder.sel = 1

  local lines = builder_lines()
  local width = 52
  local height = #lines + 1

  builder.buf = vim.api.nvim_create_buf(false, true)
  builder.win = vim.api.nvim_open_win(builder.buf, true, {
    style = 'minimal',
    relative = 'editor',
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    border = 'rounded',
  })
  builder_redraw()

  local function map(lhs, fn)
    vim.keymap.set('n', lhs, fn, { buffer = builder.buf, nowait = true })
  end

  local function move(d)
    local n = #builder.rows
    builder.sel = ((builder.sel - 1 + d) % n) + 1
    builder_redraw()
  end

  map('j', function()
    move(1)
  end)
  map('<Down>', function()
    move(1)
  end)
  map('k', function()
    move(-1)
  end)
  map('<Up>', function()
    move(-1)
  end)
  map('l', function()
    builder_change(1)
  end)
  map('<Right>', function()
    builder_change(1)
  end)
  map('h', function()
    builder_change(-1)
  end)
  map('<Left>', function()
    builder_change(-1)
  end)

  map('r', function()
    vim.ui.input({ prompt = 'Avatar name: ', default = builder.av.name }, function(input)
      if input and input ~= '' then
        builder.av.name = input:sub(1, 20)
        builder_redraw()
      end
    end)
  end)

  local function close()
    if builder.win and vim.api.nvim_win_is_valid(builder.win) then
      vim.api.nvim_win_close(builder.win, true)
    end
    builder.buf, builder.win = nil, nil
  end

  local function commit(show)
    builder.av.enabled = show and true or false
    M.save(builder.av)
    close()
    if show then
      M.show_companion()
      vim.notify(
        'Avatar "' .. M.get().name .. '" is now in the corner! 🎉',
        vim.log.levels.INFO,
        { title = 'Gamify' }
      )
    else
      M.hide_companion()
      vim.notify('Avatar saved. Use :GamifyAvatar show to summon it.', vim.log.levels.INFO, { title = 'Gamify' })
    end
  end

  map('<CR>', function()
    commit(true)
  end)
  map('x', function()
    commit(false)
  end)
  map('q', close)
  map('<Esc>', close)
end

return M
