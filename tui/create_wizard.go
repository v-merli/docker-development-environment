package main

import (
	"fmt"
	"strings"

	"github.com/charmbracelet/bubbles/textinput"
	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
)

// createWizardModel is a simplified wizard for project creation
type createWizardModel struct {
	currentStep int
	steps       []wizardStep
	answers     map[string]string
	width       int
	height      int
	completed   bool
	cancelled   bool
	err         string
	reviewMode  bool
}

// newCreateWizard creates a new project creation wizard
func newCreateWizard() createWizardModel {
	steps := []wizardStep{
		{
			id:          "name",
			title:       "Project Name",
			description: "Enter project name (lowercase, numbers, hyphens only)",
			input:       createTextInput("my-project", 40),
			options:     []string{},
			validate:    validateProjectName,
		},
		{
			id:          "type",
			title:       "Project Type",
			description: "Choose one: laravel, wordpress, php, html",
			input:       createTextInput("laravel", 40),
			options:     []string{"laravel", "wordpress", "php", "html"},
			validate:    validateProjectType,
		},
		{
			id:          "php",
			title:       "PHP Version",
			description: "Choose PHP version (skip for html)",
			input:       createTextInput("8.3", 40),
			options:     []string{"8.5", "8.4", "8.3", "8.2", "8.1", "7.4", "7.3", "skip"},
			validate:    validatePHPVersion,
		},
		{
			id:          "node",
			title:       "Node.js Version (Laravel only)",
			description: "Choose Node.js version or 'skip'",
			input:       createTextInput("20", 40),
			options:     []string{"20", "21", "18", "skip"},
			validate:    validateNodeVersion,
		},
		{
			id:          "database",
			title:       "Database Configuration",
			description: "Choose: none, shared, mysql, mariadb",
			input:       createTextInput("mysql", 40),
			options:     []string{"mysql", "mariadb", "shared", "none"},
			validate:    validateDatabaseType,
		},
		{
			id:          "db_version",
			title:       "Database Version",
			description: "Enter version or 'skip' (MySQL: 8.0/8.4/5.7, MariaDB: 11.4/10.11/10.6)",
			input:       createTextInput("8.0", 40),
			options:     []string{"8.0", "8.4", "5.7", "11.4", "10.11", "10.6", "skip"},
			validate:    validateDatabaseVersion,
		},
		{
			id:          "redis",
			title:       "Redis Cache",
			description: "Include dedicated Redis? (yes/no)",
			input:       createTextInput("no", 40),
			options:     []string{"no", "yes"},
			validate:    validateYesNo,
		},
		{
			id:          "ssl",
			title:       "SSL Certificate",
			description: "Generate SSL certificate? (yes/no)",
			input:       createTextInput("yes", 40),
			options:     []string{"yes", "no"},
			validate:    validateYesNo,
		},
	}

	// Focus first step
	steps[0].input.Focus()

	return createWizardModel{
		currentStep: 0,
		steps:       steps,
		answers:     make(map[string]string),
		reviewMode:  false,
	}
}

func validateProjectName(name string) error {
	if len(name) == 0 {
		return fmt.Errorf("project name cannot be empty")
	}
	for _, c := range name {
		if !(c >= 'a' && c <= 'z') && !(c >= '0' && c <= '9') && c != '-' {
			return fmt.Errorf("use lowercase letters, numbers, hyphens only")
		}
	}
	return nil
}

func validateProjectType(ptype string) error {
	valid := map[string]bool{
		"laravel":   true,
		"wordpress": true,
		"php":       true,
		"html":      true,
	}
	if !valid[strings.ToLower(ptype)] {
		return fmt.Errorf("invalid type (choose: laravel, wordpress, php, html)")
	}
	return nil
}

func validatePHPVersion(version string) error {
	version = strings.ToLower(strings.TrimSpace(version))
	if version == "skip" {
		return nil
	}
	valid := map[string]bool{
		"7.3": true,
		"7.4": true,
		"8.1": true,
		"8.2": true,
		"8.3": true,
		"8.4": true,
		"8.5": true,
	}
	if !valid[version] {
		return fmt.Errorf("invalid PHP version (choose: 7.3-8.5 or 'skip')")
	}
	return nil
}

func validateNodeVersion(version string) error {
	version = strings.ToLower(strings.TrimSpace(version))
	if version == "skip" {
		return nil
	}
	valid := map[string]bool{
		"18": true,
		"20": true,
		"21": true,
	}
	if !valid[version] {
		return fmt.Errorf("invalid Node version (choose: 18, 20, 21 or 'skip')")
	}
	return nil
}

