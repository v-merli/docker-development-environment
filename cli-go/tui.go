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
			PaddingTop(1).
			PaddingLeft(1).
			PaddingRight(1)

	// Content area
	newContentStyle = lipgloss.NewStyle().
			Border(lipgloss.RoundedBorder()).
			BorderForeground(lipgloss.Color("#874BFD")).
			Padding(1, 2).
			MarginLeft(2).
			MarginRight(2)

	// Command bar (bottom area)
	newCommandBarContainerStyle = lipgloss.NewStyle().
					Border(lipgloss.Border{
			Top:    "─",
			Bottom: "─",
			Left:   "",
			Right:  "",
		}).
		BorderForeground(lipgloss.Color("#FFFFFF")).
		Padding(0, 1)

	newCommandPromptStyle = lipgloss.NewStyle().
				Foreground(lipgloss.Color("#00d4ff")).
				Bold(true)

	newStatusStyle = lipgloss.NewStyle().
			Foreground(lipgloss.Color("#666666")).
			Italic(true)

	newHintStyle = lipgloss.NewStyle().
			Foreground(lipgloss.Color("#00d4ff"))

	// Status bar styles
	statusBarInfoStyle = lipgloss.NewStyle().
				Background(lipgloss.Color("#666666")).
				Foreground(lipgloss.Color("#FFFFFF")).
				Padding(0, 2).
				Bold(true)

	statusBarSuccessStyle = lipgloss.NewStyle().
				Background(lipgloss.Color("#00AA00")).
				Foreground(lipgloss.Color("#FFFFFF")).
				Padding(0, 2).
				Bold(true)

	statusBarWarningStyle = lipgloss.NewStyle().
				Background(lipgloss.Color("#CCAA00")).
				Foreground(lipgloss.Color("#000000")).
				Padding(0, 2).
				Bold(true)

	statusBarDangerStyle = lipgloss.NewStyle().
				Background(lipgloss.Color("#CC0000")).
				Foreground(lipgloss.Color("#FFFFFF")).
				Padding(0, 2).
				Bold(true)
)

// View types
type viewType string

const (
	viewHome       viewType = "home"
	viewProjects   viewType = "projects"
	viewStats      viewType = "stats"
	viewLongOutput viewType = "longoutput"
)

// Status types
type statusType string

const (
	statusInfo    statusType = "info"
	statusSuccess statusType = "success"
	statusWarning statusType = "warning"
	statusDanger  statusType = "danger"
)

// Commands available
var commands = []struct {
	name string
	desc string
}{
	{"list", "List all projects"},
	{"stats", "Show system statistics"},
	{"test", "Test long output (simulates ls)"},
	{"create", "Create a new project"},
	{"start", "Start a project"},
	{"stop", "Stop a project"},
	{"help", "Show help"},
	{"quit", "Exit TUI"},
}

// Main TUI model
type tuiModel struct {
	width         int
	height        int
	input         textinput.Model
	view          viewType
	message       string
	err           error
	statusType    statusType
	statusMessage string
	exitConfirm   bool
	scrollOffset  int
	maxScroll     int // Maximum scroll offset for current content
}

