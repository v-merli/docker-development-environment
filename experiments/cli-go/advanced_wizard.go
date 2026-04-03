package main

import (
	"fmt"
	"strconv"
	"strings"

	"github.com/charmbracelet/bubbles/textinput"
	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
)

// AdvancedWizardModel with improved navigation and review capabilities
type advancedWizardModel struct {
	currentStep   int
	steps         []wizardStep
	answers       map[string]string
	width         int
	height        int
	completed     bool
	cancelled     bool
	reviewMode    bool
	validationErr string
}

var (
	// Enhanced styles for the advanced wizard
	advWizardHeaderStyle = lipgloss.NewStyle().
				Bold(true).
				Foreground(lipgloss.Color("#FFFFFF")).
				Background(lipgloss.Color("#874BFD")).
				Padding(0, 2)

	advWizardAnswerStyle = lipgloss.NewStyle().
				Foreground(lipgloss.Color("#00FF88")).
				Bold(true)

	advWizardLabelStyle = lipgloss.NewStyle().
				Foreground(lipgloss.Color("#888888"))

	advWizardStepIndicatorStyle = lipgloss.NewStyle().
					Foreground(lipgloss.Color("#00d4ff"))

	advWizardStepCompletedStyle = lipgloss.NewStyle().
					Foreground(lipgloss.Color("#00FF88"))

	advWizardStepCurrentStyle = lipgloss.NewStyle().
					Foreground(lipgloss.Color("#FFFFFF")).
					Background(lipgloss.Color("#874BFD")).
					Bold(true).
					Padding(0, 1)

	advWizardBorderStyle = lipgloss.NewStyle().
				Border(lipgloss.DoubleBorder()).
				BorderForeground(lipgloss.Color("#874BFD")).
				Padding(1, 2)
)

// Create an advanced service configuration wizard
func newAdvancedServiceWizard() advancedWizardModel {
	steps := []wizardStep{
		{
			id:          "service_type",
			title:       "Service Type",
			description: "What type of custom service do you want to add?",
			input:       createTextInput("redis", 30),
			options:     []string{"redis", "elasticsearch", "rabbitmq", "postgres", "mongodb"},
			validate: func(s string) error {
				if len(s) == 0 {
					return fmt.Errorf("service type is required")
				}
				validTypes := map[string]bool{
					"redis":         true,
					"elasticsearch": true,
					"rabbitmq":      true,
					"postgres":      true,
					"mongodb":       true,
				}
				if !validTypes[strings.ToLower(s)] {
					return fmt.Errorf("invalid service type")
				}
				return nil
			},
		},
		{
			id:          "service_name",
			title:       "Service Name",
			description: "Enter a unique name for this service instance",
			input:       createTextInput("my-service", 40),
			validate: func(s string) error {
				if len(s) == 0 {
					return fmt.Errorf("service name is required")
				}
				if len(s) < 3 {
					return fmt.Errorf("service name must be at least 3 characters")
				}
				if !isValidProjectName(s) {
					return fmt.Errorf("use lowercase letters, numbers, and hyphens only")
				}
				return nil
			},
		},
		{
			id:          "version",
			title:       "Service Version",
			description: "Which version do you want to use?",
			input:       createTextInput("latest", 20),
			options:     []string{"latest", "7.2", "7.0", "6.2"},
			validate: func(s string) error {
				if len(s) == 0 {
					return fmt.Errorf("version is required")
				}
				return nil
			},
		},
		{
			id:          "port",
			title:       "External Port",
			description: "Expose service on which port? (leave empty for default)",
			input:       createTextInput("", 10),
			validate: func(s string) error {
				if s == "" {
					return nil // Optional
				}
				port, err := strconv.Atoi(s)
				if err != nil {
					return fmt.Errorf("port must be a number")
				}
				if port < 1024 || port > 65535 {
					return fmt.Errorf("port must be between 1024 and 65535")
				}
				return nil
			},
		},
		{
			id:          "persistent",
			title:       "Persistent Data",
			description: "Do you want to persist data? (yes/no)",
			input:       createTextInput("yes", 5),
			options:     []string{"yes", "no"},
			validate: func(s string) error {
				s = strings.ToLower(s)
				if s != "yes" && s != "no" {
					return fmt.Errorf("answer must be 'yes' or 'no'")
				}
				return nil
			},
		},
		{
			id:          "memory_limit",
			title:       "Memory Limit",
			description: "Set memory limit in MB (e.g., 512, 1024, 2048)",
			input:       createTextInput("512", 10),
			validate: func(s string) error {
				if s == "" {
					return nil // Optional
				}
				mem, err := strconv.Atoi(s)
				if err != nil {
					return fmt.Errorf("memory must be a number")
				}
				if mem < 128 {
					return fmt.Errorf("minimum memory is 128 MB")
				}
				if mem > 8192 {
					return fmt.Errorf("maximum memory is 8192 MB")
				}
				return nil
			},
		},
		{
			id:          "auto_start",
			title:       "Auto Start",
			description: "Start service automatically with PHPHarbor? (yes/no)",
			input:       createTextInput("yes", 5),
			options:     []string{"yes", "no"},
			validate: func(s string) error {
				s = strings.ToLower(s)
				if s != "yes" && s != "no" {
					return fmt.Errorf("answer must be 'yes' or 'no'")
				}
				return nil
			},
		},
		{
			id:          "notes",
			title:       "Notes (Optional)",
			description: "Add any notes or comments about this service",
			input:       createTextInput("", 60),
			validate:    func(s string) error { return nil }, // Always valid
		},
	}

	// Initialize inputs
	for i := range steps {
		if steps[i].input.Placeholder == "" && len(steps[i].options) > 0 {
			steps[i].input = createTextInput(steps[i].options[0], 20)
		}
		steps[i].input.Focus()
	}

	return advancedWizardModel{
		currentStep:   0,
		steps:         steps,
		answers:       make(map[string]string),
		completed:     false,
		cancelled:     false,
		reviewMode:    false,
		validationErr: "",
	}
}

