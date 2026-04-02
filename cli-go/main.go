package main

import (
	"fmt"
	"os"

	"github.com/fatih/color"
	"github.com/spf13/cobra"
)

var (
	version = "0.1.0-go-experiment"
	
	// Colors
	green  = color.New(color.FgGreen).SprintFunc()
	cyan   = color.New(color.FgCyan, color.Bold).SprintFunc()
	yellow = color.New(color.FgYellow).SprintFunc()
)

var rootCmd = &cobra.Command{
	Use:   "phpharbor",
	Short: "PHPHarbor - Docker development environment",
	Long:  `PHPHarbor is a Docker-based local development environment for PHP projects.`,
}

var createCmd = &cobra.Command{
	Use:   "create [name]",
	Short: "Create a new project",
	Args:  cobra.ExactArgs(1),
	Run: func(cmd *cobra.Command, args []string) {
		name := args[0]
		projectType, _ := cmd.Flags().GetString("type")
		phpVersion, _ := cmd.Flags().GetString("php")
		
		fmt.Println(green("Creating project..."))
		fmt.Printf("Name: %s\n", name)
		if projectType != "" {
			fmt.Printf("Type: %s\n", projectType)
		}
		if phpVersion != "" {
			fmt.Printf("PHP: %s\n", phpVersion)
		}
		// TODO: Implement project creation
	},
}

var listCmd = &cobra.Command{
	Use:   "list",
	Short: "List all projects",
	Run: func(cmd *cobra.Command, args []string) {
		fmt.Println(cyan("Available Projects"))
		fmt.Println("───────────────────────────────────────")
		// TODO: Implement project listing
		fmt.Println("  • laravel-1 (running)")
		fmt.Println("  • laravel-2 (stopped)")
	},
}

var startCmd = &cobra.Command{
	Use:   "start [name]",
	Short: "Start a project",
	Args:  cobra.ExactArgs(1),
	Run: func(cmd *cobra.Command, args []string) {
		name := args[0]
		fmt.Println(green(fmt.Sprintf("Starting project: %s", name)))
		// TODO: Implement project start
	},
}

var versionCmd = &cobra.Command{
	Use:   "version",
	Short: "Show version",
	Run: func(cmd *cobra.Command, args []string) {
		fmt.Printf("PHPHarbor v%s\n", version)
	},
}

func init() {
	// Create command flags
	createCmd.Flags().StringP("type", "t", "", "Project type (laravel/wordpress/php/html)")
	createCmd.Flags().String("php", "", "PHP version (7.3, 7.4, 8.1, 8.2, 8.3, 8.4, 8.5)")
	
	// Add commands
	rootCmd.AddCommand(createCmd)
	rootCmd.AddCommand(listCmd)
	rootCmd.AddCommand(startCmd)
	rootCmd.AddCommand(versionCmd)
}

func main() {
	if err := rootCmd.Execute(); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}
