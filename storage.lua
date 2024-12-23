local M = {}

local data_file = vim.fn.stdpath 'data' .. '/gamify/data.json'

-- json structure
-- {
-- xp = int
-- achievements = {} -- table of strings
-- goals = {} -- something like achievements but user sets them themself
-- date = {} -- days user opened nvim in
-- lines_of_code_written_in_nvim = {}
-- lines_in_specified_langs = {c: 123, cpp:4322, python:1243, rust: 123443}
-- last_time_entry date + time -- it's supposed to help with achievements for coding for few consecutive hours
-- total_time_in_nvim = 0 - in hours
-- code_nights = 0 -- times user spent more than 3 hours in editor between 11PM and 4AM
-- code_mornigs = 0 -- times users spent more than 3 hours in editor between 6AM and 11AM
-- errors_fixed = 0
-- day_streak = 0 -- streak in opening nvim in consecutive days
-- }
--

function M.load_data()
  local file = io.open(data_file, 'r')
  if not file then
    return {
      xp = 0,
      achievements = {
        ['Polyglot'] = '1000 lines in 10 languages',
        ['Jack of Many'] = '1000 lines in at least 5 different languages',
        ['Debug Master'] = 'Fix 20 errors in a single day',
        ['50 Shades of Debug'] = 'Fix 50 errors in a single day',
        ['Coding Deity'] = 'Fix 100 errors in a single day',
        ['Early Bird'] = 'Code for 3+ hours between 6AM and 11AM for 5 days',
        ['Marathon Coder'] = 'Code continuously for at least 5 hours',
        ['Two Thousand Lines'] = 'Write 2000 lines of code',
        ['Five Thousand Lines'] = 'Write 5000 lines of code',
        ['Ten Thousand Lines'] = 'Write 10000 lines of code',
        ['Weekly Streak'] = 'Open Neovim every day for 7 consecutive days',
        ['Two Weeks Streak'] = 'Open Neovim every day for 14 consecutive days',
        ['One Month Streak'] = 'Open Neovim every day for 30 consecutive days',
      },
      goals = {},
      date = {},
      lines_written = 0,
      last_time_entry = nil,
      total_time = 0,
      lvl = 0,
      time_spent = 0,
      code_nights = 0,
      code_mornings = 0,
      lines_written_in_specified_langs = {},
      errors_fixed = 0,
      day_streak = 0,
    } -- Default data
  end
  local content = file:read '*a'
  file:close()
  return vim.fn.json_decode(content)
end

function M.save_data(data)
  local file = io.open(data_file, 'w')
  if not file then
    error('Failed to open file for writing: ' .. data_file)
  end
  file:write(vim.fn.json_encode(data))
  file:close()
end

function M.get_last_day()
  local data = M.load_data()

  if data.date and type(data.date) == 'table' and #data.date > 0 then
    return data.date[#data.date]
  end

  return nil
end

function M.validate_time_entry(entry)
  if type(entry) == 'string' and entry:match '^%d%d%d%d%-%d%d%-%d%d %d%d:%d%d:%d%d$' then
    return true
  end
  return false
end

function M.get_last_log()
  local data = M.load_data()
  local entry = data.last_time_entry

  if entry and M.validate_time_entry(entry) then
    return entry
  end
  return os.date '%Y%d%s %H:%m:%s'
end

-- it returns boolean so we can know if we should add exp to user for logging
function M.log_new_day()
  local current_date = os.date '%Y-%m-%d' -- Current date only
  local last_day_entry = M.get_last_day()

  -- Extract date part from last_time_entry if present
  local last_logged_date = last_day_entry and last_day_entry:match '%d%d%d%d%-%d%d%-%d%d' or nil

  -- Compare only the date part
  if last_logged_date ~= current_date then
    local data = M.load_data()
    data.date = data.date or {}
    table.insert(data.date, os.date '%Y-%m-%d %H:%M:%S')
    M.save_data(data)
    return true
  end

  return false
end

local function ensure_lang_table(data)
  data.lines_in_specified_langs = data.lines_in_specified_langs or {}
end

local function split(input, delimiter)
  local result = {}
  for match in (input .. delimiter):gmatch('(.-)' .. delimiter) do
    table.insert(result, match)
  end
  return result
end

local function get_file_language(file_path)
  -- Extract the file name from the full path
  local file_split = split(file_path, '.')
  local file_extension = file_split[#file_split]

  local language_map = {
    lua = 'Lua',
    py = 'Python',
    js = 'JavaScript',
    ts = 'TypeScript',
    rb = 'Ruby',
    go = 'Go',
    rs = 'Rust',
    cpp = 'C++',
    c = 'C',
    java = 'Java',
    php = 'PHP',
    html = 'HTML',
    css = 'CSS',
    swift = 'Swift',
    kt = 'Kotlin',
    cs = 'C#',
    json = 'JSON',
    md = 'Markdown',
    sh = 'Shell',
    yaml = 'YAML',
    toml = 'TOML',
    xml = 'XML',
    hs = 'Haskell',
    pl = 'Perl',
    r = 'R',
    scala = 'Scala',
    dart = 'Dart',
    ex = 'Elixir',
    erl = 'Erlang',
    scss = 'SCSS',
    coffee = 'CoffeeScript',
    jsx = 'JavaScript (React)',
    tsx = 'TypeScript (React)',
    vim = 'Vim Script',
    unknown = 'Unknown',
  }
  return language_map[file_extension] or file_extension
end

local function update_lines_for_language(lang, new_lines)
  local data = M.load_data()
  ensure_lang_table(data)
  data.lines_written_in_specified_langs[lang] = (data.lines_written_in_specified_langs[lang] or 0) + new_lines

  M.save_data(data)
end

function M.track_lines_on_save()
  local data = M.load_data()
  ensure_lang_table(data)

  local buffer = vim.api.nvim_get_current_buf()
  local file_path = vim.api.nvim_buf_get_name(buffer)
  local lang = get_file_language(file_path)

  local current_line_count = vim.api.nvim_buf_line_count(buffer)
  data.lines_written = data.lines_written or {}
  local previous_line_count = data.lines_written_in_specified_langs[file_path] or 0

  local lines_added = math.max(current_line_count - previous_line_count, 0)
  update_lines_for_language(lang, lines_added)
  data.lines_written_in_specified_langs[file_path] = current_line_count
  data.lines_written = data.lines_written + lines_added
  M.save_data(data)
end

return M
