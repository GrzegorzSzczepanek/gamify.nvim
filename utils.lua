local M = {}

local storage = require 'gamify.storage'

function M.parse_time(time_string)
  local pattern = '(%d+)%-(%d+)%-(%d+) (%d+):(%d+):(%d+)'
  local year, month, day, hour, min, sec = time_string:match(pattern)
  return { year = year, month = month, day = day, hour = hour, min = min, sec = sec }
end

-- returns difference between specified times in Y:m:d H:M:S format
function M.check_hour_difference(time1, time2)
  local first_time = M.parse_time(time1)
  local second_time = M.parse_time(time2)

  local first_time_seconds = os.time(first_time)
  local second_time_seconds = os.time(second_time)

  local diff_in_seconds = os.difftime(second_time_seconds, first_time_seconds)
  local diff_in_hours = diff_in_seconds / 3600

  return diff_in_hours
end

function M.get_table_length(t)
  local count = 0
  for _ in pairs(t) do
    count = count + 1
  end
  return count
end

-- TODO: unify time and fix inconsistencies
function M.hours_in_nvim()
  local data = storage.load_data()
  local last_time = data.last_time_entry
  if last_time then
    local current_time = os.time()
    local time_diff = os.difftime(current_time, last_time)
    return time_diff
  end
  return 0
end

-- returns difference in hours
function M.calculate_time_difference()
  local last_entry = storage.load_data().last_entry
  if not last_entry then
    return false
  end

  local last_entry_table = M.parse_time(last_entry)
  if not last_entry_table then
    return false
  end

  local start_time = os.time(last_entry_table)
  local current_time = os.time()
  local time_diff = os.difftime(current_time, start_time)

  return time_diff / 3600
end

function M.get_file_language(extension)
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
    exs = 'Elixir',
    erl = 'Erlang',
    scss = 'SCSS',
    coffee = 'CoffeeScript',
    jsx = 'JavaScript (React)',
    tsx = 'TypeScript (React)',
    vim = 'Vim Script',
    unknown = 'Unknown',
  }
  local excluded_extensions = {
    json = true,
    toml = true,
  }
  if excluded_extensions[extension] then
    return nil
  end

  return language_map[extension]
end

function M.calculate_all_lines_written()
  local data = storage.load_data()
  local lines_per_lang = data.lines_written_in_specified_langs or {}

  local all_lines = 0
  for lang, lines in pairs(lines_per_lang) do
    if lang ~= 'Unknown' and lines > 0 then
      all_lines = all_lines + lines
    end
  end

  data.lines_written = all_lines
  storage.save_data(data)
end

function M.get_day_streak()
  local data = storage.load_data()
  local days_in_nvim = data.date

  for i = 1, #days_in_nvim do
  end
end

return M
