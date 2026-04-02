package main

import (
	"fmt"
	"strings"

	"github.com/charmbracelet/bubbles/list"
	"github.com/charmbracelet/bubbles/textinput"
	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
)

// Styles
var (
	titleStyle = lipgloss.NewStyle().
			Bold(true).
			Foreground(lipgloss.Color("#00d4ff")).
			MarginTop(1).
			MarginBottom(1)

	logoStyle = lipgloss.NewStyle().
			Foreground(lipgloss.Color("#00d4ff")).
			Bold(true)

	headerStyle = lipgloss.NewStyle().
			BorderBottom(true).
			BorderForeground(lipgloss.Color("#874BFD")).
			PaddingTop(1).
			PaddingBottom(1)

	projectListStyle = lipgloss.NewStyle().
				BorderBottom(true).
				BorderForeground(lipgloss.Color("#874BFD")).
				PaddingTop(1).
				PaddingBottom(1)

	projectListFocusedStyle = lipgloss.NewStyle().
				BorderBottom(true).
				BorderForeground(lipgloss.Color("#00d4ff")).
				PaddingTop(1).
				PaddingBottom(1)

	statusBarStyle = lipgloss.NewStyle().
			Foreground(lipgloss.Color("#FFFDF5")).
			Background(lipgloss.Color("#874BFD")).
			Padding(0, 1)

	commandBarStyle = lipgloss.NewStyle().
			BorderTop(true).
			BorderBottom(true).
			BorderForeground(lipgloss.Color("#874BFD")).
			BorderStyle(lipgloss.ThickBorder())

	commandBarFocusedStyle = lipgloss.NewStyle().
				BorderTop(true).
				BorderBottom(true).
				BorderForeground(lipgloss.Color("#00d4ff")).
				BorderStyle(lipgloss.ThickBorder())

	errorStyle = lipgloss.NewStyle().
			Foreground(lipgloss.Color("#FF0000")).
			Bold(true)

	successStyle = lipgloss.NewStyle().
			Foreground(lipgloss.Color("#00FF00")).
			Bold(true)

	helpStyle = lipgloss.NewStyle().
			Foreground(lipgloss.Color("#888888"))

	suggestionsStyle = lipgloss.NewStyle().
				Foreground(lipgloss.Color("#00d4ff")).
				Faint(true).
				Italic(true)

	suggestionItemStyle = lipgloss.NewStyle().
				Foreground(lipgloss.Color("#CCCCCC"))

	suggestionItemSelectedStyle = lipgloss.NewStyle().
					Foreground(lipgloss.Color("#00d4ff")).
					Bold(true)

	suggestionItemMarker = lipgloss.NewStyle().
				Foreground(lipgloss.Color("#00d4ff")).
				Bold(true)

	suggestionDescStyle = lipgloss.NewStyle().
				Foreground(lipgloss.Color("#888888"))
)

// Available commands - using slice to maintain order
var availableCommandsList = []struct {
	cmd  string
	desc string
}{
	{"create", "Create a new project"},
	{"start", "Start a project"},
	{"stop", "Stop a project"},
	{"restart", "Restart a project"},
	{"remove", "Remove a project"},
	{"list", "List all projects"},
	{"logs", "View project logs"},
	{"shell", "Open shell in project"},
	{"stats", "Show system statistics"},
	{"help", "Show available commands"},
}

// Keep map for validation
var availableCommands = map[string]string{
	"create":  "Create a new project",
	"start":   "Start a project",
	"stop":    "Stop a project",
	"restart": "Restart a project",
	"remove":  "Remove a project",
	"list":    "List all projects",
	"logs":    "View project logs",
	"shell":   "Open shell in project",
	"stats":   "Show system statistics",
	"help":    "Show available commands",
}

// Project represents a PHPHarbor project
type Project struct {
	Name   string
	Status string
	PHPVer string
	Type   string
}

func (p Project) Title() string { return p.Name }
func (p Project) Description() string {
	return fmt.Sprintf("%s | PHP %s | %s", p.Status, p.PHPVer, p.Type)
}
func (p Project) FilterValue() string { return p.Name }

// Focus state
type focusState int

const (
	focusProjects focusState = iota
	focusCommand
)

// View mode
type viewMode int

const (
	viewNormal viewMode = iota
	viewWizard
	viewStatsTable
	viewProjectsTable
	viewStatsOverview
)

