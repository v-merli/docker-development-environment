package main

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"

	"github.com/fatih/color"
	"github.com/spf13/cobra"
)

var (
	version = "0.1.0-go-experiment"

	// Colors
	green   = color.New(color.FgGreen).SprintFunc()
	red     = color.New(color.FgRed).SprintFunc()
	cyan    = color.New(color.FgCyan, color.Bold).SprintFunc()
	yellow  = color.New(color.FgYellow).SprintFunc()
	blue    = color.New(color.FgBlue, color.Bold).SprintFunc()
	magenta = color.New(color.FgMagenta, color.Bold).SprintFunc()
)

func printBanner() {
	banner := `
    ____  __  ______  __  __           __              
   / __ \/ / / / __ \/ / / /___ ______/ /_  ____  _____
  / /_/ / /_/ / /_/ / /_/ / __ '/ ___/ __ \/ __ \/ ___/
 / ____/ __  / ____/ __  / /_/ / /  / /_/ / /_/ / /    
/_/   /_/ /_/_/   /_/ /_/\__,_/_/  /_.___/\____/_/     
`
	fmt.Println(cyan(banner))
	fmt.Printf("  %s  %s\n", magenta("Docker Development Environment"), yellow("v"+version))
	fmt.Println()
}

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

	// Find phpharbor script by searching up the directory tree
	bashScriptPath := ""
	searchDir := baseDir
	for i := 0; i < 5; i++ { // Search up to 5 levels
		candidatePath := filepath.Join(searchDir, "phpharbor")
		if _, err := os.Stat(candidatePath); err == nil {
			bashScriptPath = candidatePath
			break
		}
		searchDir = filepath.Dir(searchDir)
	}

	if bashScriptPath == "" {
		return fmt.Errorf("phpharbor script not found (searched from %s)", baseDir)
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

var rootCmd = &cobra.Command{
	Use:   "phpharbor",
	Short: "PHPHarbor - Docker development environment",
	Long:  `PHPHarbor is a Docker-based local development environment for PHP projects.`,
	PersistentPreRun: func(cmd *cobra.Command, args []string) {
		// Skip banner for completion command, help, or when called from TUI
		if cmd.Name() != "completion" && cmd.Name() != "help" && os.Getenv("PHPHARBOR_NO_BANNER") != "1" {
			printBanner()
		}
	},
}

var createCmd = &cobra.Command{
	Use:   "create [name]",
	Short: "Create a new project",
	Long:  `Create a new PHP project with interactive configuration`,
	Run: func(cmd *cobra.Command, args []string) {
		// Delegate to bash script - it handles interactivity
		if err := executeBashScript("create", args...); err != nil {
			fmt.Fprintln(os.Stderr, red("Error: "+err.Error()))
			os.Exit(1)
		}
	},
}

var listCmd = &cobra.Command{
	Use:   "list",
	Short: "List all projects",
	Run: func(cmd *cobra.Command, args []string) {
		// Delegate to bash script
		if err := executeBashScript("list"); err != nil {
			fmt.Fprintln(os.Stderr, red("Error: "+err.Error()))
			os.Exit(1)
		}
	},
}

var startCmd = &cobra.Command{
	Use:   "start [name]",
	Short: "Start a project",
	Args:  cobra.MinimumNArgs(1),
	Run: func(cmd *cobra.Command, args []string) {
		// Delegate to bash script
		if err := executeBashScript("start", args...); err != nil {
			fmt.Fprintln(os.Stderr, red("Error: "+err.Error()))
			os.Exit(1)
		}
	},
}

var versionCmd = &cobra.Command{
	Use:   "version",
	Short: "Show version",
	Run: func(cmd *cobra.Command, args []string) {
		fmt.Printf("%s %s\n", blue("PHPHarbor"), yellow("v"+version))
		fmt.Println()
		fmt.Println("  Platform: Go CLI (Experimental)")
		fmt.Println("  Build: Compiled binary")
	},
}

var tuiCmd = &cobra.Command{
	Use:   "tui",
	Short: "Launch interactive TUI interface",
	Long:  `Launch a fullscreen terminal user interface for managing projects`,
	Run: func(cmd *cobra.Command, args []string) {
		if err := RunTUI(); err != nil {
			fmt.Fprintln(os.Stderr, red("Error running TUI: "+err.Error()))
			os.Exit(1)
		}
	},
}

func init() {
	// Add commands
	rootCmd.AddCommand(createCmd)
	rootCmd.AddCommand(listCmd)
	rootCmd.AddCommand(startCmd)
	rootCmd.AddCommand(versionCmd)
	rootCmd.AddCommand(tuiCmd)
}

func main() {
	// If no arguments provided, launch TUI by default
	if len(os.Args) == 1 {
		if err := RunTUI(); err != nil {
			fmt.Fprintln(os.Stderr, "Error running TUI:", err)
			os.Exit(1)
		}
		return
	}

	// If arguments provided, use Cobra CLI (for now, could delegate to bash later)
	if err := rootCmd.Execute(); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}
