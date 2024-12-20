local M = {}

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

return M