func validateDatabaseType(dbtype string) error {
	dbtype = strings.ToLower(strings.TrimSpace(dbtype))
	valid := map[string]bool{
		"none":    true,
		"shared":  true,
		"mysql":   true,
		"mariadb": true,
	}
	if !valid[dbtype] {
		return fmt.Errorf("invalid database type (choose: none, shared, mysql, mariadb)")
	}
	return nil
}

func validateDatabaseVersion(version string) error {
	version = strings.ToLower(strings.TrimSpace(version))
	if version == "skip" {
		return nil
	}
	valid := map[string]bool{
		// MySQL versions
		"5.7": true,
		"8.0": true,
		"8.4": true,
		// MariaDB versions
		"10.4":  true,
		"10.5":  true,
		"10.6":  true,
		"10.11": true,
		"11.4":  true,
	}
	if !valid[version] {
		return fmt.Errorf("invalid DB version (MySQL: 5.7/8.0/8.4, MariaDB: 10.4-11.4 or 'skip')")
	}
	return nil
}

func validateYesNo(answer string) error {
	answer = strings.ToLower(strings.TrimSpace(answer))
	if answer != "yes" && answer != "no" {
		return fmt.Errorf("answer must be 'yes' or 'no'")
	}
	return nil
}

func (m createWizardModel) Init() tea.Cmd {
	return textinput.Blink
}

func (m createWizardModel) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	var cmd tea.Cmd

	switch msg := msg.(type) {
	case tea.WindowSizeMsg:
		m.width = msg.Width
		m.height = msg.Height
		return m, nil

	case tea.KeyMsg:
		switch msg.String() {
		case "ctrl+c", "esc":
			m.cancelled = true
			return m, nil

		case "ctrl+r":
			// Toggle review mode
			m.reviewMode = !m.reviewMode
			return m, nil

		case "enter":
			if m.reviewMode {
				// Exit review mode
				m.reviewMode = false
				return m, nil
			}

			// Validate current step
			currentStep := &m.steps[m.currentStep]
			value := strings.TrimSpace(currentStep.input.Value())

			if err := currentStep.validate(value); err != nil {
				m.err = err.Error()
				return m, nil
			}

			// Save answer
			m.err = ""
			m.answers[currentStep.id] = value

			// Move to next step or complete
			if m.currentStep < len(m.steps)-1 {
				m.currentStep++
				m.steps[m.currentStep].input.Focus()
			} else {
				m.completed = true
			}
			return m, nil

		case "shift+tab":
			// Go back
			if m.currentStep > 0 {
				m.currentStep--
				// Restore previous answer
				if prev, exists := m.answers[m.steps[m.currentStep].id]; exists {
					m.steps[m.currentStep].input.SetValue(prev)
				}
				m.steps[m.currentStep].input.Focus()
			}
			return m, nil

		case "tab":
			// Quick forward (if valid)
			currentStep := &m.steps[m.currentStep]
			value := strings.TrimSpace(currentStep.input.Value())
			if err := currentStep.validate(value); err == nil {
				m.answers[currentStep.id] = value
				if m.currentStep < len(m.steps)-1 {
					m.currentStep++
					if prev, exists := m.answers[m.steps[m.currentStep].id]; exists {
						m.steps[m.currentStep].input.SetValue(prev)
					}
					m.steps[m.currentStep].input.Focus()
				}
			}
			return m, nil
		}
	}

	// Update input
	m.steps[m.currentStep].input, cmd = m.steps[m.currentStep].input.Update(msg)
	return m, cmd
}

func (m createWizardModel) View() string {
	if m.completed {
		return m.renderSummary()
	}

	if m.cancelled {
		return wizardErrorStyle.Render("✗ Wizard cancelled")
	}

	if m.reviewMode {
		return m.renderReview()
	}

	return m.renderStep()
}

