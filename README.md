# Gamify.nvim

A small plugin to “gamify” your coding sessions in Neovim. It tracks your coding activity, rewards you with experience points (XP), and unlocks achievements based on various milestones—from writing lines of code to hitting daily streaks and fixing errors.  

## Features

- **Daily Tracking**: Increments your day streak each time you open Neovim on a new day.  
- **Line Counting**: Collects how many lines of code you’ve written per language.  
- **Error Fixes**: Counts how many errors you fix (with optional checks that errors truly disappear).  
- **XP and Levels**: Earn XP for tasks, achievements, or random “lucky” events.  
- **Achievement Popups**: Unlock achievements that display a popup and confetti effect.  

## Commands
- **`:Gamify`** – Show the status window (XP, level, achievements, lines, etc.)  
- **`:Langstats`** – Show a bar chart of languages and line counts  
- **`:Achievements`** – List your unlocked achievements.

## Achievements

- **Weekly Streak**: Open Neovim daily for 7 consecutive days.  
- **Two Weeks Streak**: Open Neovim daily for 14 consecutive days.  
- **One Month Streak**: 30 consecutive days of Neovim usage.  
- **Lines of Code**: 100, 1,000, 2,000, 5,000, 10,000, and 25,000 lines milestones.  
- **Night Owl & Early Bird**: Log 3+ hours of coding at night/morning five times.  
- **Debug Master**: Fix 20 errors in a single day.  
- **50 Shades of Debugging**: Fix 50 errors in a single day.  
- **Coding Deity**: Fix 100 errors in a single day.  
- **Marathoner**: Code continuously for 6 hours.  
- **Vim Enjoyer**: Spend 100 hours in Neovim.  
- **Get a Life!**: Spend 200 hours in Neovim.  
- **Polyglot**: Write 1,000+ lines in 10 different languages.  
- *(And more...)*

## Screenshots

