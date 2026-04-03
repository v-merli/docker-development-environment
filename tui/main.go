package main

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
)

// executeBashScript executes the main phpharbor bash script
func executeBashScript(command string, args ...string) error {
	// Get executable directory
	execPath, err := os.Executable()
	if err != nil {
		return fmt.Errorf("failed to get executable path: %w", err)
	}
	execPath, err = filepath.EvalSymlinks(execPath)
	if err != nil {
		return fmt.Errorf("failed to resolve symlinks: %w", err)
	}
	baseDir := filepath.Dir(execPath)

	// Find phpharbor bash script by searching up the directory tree
	// IMPORTANT: Skip the current directory to avoid finding the Go binary itself
	bashScriptPath := ""
	searchDir := filepath.Dir(baseDir) // Start from parent directory
	for i := 0; i < 5; i++ {           // Search up to 5 levels
		candidatePath := filepath.Join(searchDir, "phpharbor")
		// Check if exists and is NOT the same as our binary
		if stat, err := os.Stat(candidatePath); err == nil {
			absCandidate, _ := filepath.Abs(candidatePath)
			absExec, _ := filepath.Abs(execPath)
			// Make sure it's not our binary and it's executable
			if absCandidate != absExec && stat.Mode()&0111 != 0 {
				bashScriptPath = candidatePath
				break
			}
		}
		searchDir = filepath.Dir(searchDir)
	}

	if bashScriptPath == "" {
		return fmt.Errorf("phpharbor bash script not found (searched from %s)", baseDir)
	}

	// Execute the main phpharbor script with command and args
	scriptArgs := append([]string{command}, args...)
	cmd := exec.Command("bash", append([]string{bashScriptPath}, scriptArgs...)...)
	cmd.Dir = filepath.Dir(bashScriptPath) // Run from project root
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	cmd.Stdin = os.Stdin

	return cmd.Run()
}

func main() {
	// Launch TUI - the only entry point
	if err := RunTUI(); err != nil {
		fmt.Fprintln(os.Stderr, "Error running TUI:", err)
		os.Exit(1)
	}
}