func (m advancedWizardModel) Init() tea.Cmd {
	return textinput.Blink
}

func (m advancedWizardModel) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	var cmd tea.Cmd

	switch msg := msg.(type) {
	case tea.KeyMsg:
		switch msg.String() {
		case "ctrl+c", "esc":
			if m.reviewMode {
				// In review mode, ESC goes back to editing
				m.reviewMode = false
				m.currentStep = 0
				m.steps[m.currentStep].input.Focus()
				return m, nil
			}
			m.cancelled = true
			return m, tea.Quit

		case "ctrl+r":
			// Toggle review mode to see all answers
			m.reviewMode = !m.reviewMode
			return m, nil

		case "enter":
			if m.reviewMode {
				// In review mode, Enter confirms and completes
				m.completed = true
				return m, tea.Quit
			}

			// Validate current step
			currentStep := &m.steps[m.currentStep]
			value := strings.TrimSpace(currentStep.input.Value())

			// Validate
			if currentStep.validate != nil {
				if err := currentStep.validate(value); err != nil {
					m.validationErr = err.Error()
					return m, nil
				}
			}

			// Clear validation error
			m.validationErr = ""

			// Save answer
			m.answers[currentStep.id] = value

			// Move to next step or enter review mode
			if m.currentStep < len(m.steps)-1 {
				m.currentStep++
				// Restore previous answer if exists
				if prevAnswer, exists := m.answers[m.steps[m.currentStep].id]; exists {
					m.steps[m.currentStep].input.SetValue(prevAnswer)
				}
				m.steps[m.currentStep].input.Focus()
				return m, nil
			} else {
				// All steps completed, enter review mode
				m.reviewMode = true
				return m, nil
			}

		case "up", "shift+tab":
			if m.reviewMode {
				return m, nil // No navigation in review mode
			}

			// Go back to previous step
			if m.currentStep > 0 {
				// Save current answer before moving
				value := strings.TrimSpace(m.steps[m.currentStep].input.Value())
				if value != "" {
					m.answers[m.steps[m.currentStep].id] = value
				}

				m.currentStep--
				m.validationErr = ""

				// Restore previous answer
				if prevAnswer, exists := m.answers[m.steps[m.currentStep].id]; exists {
					m.steps[m.currentStep].input.SetValue(prevAnswer)
				} else {
					m.steps[m.currentStep].input.SetValue("")
				}
				m.steps[m.currentStep].input.Focus()
				return m, nil
			}

		case "down", "tab":
			if m.reviewMode {
				return m, nil // No navigation in review mode
			}

			// Quick navigation forward (save and move)
			currentStep := &m.steps[m.currentStep]
			value := strings.TrimSpace(currentStep.input.Value())

			// Try to validate and move forward
			if currentStep.validate != nil {
				if err := currentStep.validate(value); err != nil {
					m.validationErr = err.Error()
					return m, nil
				}
			}

			// Clear validation error and save
			m.validationErr = ""
			m.answers[currentStep.id] = value

			if m.currentStep < len(m.steps)-1 {
				m.currentStep++
				if prevAnswer, exists := m.answers[m.steps[m.currentStep].id]; exists {
					m.steps[m.currentStep].input.SetValue(prevAnswer)
				}
				m.steps[m.currentStep].input.Focus()
			}
			return m, nil

		case "ctrl+e":
			// Jump to specific step by number (1-9)
			// Not implemented yet, but shown in help
			return m, nil
		}

	case tea.WindowSizeMsg:
		m.width = msg.Width
		m.height = msg.Height
	}

	// Update current step's input
	if !m.reviewMode {
		m.steps[m.currentStep].input, cmd = m.steps[m.currentStep].input.Update(msg)
	}
	return m, cmd
}