func newTUIModel() tuiModel {
	ti := textinput.New()
	ti.Placeholder = "Type a command (try '/help')"
	ti.Focus()
	ti.CharLimit = 50
	ti.Width = 50

	return tuiModel{
		input:         ti,
		view:          viewHome,
		statusType:    statusInfo,
		statusMessage: "Ready",
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
		// Recalculate maxScroll when window size changes
		m.maxScroll = m.calculateMaxScroll()
		return m, nil

	case tea.KeyMsg:
		switch msg.String() {
		case "ctrl+c":
			return m, tea.Quit

		case "esc":
			// If already in home view, require double ESC to quit
			if m.view == viewHome {
				if m.exitConfirm {
					return m, tea.Quit
				}
				m.exitConfirm = true
				m.statusType = statusWarning
				m.statusMessage = "Press ESC again to quit, or any other key to cancel"
				return m, nil
			}

			// If in other views, navigate back to home
			m.view = viewHome
			m.message = ""
			m.statusType = statusInfo
			m.statusMessage = "Navigated back to home"
			m.exitConfirm = false
			m.scrollOffset = 0
			m.maxScroll = m.calculateMaxScroll()
			return m, nil

		case "enter":
			// Cancel exit confirmation on any input
			m.exitConfirm = false

			// Execute command
			command := strings.TrimSpace(m.input.Value())
			m = m.executeCommand(command)
			m.input.SetValue("")
			return m, nil

		case "up", "k":
			// Scroll up
			if m.scrollOffset > 0 {
				m.scrollOffset--
			}
			m.exitConfirm = false
			return m, nil

		case "down", "j":
			// Scroll down (will be clamped in render)
			m.scrollOffset++
			// Limit to reasonable maximum to avoid overflow
			if m.scrollOffset > m.maxScroll && m.maxScroll > 0 {
				m.scrollOffset = m.maxScroll
			}
			m.exitConfirm = false
			return m, nil

		case "pgup":
			// Page up (scroll up by 10 lines)
			m.scrollOffset -= 10
			if m.scrollOffset < 0 {
				m.scrollOffset = 0
			}
			m.exitConfirm = false
			return m, nil

		case "pgdown":
			// Page down (scroll down by 10 lines)
			m.scrollOffset += 10
			// Limit to reasonable maximum to avoid overflow
			if m.scrollOffset > m.maxScroll && m.maxScroll > 0 {
				m.scrollOffset = m.maxScroll
			}
			m.exitConfirm = false
			return m, nil

		case "home":
			// Go to top
			m.scrollOffset = 0
			m.exitConfirm = false
			return m, nil

		case "end":
			// Go to bottom
			m.scrollOffset = m.maxScroll
			m.exitConfirm = false
			return m, nil

		default:
			// Cancel exit confirmation on any other key
			if m.exitConfirm {
				m.exitConfirm = false
				m.statusType = statusInfo
				m.statusMessage = "Ready"
			}
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
	headerHeight := 12
	commandBarHeight := 1
	statusBarHeight := 1
	contentHeight := m.height - headerHeight - commandBarHeight - statusBarHeight

	// Header
	header := m.renderHeader()

	// Main content
	content := m.renderContent(contentHeight)

	// Command bar
	commandBar := m.renderCommandBar()

	// Status bar
	statusBar := m.renderStatusBar()

	// Join all parts vertically
	return lipgloss.JoinVertical(
		lipgloss.Left,
		header,
		content,
		commandBar,
		statusBar,
	)
}

// Helper to calculate maxScroll based on current content
func (m tuiModel) calculateMaxScroll() int {
	if m.width == 0 || m.height == 0 {
		return 0
	}

	// Calculate content height
	headerHeight := 12
	commandBarHeight := 1
	statusBarHeight := 1
	contentHeight := m.height - headerHeight - commandBarHeight - statusBarHeight

	// Get raw content
	var content string
	switch m.view {
	case viewHome:
		content = m.renderHomeView()
	case viewProjects:
		content = m.renderProjectsView()
	case viewStats:
		content = m.renderStatsView()
	case viewLongOutput:
		content = m.renderLongOutputView()
	default:
		content = "Unknown view"
	}

	if m.message != "" {
		content = m.message + "\n\n" + content
	}

	lines := strings.Split(content, "\n")
	totalLines := len(lines)
	visibleLines := contentHeight - 4
	if visibleLines < 1 {
		visibleLines = 1
	}

	maxScroll := totalLines - visibleLines
	if maxScroll < 0 {
		maxScroll = 0
	}
	return maxScroll
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
	case viewLongOutput:
		content = m.renderLongOutputView()
	default:
		content = "Unknown view"
	}

	// Add message if any
	if m.message != "" {
		content = m.message + "\n\n" + content
	}

	// Handle scrolling for long content
	lines := strings.Split(content, "\n")
	totalLines := len(lines)

	// Calculate visible area (subtract borders and padding)
	visibleLines := height - 4
	if visibleLines < 1 {
		visibleLines = 1
	}

	// Clamp scroll offset
	maxScroll := totalLines - visibleLines
	if maxScroll < 0 {
		maxScroll = 0
	}
	if m.scrollOffset > maxScroll {
		m.scrollOffset = maxScroll
	}
	if m.scrollOffset < 0 {
		m.scrollOffset = 0
	}

	// Get visible lines
	endLine := m.scrollOffset + visibleLines
	if endLine > totalLines {
		endLine = totalLines
	}

	visibleContent := strings.Join(lines[m.scrollOffset:endLine], "\n")

	// Add scroll indicators
	var scrollInfo string
	if totalLines > visibleLines {
		scrollInfo = fmt.Sprintf("\n\n  [%d-%d of %d lines | ↑/↓ or j/k to scroll | PgUp/PgDn | Home/End]",
			m.scrollOffset+1, endLine, totalLines)
		visibleContent += scrollInfo
	}

	// Set height for content
	style := newContentStyle.Copy().Height(height)
	return style.Render(visibleContent)
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
		b.WriteString(fmt.Sprintf("     /%-11s  →  %s\n", cmd.name, cmd.desc))
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

func (m tuiModel) renderLongOutputView() string {
	var b strings.Builder

	b.WriteString("📁 Long Output Test (Simulated ls -la)\n")
	b.WriteString("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n")

	// Generate 100 fake file entries to test scrolling/overflow
	for i := 1; i <= 100; i++ {
		permissions := "-rw-r--r--"
		if i%7 == 0 {
			permissions = "drwxr-xr-x"
		}
		size := fmt.Sprintf("%6d", 1024*(i%50+1))
		date := "Apr  2 17:30"
		filename := fmt.Sprintf("file_%03d.txt", i)

		if i%7 == 0 {
			filename = fmt.Sprintf("directory_%03d/", i)
		} else if i%13 == 0 {
			filename = fmt.Sprintf("very_long_filename_with_many_characters_%03d.config.backup.old", i)
		}

		b.WriteString(fmt.Sprintf("%s  1 user  staff  %s  %s  %s\n",
			permissions, size, date, filename))
	}

	b.WriteString("\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
	b.WriteString("\nTotal: 100 items\n")
	b.WriteString("Type '/help' to go back or ESC to navigate back")

	return b.String()
}

func (m tuiModel) renderCommandBar() string {
	// Command input with prompt
	prompt := newCommandPromptStyle.Render(" ➜ ")
	content := prompt + m.input.View()

	return newCommandBarContainerStyle.Width(m.width).Render(content)
}

func (m tuiModel) renderStatusBar() string {
	// Select style based on status type
	var style lipgloss.Style
	var icon string
	var message string

	switch m.statusType {
	case statusSuccess:
		style = statusBarSuccessStyle
		icon = "✓"
	case statusWarning:
		style = statusBarWarningStyle
		icon = "⚠"
	case statusDanger:
		style = statusBarDangerStyle
		icon = "✗"
	default: // statusInfo
		style = statusBarInfoStyle
		icon = "ℹ"
	}

	// If we're in idle state (Ready), add hint
	if m.statusMessage == "Ready" {
		hint := m.getHint()
		message = fmt.Sprintf("%s  %s - %s", icon, m.statusMessage, hint)
	} else if m.statusMessage != "" {
		message = fmt.Sprintf("%s  %s", icon, m.statusMessage)
	} else {
		// No message, show hint by default
		hint := m.getHint()
		message = fmt.Sprintf("%s  Ready - %s", icon, hint)
	}

	// Make it full width
	return style.Width(m.width).Render(message)
}

func (m tuiModel) getHint() string {
	input := strings.TrimSpace(m.input.Value())

	if input == "" {
		return "Type '/help' to see all commands | ESC to quit"
	}

	// Check if input starts with "/"
	if strings.HasPrefix(input, "/") {
		// Remove the "/" for matching
		searchTerm := strings.TrimPrefix(input, "/")

		// Find matching commands
		var matches []string
		for _, cmd := range commands {
			if strings.HasPrefix(cmd.name, searchTerm) {
				matches = append(matches, "/"+cmd.name)
			}
		}

		if len(matches) > 0 {
			return fmt.Sprintf("Suggestions: %s", strings.Join(matches, ", "))
		}

		return "Press Enter to execute | ESC to quit"
	}

	// If no "/" prefix, suggest adding it
	return "Commands must start with '/' (e.g., /help, /list)"
}

func (m tuiModel) executeCommand(cmd string) tuiModel {
	cmd = strings.TrimSpace(cmd)

	// Empty command, do nothing
	if cmd == "" {
		return m
	}

	// Check if command starts with "/"
	if !strings.HasPrefix(cmd, "/") {
		m.message = "❌ Commands must start with '/'"
		m.statusType = statusDanger
		m.statusMessage = "Invalid command format. Use '/' prefix (e.g., /help, /list)"
		return m
	}

	// Remove leading "/" and convert to lowercase
	cmd = strings.ToLower(strings.TrimPrefix(cmd, "/"))

	switch cmd {
	case "list", "projects":
		m.view = viewProjects
		m.message = "✓ Showing projects"
		m.statusType = statusSuccess
		m.statusMessage = "Projects view loaded successfully"
		m.scrollOffset = 0
	case "stats", "statistics":
		m.view = viewStats
		m.message = "✓ Showing statistics"
		m.statusType = statusInfo
		m.statusMessage = "System statistics displayed"
		m.scrollOffset = 0
	case "test", "longoutput":
		m.view = viewLongOutput
		m.message = "✓ Showing long output test"
		m.statusType = statusWarning
		m.statusMessage = "Long output test - scroll to see overflow behavior"
		m.scrollOffset = 0
	case "home":
		m.view = viewHome
		m.message = "✓ Back to home"
		m.statusType = statusInfo
		m.statusMessage = "Navigated to home"
		m.scrollOffset = 0
	case "help":
		m.view = viewHome
		m.message = "✓ Showing help"
		m.statusType = statusInfo
		m.statusMessage = "Help information displayed"
		m.scrollOffset = 0
	case "quit", "exit":
		m.message = "👋 Goodbye!"
		m.statusType = statusWarning
		m.statusMessage = "Use ESC or Ctrl+C to exit"
	default:
		m.message = fmt.Sprintf("❌ Unknown command: '/%s'. Type '/help' for available commands.", cmd)
		m.statusType = statusDanger
		m.statusMessage = fmt.Sprintf("Command not found: '/%s'", cmd)
	}

	// Recalculate maxScroll after view change
	m.maxScroll = m.calculateMaxScroll()

	return m
}

// RunTUI starts the new TUI
func RunTUI() error {
	p := tea.NewProgram(newTUIModel(), tea.WithAltScreen())
	_, err := p.Run()
	return err
}
