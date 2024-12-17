# gamify-nvim



# ToDo
Here are additional ideas and enhancements to make your **Neovim gamification plugin** more engaging and rewarding for users:

---

## **Features and Ideas**

### **1. Achievements (Detailed List)**  
Expand on the achievements you’ve started. Add unique and fun challenges:

| **Achievement**        | **Condition**                                                                 | **Reward**              |
|------------------------|------------------------------------------------------------------------------|-------------------------|
| Jack of Many           | Write 1000 lines with files containing at least 5 lines each.               | +500 XP                 |
| Polyglot               | Write 1000 lines across 10 different programming languages.                 | +1000 XP                |
| Night Owl              | Code between 12 AM - 3 AM for 5 consecutive days.                           | +300 XP                 |
| Early Bird             | Code between 6 AM - 8 AM for 5 consecutive days.                            | +300 XP                 |
| Marathon Coder         | Code continuously for 4 hours without closing Neovim.                       | +500 XP                 |
| Sprint Coder           | Write 200 lines in under 30 minutes.                                        | +500 XP                 |
| First Commit           | Save or write code in a file for the first time.                            | +100 XP                 |
| Speed Debugger         | Fix 20 errors (tracked through LSP diagnostics).                            | +400 XP                 |
| Neovim Veteran         | Use Neovim for 100 total hours.                                             | +1500 XP                |
| VIM Enthusiast         | Open Neovim 7 days in a row.                                                | +200 XP                 |
| Refactor Master        | Refactor 50 functions across different files (LSP rename, edits, etc.).     | +500 XP                 |

#### Achievement Popups  
- Use **nvim-notify** or a floating window with a "Minecraft-like" achievement message:  
  `🎉 Achievement Unlocked: "Marathon Coder" 🎉`  

---

### **2. Daily Goals**
Add customizable **daily goals** for users to complete.  

| **Goal Type**         | **Examples**                                     | **Mechanics**                     |
|-----------------------|--------------------------------------------------|----------------------------------|
| Line-based            | Write 200+ lines of code in a day.               | Tracks written lines per day.     |
| Language-specific     | Write at least 50 lines in Lua.                  | Ties into filetype tracking.      |
| Error Fixing          | Fix 5+ LSP errors or diagnostics.                | Tied to `vim.diagnostic`.         |
| Time-based            | Code for at least 2 hours today.                 | Tracks active time in Neovim.     |
| Refactoring Goals     | Refactor 10+ functions or variables.             | Count LSP rename actions.         |

- Use a **floating dashboard window** to show progress for the day:  
   ```
   🎯 Daily Goals
   - Write 200 lines: 150/200
   - Fix 5 errors: 5/5 ✅
   ```

---

### **3. Leaderboards**
Track and display global/local leaderboards.  
1. **Local Leaderboard:** Display user-specific stats:
   - Total XP, achievements unlocked, and coding time.
   - Files edited per language.
2. **Global Leaderboard (Optional):** Allow opt-in to share stats to a server for comparison. (Maybe some export to MD into clipboard will be done)

---

### **4. Streak System**
Introduce a streak system to encourage daily usage:  
- **Daily Coding Streak**: Award XP for maintaining streaks.  
  Example:  
   - 3 days: +100 XP  
   - 7 days: +300 XP  
   - 30 days: +1000 XP  

Show a **streak reminder** on Neovim startup:  
```  
🔥 Streak: 7 Days! Keep going for +300 XP tomorrow! 🔥  
```

---

### **5. Stats Dashboard**
Provide a detailed "Stats" screen that tracks:  
- Total lines written.  
- XP progress and level-up thresholds.  
- Lines per programming language.  
- Top 5 most productive days.  
- Total Neovim usage time.

---

### **6. XP and Level Progression**
Introduce a leveling system based on XP:  
- Start at Level 1 and increase levels as XP is earned.  
- Customize XP thresholds per level (e.g., Level 2 at 500 XP, Level 3 at 1000 XP).  
- Display progress:  
   ```
   Level 3 (XP: 1100/1500) 🟩🟩🟩⬜⬜⬜
   ```

---

### **7. Customizable Themes**
Add **"Gamify Themes"** to customize achievement popups or XP progress bars with styles. Allow users to:  
- Choose different colors.  
- Add emojis (e.g., 🎮, 🏆, 🔥).  
- Personalize XP notifications.

---

### **8. Sounds and Visual Effects**
- Play a subtle sound or show a quick animation when XP is earned or an achievement is unlocked.  
  - Use tools like `vim.ui` for notifications.  
  - Optional plugin dependencies for sound support.

---

### **9. Challenges** (optional)
Create **weekly/monthly challenges**:  
- Write X lines of code this week.  
- Fix 50 errors in the next 7 days.

Users can "opt in" to challenges, and completion rewards additional XP or achievements.

---

### **10. Fun Random XP Bonuses**
Occasionally give "random events" to gamify surprises:  
- **"Lucky XP"**: "You found a hidden XP chest: +50 XP 🎁"  
- **"Trivia"**: Show coding-related trivia and award XP for correct answers.  

---

## **To-Do Updates**  
- [x] Save data to JSON and add XP.  
- [x] XP for daily log.  
- [ ] **Achievements**:  
   - [ ] Jack of Many (1000 lines for 5+ line files).  
   - [ ] Polyglot (1000 lines in 10 languages).  
   - [ ] Minecraft-style achievement popups.  
   - [ ] Night Owl / Early Bird.  
- [ ] **Stats Dashboard**: Show written lines per language, XP, streaks.  
- [ ] **Daily Goals**: Set and track custom daily goals.  
- [ ] **Streak System**: Track consecutive coding days.  
- [ ] **Random XP Events**: Fun rewards for engagement.  

