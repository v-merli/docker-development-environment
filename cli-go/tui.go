package main

import (
	"fmt"
	"strings"

	"github.com/charmbracelet/bubbles/textinput"
	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
)

// Styles for the new TUI
var (
	// Header
	newHeaderStyle = lipgloss.NewStyle().
			Foreground(lipgloss.Color("#00d4ff")).
			Bold(true).
			Padding(0, 1)

	// Content area
	newContentStyle = lipgloss.NewStyle().
			Border(lipgloss.RoundedBorder()).
			BorderForeground(lipgloss.Color("#874BFD")).
			Padding(1, 2).
			MarginLeft(2).
			MarginRight(2)

	// Command bar (bottom area)
	newCommandBarContainerStyle = lipgloss.NewStyle().
					BorderTop(true).
					BorderForeground(lipgloss.Color("#874BFD")).
					Padding(1, 2).
					MarginTop(1)

	newCommandPromptStyle = lipgloss.NewStyle().
				Foreground(lipgloss.Color("#00d4ff")).
				Bold(true)

	newStatusStyle = lipgloss.NewStyle().
			Foreground(lipgloss.Color("#666666")).
			Italic(true)

	newHintStyle = lipgloss.NewStyle().
			Foreground(lipgloss.Color("#00d4ff"))
)

// View types
type viewType string

const (
	viewHome     viewType = "home"
	viewProjects viewType = "projects"
	viewStats    viewType = "stats"
)

// Commands available
var commands = []struct {
	name string
	desc string
}{
	{"list", "List all projects"},
	{"stats", "Show system statistics"},
	{"create", "Create a new project"},
	{"start", "Start a project"},
	{"stop", "Stop a project"},
	{"help", "Show help"},
	{"quit", "Exit TUI"},
}

// Main TUI model
type tuiModel struct {
	width   int
	height  int
	input   textinput.Model
	view    viewType
	message string
	err     error
}

func newTUIModel() tuiModel {
	ti := textinput.New()
	ti.Placeholder = "Type a command (try 'help')"
	ti.Focus()
	ti.CharLimit = 50
	ti.Width = 50

	return tuiModel{
		input: ti,
		view:  viewHome,
	}
}

func (m tuiModel) Init() tea.Cmd {
	return textinput.Blink
}

func (m tuiModel) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	var cmd tea.Cmd

	switch msg := msg.(type) {
	case tea.WindowSizeMsg:
		m.width = msg.Width
		m.height = msg.Height
		return m, nil

	case tea.KeyMsg:
		switch msg.String() {
		case "ctrl+c", "esc":
			return m, tea.Quit

		case "enter":
			// Execute command
			command := strings.TrimSpace(m.input.Value())
			m = m.executeCommand(command)
			m.input.SetValue("")
			return m, nil
		}
	}

	// Update input
	m.input, cmd = m.input.Update(msg)
	return m, cmd
}

func (m tuiModel) View() string {
	if m.width == 0 {
		return "Loading..."
	}

	// Calculate heights
	headerHeight := 10
	commandBarHeight := 5
	contentHeight := m.height - headerHeight - commandBarHeight - 2

	// Header
	header := m.renderHeader()

	// Main content
	content := m.renderContent(contentHeight)

	// Command bar
	commandBar := m.renderCommandBar()

	// Join all parts vertically
	return lipgloss.JoinVertical(
		lipgloss.Left,
		header,
		content,
		commandBar,
	)
}

func (m tuiModel) renderHeader() string {
	logo := `
    ____  __  ______  __  __           __              
   / __ \/ / / / __ \/ / / /___ ______/ /_  ____  _____
  / /_/ / /_/ / /_/ / /_/ / __ '/ ___/ __ \/ __ \/ ___/
 / ____/ __  / ____/ __  / /_/ / /  / /_/ / /_/ / /    
/_/   /_/ /_/_/   /_/ /_/\__,_/_/  /_.___/\____/_/     
                                                        
     🐳  Docker Development Environment  •  v0.1.0-go-experiment
`

	return newHeaderStyle.Render(logo)
}

func (m tuiModel) renderContent(height int) string {
	var content string

	switch m.view {
	case viewHome:
		content = m.renderHomeView()
	case viewProjects:
		content = m.renderProjectsView()
	case viewStats:
		content = m.renderStatsView()
	default:
		content = "Unknown view"
	}

	// Add message if any
	if m.message != "" {
		content = m.message + "\n\n" + content
	}

	// Set height for content
	style := newContentStyle.Copy().Height(height)
	return style.Render(content)
}

