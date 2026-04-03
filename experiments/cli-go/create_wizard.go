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
			validate:    validateProjectName,
		},
		{
			id:          "type",
			title:       "Project Type",
			description: "Choose: laravel, wordpress, php, html",
			input:       createTextInput("laravel", 40),
			validate:    validateProjectType,
		},
		{
			id:          "php",
			title:       "PHP Version",
			description: "Choose: 7.3, 7.4, 8.1, 8.2, 8.3, 8.4, 8.5",
			input:       createTextInput("8.3", 40),
			validate:    validatePHPVersion,
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
		return fmt.Errorf("invalid PHP version")
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
	b.WriteString(wizardInputStyle.Render(step.input.View()) + "\n")

	// Error if any
	if m.err != "" {
		b.WriteString("\n" + wizardErrorStyle.Render("✗ "+m.err) + "\n")
	}

	// Help
	b.WriteString("\n")
	b.WriteString(wizardDescStyle.Render("Tab: next • Shift+Tab: back • Ctrl+R: review • Esc: cancel"))

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