// Model represents the TUI state
type model struct {
	projects       list.Model
	textInput      textinput.Model
	width          int
	height         int
	logo           string
	ready          bool
	statusMsg      string
	errorMsg       string
	focusedSection focusState
	// Integrated views
	currentMode   viewMode
	wizard        wizardModel
	statsTable    tableModel
	projectsTable tableModel
	statsOverview statsOverviewModel
	// UX improvements
	exitConfirm              bool                // Track if waiting for exit confirmation
	showSuggestions          bool                // Show command suggestions menu
	filteredCommands         []commandSuggestion // Filtered command list
	selectedCmd              int                 // Currently selected command in suggestions
	previousSuggestionsCount int                 // Track previous suggestions count to avoid unnecessary SetSize calls
	previousInput            string              // Track previous input to avoid unnecessary updates
}

// commandSuggestion represents a command in the autocomplete menu
type commandSuggestion struct {
	cmd  string
	desc string
}

func initialModel() model {
	// Logo ASCII art - compact version
	logo := `🚢 PHPHarbor - Docker Development Environment`

	// Sample projects
	projects := []list.Item{
		Project{Name: "laravel-1", Status: "running", PHPVer: "8.5", Type: "Laravel"},
		Project{Name: "laravel-2", Status: "stopped", PHPVer: "8.3", Type: "Laravel"},
		Project{Name: "mailpit", Status: "running", PHPVer: "system", Type: "Email Testing"},
	}

	// Create project list
	projectList := list.New(projects, list.NewDefaultDelegate(), 0, 0)
	projectList.Title = "Projects"
	projectList.SetShowStatusBar(false)
	projectList.SetFilteringEnabled(false)

	// Create text input for commands
	ti := textinput.New()
	ti.Placeholder = "Type /command (e.g. /create, /start, /list, /help)"
	ti.CharLimit = 200
	ti.Width = 80 // Will be updated on first render
	ti.Prompt = "❯ "
	ti.Focus() // Start with focus on command bar

	return model{
		projects:       projectList,
		textInput:      ti,
		logo:           logo,
		statusMsg:      "Type / to see commands | ↑↓ Navigate suggestions | Tab/Enter: Complete | Esc twice: Quit",
		focusedSection: focusCommand, // Start with command bar focused
		currentMode:    viewNormal,   // Start in normal view
	}
}

func (m model) Init() tea.Cmd {
	return textinput.Blink
}

