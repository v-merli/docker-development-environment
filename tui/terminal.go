package main

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"strings"
)

// terminalType represents the detected terminal emulator
type terminalType string

const (
	terminalVSCode      terminalType = "vscode"
	terminalITerm2      terminalType = "iterm2"
	terminalApple       terminalType = "apple-terminal"
	terminalGnome       terminalType = "gnome-terminal"
	terminalKonsole     terminalType = "konsole"
	terminalWindowsTerm terminalType = "windows-terminal"
	terminalUnknown     terminalType = "unknown"
)

// detectTerminal detects the current terminal emulator
func detectTerminal() terminalType {
	// Check VS Code first (works cross-platform)
	if os.Getenv("TERM_PROGRAM") == "vscode" {
		return terminalVSCode
	}

	// macOS terminals
	if runtime.GOOS == "darwin" {
		termProgram := os.Getenv("TERM_PROGRAM")
		if termProgram == "iTerm.app" {
			return terminalITerm2
		}
		if termProgram == "Apple_Terminal" {
			return terminalApple
		}
	}

	// Linux terminals
	if runtime.GOOS == "linux" {
		if os.Getenv("GNOME_TERMINAL_SERVICE") != "" {
			return terminalGnome
		}
		if os.Getenv("KONSOLE_VERSION") != "" {
			return terminalKonsole
		}
	}

	// Windows
	if runtime.GOOS == "windows" {
		if os.Getenv("WT_SESSION") != "" {
			return terminalWindowsTerm
		}
	}

	return terminalUnknown
}

// openCommandInNewTab opens a PHPHarbor command in a new terminal tab
// Returns true if successful, false if fallback should be shown
func openCommandInNewTab(command string, args ...string) (bool, error) {
	// Find phpharbor bash script
	bashScriptPath, err := findPHPHarborScript()
	if err != nil {
		return false, err
	}

	// Build the full command to execute
	fullCommand := fmt.Sprintf("cd %s && ./phpharbor %s %s",
		filepath.Dir(bashScriptPath),
		command,
		strings.Join(args, " "))

	terminal := detectTerminal()

	switch terminal {
	case terminalVSCode:
		return openInVSCode(fullCommand)
	case terminalITerm2:
		return openInITerm2(fullCommand)
	case terminalApple:
		return openInAppleTerminal(fullCommand)
	case terminalGnome:
		return openInGnomeTerminal(fullCommand)
	case terminalKonsole:
		return openInKonsole(fullCommand)
	case terminalWindowsTerm:
		return openInWindowsTerminal(fullCommand)
	default:
		return false, fmt.Errorf("unsupported terminal: %s", terminal)
	}
}

// findPHPHarborScript finds the main phpharbor bash script
func findPHPHarborScript() (string, error) {
	execPath, err := os.Executable()
	if err != nil {
		return "", fmt.Errorf("failed to get executable path: %w", err)
	}
	execPath, err = filepath.EvalSymlinks(execPath)
	if err != nil {
		return "", fmt.Errorf("failed to resolve symlinks: %w", err)
	}
	baseDir := filepath.Dir(execPath)

	// Search up the directory tree
	searchDir := filepath.Dir(baseDir)
	for i := 0; i < 5; i++ {
		candidatePath := filepath.Join(searchDir, "phpharbor")
		if stat, err := os.Stat(candidatePath); err == nil {
			absCandidate, _ := filepath.Abs(candidatePath)
			absExec, _ := filepath.Abs(execPath)
			if absCandidate != absExec && stat.Mode()&0111 != 0 {
				return candidatePath, nil
			}
		}
		searchDir = filepath.Dir(searchDir)
	}

	return "", fmt.Errorf("phpharbor bash script not found")
}

// openInVSCode opens command in VS Code integrated terminal
func openInVSCode(command string) (bool, error) {
	// VS Code doesn't provide a simple way to open new terminal with command from CLI
	// User can easily open new terminal with Cmd+Shift+` (macOS) or Ctrl+Shift+` (Windows/Linux)
	// Return false to show user-friendly fallback with VS Code-specific instructions
	return false, fmt.Errorf("VS Code: please open new terminal manually with Cmd+Shift+` (macOS) or Ctrl+Shift+` (Windows/Linux)")
}