![Gamify.nvim Status Window](https://private-user-images.githubusercontent.com/113286903/400165080-398c0d50-cfb3-4a9b-8c0d-b0c6dba05dd9.jpg?jwt=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJnaXRodWIuY29tIiwiYXVkIjoicmF3LmdpdGh1YnVzZXJjb250ZW50LmNvbSIsImtleSI6ImtleTUiLCJleHAiOjE3MzYwMjUzOTcsIm5iZiI6MTczNjAyNTA5NywicGF0aCI6Ii8xMTMyODY5MDMvNDAwMTY1MDgwLTM5OGMwZDUwLWNmYjMtNGE5Yi04YzBkLWIwYzZkYmEwNWRkOS5qcGc_WC1BbXotQWxnb3JpdGhtPUFXUzQtSE1BQy1TSEEyNTYmWC1BbXotQ3JlZGVudGlhbD1BS0lBVkNPRFlMU0E1M1BRSzRaQSUyRjIwMjUwMTA0JTJGdXMtZWFzdC0xJTJGczMlMkZhd3M0X3JlcXVlc3QmWC1BbXotRGF0ZT0yMDI1MDEwNFQyMTExMzdaJlgtQW16LUV4cGlyZXM9MzAwJlgtQW16LVNpZ25hdHVyZT1iYzIxNjhmMjdmMWZmMGMxNjBiN2IxNDc4YWM2ZmYzYjQ1ODlmNTJlMGVhMWE2ODU0MmE0OTA3NWRlZmFlMGYwJlgtQW16LVNpZ25lZEhlYWRlcnM9aG9zdCJ9.v7TK1ywzWEhTmI6Egd7u_kPgUpWRGUrTtjpblnjfe84)

![Most Used Languages](https://private-user-images.githubusercontent.com/113286903/400165086-d9d20490-8781-46d9-bd90-436af5404ee1.jpg?jwt=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJnaXRodWIuY29tIiwiYXVkIjoicmF3LmdpdGh1YnVzZXJjb250ZW50LmNvbSIsImtleSI6ImtleTUiLCJleHAiOjE3MzYwMjUzOTcsIm5iZiI6MTczNjAyNTA5NywicGF0aCI6Ii8xMTMyODY5MDMvNDAwMTY1MDg2LWQ5ZDIwNDkwLTg3ODEtNDZkOS1iZDkwLTQzNmFmNTQwNGVlMS5qcGc_WC1BbXotQWxnb3JpdGhtPUFXUzQtSE1BQy1TSEEyNTYmWC1BbXotQ3JlZGVudGlhbD1BS0lBVkNPRFlMU0E1M1BRSzRaQSUyRjIwMjUwMTA0JTJGdXMtZWFzdC0xJTJGczMlMkZhd3M0X3JlcXVlc3QmWC1BbXotRGF0ZT0yMDI1MDEwNFQyMTExMzdaJlgtQW16LUV4cGlyZXM9MzAwJlgtQW16LVNpZ25hdHVyZT04NmVmODU5NDc2YjJlOTRiZmIzMGRlYTQzOWYzYzI4MDI5ZDc2MmNiNGRmMDI3NGJhMzc1MWY0NzllYzMzY2I2JlgtQW16LVNpZ25lZEhlYWRlcnM9aG9zdCJ9.rbms8Bpi4KVmRI5YDSOmNgQndIu7VMtn94d50DU8QBE)

![Achievements List](https://private-user-images.githubusercontent.com/113286903/400165090-6319b1fd-6481-4879-a653-f16fdc5e6660.jpg?jwt=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJnaXRodWIuY29tIiwiYXVkIjoicmF3LmdpdGh1YnVzZXJjb250ZW50LmNvbSIsImtleSI6ImtleTUiLCJleHAiOjE3MzYwMjUzOTcsIm5iZiI6MTczNjAyNTA5NywicGF0aCI6Ii8xMTMyODY5MDMvNDAwMTY1MDkwLTYzMTliMWZkLTY0ODEtNDg3OS1hNjUzLWYxNmZkYzVlNjY2MC5qcGc_WC1BbXotQWxnb3JpdGhtPUFXUzQtSE1BQy1TSEEyNTYmWC1BbXotQ3JlZGVudGlhbD1BS0lBVkNPRFlMU0E1M1BRSzRaQSUyRjIwMjUwMTA0JTJGdXMtZWFzdC0xJTJGczMlMkZhd3M0X3JlcXVlc3QmWC1BbXotRGF0ZT0yMDI1MDEwNFQyMTExMzdaJlgtQW16LUV4cGlyZXM9MzAwJlgtQW16LVNpZ25hdHVyZT1lYjg5M2VkMzBlNDBkNzM4ZmIxYTAwODEwMTIzYWE3YTE4MTM2NDJiZTRkMzc2NjU5ZDYyNTcwMTZiZDk4NWU1JlgtQW16LVNpZ25lZEhlYWRlcnM9aG9zdCJ9.-SyQApj4qUAqG_SABdIPd9qPxf5ITvMiwzccACvA6FM)

Random lucky popup
![Random Lucku Popup][https://private-user-images.githubusercontent.com/113286903/400165068-b8d0c7e8-0e52-4c4d-986e-252a3ff6cc18.jpg?jwt=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJnaXRodWIuY29tIiwiYXVkIjoicmF3LmdpdGh1YnVzZXJjb250ZW50LmNvbSIsImtleSI6ImtleTUiLCJleHAiOjE3MzYwMjUzOTcsIm5iZiI6MTczNjAyNTA5NywicGF0aCI6Ii8xMTMyODY5MDMvNDAwMTY1MDY4LWI4ZDBjN2U4LTBlNTItNGM0ZC05ODZlLTI1MmEzZmY2Y2MxOC5qcGc_WC1BbXotQWxnb3JpdGhtPUFXUzQtSE1BQy1TSEEyNTYmWC1BbXotQ3JlZGVudGlhbD1BS0lBVkNPRFlMU0E1M1BRSzRaQSUyRjIwMjUwMTA0JTJGdXMtZWFzdC0xJTJGczMlMkZhd3M0X3JlcXVlc3QmWC1BbXotRGF0ZT0yMDI1MDEwNFQyMTExMzdaJlgtQW16LUV4cGlyZXM9MzAwJlgtQW16LVNpZ25hdHVyZT0yNzNlMDYxMzkzNTQ1N2E3ZjMzOTYxYTNiZWFlZTYxODgxOTRiNzBmZGE3Y2RlMDczNTZlMGVkZGVmZDU2ZDgwJlgtQW16LVNpZ25lZEhlYWRlcnM9aG9zdCJ9.G-wHNgAZBVNGyzOdLdtdgUmGregH9cnYxeoKnGLLoQ0]

## Video Preview

![Achievement Get][https://private-user-images.githubusercontent.com/113286903/400165045-f5b07484-a700-47ee-97a7-5d13e9d4ebcf.gif?jwt=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJnaXRodWIuY29tIiwiYXVkIjoicmF3LmdpdGh1YnVzZXJjb250ZW50LmNvbSIsImtleSI6ImtleTUiLCJleHAiOjE3MzYwMjUzOTcsIm5iZiI6MTczNjAyNTA5NywicGF0aCI6Ii8xMTMyODY5MDMvNDAwMTY1MDQ1LWY1YjA3NDg0LWE3MDAtNDdlZS05N2E3LTVkMTNlOWQ0ZWJjZi5naWY_WC1BbXotQWxnb3JpdGhtPUFXUzQtSE1BQy1TSEEyNTYmWC1BbXotQ3JlZGVudGlhbD1BS0lBVkNPRFlMU0E1M1BRSzRaQSUyRjIwMjUwMTA0JTJGdXMtZWFzdC0xJTJGczMlMkZhd3M0X3JlcXVlc3QmWC1BbXotRGF0ZT0yMDI1MDEwNFQyMTExMzdaJlgtQW16LUV4cGlyZXM9MzAwJlgtQW16LVNpZ25hdHVyZT0yYzI0ZjdkMWYzY2QyZjUwNzVhNzQ1NWZkZDJkMzdmYjA0MzAzYzBlNzIxNzc3MDA4MTFhNDE5Zjg5ZmFjYWI4JlgtQW16LVNpZ25lZEhlYWRlcnM9aG9zdCJ9.nD-0UujdZyx72u6geeIsLrc-Gg0HOXRou_y-kh89Il8]

## Installation & Usage

1. Install via your preferred plugin manager (e.g., `lazy.nvim`, `packer.nvim`, etc.).  
2. Require as needed (e.g., `require('gamify')`). Configuration is not available yet.
3. Start coding! Achievements will unlock automatically, and popups will appear.  

## License
Licensed under the [Apache License 2.0](LICENSE).
