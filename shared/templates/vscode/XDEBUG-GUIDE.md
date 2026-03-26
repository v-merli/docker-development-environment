# Xdebug Test Guide with VS Code

## ✅ Configuration Completed

- **Xdebug installed**: v3.5.1
- **Port**: 9003
- **Host**: host.docker.internal
- **VS Code launch.json**: Configured
- **Test route**: /xdebug-test

---

## 🧪 How to Test Xdebug

### Step 1: Install the PHP Debug Extension in VS Code
1. Open VS Code
2. Go to Extensions (Cmd+Shift+X)
3. Search for "PHP Debug" by **Xdebug**
4. Install the extension

### Step 2: Open the Project in VS Code
```bash
cd /path/to/your/project/app
code .
```

### Step 3: Set Breakpoints
1. Open the file: `routes/xdebug-test.php`
2. Click on the left margin of lines 7 and 25 to set breakpoints (red dot)

### Step 4: Start the Debug Listener
1. In VS Code, go to "Run and Debug" (Cmd+Shift+D)
2. Select "Listen for Xdebug (PHPHarbor)" from the dropdown menu
3. Click the green "Start Debugging" button (F5)
4. You should see "Xdebug: Listening on port 9003" in the Debug Console

### Step 5: Make a Request with Xdebug Trigger
In your browser, open one of these URLs:

**Option A - With query parameter:**
```
http://your-project.test:8080/xdebug-test?XDEBUG_TRIGGER=1
```

**Option B - With cookie (more convenient):**
1. Install the "Xdebug helper" extension for Chrome/Firefox
2. Activate it by clicking the icon and selecting "Debug"
3. Go to: `http://your-project.test:8080/xdebug-test`

### Step 6: Debug!
When the request hits the breakpoint:
- VS Code will stop at that line
- You can see variables in the side panel
- You can "Step Over" (F10), "Step Into" (F11), "Continue" (F5)
- In the Debug Console you'll see variable values

---

## 🎯 Verify It Works

If everything works, you'll see:
1. VS Code stops at the line with the breakpoint
2. The "VARIABLES" panel shows `$message`, `$data`, etc.
3. You can inspect arrays and objects
4. The browser request stays "loading" until you press "Continue"

---

## 🐛 Troubleshooting

### Debug doesn't start?
1. Verify the listener is active (green icon in debug bar)
2. Check the Debug Console for errors
3. Verify port 9003 is not in use: `lsof -i :9003`

### Breakpoints ignored?
1. Verify path mapping is correct in launch.json
2. Make sure to use `?XDEBUG_TRIGGER=1` or the cookie

### Other issues?
Check container logs:
```bash
docker logs your-project-app | grep -i xdebug
```

---

## 📚 Useful Resources

- [VS Code PHP Debugging](https://code.visualstudio.com/docs/languages/php#_debugging)
- [Xdebug Documentation](https://xdebug.org/docs/step_debug)
- [Xdebug Helper Chrome](https://chrome.google.com/webstore/detail/xdebug-helper)
- [Xdebug Helper Firefox](https://addons.mozilla.org/en-US/firefox/addon/xdebug-helper-for-firefox/)

---

## 🎓 Tutorial: Debug a Laravel Request

1. Set a breakpoint in a Controller
2. Open the route in browser with `?XDEBUG_TRIGGER=1`
3. Follow the execution step-by-step
4. Inspect `$request`, models, database queries, etc.

**Happy debugging!** 🐛🔍
