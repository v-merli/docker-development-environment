package main

import (
	"fmt"
	"os"
	"strings"
	"time"

	"github.com/AlecAivazis/survey/v2"
	"github.com/briandowns/spinner"
	tea "github.com/charmbracelet/bubbletea"
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

var rootCmd = &cobra.Command{
	Use:   "phpharbor",
	Short: "PHPHarbor - Docker development environment",
	Long:  `PHPHarbor is a Docker-based local development environment for PHP projects.`,
	PersistentPreRun: func(cmd *cobra.Command, args []string) {
		// Skip banner for completion command
		if cmd.Name() != "completion" && cmd.Name() != "help" {
			printBanner()
		}
	},
}

var createCmd = &cobra.Command{
	Use:   "create [name]",
	Short: "Create a new project",
	Long:  `Create a new PHP project with interactive configuration`,
	Run: func(cmd *cobra.Command, args []string) {
		interactive, _ := cmd.Flags().GetBool("interactive")

		var name string
		var projectType string
		var phpVersion string

		// If name provided via args, use it
		if len(args) > 0 {
			name = args[0]
		}

		// Interactive mode or missing required flags
		if interactive || name == "" {
			createInteractive(&name, &projectType, &phpVersion)
		} else {
			projectType, _ = cmd.Flags().GetString("type")
			phpVersion, _ = cmd.Flags().GetString("php")
		}

		// Create project (simulated)
		createProject(name, projectType, phpVersion)
	},
}

var listCmd = &cobra.Command{
	Use:   "list",
	Short: "List all projects",
	Run: func(cmd *cobra.Command, args []string) {
		// Mock data - in real implementation would read from projects directory
		projects := []struct {
			name  string
			ptype string
			php   string
			state string
			icon  string
		}{
			{"laravel-1", "Laravel", "8.3", "running", "🟢"},
			{"laravel-2", "Laravel", "8.5", "stopped", "🔴"},
			{"wordpress-site", "WordPress", "8.2", "running", "🟢"},
		}

		fmt.Println(cyan("📦 Available Projects"))
		fmt.Println()

		// Table header
		fmt.Printf("  %s  %-20s %-12s %-6s %s\n",
			cyan("●"),
			cyan("NAME"),
			cyan("TYPE"),
			cyan("PHP"),
			cyan("STATUS"))
		fmt.Println("  " + cyan("─────────────────────────────────────────────────"))

		// Table rows
		for _, p := range projects {
			statusColor := red
			if p.state == "running" {
				statusColor = green
			}

			fmt.Printf("  %s  %-20s %-12s %-6s %s\n",
				p.icon,
				p.name,
				magenta(p.ptype),
				yellow(p.php),
				statusColor(p.state))
		}

		fmt.Println()
		fmt.Println(yellow("💡 Tip: Use 'phpharbor start <name>' to start a project"))
	},
}

var startCmd = &cobra.Command{
	Use:   "start [name]",
	Short: "Start a project",
	Args:  cobra.MinimumNArgs(1),
	Run: func(cmd *cobra.Command, args []string) {
		name := args[0]

		fmt.Println(blue(fmt.Sprintf("🚀 Starting project: %s", name)))
		fmt.Println()

		// Simulated operations with spinner
		operations := []string{
			"Building Docker images",
			"Starting containers",
			"Configuring network",
			"Generating SSL certificates",
		}

		for _, op := range operations {
			s := spinner.New(spinner.CharSets[14], 100*time.Millisecond)
			s.Suffix = fmt.Sprintf("  %s...", op)
			s.Color("cyan")
			s.Start()

			// Simulate work
			time.Sleep(800 * time.Millisecond)

			s.Stop()
			fmt.Printf("  %s %s\n", green("✓"), op)
		}

		fmt.Println()
		fmt.Println(green("✅ Project started successfully!"))
		fmt.Println()
		fmt.Printf("  🌐 URL: %s\n", cyan(fmt.Sprintf("https://%s.test:8443", name)))
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

var wizardCmd = &cobra.Command{
	Use:   "wizard",
	Short: "Interactive project creation wizard",
	Long:  `Launch an interactive wizard to create a new project with guided steps`,
	Run: func(cmd *cobra.Command, args []string) {
		wizard := newCreateProjectWizard()
		p := tea.NewProgram(wizard)
		finalModel, err := p.Run()
		if err != nil {
			fmt.Fprintln(os.Stderr, red("Error running wizard: "+err.Error()))
			os.Exit(1)
		}

		// Check if completed
		if w, ok := finalModel.(wizardModel); ok {
			if w.WasCompleted() {
				answers := w.GetAnswers()
				fmt.Println()
				fmt.Println(green("✅ Project configuration saved!"))
				fmt.Println()
				fmt.Println("You configured:")
				for k, v := range answers {
					fmt.Printf("  %s: %s\n", k, cyan(v))
				}
				fmt.Println()
				fmt.Println(yellow("💡 Next: Run project creation with these settings"))
			} else if w.WasCancelled() {
				fmt.Println(yellow("⚠️  Wizard cancelled"))
			}
		}
	},
}

var statsTableCmd = &cobra.Command{
	Use:   "stats-table",
	Short: "Show system statistics in table format",
	Long:  `Display PHPHarbor disk usage statistics in an interactive table`,
	Run: func(cmd *cobra.Command, args []string) {
		table := newStatsTable()
		p := tea.NewProgram(table)
		if _, err := p.Run(); err != nil {
			fmt.Fprintln(os.Stderr, red("Error displaying stats: "+err.Error()))
			os.Exit(1)
		}
	},
}

var projectsTableCmd = &cobra.Command{
	Use:   "projects-table",
	Short: "Show projects in table format",
	Long:  `Display all PHPHarbor projects in an interactive table`,
	Run: func(cmd *cobra.Command, args []string) {
		table := newProjectsTable()
		p := tea.NewProgram(table)
		if _, err := p.Run(); err != nil {
			fmt.Fprintln(os.Stderr, red("Error displaying projects: "+err.Error()))
			os.Exit(1)
		}
	},
}

var statsOverviewCmd = &cobra.Command{
	Use:   "stats-overview",
	Short: "Show system overview",
	Long:  `Display PHPHarbor system overview with resource statistics`,
	Run: func(cmd *cobra.Command, args []string) {
		overview := newStatsOverview()
		p := tea.NewProgram(overview)
		if _, err := p.Run(); err != nil {
			fmt.Fprintln(os.Stderr, red("Error displaying overview: "+err.Error()))
			os.Exit(1)
		}
	},
}

// Interactive project creation
func createInteractive(name *string, projectType *string, phpVersion *string) {
	fmt.Println(cyan("🎨 Interactive Project Creation"))
	fmt.Println()

	// Project name
	if *name == "" {
		namePrompt := &survey.Input{
			Message: "Project name:",
			Help:    "Use lowercase letters, numbers, and hyphens only",
		}
		survey.AskOne(namePrompt, name, survey.WithValidator(survey.Required))
	}

	// Project type selection with descriptions
	typePrompt := &survey.Select{
		Message: "Choose project type:",
		Options: []string{
			"Laravel - Modern PHP framework",
			"WordPress - CMS platform",
			"PHP - Generic PHP application",
			"HTML - Static website",
		},
	}
	var typeChoice string
	err := survey.AskOne(typePrompt, &typeChoice)
	if err != nil || typeChoice == "" {
		fmt.Println(yellow("❌ Creation cancelled"))
		return
	}

	// Extract just the type name
	switch {
	case strings.HasPrefix(typeChoice, "Laravel"):
		*projectType = "laravel"
	case strings.HasPrefix(typeChoice, "WordPress"):
		*projectType = "wordpress"
	case strings.HasPrefix(typeChoice, "PHP"):
		*projectType = "php"
	case strings.HasPrefix(typeChoice, "HTML"):
		*projectType = "html"
	}

	// PHP version selection (if not HTML)
	if *projectType != "html" {
		versionPrompt := &survey.Select{
			Message: "Choose PHP version:",
			Options: []string{"8.5 (latest)", "8.4", "8.3 (LTS)", "8.2", "8.1", "7.4 (legacy)"},
			Default: "8.3 (LTS)",
		}
		var versionChoice string
		err := survey.AskOne(versionPrompt, &versionChoice)
		if err != nil || versionChoice == "" {
			fmt.Println(yellow("❌ Creation cancelled"))
			return
		}

		// Extract version number (first 3 chars)
		if len(versionChoice) >= 3 {
			*phpVersion = versionChoice[:3]
		}
	}

	// Confirmation
	fmt.Println()
	fmt.Println(yellow("📋 Configuration Summary:"))
	fmt.Printf("  Name: %s\n", cyan(*name))
	fmt.Printf("  Type: %s\n", cyan(*projectType))
	if *phpVersion != "" {
		fmt.Printf("  PHP:  %s\n", cyan(*phpVersion))
	}
	fmt.Println()

	confirm := false
	confirmPrompt := &survey.Confirm{
		Message: "Proceed with creation?",
		Default: true,
	}
	survey.AskOne(confirmPrompt, &confirm)

	if !confirm {
		fmt.Println(yellow("❌ Creation cancelled"))
		os.Exit(0)
	}
}

// Simulated project creation
func createProject(name, projectType, phpVersion string) {
	fmt.Println()
	fmt.Println(blue("🔨 Creating project..."))
	fmt.Println()

	steps := []string{
		"Creating project directory",
		"Generating docker-compose.yml",
		"Creating .env configuration",
		"Setting up nginx config",
		"Initializing project files",
		"Generating SSL certificate",
	}

	for _, step := range steps {
		s := spinner.New(spinner.CharSets[14], 100*time.Millisecond)
		s.Suffix = fmt.Sprintf("  %s...", step)
		s.Color("cyan")
		s.Start()

		time.Sleep(600 * time.Millisecond)

		s.Stop()
		fmt.Printf("  %s %s\n", green("✓"), step)
	}

	fmt.Println()
	fmt.Println(green("✅ Project created successfully!"))
	fmt.Println()
	fmt.Printf("  📁 Directory: %s\n", cyan("projects/"+name))
	fmt.Printf("  🌐 Domain:    %s\n", cyan(name+".test"))
	fmt.Println()
	fmt.Println(yellow("Next steps:"))
	fmt.Printf("  1. cd projects/%s/app\n", name)
	fmt.Println("  2. phpharbor start " + name)
	fmt.Printf("  3. open https://%s.test:8443\n", name)
	fmt.Println()
}

func init() {
	// Create command flags
	createCmd.Flags().StringP("type", "t", "", "Project type (laravel/wordpress/php/html)")
	createCmd.Flags().String("php", "", "PHP version (7.3, 7.4, 8.1, 8.2, 8.3, 8.4, 8.5)")
	createCmd.Flags().BoolP("interactive", "i", false, "Use interactive wizard")

	// Add commands
	rootCmd.AddCommand(createCmd)
	rootCmd.AddCommand(listCmd)
	rootCmd.AddCommand(startCmd)
	rootCmd.AddCommand(versionCmd)
	rootCmd.AddCommand(tuiCmd)
	rootCmd.AddCommand(wizardCmd)
	rootCmd.AddCommand(statsTableCmd)
	rootCmd.AddCommand(projectsTableCmd)
	rootCmd.AddCommand(statsOverviewCmd)
}

func main() {
	if err := rootCmd.Execute(); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}