func (m advancedWizardModel) View() string {
	if m.completed {
		return m.renderFinalSummary()
	}

	if m.cancelled {
		return wizardErrorStyle.Render("✗ Configuration cancelled")
	}

	if m.reviewMode {
		return m.renderReview()
	}

	return m.renderStep()
}

func (m advancedWizardModel) renderStep() string {
	currentStep := m.steps[m.currentStep]

	// Header with wizard title
	header := advWizardHeaderStyle.Render(
		"🔧 ADVANCED SERVICE CONFIGURATION WIZARD",
	)

	// Progress bar with step indicators
	var progressSteps []string
	for i := range m.steps {
		stepNum := fmt.Sprintf("%d", i+1)

		if i < m.currentStep {
			// Completed step
			progressSteps = append(progressSteps,
				advWizardStepCompletedStyle.Render("✓ "+stepNum))
		} else if i == m.currentStep {
			// Current step
			progressSteps = append(progressSteps,
				advWizardStepCurrentStyle.Render("▶ "+stepNum))
		} else {
			// Future step
			progressSteps = append(progressSteps,
				advWizardLabelStyle.Render("○ "+stepNum))
		}
	}
	progressBar := strings.Join(progressSteps, " ")

	// Current step label
	stepLabel := advWizardStepIndicatorStyle.Render(
		fmt.Sprintf("Step %d of %d", m.currentStep+1, len(m.steps)),
	)

	// Previously answered questions (show last 2)
	var previousAnswers string
	if m.currentStep > 0 {
		previousAnswers = advWizardLabelStyle.Render("Previous answers:") + "\n"

		startIdx := m.currentStep - 2
		if startIdx < 0 {
			startIdx = 0
		}

		for i := startIdx; i < m.currentStep; i++ {
			if answer, exists := m.answers[m.steps[i].id]; exists {
				previousAnswers += fmt.Sprintf("  %s: %s\n",
					advWizardLabelStyle.Render(m.steps[i].title),
					advWizardAnswerStyle.Render(answer))
			}
		}
		previousAnswers += "\n"
	}

	// Current question
	title := wizardTitleStyle.Render(currentStep.title)
	desc := wizardDescStyle.Render(currentStep.description)

	// Input field with options
	var inputView string
	if len(currentStep.options) > 0 {
		optionsView := advWizardLabelStyle.Render("Options: ")
		optionsList := strings.Join(currentStep.options, ", ")
		inputView = optionsView + optionsList + "\n\n" + currentStep.input.View()
	} else {
		inputView = currentStep.input.View()
	}

	// Validation feedback
	var feedbackView string
	value := strings.TrimSpace(currentStep.input.Value())
	if m.validationErr != "" {
		feedbackView = "\n" + wizardErrorStyle.Render("✗ "+m.validationErr)
	} else if value != "" {
		if currentStep.validate != nil && currentStep.validate(value) == nil {
			feedbackView = "\n" + wizardSuccessStyle.Render("✓ Valid")
		}
	}

	// Help text with enhanced navigation
	help := wizardHelpStyle.Render(
		"↑/↓: Navigate | Enter: Next/Confirm | Ctrl+R: Review All | Esc: Cancel",
	)

	// Combine all sections
	content := lipgloss.JoinVertical(
		lipgloss.Left,
		header,
		"",
		progressBar,
		"",
		stepLabel,
		"",
		previousAnswers,
		title,
		desc,
		"",
		inputView,
		feedbackView,
		"",
		"",
		help,
	)

	return advWizardBorderStyle.Render(content)
}