func (m createWizardModel) renderStep() string {
	var b strings.Builder

	// Progress
	progress := wizardProgressStyle.Render(
		fmt.Sprintf("Step %d of %d", m.currentStep+1, len(m.steps)),
	)
	b.WriteString(progress + "\n\n")

	// Current step
	step := m.steps[m.currentStep]
	b.WriteString(wizardTitleStyle.Render(step.title) + "\n")
	b.WriteString(wizardDescStyle.Render(step.description) + "\n")

	// Show options if available
	if len(step.options) > 0 {
		optionsStyle := lipgloss.NewStyle().
			Foreground(lipgloss.Color("#00d4ff")).
			Italic(true)
		b.WriteString("\n" + optionsStyle.Render("Options: "+strings.Join(step.options, ", ")) + "\n")
	}

	b.WriteString(wizardInputStyle.Render(step.input.View()) + "\n")

	// Error if any
	if m.err != "" {
		b.WriteString("\n" + wizardErrorStyle.Render("✗ "+m.err) + "\n")
	} else if strings.TrimSpace(step.input.Value()) != "" {
		// Show validation success if valid
		if step.validate != nil && step.validate(strings.TrimSpace(step.input.Value())) == nil {
			b.WriteString("\n" + wizardSuccessStyle.Render("✓ Valid") + "\n")
		}
	}

	// Help
	b.WriteString("\n")
	b.WriteString(wizardDescStyle.Render("Tab: next • Shift+Tab: back • Ctrl+R: review • Enter: confirm • Esc: cancel"))

	return b.String()
}

func (m createWizardModel) renderReview() string {
	var b strings.Builder

	b.WriteString(wizardTitleStyle.Render("📋 Review Configuration") + "\n\n")

	for i, step := range m.steps {
		value := m.answers[step.id]
		if value == "" {
			value = lipgloss.NewStyle().Foreground(lipgloss.Color("#666666")).Render("(not set)")
		} else {
			value = wizardSuccessStyle.Render(value)
		}
		b.WriteString(fmt.Sprintf("  %d. %s: %s\n", i+1, step.title, value))
	}

	b.WriteString("\n" + wizardDescStyle.Render("Press any key to continue editing"))
	return b.String()
}

func (m createWizardModel) renderSummary() string {
	var b strings.Builder

	b.WriteString(wizardSuccessStyle.Render("✓ Configuration Complete!") + "\n\n")
	b.WriteString(wizardTitleStyle.Render("Project Configuration:") + "\n\n")

	for _, step := range m.steps {
		value := m.answers[step.id]
		b.WriteString(fmt.Sprintf("  %s: %s\n", step.title, wizardSuccessStyle.Render(value)))
	}

	return b.String()
}

// Helper methods for integration
func (m createWizardModel) WasCompleted() bool {
	return m.completed
}

func (m createWizardModel) WasCancelled() bool {
	return m.cancelled
}

func (m createWizardModel) GetAnswers() map[string]string {
	return m.answers
}

func (m createWizardModel) IsInReviewMode() bool {
	return m.reviewMode
}

// BuildCreateCommand builds the command arguments for phpharbor create
func (m createWizardModel) BuildCreateCommand() []string {
	args := []string{}

	// Project name (required)
	if name, ok := m.answers["name"]; ok && name != "" {
		args = append(args, name)
	}

	// Project type --type
	if ptype, ok := m.answers["type"]; ok && ptype != "" {
		args = append(args, "--type", ptype)
	}

	// PHP version --php (skip for html or if 'skip')
	if php, ok := m.answers["php"]; ok && php != "" && strings.ToLower(php) != "skip" {
		if ptype, ok := m.answers["type"]; !ok || ptype != "html" {
			args = append(args, "--php", php)
		}
	}

	// Node version --node (only for laravel, skip if 'skip')
	if node, ok := m.answers["node"]; ok && node != "" && strings.ToLower(node) != "skip" {
		if ptype, ok := m.answers["type"]; ok && ptype == "laravel" {
			args = append(args, "--node", node)
		}
	}

	// Database configuration
	if db, ok := m.answers["database"]; ok && db != "" {
		switch strings.ToLower(db) {
		case "none":
			args = append(args, "--no-db")
		case "shared":
			args = append(args, "--shared-db")
		case "mysql", "mariadb":
			// Dedicated database
			if dbver, ok := m.answers["db_version"]; ok && dbver != "" && strings.ToLower(dbver) != "skip" {
				if db == "mysql" {
					args = append(args, "--mysql", dbver)
				} else if db == "mariadb" {
					args = append(args, "--mariadb", dbver)
				}
			} else {
				// Default version
				if db == "mysql" {
					args = append(args, "--mysql", "8.0")
				} else {
					args = append(args, "--mariadb", "11.4")
				}
			}
		}
	}

	// Redis
	if redis, ok := m.answers["redis"]; ok && strings.ToLower(redis) == "yes" {
		args = append(args, "--redis")
	}

	// SSL
	if ssl, ok := m.answers["ssl"]; ok && strings.ToLower(ssl) == "yes" {
		args = append(args, "--ssl")
	}

	return args
}
