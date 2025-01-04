local M = {}

local storage = require 'gamify.storage'

M.compliments = {

  'You’re doing amazing, keep it up! ',
  'Today is your day to shine! ',
  "Small progress is still progress. You're awesome! ",
  'Remember, the journey is just as important as the destination. ',
  'Every keystroke is a step toward greatness! ',
  'Your focus and dedication are inspiring! ',
  'Take a deep breath—you’re doing better than you think. ',
  'Coding or not, you’re a star! ',
  'You’re on fire today! ',
  'Your determination is unmatched. Keep going! ',
  'Somewhere out there, someone is impressed by your dedication. ',
  "You're building something amazing, one line at a time! ",
  'No matter the challenge, you’re capable of overcoming it. ',
  'Even the greatest started with small steps. You’ve got this! ',
  'If progress was easy, everyone would do it. Keep grinding! ',
  'You’ve come so far—don’t stop now! ',
  'Every day you improve just by showing up. ',
  'You bring creativity and passion to everything you do. ',
  'Your work makes a difference, even if you don’t see it yet. ',
  'It’s okay to take breaks—you’re still amazing! ',
  'Mistakes are proof you’re learning. Keep going! ',
  'You’re capable of more than you know. Trust yourself! ',
  'The hardest part is starting, and you’ve already done that. ',
  'You’re not just writing code—you’re creating something unique! ',
  'Believe in your abilities. The best is yet to come',
}

function M.parse_time(time_string)
  if not time_string then
    return nil
  end
  local pattern = '(%d+)%-(%d+)%-(%d+) (%d+):(%d+):(%d+)'
  local year, month, day, hour, min, sec = time_string:match(pattern)
  if not year or not month or not day or not hour or not min or not sec then
    return nil
  end
  return { year = year, month = month, day = day, hour = hour, min = min, sec = sec }
end

-- returns difference between specified times in Y:m:d H:M:S format
function M.check_hour_difference(time1, time2)
  local first_time = M.parse_time(time1)
  local second_time = M.parse_time(time2)

  if not first_time or not second_time then
    return 0
  end

  local first_time_seconds = os.time(first_time)
  local second_time_seconds = os.time(second_time)

  if not first_time_seconds or not second_time_seconds then
    return 0
  end

  local diff_in_seconds = os.difftime(second_time_seconds, first_time_seconds)
  return diff_in_seconds / 3600
end

function M.check_streak()
  local data = storage.load_data()
  if not data or type(data.date) ~= 'table' or #data.date == 0 then
    return 0
  end

  local dates = data.date
  local streak = 1
  local one_day_seconds = 86400

  -- convert dates to seconds since epoch
  local timestamps = {}
  for _, date in ipairs(dates) do
    local year, month, day = date:match '(%d+)-(%d+)-(%d+)'
    local time = os.time { year = year, month = month, day = day, hour = 0, min = 0, sec = 0 }
    table.insert(timestamps, time)
  end

  table.sort(timestamps, function(a, b)
    return a > b
  end)

  for i = 2, #timestamps do
    local difference = os.difftime(timestamps[i - 1], timestamps[i])
    if difference <= one_day_seconds then
      streak = streak + 1
    else
      break
    end
  end

  data.day_streak = streak
  storage.save_data(data)
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

function M.track_night_coding()
  local data = storage.load_data()
  local current_time = os.date '%Y-%m-%d %H:%M:%S'

  local hours_coded = M.check_hour_difference(data.last_entry, current_time)
  if hours_coded >= 3 then
    local last_entry_parsed = M.parse_time(data.last_entry)
    if last_entry_parsed then
      local last_hour = tonumber(last_entry_parsed.hour)
      -- Condition: hour >= 23 (11PM) OR hour < 4 (midnight–3AM)
      if (last_hour >= 23) or (last_hour < 4) then
        data.code_nights = (data.code_nights or 0) + 1
      end
    end
  end

  data.last_entry = current_time
  storage.save_data(data)
end

-- Morning is 06:00–10:59
-- If the 'last_entry' was in that window and you've coded >= 3 hrs, increment code_mornings.
function M.track_morning_coding()
  local data = storage.load_data()
  local current_time = os.date '%Y-%m-%d %H:%M:%S'

  local hours_coded = M.check_hour_difference(data.last_entry, current_time)
  if hours_coded >= 3 then
    local last_entry_parsed = M.parse_time(data.last_entry)
    if last_entry_parsed then
      local last_hour = tonumber(last_entry_parsed.hour)
      -- Condition: hour >= 6 (6AM) and hour < 11 (10:59AM)
      if last_hour >= 6 and last_hour < 11 then
        data.code_mornings = (data.code_mornings or 0) + 1
      end
    end
  end

  data.last_entry = current_time
  storage.save_data(data)
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
