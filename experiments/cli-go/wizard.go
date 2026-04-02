package main

import (
	"fmt"
	"strings"

	"github.com/charmbracelet/bubbles/textinput"
	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
)

// Wizard represents a multi-step form
type wizardModel struct {
	currentStep int
	steps       []wizardStep
	answers     map[string]string
	width       int
	height      int
	completed   bool
	cancelled   bool
}

// wizardStep represents a single question in the wizard
type wizardStep struct {
	id          string
	title       string
	description string
	input       textinput.Model
	validate    func(string) error
	options     []string // For selection steps
}

var (
	wizardTitleStyle = lipgloss.NewStyle().
				Bold(true).
				Foreground(lipgloss.Color("#00d4ff")).
				MarginBottom(1)

	wizardDescStyle = lipgloss.NewStyle().
			Foreground(lipgloss.Color("#888888")).
			MarginBottom(1)

	wizardInputStyle = lipgloss.NewStyle().
				Border(lipgloss.RoundedBorder()).
				BorderForeground(lipgloss.Color("#874BFD")).
				Padding(1).
				MarginTop(1).
				MarginBottom(1)

	wizardProgressStyle = lipgloss.NewStyle().
				Foreground(lipgloss.Color("#00d4ff")).
				Bold(true)

	wizardHelpStyle = lipgloss.NewStyle().
			Foreground(lipgloss.Color("#666666")).
			Italic(true)

	wizardErrorStyle = lipgloss.NewStyle().
				Foreground(lipgloss.Color("#FF0000")).
				Bold(true)

	wizardSuccessStyle = lipgloss.NewStyle().
				Foreground(lipgloss.Color("#00FF00")).
				Bold(true)
)

// Create a new project wizard
func newCreateProjectWizard() wizardModel {
	steps := []wizardStep{
		{
			id:          "name",
			title:       "Project Name",
			description: "Enter a name for your project (lowercase, alphanumeric, hyphens allowed)",
			input:       createTextInput("my-project", 50),
			validate: func(s string) error {
				if len(s) == 0 {
					return fmt.Errorf("project name is required")
				}
				if len(s) < 3 {
					return fmt.Errorf("project name must be at least 3 characters")
				}
				if !isValidProjectName(s) {
					return fmt.Errorf("invalid project name (use lowercase, numbers, hyphens)")
				}
				return nil
			},
		},
		{
			id:          "type",
			title:       "Project Type",
			description: "Select the type of project you want to create",
			options:     []string{"laravel", "wordpress", "php", "html"},
			validate: func(s string) error {
				validTypes := map[string]bool{"laravel": true, "wordpress": true, "php": true, "html": true}
				if !validTypes[s] {
					return fmt.Errorf("invalid project type")
				}
				return nil
			},
		},
		{
			id:          "php",
			title:       "PHP Version",
			description: "Select the PHP version for your project",
			options:     []string{"8.5", "8.4", "8.3", "8.2", "8.1", "7.4"},
			validate: func(s string) error {
				validVersions := map[string]bool{"8.5": true, "8.4": true, "8.3": true, "8.2": true, "8.1": true, "7.4": true}
				if !validVersions[s] {
					return fmt.Errorf("invalid PHP version")
				}
				return nil
			},
		},
		{
			id:          "domain",
			title:       "Domain (Optional)",
			description: "Custom domain for the project (default: {name}.test)",
			input:       createTextInput("", 50),
			validate:    func(s string) error { return nil }, // Optional field
		},
	}

	// Initialize text inputs where needed
	for i := range steps {
		if steps[i].input.Placeholder == "" && len(steps[i].options) > 0 {
			steps[i].input = createTextInput(steps[i].options[0], 20)
		}
		steps[i].input.Focus()
	}

	return wizardModel{
		currentStep: 0,
		steps:       steps,
		answers:     make(map[string]string),
		completed:   false,
		cancelled:   false,
	}
}

func createTextInput(placeholder string, width int) textinput.Model {
	ti := textinput.New()
	ti.Placeholder = placeholder
	ti.Width = width
	ti.CharLimit = 100
	return ti
}

func isValidProjectName(name string) bool {
	if len(name) == 0 {
		return false
	}
	for _, c := range name {
		if !(c >= 'a' && c <= 'z') && !(c >= '0' && c <= '9') && c != '-' {
			return false
		}
	}
	return true
}

func (m wizardModel) Init() tea.Cmd {
	return textinput.Blink
}