func (m model) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	var cmd tea.Cmd
	var cmds []tea.Cmd

	// If we're in a special view mode, delegate to that view
	switch m.currentMode {
	case viewWizard:
		// Handle wizard navigation
		switch msg := msg.(type) {
		case tea.KeyMsg:
			if msg.String() == "esc" {
				// Exit wizard and return to normal view
				m.currentMode = viewNormal
				m.statusMsg = "Wizard cancelled"
				m.errorMsg = ""
				m.focusedSection = focusProjects
				m.textInput.Blur()
				return m, nil
			}
		}

		// Update wizard
		updatedWizard, cmd := m.wizard.Update(msg)
		m.wizard = updatedWizard.(wizardModel)

		// Check if wizard completed or cancelled
		if m.wizard.WasCompleted() {
			m.currentMode = viewNormal
			answers := m.wizard.GetAnswers()
			m.statusMsg = fmt.Sprintf("✓ Project '%s' configured! (Type: %s, PHP: %s)",
				answers["name"], answers["type"], answers["php"])
			m.focusedSection = focusProjects
			m.textInput.Blur()
			// Could save wizard answers here and trigger actual project creation
		} else if m.wizard.WasCancelled() {
			m.currentMode = viewNormal
			m.statusMsg = "Wizard cancelled"
			m.focusedSection = focusProjects
			m.textInput.Blur()
		}

		return m, cmd

	case viewStatsTable:
		// Handle table view
		switch msg := msg.(type) {
		case tea.KeyMsg:
			if msg.String() == "q" || msg.String() == "esc" {
				m.currentMode = viewNormal
				m.statusMsg = "Returned to main view"
				m.focusedSection = focusProjects
				m.textInput.Blur()
				return m, nil
			}
		case tea.WindowSizeMsg:
			m.width = msg.Width
			m.height = msg.Height
			m.statsTable.width = msg.Width
			m.statsTable.height = msg.Height
		}

		updatedTable, cmd := m.statsTable.Update(msg)
		m.statsTable = updatedTable.(tableModel)
		return m, cmd

	case viewProjectsTable:
		switch msg := msg.(type) {
		case tea.KeyMsg:
			if msg.String() == "q" || msg.String() == "esc" {
				m.currentMode = viewNormal
				m.statusMsg = "Returned to main view"
				m.focusedSection = focusProjects
				m.textInput.Blur()
				return m, nil
			}
		case tea.WindowSizeMsg:
			m.width = msg.Width
			m.height = msg.Height
			m.projectsTable.width = msg.Width
			m.projectsTable.height = msg.Height
		}

		updatedTable, cmd := m.projectsTable.Update(msg)
		m.projectsTable = updatedTable.(tableModel)
		return m, cmd

	case viewStatsOverview:
		switch msg := msg.(type) {
		case tea.KeyMsg:
			if msg.String() == "q" || msg.String() == "esc" {
				m.currentMode = viewNormal
				m.statusMsg = "Returned to main view"
				m.focusedSection = focusProjects
				m.textInput.Blur()
				return m, nil
			}
		case tea.WindowSizeMsg:
			m.width = msg.Width
			m.height = msg.Height
			m.statsOverview.width = msg.Width
			m.statsOverview.height = msg.Height
		}

		updatedOverview, cmd := m.statsOverview.Update(msg)
		m.statsOverview = updatedOverview.(statsOverviewModel)
		return m, cmd
	}

	// Normal view mode - original TUI logic
	switch msg := msg.(type) {
	case tea.KeyMsg:
		switch msg.String() {
		case "ctrl+c":
			return m, tea.Quit

		case "esc":
			// Double Esc to quit confirmation
			if m.exitConfirm {
				return m, tea.Quit
			}
			m.exitConfirm = true
			m.statusMsg = "Press Esc again to quit, or any other key to cancel"
			return m, nil

		case "down", "ctrl+n":
			m.exitConfirm = false
			// Navigate down in suggestions
			if m.showSuggestions && len(m.filteredCommands) > 0 {
				m.selectedCmd = (m.selectedCmd + 1) % len(m.filteredCommands)
				return m, nil
			}

		case "up", "ctrl+p":
			m.exitConfirm = false
			// Navigate up in suggestions
			if m.showSuggestions && len(m.filteredCommands) > 0 {
				m.selectedCmd--
				if m.selectedCmd < 0 {
					m.selectedCmd = len(m.filteredCommands) - 1
				}
				return m, nil
			}

		case "tab":
			m.exitConfirm = false // Cancel exit on any key

			// If suggestions visible, autocomplete with selected
			if m.showSuggestions && len(m.filteredCommands) > 0 && m.focusedSection == focusCommand {
				selected := m.filteredCommands[m.selectedCmd]
				m.textInput.SetValue("/" + selected.cmd)
				m.textInput.SetCursor(len(m.textInput.Value()))
				// Hide suggestions after autocomplete
				m.showSuggestions = false
				m.filteredCommands = nil
				m.selectedCmd = 0
				return m, nil
			}

			// Switch focus between sections
			if m.focusedSection == focusProjects {
				m.focusedSection = focusCommand
				m.textInput.Focus()
				m.statusMsg = "Type /command and press Enter | Type /help for available commands | Tab: Autocomplete or switch"
				m.errorMsg = "" // Clear errors when switching focus
			} else {
				m.focusedSection = focusProjects
				m.textInput.Blur()
				m.statusMsg = "↑↓ Navigate projects | Enter: Actions | Tab: Command mode | Esc twice: Quit"
				m.errorMsg = ""           // Clear errors when switching focus
				m.showSuggestions = false // Hide suggestions when switching away
				m.filteredCommands = nil  // Clear filtered commands
			}
			return m, nil

		case "enter":
			m.exitConfirm = false // Cancel exit on any key

			// If suggestions menu is visible, complete with selected command
			if m.showSuggestions && len(m.filteredCommands) > 0 && m.focusedSection == focusCommand {
				selected := m.filteredCommands[m.selectedCmd]
				m.textInput.SetValue("/" + selected.cmd)
				m.textInput.SetCursor(len(m.textInput.Value()))
				// Hide suggestions after autocomplete
				m.showSuggestions = false
				m.filteredCommands = nil
				m.selectedCmd = 0
				return m, nil
			}

			if m.focusedSection == focusProjects {
				// Project selected - show actions
				selected := m.projects.SelectedItem()
				if selected != nil {
					project := selected.(Project)
					m.statusMsg = fmt.Sprintf("Selected: %s (%s)", project.Name, project.Status)
					m.errorMsg = ""
					// TODO: Show action menu or execute action
				}
				return m, nil
			} else {
				// Command mode - validate and execute command
				input := strings.TrimSpace(m.textInput.Value())
				// Hide suggestions when executing command
				m.showSuggestions = false
				m.filteredCommands = nil
				m.selectedCmd = 0
				if input != "" {
					// Check if starts with /
					if !strings.HasPrefix(input, "/") {
						m.errorMsg = "Commands must start with / (e.g. /create, /start, /help)"
						m.statusMsg = ""
						return m, nil
					}

					// Parse command (remove / and get first word)
					cmdParts := strings.Fields(input[1:]) // Remove leading /
					if len(cmdParts) == 0 {
						m.errorMsg = "Empty command. Type /help for available commands"
						m.statusMsg = ""
						return m, nil
					}

					cmdName := cmdParts[0]

					// Special case for help command
					if cmdName == "help" {
						m.errorMsg = ""
						m.statusMsg = m.getHelpMessage()
						m.textInput.SetValue("")
						return m, nil
					}

					// Check if command exists
					if _, exists := availableCommands[cmdName]; !exists {
						m.errorMsg = fmt.Sprintf("Unknown command: /%s. Type /help for available commands", cmdName)
						m.statusMsg = ""
						return m, nil
					}

					// Valid command - switch to appropriate view mode
					m.errorMsg = ""
					m.textInput.SetValue("")

					switch cmdName {
					case "create":
						// Launch wizard
						m.wizard = newCreateProjectWizard()
						m.wizard.width = m.width
						m.wizard.height = m.height
						m.currentMode = viewWizard
						m.statusMsg = ""
						return m, m.wizard.Init()

					case "stats":
						// Show stats table
						m.statsTable = newStatsTable()
						m.statsTable.width = m.width
						m.statsTable.height = m.height
						m.currentMode = viewStatsTable
						return m, nil

					case "list":
						// Show projects table
						m.projectsTable = newProjectsTable()
						m.projectsTable.width = m.width
						m.projectsTable.height = m.height
						m.currentMode = viewProjectsTable
						return m, nil

					default:
						// For other commands, just show a message
						m.statusMsg = fmt.Sprintf("✓ Executing: /%s", cmdName)
					}
				}
				return m, nil
			}
		}

	case tea.WindowSizeMsg:
		m.width = msg.Width
		m.height = msg.Height
		m.ready = true

		// Update text input width to match terminal
		m.textInput.Width = msg.Width - 4 // Leave some margin for prompt

		// Update project list size - reserve space for hints area (always)
		headerHeight := 4    // Compact header
		commandHeight := 4   // Command bar with borders
		statusHeight := 1    // Status bar
		hintsAreaHeight := 6 // Reserve space for hints (5 lines + 1 separator)
		verticalMargins := headerHeight + commandHeight + statusHeight + hintsAreaHeight + 2

		m.projects.SetSize(msg.Width, msg.Height-verticalMargins)
	}

	// Pass events to the focused component
	if m.focusedSection == focusProjects {
		m.projects, cmd = m.projects.Update(msg)
		cmds = append(cmds, cmd)
	} else {
		// Update text input and refresh suggestions
		m.textInput, cmd = m.textInput.Update(msg)
		cmds = append(cmds, cmd)

		// Update autocomplete suggestions ONLY when input actually changes
		input := strings.TrimSpace(m.textInput.Value())

		if input != m.previousInput {
			m.previousInput = input

			// Show suggestions menu when input starts with /
			if strings.HasPrefix(input, "/") {
				m.showSuggestions = true
				m.filteredCommands = m.getFilteredCommands(input[1:]) // Remove leading /

				// Reset selection ONLY when the filtered list actually changes
				if len(m.filteredCommands) != m.previousSuggestionsCount {
					m.selectedCmd = 0
					m.previousSuggestionsCount = len(m.filteredCommands)
				}

				// Keep selected index in bounds
				if len(m.filteredCommands) > 0 && m.selectedCmd >= len(m.filteredCommands) {
					m.selectedCmd = len(m.filteredCommands) - 1
				}
			} else {
				m.showSuggestions = false
				m.filteredCommands = nil
				m.selectedCmd = 0
				m.previousSuggestionsCount = 0
			}
		}

		// Cancel exit confirmation on typing
		if msg, ok := msg.(tea.KeyMsg); ok {
			if msg.Type == tea.KeyRunes {
				m.exitConfirm = false
			}
		}
	}

	return m, tea.Batch(cmds...)
}