func (m tuiModel) renderHomeView() string {
	var b strings.Builder

	b.WriteString("\n")
	b.WriteString("  ╭────────────────────────────────────────────────────────────╮\n")
	b.WriteString("  │                                                            │\n")
	b.WriteString("  │  Welcome to PHPHarbor Terminal User Interface!            │\n")
	b.WriteString("  │                                                            │\n")
	b.WriteString("  │  Manage your Docker-based PHP development projects         │\n")
	b.WriteString("  │  with ease using this interactive interface.               │\n")
	b.WriteString("  │                                                            │\n")
	b.WriteString("  ╰────────────────────────────────────────────────────────────╯\n")
	b.WriteString("\n\n")

	b.WriteString("  📋 Available Commands\n")
	b.WriteString("  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n")

	for _, cmd := range commands {
		b.WriteString(fmt.Sprintf("     %-12s  →  %s\n", cmd.name, cmd.desc))
	}

	b.WriteString("\n  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
	b.WriteString("\n  💡 Quick Start\n")
	b.WriteString("     Type a command in the input field below and press Enter\n")
	b.WriteString("     Press ESC or Ctrl+C to exit\n")

	return b.String()
}

func (m tuiModel) renderProjectsView() string {
	var b strings.Builder

	b.WriteString("📦 Projects\n")
	b.WriteString("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n")

	// Mock projects
	projects := []struct {
		name   string
		status string
		php    string
	}{
		{"laravel-app", "running", "8.3"},
		{"wordpress-site", "stopped", "8.2"},
		{"api-project", "running", "8.5"},
	}

	for _, p := range projects {
		statusIcon := "🟢"
		if p.status == "stopped" {
			statusIcon = "🔴"
		}
		b.WriteString(fmt.Sprintf("  %s  %-20s  PHP %s  [%s]\n", statusIcon, p.name, p.php, p.status))
	}

	b.WriteString("\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
	b.WriteString("\nType 'help' for more commands.")

	return b.String()
}

func (m tuiModel) renderStatsView() string {
	var b strings.Builder

	b.WriteString("📊 System Statistics\n")
	b.WriteString("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n")

	stats := []struct {
		label string
		value string
	}{
		{"Docker Containers", "12 running"},
		{"Total Disk Usage", "4.2 GB"},
		{"Projects", "3 active"},
		{"Shared Services", "5 running"},
	}

	for _, s := range stats {
		b.WriteString(fmt.Sprintf("  %-25s : %s\n", s.label, s.value))
	}

	b.WriteString("\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
	b.WriteString("\nType 'help' for more commands.")

	return b.String()
}

func (m tuiModel) renderCommandBar() string {
	var b strings.Builder

	// Command input with prompt
	prompt := newCommandPromptStyle.Render("➜ ")
	
	b.WriteString(prompt)
	b.WriteString(m.input.View())
	b.WriteString("\n\n")

	// Status/hints
	hint := m.getHint()
	b.WriteString(newStatusStyle.Render(hint))

	return newCommandBarContainerStyle.Render(b.String())
}

func (m tuiModel) getHint() string {
	input := strings.TrimSpace(m.input.Value())

	if input == "" {
		return "💡 Hint: Type 'help' to see all commands | ESC to quit"
	}

	// Find matching commands
	var matches []string
	for _, cmd := range commands {
		if strings.HasPrefix(cmd.name, input) {
			matches = append(matches, cmd.name)
		}
	}

	if len(matches) > 0 {
		return fmt.Sprintf("💡 Suggestions: %s", strings.Join(matches, ", "))
	}

	return "💡 Press Enter to execute | ESC to quit"
}

func (m tuiModel) executeCommand(cmd string) tuiModel {
	cmd = strings.ToLower(strings.TrimSpace(cmd))

	switch cmd {
	case "list", "projects":
		m.view = viewProjects
		m.message = "✓ Showing projects"
	case "stats", "statistics":
		m.view = viewStats
		m.message = "✓ Showing statistics"
	case "home":
		m.view = viewHome
		m.message = "✓ Back to home"
	case "help":
		m.view = viewHome
		m.message = "✓ Showing help"
	case "quit", "exit":
		m.message = "👋 Goodbye!"
		// Could return tea.Quit here
	case "":
		// Empty command, do nothing
		return m
	default:
		m.message = fmt.Sprintf("❌ Unknown command: '%s'. Type 'help' for available commands.", cmd)
	}

	return m
}

// RunTUI starts the new TUI
func RunTUI() error {
	p := tea.NewProgram(newTUIModel(), tea.WithAltScreen())
	_, err := p.Run()
	return err
}
