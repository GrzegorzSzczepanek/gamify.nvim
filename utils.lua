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
  return language_map[extension]
end

return M