func (m model) View() string {
	if !m.ready {
		return "Initializing..."
	}

	// If in a special view mode, render that view
	switch m.currentMode {
	case viewWizard:
		return m.wizard.View()

	case viewStatsTable:
		return m.statsTable.View()

	case viewProjectsTable:
		return m.projectsTable.View()

	case viewStatsOverview:
		return m.statsOverview.View()
	}

	// Normal view mode - render main TUI
	// Header with logo
	header := headerStyle.Width(m.width).Render(logoStyle.Render(m.logo))

	// Command bar - always at bottom (above status bar)
	var commandView string
	if m.focusedSection == focusCommand {
		commandView = commandBarFocusedStyle.Width(m.width).Render(m.textInput.View())
	} else {
		commandView = commandBarStyle.Width(m.width).Render(m.textInput.View())
	}

	// Status bar
	var statusBar string
	if m.errorMsg != "" {
		statusBar = statusBarStyle.Width(m.width).Render(
			errorStyle.Render("✗ ") + m.errorMsg,
		)
	} else if m.exitConfirm {
		statusBar = statusBarStyle.Width(m.width).Render(
			errorStyle.Render("⚠ Press Esc again to quit, or any other key to cancel"),
		)
	} else if m.statusMsg != "" {
		statusBar = statusBarStyle.Width(m.width).Render(m.statusMsg)
	} else {
		statusBar = statusBarStyle.Width(m.width).Render("Type / to see commands | ↑↓ Navigate suggestions | Tab/Enter: Complete | Esc twice: Quit")
	}

	// Main content area - either projects list OR hints
	var mainContent string

	if m.showSuggestions && len(m.filteredCommands) > 0 && m.focusedSection == focusCommand {
		// Show hints instead of projects
		var suggestions []string
		maxVisible := 8
		totalItems := len(m.filteredCommands)

		// Calculate visible window
		startIdx := 0
		if totalItems > maxVisible {
			startIdx = m.selectedCmd - (maxVisible / 2)
			if startIdx < 0 {
				startIdx = 0
			}
			if startIdx > totalItems-maxVisible {
				startIdx = totalItems - maxVisible
			}
		}

		endIdx := startIdx + maxVisible
		if endIdx > totalItems {
			endIdx = totalItems
		}

		// Render hints
		for i := startIdx; i < endIdx; i++ {
			cmd := m.filteredCommands[i]
			var line string

			if i == m.selectedCmd {
				marker := suggestionItemMarker.Render("▋")
				cmdText := suggestionItemSelectedStyle.Render(fmt.Sprintf("/%s", cmd.cmd))
				desc := suggestionDescStyle.Render(cmd.desc)
				line = fmt.Sprintf("  %s %s\t%s", marker, cmdText, desc)
			} else {
				cmdText := suggestionItemStyle.Render(fmt.Sprintf("/%s", cmd.cmd))
				desc := suggestionDescStyle.Render(cmd.desc)
				line = fmt.Sprintf("    %s\t%s", cmdText, desc)
			}
			suggestions = append(suggestions, line)
		}

		if totalItems > maxVisible {
			scrollInfo := fmt.Sprintf("    (%d/%d)", m.selectedCmd+1, totalItems)
			suggestions = append(suggestions, suggestionDescStyle.Render(scrollInfo))
		}

		mainContent = strings.Join(suggestions, "\n")
	} else {
		// Show projects list
		if m.focusedSection == focusProjects {
			mainContent = m.projects.View()
		} else {
			mainContent = m.projects.View()
		}
	}

	// Final layout: header, content, command bar, status
	fullView := lipgloss.JoinVertical(
		lipgloss.Left,
		header,
		mainContent,
		commandView,
		statusBar,
	)

	return fullView
}

