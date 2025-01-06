
<div align="center">
<h1 style="text-align: center;">🎮 Gamify your Neovim experience 🎮</h1>


![logo](https://github.com/user-attachments/assets/d24d6a76-76cb-4a75-a862-0aa1764e5e13)

A small plugin to “gamify” your coding sessions in Neovim. It tracks your coding activity, rewards you with experience points (XP), and unlocks achievements based on various milestones—from writing lines of code to hitting daily streaks and fixing errors. It also gives you random compliments and xp just for using the best editor around. 
</div>

## Features

- **Daily Tracking**: Increments your day streak each time you open Neovim on a new day.  
- **Line Counting**: Collects how many lines of code you’ve written per language.  
- **Error Fixes**: Counts how many errors you fix (with optional checks that errors truly disappear).  
- **XP and Levels**: Earn XP for tasks, achievements, or random “lucky” events.  
- **Achievement Popups**: Unlock achievements that display a popup and confetti effect.

## Screenshots  
![telegram-cloud-photo-size-4-6037212632525687285-y](https://github.com/user-attachments/assets/398c0d50-cfb3-4a9b-8c0d-b0c6dba05dd9)

![telegram-cloud-photo-size-4-6037212632525687286-y](https://github.com/user-attachments/assets/d9d20490-8781-46d9-bd90-436af5404ee1)

![telegram-cloud-photo-size-4-6037212632525687287-y](https://github.com/user-attachments/assets/6319b1fd-6481-4879-a653-f16fdc5e6660)

## Video Preview

![achievement-gif](https://github.com/user-attachments/assets/f5b07484-a700-47ee-97a7-5d13e9d4ebcf)

## Commands
- **`:Gamify`** – Show the status window (XP, level, achievements, lines, etc.)  
- **`:Langstats`** – Show a bar chart of languages and line counts  
- **`:Achievements`** – List your unlocked achievements.








## Installation & Usage

1. Install via your preferred plugin manager (e.g., `lazy.nvim`, `packer.nvim`, etc.).  
2. Require as needed (e.g., `require('gamify')`). Configuration is not available yet.
3. Start coding! Achievements will unlock automatically, and popups will appear.

```lua
-- lazy.nvim  
{
  'grzegorzszczepanek/gamify.nvim',
  config = function()
    require('gamify')
  end,
}
```

```lua
-- for lazy loading
local add, later = MiniDeps.add, MiniDeps.later

later(function()
    add("GrzegorzSzczepanek/gamify.nvim")
    require("gamify")
end)

```


## Achievements

| **Achievement**            | **Description**                                                              | **XP**  |
|----------------------------|------------------------------------------------------------------------------|--------:|
| **Weekly Streak**          | Open Neovim every day for 7 consecutive days                                 | 500     |
| **Two Weeks Streak**       | Open Neovim every day for 14 consecutive days                                | 1500    |
| **One Month Streak**       | Open Neovim every day for 30 consecutive days                                | 4000    |
| **Hundred lines**          | Write 100 lines of code                                                      | 100     |
| **Thousand Lines**         | Write 1000 lines of code                                                     | 150     |
| **Two Thousand Lines**     | Write 2000 lines of code                                                     | 350     |
| **Five Thousand Lines**    | Write 5000 lines of code                                                     | 600     |
| **Ten Thousand Lines**     | Write 10000 lines of code                                                    | 800     |
| **Twenty Five Thousand Lines** | Write 25000 lines of code                                               | 2000    |
| **Night Owl**              | Code for at least 3 hours between 11PM and 4AM five times                     | 1000    |
| **Early Bird**             | Code for at least 3 hours between 6AM and 11AM five times                     | 1000    |
| **Jack of Many**           | Write at least 1000 lines in at least 5 languages                            | 2500    |
| **Polyglot**               | Write at least 1000 lines in at least 10 languages                           | 5000    |
| **Marathoner**             | Code continuously for at least 6 hours                                       | 1800    |
| **Git Apprentice**         | Make 10 total commits in your coding journey                                 | 300     |
| **Git Journeyman**         | Make 50 total commits in your coding journey                                 | 1000    |
| **Git Master**             | Make 100 total commits in your coding journey                                | 3000    |
| **Commit Deity**           | Make 500 total commits in your coding journey                                | 8000    |
| **Vim enjoyer**            | Spend at least 100 hours in nvim                                             | 4500    |
| **Get a Life!**            | Spend at least 200 hours in nvim                                             | 9000    |

## Contributing
Contributions, whether they're bug fixes, new features, documentation improvements, or other enhancements, are always welcome. To ensure a smooth collaboration, please follow these steps:

1. **Open an Issue**: Before submitting a Pull Request (PR), please open an issue to discuss the proposed change. This helps us understand the problem or enhancement you are addressing and avoid duplicate work.

2. **Fork the Repository**: Create a copy of this repository in your own GitHub account by clicking the "Fork" button.

3. **Make Changes**: Implement your changes in a new branch. Use meaningful commit messages to describe your work.

4. **Submit a Pull Request**: Once your changes are ready, submit a PR to the main repository. Ensure that you:
   - Reference the issue number (if applicable) in your PR description.
   - Provide a clear and concise summary of your changes.

5. **Code Review**: Your PR will be reviewed, and feedback may be provided. 


## License
Licensed under the [Apache License 2.0](LICENSE).
