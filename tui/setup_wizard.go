package main

import (
	"fmt"
	"os"
	"os/exec"
	"strings"

	"github.com/charmbracelet/bubbles/textinput"
	tea "github.com/charmbracelet/bubbletea"
)

// setupWizardModel represents the system setup wizard
type setupWizardModel struct {
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

// newSetupWizard creates a new system setup wizard
func newSetupWizard() setupWizardModel {
	steps := []wizardStep{
		{
			id:          "projects_dir",
			title:       "Projects Directory",
			description: "Where to store Docker projects?",
			input:       createTextInput("./projects", 60),
			options:     []string{"./projects", "~/Development/docker-projects", "custom"},
			validate:    validateProjectsDir,
		},
		{
			id:          "dns_enable",
			title:       "DNS Configuration (dnsmasq)",
			description: "Enable *.test domains? (requires sudo)",
			input:       createTextInput("no", 40),
			options:     []string{"yes", "no"},
			validate:    validateYesNo,
		},
		{
			id:          "proxy_enable",
			title:       "Reverse Proxy",
			description: "Start nginx reverse proxy?",
			input:       createTextInput("yes", 40),
			options:     []string{"yes", "no"},
			validate:    validateYesNo,
		},
		{
			id:          "mailpit_enable",
			title:       "MailPit Email Catcher",
			description: "Install email testing tool? (only if proxy enabled)",
			input:       createTextInput("yes", 40),
			options:     []string{"yes", "no"},
			validate:    validateYesNo,
		},
	}

	// Focus first step
	steps[0].input.Focus()

	return setupWizardModel{
		currentStep: 0,
		steps:       steps,
		answers:     make(map[string]string),
		reviewMode:  false,
	}
}

func validateProjectsDir(path string) error {
	if len(strings.TrimSpace(path)) == 0 {
		return fmt.Errorf("projects directory cannot be empty")
	}
	// Expand ~ and env vars
	expanded := os.ExpandEnv(path)
	if strings.HasPrefix(expanded, "~") {
		home, _ := os.UserHomeDir()
		expanded = strings.Replace(expanded, "~", home, 1)
	}
	return nil
}

func (m setupWizardModel) Init() tea.Cmd {
	return textinput.Blink
}

func (m setupWizardModel) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	var cmd tea.Cmd

	switch msg := msg.(type) {
	case tea.WindowSizeMsg:
		m.width = msg.Width
		m.height = msg.Height
		return m, nil

	case tea.KeyMsg:
		switch msg.String() {
		case "ctrl+c":
			m.cancelled = true
			return m, nil

		case "esc":
			if m.reviewMode {
				// In review mode, ESC goes back to editing
				m.reviewMode = false
				m.currentStep = 0
				m.steps[m.currentStep].input.Focus()
				return m, nil
			}
			m.cancelled = true
			return m, nil

		case "ctrl+r":
			// Toggle review mode
			m.reviewMode = !m.reviewMode
			return m, nil

		case "enter":
			if m.reviewMode {
				// In review mode, Enter confirms and completes
				m.completed = true
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

			// Move to next step or enter review mode
			if m.currentStep < len(m.steps)-1 {
				m.currentStep++
				// Skip mailpit if proxy disabled
				if m.steps[m.currentStep].id == "mailpit_enable" && m.answers["proxy_enable"] == "no" {
					m.answers["mailpit_enable"] = "no"
					// Auto-complete wizard
					m.reviewMode = true
					return m, nil
				}
				m.steps[m.currentStep].input.Focus()
			} else {
				// All steps completed, enter review mode
				m.reviewMode = true
			}
			return m, nil

		case "shift+tab":
			if m.reviewMode {
				return m, nil
			}
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
			if m.reviewMode {
				return m, nil
			}
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
	if !m.reviewMode && m.currentStep < len(m.steps) {
		m.steps[m.currentStep].input, cmd = m.steps[m.currentStep].input.Update(msg)
	}
	return m, cmd
}

func (m setupWizardModel) View() string {
	if m.completed {
		return m.renderSummary()
	}

	if m.cancelled {
		return wizardErrorStyle.Render("✗ Setup wizard cancelled")
	}

	if m.reviewMode {
		return m.renderReview()
	}

	return m.renderStep()
}

func (m setupWizardModel) renderStep() string {
	var b strings.Builder

	// Header with wizard title
	header := wizardHeaderStyle.Render("🔧 SYSTEM SETUP WIZARD")
	b.WriteString(header + "\n\n")

	// Visual progress bar
	var progressSteps []string
	for i := range m.steps {
		// Skip mailpit in progress if proxy disabled
		if m.steps[i].id == "mailpit_enable" && m.answers["proxy_enable"] == "no" {
			continue
		}

		stepNum := fmt.Sprintf("%d", i+1)
		if i < m.currentStep {
			progressSteps = append(progressSteps, wizardStepCompletedStyle.Render("✓ "+stepNum))
		} else if i == m.currentStep {
			progressSteps = append(progressSteps, wizardStepCurrentStyle.Render("▶ "+stepNum))
		} else {
			progressSteps = append(progressSteps, wizardStepFutureStyle.Render("○ "+stepNum))
		}
	}
	progressBar := strings.Join(progressSteps, " ")
	b.WriteString(progressBar + "\n\n")

	// Step counter
	stepLabel := wizardProgressStyle.Render(
		fmt.Sprintf("Step %d of %d", m.currentStep+1, len(m.steps)),
	)
	b.WriteString(stepLabel + "\n\n")

	// Show previous answers (last 2 steps)
	if m.currentStep > 0 {
		b.WriteString(wizardLabelStyle.Render("Previous answers:") + "\n")
		startIdx := m.currentStep - 2
		if startIdx < 0 {
			startIdx = 0
		}
		for i := startIdx; i < m.currentStep; i++ {
			if answer, exists := m.answers[m.steps[i].id]; exists {
				b.WriteString(fmt.Sprintf("  %s: %s\n",
					wizardLabelStyle.Render(m.steps[i].title),
					wizardAnswerStyle.Render(answer)))
			}
		}
		b.WriteString("\n")
	}

	// Current step
	step := m.steps[m.currentStep]
	b.WriteString(wizardTitleStyle.Render(step.title) + "\n")
	b.WriteString(wizardDescStyle.Render(step.description) + "\n")

	// Show options if available
	if len(step.options) > 0 {
		optionsStyle := wizardLabelStyle.Copy().Italic(true)
		b.WriteString("\n" + optionsStyle.Render("Options: "+strings.Join(step.options, ", ")) + "\n")
	}

	b.WriteString(wizardInputStyle.Render(step.input.View()) + "\n")

	// Error or validation feedback
	if m.err != "" {
		b.WriteString("\n" + wizardErrorStyle.Render("✗ "+m.err) + "\n")
	} else if strings.TrimSpace(step.input.Value()) != "" {
		if step.validate != nil && step.validate(strings.TrimSpace(step.input.Value())) == nil {
			b.WriteString("\n" + wizardSuccessStyle.Render("✓ Valid") + "\n")
		}
	}

	// Help
	b.WriteString("\n")
	b.WriteString(wizardDescStyle.Render("Tab: next • Shift+Tab: back • Ctrl+R: review • Enter: confirm • Esc: cancel"))

	return b.String()
}

func (m setupWizardModel) renderReview() string {
	var b strings.Builder

	// Header
	header := wizardHeaderStyle.Render("📋 REVIEW SETUP CONFIGURATION")
	b.WriteString(header + "\n\n")

	// All progress steps as completed
	var progressSteps []string
	for i := range m.steps {
		// Skip mailpit if proxy disabled
		if m.steps[i].id == "mailpit_enable" && m.answers["proxy_enable"] == "no" {
			continue
		}
		stepNum := fmt.Sprintf("%d", i+1)
		progressSteps = append(progressSteps, wizardStepCompletedStyle.Render("✓ "+stepNum))
	}
	progressBar := strings.Join(progressSteps, " ")
	b.WriteString(progressBar + "\n\n")

	b.WriteString(wizardLabelStyle.Render("Please review your configuration:") + "\n\n")

	for i, step := range m.steps {
		// Skip mailpit display if proxy disabled
		if step.id == "mailpit_enable" && m.answers["proxy_enable"] == "no" {
			continue
		}

		value := m.answers[step.id]
		if value == "" {
			value = wizardLabelStyle.Render("(not set)")
		} else {
			value = wizardAnswerStyle.Render(value)
		}
		b.WriteString(fmt.Sprintf("%s. %s\n   %s\n\n",
			wizardProgressStyle.Render(fmt.Sprintf("%d", i+1)),
			wizardTitleStyle.Render(step.title),
			value))
	}

	// Important notes
	b.WriteString(wizardLabelStyle.Render("Important:") + "\n")
	b.WriteString("  • All pre-flight checks will run before making changes\n")
	if m.answers["dns_enable"] == "yes" {
		b.WriteString("  • Sudo password will be requested for DNS setup\n")
	}
	b.WriteString("  • If any check fails, NO changes will be made\n")

	b.WriteString("\n" + wizardDescStyle.Render("Press Esc to edit • Enter to confirm and start setup"))
	return b.String()
}

func (m setupWizardModel) renderSummary() string {
	var b strings.Builder

	b.WriteString(wizardSuccessStyle.Render("✓ Configuration collected!") + "\n\n")
	b.WriteString(wizardTitleStyle.Render("Setup will now execute...") + "\n\n")
	b.WriteString(wizardLabelStyle.Render("This may take a few moments."))

	return b.String()
}

// Helper methods
func (m setupWizardModel) WasCompleted() bool {
	return m.completed
}

func (m setupWizardModel) WasCancelled() bool {
	return m.cancelled
}

func (m setupWizardModel) GetAnswers() map[string]string {
	return m.answers
}

// ExecuteSetup performs the actual setup with all-or-nothing semantics
func (m setupWizardModel) ExecuteSetup() (string, error) {
	var output strings.Builder

	output.WriteString("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
	output.WriteString("🔍 PRE-FLIGHT CHECKS\n")
	output.WriteString("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n")

	// Check 1: Docker
	output.WriteString("Checking Docker... ")
	cmd := exec.Command("docker", "info")
	cmd.Stdout = nil
	cmd.Stderr = nil
	if err := cmd.Run(); err != nil {
		output.WriteString("❌ FAILED\n\n")
		output.WriteString("⚠️  Setup ABORTED - Docker is not running\n")
		output.WriteString("Please start Docker Desktop and try again.\n")
		return output.String(), fmt.Errorf("Docker not available")
	}
	output.WriteString("✓\n")

	// Check 2: Docker Compose
	output.WriteString("Checking Docker Compose... ")
	cmd = exec.Command("docker", "compose", "version")
	cmd.Stdout = nil
	cmd.Stderr = nil
	if err := cmd.Run(); err != nil {
		output.WriteString("❌ FAILED\n\n")
		output.WriteString("⚠️  Setup ABORTED - Docker Compose not available\n")
		return output.String(), fmt.Errorf("Docker Compose not available")
	}
	output.WriteString("✓\n")

	// Check 3: Sudo (only if DNS enabled)
	if m.answers["dns_enable"] == "yes" {
		output.WriteString("Checking sudo privileges (DNS setup requires it)...\n")
		output.WriteString("Please authenticate:\n\n")

		// Call sudo -v to refresh credentials
		sudoCmd := exec.Command("sudo", "-v")
		sudoCmd.Stdout = os.Stdout
		sudoCmd.Stderr = os.Stderr
		sudoCmd.Stdin = os.Stdin

		if err := sudoCmd.Run(); err != nil {
			output.WriteString("\n❌ FAILED: Sudo authentication failed\n\n")
			output.WriteString("⚠️  Setup ABORTED - no changes were made\n")
			output.WriteString("Please check your password and try again.\n")
			return output.String(), fmt.Errorf("sudo authentication failed")
		}
		output.WriteString("✓ Sudo authenticated\n")
	}

	output.WriteString("\n✅ All pre-flight checks passed!\n\n")

	// Execute setup by delegating to bash script
	output.WriteString("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
	output.WriteString("🚀 EXECUTING SETUP\n")
	output.WriteString("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n")

	// Build arguments for setup init
	args := []string{"init"}

	// Call phpharbor setup init (non-interactive since we've done preflight)
	setupOutput, err := executePHPHarborCommand("setup", args...)
	if err != nil {
		output.WriteString(setupOutput)
		output.WriteString("\n\n❌ Setup failed: " + err.Error() + "\n")
		return output.String(), err
	}

	output.WriteString(setupOutput)
	output.WriteString("\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
	output.WriteString("✅ SETUP COMPLETED SUCCESSFULLY!\n")
	output.WriteString("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n")

	output.WriteString("Next steps:\n")
	output.WriteString("  1. Create a project: /create\n")
	output.WriteString("  2. List projects: /list\n")
	output.WriteString("  3. Start project: /start <name>\n")

	return output.String(), nil
}