func (m advancedWizardModel) renderReview() string {
	// Header
	header := advWizardHeaderStyle.Render(
		"📋 REVIEW YOUR CONFIGURATION",
	)

	// All answers
	var answersView string
	answersView += advWizardLabelStyle.Render("Please review your configuration:") + "\n\n"

	for i, step := range m.steps {
		answer := m.answers[step.id]
		if answer == "" {
			answer = advWizardLabelStyle.Render("(not set)")
		} else {
			answer = advWizardAnswerStyle.Render(answer)
		}

		answersView += fmt.Sprintf("%s. %s\n   %s\n\n",
			advWizardStepIndicatorStyle.Render(fmt.Sprintf("%d", i+1)),
			wizardTitleStyle.Render(step.title),
			answer)
	}

	// Help text
	help := wizardHelpStyle.Render(
		"Enter: Confirm & Create | Esc: Go Back & Edit | Ctrl+C: Cancel",
	)

	content := lipgloss.JoinVertical(
		lipgloss.Left,
		header,
		"",
		answersView,
		help,
	)

	return advWizardBorderStyle.Render(content)
}

func (m advancedWizardModel) renderFinalSummary() string {
	// Success message
	successMsg := wizardSuccessStyle.Render("✓ Service Configuration Complete!") + "\n\n"

	// Generate docker-compose snippet based on answers
	serviceType := m.answers["service_type"]
	serviceName := m.answers["service_name"]
	version := m.answers["version"]
	port := m.answers["port"]
	persistent := m.answers["persistent"]
	memoryLimit := m.answers["memory_limit"]
	autoStart := m.answers["auto_start"]
	notes := m.answers["notes"]

	// Build configuration summary
	summary := "Configuration Summary:\n"
	summary += "─────────────────────────────────────────────\n"
	summary += fmt.Sprintf("  Service Type:    %s\n", advWizardAnswerStyle.Render(serviceType))
	summary += fmt.Sprintf("  Service Name:    %s\n", advWizardAnswerStyle.Render(serviceName))
	summary += fmt.Sprintf("  Version:         %s\n", advWizardAnswerStyle.Render(version))

	if port != "" {
		summary += fmt.Sprintf("  External Port:   %s\n", advWizardAnswerStyle.Render(port))
	}
	summary += fmt.Sprintf("  Persistent Data: %s\n", advWizardAnswerStyle.Render(persistent))

	if memoryLimit != "" {
		summary += fmt.Sprintf("  Memory Limit:    %s MB\n", advWizardAnswerStyle.Render(memoryLimit))
	}
	summary += fmt.Sprintf("  Auto Start:      %s\n", advWizardAnswerStyle.Render(autoStart))

	if notes != "" {
		summary += fmt.Sprintf("  Notes:           %s\n", advWizardAnswerStyle.Render(notes))
	}

	summary += "\n\n"

	// Mock docker-compose configuration
	dockerCompose := "Generated docker-compose.yml snippet:\n\n"
	dockerCompose += advWizardLabelStyle.Render("services:\n")
	dockerCompose += fmt.Sprintf("  %s:\n", serviceName)
	dockerCompose += fmt.Sprintf("    image: %s:%s\n", serviceType, version)
	dockerCompose += "    container_name: " + serviceName + "\n"

	if port != "" {
		dockerCompose += "    ports:\n"
		dockerCompose += fmt.Sprintf("      - \"%s:%s\"\n", port, getDefaultPort(serviceType))
	}

	if persistent == "yes" {
		dockerCompose += "    volumes:\n"
		dockerCompose += fmt.Sprintf("      - ./%s-data:/data\n", serviceName)
	}

	if memoryLimit != "" {
		dockerCompose += "    mem_limit: " + memoryLimit + "m\n"
	}

	if autoStart == "no" {
		dockerCompose += "    restart: \"no\"\n"
	} else {
		dockerCompose += "    restart: unless-stopped\n"
	}

	// Next steps
	nextSteps := "\n" + wizardHelpStyle.Render("Next steps:") + "\n"
	nextSteps += "  1. Save this configuration to your project\n"
	nextSteps += "  2. Run 'docker-compose up -d' to start the service\n"
	nextSteps += "  3. Access your service on the configured port\n"

	return successMsg + summary + dockerCompose + nextSteps
}