// openInITerm2 opens command in iTerm2 new tab (macOS)
func openInITerm2(command string) (bool, error) {
	script := fmt.Sprintf(`
tell application "iTerm"
	tell current window
		create tab with default profile
		tell current session
			write text "%s"
		end tell
	end tell
end tell
`, escapeAppleScript(command))

	cmd := exec.Command("osascript", "-e", script)
	if err := cmd.Run(); err != nil {
		return false, fmt.Errorf("failed to open iTerm2 tab: %w", err)
	}
	return true, nil
}

// openInAppleTerminal opens command in Terminal.app new tab (macOS)
func openInAppleTerminal(command string) (bool, error) {
	script := fmt.Sprintf(`
tell application "Terminal"
	activate
	tell application "System Events" to keystroke "t" using command down
	delay 0.5
	do script "%s" in selected tab of front window
end tell
`, escapeAppleScript(command))

	cmd := exec.Command("osascript", "-e", script)
	if err := cmd.Run(); err != nil {
		return false, fmt.Errorf("failed to open Terminal.app tab: %w", err)
	}
	return true, nil
}

// openInGnomeTerminal opens command in GNOME Terminal new tab (Linux)
func openInGnomeTerminal(command string) (bool, error) {
	cmd := exec.Command("gnome-terminal", "--tab", "--", "bash", "-c", command+"; exec bash")
	if err := cmd.Start(); err != nil {
		return false, fmt.Errorf("failed to open gnome-terminal tab: %w", err)
	}
	return true, nil
}

// openInKonsole opens command in Konsole new tab (Linux/KDE)
func openInKonsole(command string) (bool, error) {
	cmd := exec.Command("konsole", "--new-tab", "-e", "bash", "-c", command+"; exec bash")
	if err := cmd.Start(); err != nil {
		return false, fmt.Errorf("failed to open konsole tab: %w", err)
	}
	return true, nil
}

// openInWindowsTerminal opens command in Windows Terminal new tab
func openInWindowsTerminal(command string) (bool, error) {
	// Windows Terminal command: wt -w 0 nt
	cmd := exec.Command("wt.exe", "-w", "0", "nt", "cmd", "/c", command)
	if err := cmd.Start(); err != nil {
		return false, fmt.Errorf("failed to open Windows Terminal tab: %w", err)
	}
	return true, nil
}

// escapeAppleScript escapes a string for use in AppleScript
func escapeAppleScript(s string) string {
	s = strings.ReplaceAll(s, "\\", "\\\\")
	s = strings.ReplaceAll(s, "\"", "\\\"")
	return s
}

// buildFallbackMessage creates a user-friendly message when auto-opening fails
func buildFallbackMessage(command string, args []string) string {
	bashScriptPath, _ := findPHPHarborScript()
	projectRoot := filepath.Dir(bashScriptPath)
	
	fullCmd := fmt.Sprintf("cd %s && ./phpharbor %s %s",
		projectRoot,
		command,
		strings.Join(args, " "))

	// Detect terminal for specific instructions
	terminal := detectTerminal()
	var instructions string
	
	switch terminal {
	case terminalVSCode:
		instructions = `
💡 VS Code Instructions:
   1. Press Cmd+Shift+` + "`" + ` (macOS) or Ctrl+Shift+` + "`" + ` (Windows/Linux) to open new terminal
   2. Paste the command above
   3. Press Enter
`
	case terminalITerm2, terminalApple:
		instructions = `
💡 macOS Instructions:
   1. Press Cmd+T to open new terminal tab
   2. Paste the command above
   3. Press Enter
`
	case terminalGnome, terminalKonsole:
		instructions = `
💡 Linux Instructions:
   1. Press Ctrl+Shift+T to open new terminal tab
   2. Paste the command above
   3. Press Enter
`
	default:
		instructions = `
💡 Instructions:
   1. Open a new terminal tab
   2. Paste the command above
   3. Press Enter
`
	}

	return fmt.Sprintf(`⚠️  Could not auto-open new terminal tab

Command to run:

  %s
%s`, fullCmd, instructions)
}