func (m wizardModel) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	var cmd tea.Cmd

	switch msg := msg.(type) {
	case tea.KeyMsg:
		switch msg.String() {
		case "ctrl+c", "esc":
			m.cancelled = true
			return m, nil

		case "enter":
			// Validate current step
			currentStep := &m.steps[m.currentStep]
			var value string

			if len(currentStep.options) > 0 {
				// Selection step - use input value
				value = strings.TrimSpace(currentStep.input.Value())
			} else {
				// Text input step
				value = strings.TrimSpace(currentStep.input.Value())
			}

			// Validate
			if currentStep.validate != nil {
				if err := currentStep.validate(value); err != nil {
					// Show error in status (we'll handle this in View)
					return m, nil
				}
			}

			// Save answer
			m.answers[currentStep.id] = value

			// Move to next step or complete
			if m.currentStep < len(m.steps)-1 {
				m.currentStep++
				m.steps[m.currentStep].input.Focus()
				return m, nil
			} else {
				// Wizard completed
				m.completed = true
				return m, nil
			}

		case "shift+tab", "up":
			// Go back to previous step
			if m.currentStep > 0 {
				m.currentStep--
				// Restore previous answer if exists
				if prevAnswer, exists := m.answers[m.steps[m.currentStep].id]; exists {
					m.steps[m.currentStep].input.SetValue(prevAnswer)
				}
				m.steps[m.currentStep].input.Focus()
				return m, nil
			}

		case "tab", "down":
			// Quick navigation forward (if already answered)
			currentStep := &m.steps[m.currentStep]
			value := strings.TrimSpace(currentStep.input.Value())
			if value != "" && currentStep.validate != nil {
				if err := currentStep.validate(value); err == nil {
					m.answers[currentStep.id] = value
					if m.currentStep < len(m.steps)-1 {
						m.currentStep++
						if prevAnswer, exists := m.answers[m.steps[m.currentStep].id]; exists {
							m.steps[m.currentStep].input.SetValue(prevAnswer)
						}
						m.steps[m.currentStep].input.Focus()
					}
				}
			}
			return m, nil
		}

	case tea.WindowSizeMsg:
		m.width = msg.Width
		m.height = msg.Height
	}

	// Update current step's input
	m.steps[m.currentStep].input, cmd = m.steps[m.currentStep].input.Update(msg)
	return m, cmd
}

func (m wizardModel) View() string {
	if m.completed {
		return m.renderSummary()
	}

	if m.cancelled {
		return wizardErrorStyle.Render("✗ Wizard cancelled")
	}

	currentStep := m.steps[m.currentStep]

	// Progress indicator
	progress := wizardProgressStyle.Render(
		fmt.Sprintf("Step %d of %d", m.currentStep+1, len(m.steps)),
	)

	// Title and description
	title := wizardTitleStyle.Render(currentStep.title)
	desc := wizardDescStyle.Render(currentStep.description)

	// Input field or options
	var inputView string
	if len(currentStep.options) > 0 {
		// Show options
		optionsView := "Available options:\n"
		for i, opt := range currentStep.options {
			if i < len(currentStep.options)-1 {
				optionsView += fmt.Sprintf("  • %s\n", opt)
			} else {
				optionsView += fmt.Sprintf("  • %s", opt)
			}
		}
		inputView = wizardInputStyle.Render(
			optionsView + "\n\n" + currentStep.input.View(),
		)
	} else {
		inputView = wizardInputStyle.Render(currentStep.input.View())
	}

	// Validation error (if any)
	value := strings.TrimSpace(currentStep.input.Value())
	var errorView string
	if value != "" && currentStep.validate != nil {
		if err := currentStep.validate(value); err != nil {
			errorView = "\n" + wizardErrorStyle.Render("✗ "+err.Error())
		} else {
			errorView = "\n" + wizardSuccessStyle.Render("✓ Valid")
		}
	}

	// Help text
	help := wizardHelpStyle.Render(
		"↑/Shift+Tab: Previous | ↓/Tab: Next | Enter: Confirm | Esc: Cancel",
	)

	// Combine everything
	content := lipgloss.JoinVertical(
		lipgloss.Left,
		progress,
		"",
		title,
		desc,
		"",
		inputView,
		errorView,
		"",
		help,
	)

	return content
}

func (m wizardModel) renderSummary() string {
	summary := wizardSuccessStyle.Render("✓ Project Configuration Complete!") + "\n\n"
	summary += "Summary:\n"
	summary += "─────────────────────────────────────\n"

	for _, step := range m.steps {
		if answer, exists := m.answers[step.id]; exists && answer != "" {
			summary += fmt.Sprintf("  %-15s: %s\n", step.title, answer)
		}
	}

	summary += "\n" + wizardHelpStyle.Render("Creating project...")

	return summary
}

// Helper function to get answers
func (m wizardModel) GetAnswers() map[string]string {
	return m.answers
}

func (m wizardModel) WasCompleted() bool {
	return m.completed
}

func (m wizardModel) WasCancelled() bool {
	return m.cancelled
}