// Helper function to get default port for a service type
func getDefaultPort(serviceType string) string {
	ports := map[string]string{
		"redis":         "6379",
		"elasticsearch": "9200",
		"rabbitmq":      "5672",
		"postgres":      "5432",
		"mongodb":       "27017",
	}
	if port, exists := ports[serviceType]; exists {
		return port
	}
	return "8080"
}

// Helper methods
func (m advancedWizardModel) GetAnswers() map[string]string {
	return m.answers
}

func (m advancedWizardModel) WasCompleted() bool {
	return m.completed
}

func (m advancedWizardModel) WasCancelled() bool {
	return m.cancelled
}

// IsScrollable returns true if the wizard is in a state where content might need scrolling
func (m advancedWizardModel) IsScrollable() bool {
	return m.reviewMode || m.completed
}

// IsReviewMode returns true if in review mode
func (m advancedWizardModel) IsReviewMode() bool {
	return m.reviewMode
}

// IsCompleted returns the completed state
func (m advancedWizardModel) IsCompleted() bool {
	return m.completed
}

// RenderForTUI renders the wizard content without external borders
// to fit within the TUI's standard layout (with header and status bar)
func (m advancedWizardModel) RenderForTUI() string {
	if m.completed {
		return m.renderFinalSummaryForTUI()
	}

	if m.cancelled {
		return wizardErrorStyle.Render("✗ Configuration cancelled")
	}

	if m.reviewMode {
		return m.renderReviewForTUI()
	}

	return m.renderStepForTUI()
}

func (m advancedWizardModel) renderStepForTUI() string {
	currentStep := m.steps[m.currentStep]

	// Compact header (no background box)
	header := lipgloss.NewStyle().
		Foreground(lipgloss.Color("#874BFD")).
		Bold(true).
		Render("🔧 SERVICE CONFIGURATION WIZARD")

	// Progress bar with step indicators
	var progressSteps []string
	for i := range m.steps {
		stepNum := fmt.Sprintf("%d", i+1)

		if i < m.currentStep {
			progressSteps = append(progressSteps,
				advWizardStepCompletedStyle.Render("✓ "+stepNum))
		} else if i == m.currentStep {
			progressSteps = append(progressSteps,
				advWizardStepCurrentStyle.Render("▶ "+stepNum))
		} else {
			progressSteps = append(progressSteps,
				advWizardLabelStyle.Render("○ "+stepNum))
		}
	}
	progressBar := strings.Join(progressSteps, " ")

	// Current step label
	stepLabel := advWizardStepIndicatorStyle.Render(
		fmt.Sprintf("Step %d of %d", m.currentStep+1, len(m.steps)),
	)

	// Previously answered questions (show last 2)
	var previousAnswers string
	if m.currentStep > 0 {
		previousAnswers = advWizardLabelStyle.Render("Previous answers:") + "\n"

		startIdx := m.currentStep - 2
		if startIdx < 0 {
			startIdx = 0
		}

		for i := startIdx; i < m.currentStep; i++ {
			if answer, exists := m.answers[m.steps[i].id]; exists {
				previousAnswers += fmt.Sprintf("  %s: %s\n",
					advWizardLabelStyle.Render(m.steps[i].title),
					advWizardAnswerStyle.Render(answer))
			}
		}
		previousAnswers += "\n"
	}

	// Current question
	title := wizardTitleStyle.Render(currentStep.title)
	desc := wizardDescStyle.Render(currentStep.description)

	// Input field with options
	var inputView string
	if len(currentStep.options) > 0 {
		optionsView := advWizardLabelStyle.Render("Options: ")
		optionsList := strings.Join(currentStep.options, ", ")
		inputView = optionsView + optionsList + "\n\n" + currentStep.input.View()
	} else {
		inputView = currentStep.input.View()
	}

	// Validation feedback
	var feedbackView string
	value := strings.TrimSpace(currentStep.input.Value())
	if m.validationErr != "" {
		feedbackView = "\n" + wizardErrorStyle.Render("✗ "+m.validationErr)
	} else if value != "" {
		if currentStep.validate != nil && currentStep.validate(value) == nil {
			feedbackView = "\n" + wizardSuccessStyle.Render("✓ Valid")
		}
	}

	// Help text with enhanced navigation
	help := wizardHelpStyle.Render(
		"↑/↓: Navigate | Enter: Next/Confirm | Ctrl+R: Review All | Esc: Cancel",
	)

	// Combine all sections (no external border)
	content := lipgloss.JoinVertical(
		lipgloss.Left,
		header,
		"",
		progressBar,
		"",
		stepLabel,
		"",
		previousAnswers,
		title,
		desc,
		"",
		inputView,
		feedbackView,
		"",
		"",
		help,
	)

	return content
}