// getHelpMessage returns a formatted list of available commands
func (m model) getHelpMessage() string {
	commands := []string{
		"/create   - Create a new project",
		"/start    - Start a project",
		"/stop     - Stop a project",
		"/restart  - Restart a project",
		"/remove   - Remove a project",
		"/list     - List all projects",
		"/logs     - View project logs",
		"/shell    - Open shell in project",
		"/stats    - Show system statistics",
		"/help     - Show this help message",
	}

	return "Available commands: " + strings.Join(commands, " | ")
}

// getFilteredCommands returns command suggestions based on current input (Copilot CLI style)
func (m model) getFilteredCommands(input string) []commandSuggestion {
	// Clean input - trim spaces and convert to lowercase
	input = strings.TrimSpace(strings.ToLower(input))

	var filtered []commandSuggestion

	// If empty input, return all commands
	if input == "" {
		for _, cmdInfo := range availableCommandsList {
			filtered = append(filtered, commandSuggestion{
				cmd:  cmdInfo.cmd,
				desc: cmdInfo.desc,
			})
		}
		return filtered
	}

	// Filter commands that start with the input
	for _, cmdInfo := range availableCommandsList {
		if strings.HasPrefix(cmdInfo.cmd, input) {
			filtered = append(filtered, commandSuggestion{
				cmd:  cmdInfo.cmd,
				desc: cmdInfo.desc,
			})
		}
	}

	return filtered
}

func RunTUI() error {
	p := tea.NewProgram(initialModel(), tea.WithAltScreen())
	_, err := p.Run()
	return err
}
