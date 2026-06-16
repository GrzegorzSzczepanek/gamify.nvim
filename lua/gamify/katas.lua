local M = {}

M.list = {
  {
    id = 1,
    title = 'Reverse String',
    description = "Write a function 'solution(str)' that reverses the input string.",
    initial_code = 'function solution(str)\n  -- Your code here\n  \nend',
    tests = {
      { input = 'hello', expected = 'olleh' },
      { input = 'world', expected = 'dlrow' },
      { input = 'lua', expected = 'aul' },
    },
    xp = 100,
  },
  {
    id = 2,
    title = 'Sum of Array',
    description = "Write a function 'solution(arr)' that returns the sum of all numbers in an array.",
    initial_code = 'function solution(arr)\n  -- Your code here\n  \nend',
    tests = {
      { input = { 1, 2, 3 }, expected = 6 },
      { input = { 10, -5, 5 }, expected = 10 },
      { input = {}, expected = 0 },
    },
    xp = 150,
  },
  {
    id = 3,
    title = 'Is Palindrome',
    description = "Write a function 'solution(str)' that returns true if a string is a palindrome.",
    initial_code = 'function solution(str)\n  -- Your code here\n  \nend',
    tests = {
      { input = 'racecar', expected = true },
      { input = 'hello', expected = false },
      { input = 'madam', expected = true },
    },
    xp = 200,
  },
  {
    id = 4,
    title = 'FizzBuzz',
    description = "Write 'solution(n)' returning 'Fizz' if divisible by 3, 'Buzz' if by 5, 'FizzBuzz' if both, else the number as a string.",
    initial_code = 'function solution(n)\n  -- Your code here\n  \nend',
    tests = {
      { input = 3, expected = 'Fizz' },
      { input = 5, expected = 'Buzz' },
      { input = 15, expected = 'FizzBuzz' },
      { input = 7, expected = '7' },
    },
    xp = 150,
  },
  {
    id = 5,
    title = 'Count Vowels',
    description = "Write 'solution(str)' that returns the number of vowels (a, e, i, o, u) in the string.",
    initial_code = 'function solution(str)\n  -- Your code here\n  \nend',
    tests = {
      { input = 'hello', expected = 2 },
      { input = 'sky', expected = 0 },
      { input = 'aeiou', expected = 5 },
    },
    xp = 150,
  },
  {
    id = 6,
    title = 'Max of Array',
    description = "Write 'solution(arr)' that returns the largest number in the array.",
    initial_code = 'function solution(arr)\n  -- Your code here\n  \nend',
    tests = {
      { input = { 1, 7, 3 }, expected = 7 },
      { input = { -5, -2, -9 }, expected = -2 },
      { input = { 42 }, expected = 42 },
    },
    xp = 175,
  },
  {
    id = 7,
    title = 'Factorial',
    description = "Write 'solution(n)' that returns n! (n factorial). solution(0) is 1.",
    initial_code = 'function solution(n)\n  -- Your code here\n  \nend',
    tests = {
      { input = 0, expected = 1 },
      { input = 5, expected = 120 },
      { input = 6, expected = 720 },
    },
    xp = 200,
  },
  {
    id = 8,
    title = 'Fibonacci',
    description = "Write 'solution(n)' that returns the n-th Fibonacci number (0-indexed: 0,1,1,2,3,5...).",
    initial_code = 'function solution(n)\n  -- Your code here\n  \nend',
    tests = {
      { input = 0, expected = 0 },
      { input = 1, expected = 1 },
      { input = 7, expected = 13 },
      { input = 10, expected = 55 },
    },
    xp = 250,
  },
}

function M.daily_id()
  local seed = 0
  for _, b in ipairs { os.date('%Y%m%d'):byte(1, -1) } do
    seed = seed + b
  end
  return (seed % #M.list) + 1
end

return M