func (m advancedWizardModel) renderReviewForTUI() string {
	// Header
	header := lipgloss.NewStyle().
		Foreground(lipgloss.Color("#874BFD")).
		Bold(true).
		Render("📋 REVIEW YOUR CONFIGURATION")

	// All answers
	var answersView string
	answersView += advWizardLabelStyle.Render("Please review your configuration:") + "\n\n"

	for i, step := range m.steps {
		answer := m.answers[step.id]
		if answer == "" {
			answer = advWizardLabelStyle.Render("(not set)")
		} else {
			answer = advWizardAnswerStyle.Render(answer)
		}

		answersView += fmt.Sprintf("%s. %s\n   %s\n\n",
			advWizardStepIndicatorStyle.Render(fmt.Sprintf("%d", i+1)),
			wizardTitleStyle.Render(step.title),
			answer)
	}

	// Help text with scroll info
	help := wizardHelpStyle.Render(
		"Enter: Confirm & Create | Esc: Go Back & Edit | PgUp/PgDn: Scroll",
	)

	content := lipgloss.JoinVertical(
		lipgloss.Left,
		header,
		"",
		answersView,
		help,
	)

	return content
}

func (m advancedWizardModel) renderFinalSummaryForTUI() string {
	// Success message
	successMsg := wizardSuccessStyle.Render("✓ Service Configuration Complete!") + "\n\n"

	// Generate docker-compose snippet based on answers
	serviceType := m.answers["service_type"]
	serviceName := m.answers["service_name"]
	version := m.answers["version"]
	port := m.answers["port"]
	persistent := m.answers["persistent"]
	memoryLimit := m.answers["memory_limit"]
	autoStart := m.answers["auto_start"]
	notes := m.answers["notes"]

	// Build configuration summary
	summary := "Configuration Summary:\n"
	summary += "─────────────────────────────────────────────\n"
	summary += fmt.Sprintf("  Service Type:    %s\n", advWizardAnswerStyle.Render(serviceType))
	summary += fmt.Sprintf("  Service Name:    %s\n", advWizardAnswerStyle.Render(serviceName))
	summary += fmt.Sprintf("  Version:         %s\n", advWizardAnswerStyle.Render(version))

	if port != "" {
		summary += fmt.Sprintf("  External Port:   %s\n", advWizardAnswerStyle.Render(port))
	}
	summary += fmt.Sprintf("  Persistent Data: %s\n", advWizardAnswerStyle.Render(persistent))

	if memoryLimit != "" {
		summary += fmt.Sprintf("  Memory Limit:    %s MB\n", advWizardAnswerStyle.Render(memoryLimit))
	}
	summary += fmt.Sprintf("  Auto Start:      %s\n", advWizardAnswerStyle.Render(autoStart))

	if notes != "" {
		summary += fmt.Sprintf("  Notes:           %s\n", advWizardAnswerStyle.Render(notes))
	}

	summary += "\n\n"

	// Mock docker-compose configuration
	dockerCompose := "Generated docker-compose.yml snippet:\n\n"
	dockerCompose += advWizardLabelStyle.Render("services:\n")
	dockerCompose += fmt.Sprintf("  %s:\n", serviceName)
	dockerCompose += fmt.Sprintf("    image: %s:%s\n", serviceType, version)
	dockerCompose += "    container_name: " + serviceName + "\n"

	if port != "" {
		dockerCompose += "    ports:\n"
		dockerCompose += fmt.Sprintf("      - \"%s:%s\"\n", port, getDefaultPort(serviceType))
	}

	if persistent == "yes" {
		dockerCompose += "    volumes:\n"
		dockerCompose += fmt.Sprintf("      - ./%s-data:/data\n", serviceName)
	}

	if memoryLimit != "" {
		dockerCompose += "    mem_limit: " + memoryLimit + "m\n"
	}

	if autoStart == "no" {
		dockerCompose += "    restart: \"no\"\n"
	} else {
		dockerCompose += "    restart: unless-stopped\n"
	}

	// Next steps
	nextSteps := "\n" + wizardHelpStyle.Render("Press ESC to return to home (PgUp/PgDn to scroll)")

	return successMsg + summary + dockerCompose + nextSteps
}
