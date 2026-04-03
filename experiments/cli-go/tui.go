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

	// Content area (full-width, no horizontal padding to avoid width issues)
	newContentStyle = lipgloss.NewStyle().
			Border(lipgloss.RoundedBorder()).
			BorderForeground(lipgloss.Color("#874BFD")).
			Padding(1, 1)

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

	// Suggestions area styles
	suggestionsContainerStyle = lipgloss.NewStyle().
					Padding(0, 2).
					MarginTop(0)

	suggestionItemStyle = lipgloss.NewStyle().
				Foreground(lipgloss.Color("#CCCCCC"))

	suggestionItemSelectedStyle = lipgloss.NewStyle().
					Foreground(lipgloss.Color("#00d4ff")).
					Background(lipgloss.Color("#333333")).
					Bold(true)

	suggestionDescStyle = lipgloss.NewStyle().
				Foreground(lipgloss.Color("#888888"))

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
	viewHome          viewType = "home"
	viewProjects      viewType = "projects"
	viewStats         viewType = "stats"
	viewLongOutput    viewType = "longoutput"
	viewServiceWizard viewType = "servicewizard"
	viewTable         viewType = "table"
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
	{"table", "Show data in tabular format (mock)"},
	{"service", "Configure a custom service (wizard)"},
	{"test", "Test long output (simulates ls)"},
	{"create", "Create a new project"},
	{"start", "Start a project"},
	{"stop", "Stop a project"},
	{"help", "Show help"},
	{"quit", "Exit TUI"},
}

// Main TUI model
type tuiModel struct {
	width                   int
	height                  int
	input                   textinput.Model
	view                    viewType
	message                 string
	err                     error
	statusType              statusType
	statusMessage           string
	exitConfirm             bool
	scrollOffset            int
	maxScroll               int // Maximum scroll offset for current content
	showSuggestions         bool
	selectedSuggestionIndex int
	suggestions             []string
	wizard                  *advancedWizardModel // Embedded wizard
	wizardActive            bool
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

	// If wizard is active, delegate to wizard Update
	if m.wizardActive && m.wizard != nil {
		// Handle window size for wizard
		if msg, ok := msg.(tea.WindowSizeMsg); ok {
			m.width = msg.Width
			m.height = msg.Height
			m.wizard.width = msg.Width
			m.wizard.height = msg.Height
			m.maxScroll = m.calculateMaxScroll()
		}

		// Handle scrolling keys BEFORE wizard (arrows are for scrolling, not text input cursor)
		// Wizard uses Tab/Shift+Tab for navigation between steps
		if keyMsg, ok := msg.(tea.KeyMsg); ok {
			switch keyMsg.String() {
			case "up":
				// Scroll up one line
				if m.scrollOffset > 0 {
					m.scrollOffset--
				}
				return m, nil
			case "down":
				// Scroll down one line
				if m.scrollOffset < m.maxScroll {
					m.scrollOffset++
				}
				return m, nil
			case "pgup":
				// Page up (scroll up by 10 lines)
				m.scrollOffset -= 10
				if m.scrollOffset < 0 {
					m.scrollOffset = 0
				}
				return m, nil
			case "pgdown":
				// Page down (scroll down by 10 lines)
				m.scrollOffset += 10
				if m.scrollOffset > m.maxScroll {
					m.scrollOffset = m.maxScroll
				}
				return m, nil
				// Note: Home/End are NOT intercepted here so they can be used
				// in the text input field to move cursor to start/end of line
			}
		}

		// Update wizard (will receive Tab/Shift+Tab, Enter, Esc, etc. but not arrows)
		wizardModel, wizardCmd := m.wizard.Update(msg)
		if wm, ok := wizardModel.(advancedWizardModel); ok {
			m.wizard = &wm

			// Recalculate scroll when wizard state changes
			m.maxScroll = m.calculateMaxScroll()

			// Check if wizard is completed or cancelled
			if m.wizard.WasCompleted() {
				m.wizardActive = false
				m.view = viewHome
				m.message = "✓ Service configuration completed!"
				m.statusType = statusSuccess
				m.statusMessage = "Service wizard completed successfully"
				m.wizard = nil
				m.scrollOffset = 0
				return m, nil
			} else if m.wizard.WasCancelled() {
				m.wizardActive = false
				m.view = viewHome
				m.message = "⚠ Service wizard cancelled"
				m.statusType = statusWarning
				m.statusMessage = "Wizard cancelled, returned to home"
				m.wizard = nil
				m.scrollOffset = 0
				return m, nil
			}
		}
		return m, wizardCmd
	}

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

			// If suggestions are shown and one is selected, use it
			if m.showSuggestions && len(m.suggestions) > 0 {
				m.input.SetValue(m.suggestions[m.selectedSuggestionIndex])
				m.showSuggestions = false
				m.suggestions = nil
				m.selectedSuggestionIndex = 0
				return m, nil
			}

			// Execute command
			command := strings.TrimSpace(m.input.Value())
			m = m.executeCommand(command)
			m.input.SetValue("")
			m.showSuggestions = false
			m.suggestions = nil
			m.selectedSuggestionIndex = 0
			return m, nil

		case "tab":
			// Navigate suggestions with Tab
			if m.showSuggestions && len(m.suggestions) > 0 {
				m.selectedSuggestionIndex = (m.selectedSuggestionIndex + 1) % len(m.suggestions)
				// Update input with selected suggestion
				m.input.SetValue(m.suggestions[m.selectedSuggestionIndex])
				return m, nil
			}
			return m, nil

		case "up":
			// If suggestions visible, navigate them instead of scrolling
			if m.showSuggestions && len(m.suggestions) > 0 {
				m.selectedSuggestionIndex--
				if m.selectedSuggestionIndex < 0 {
					m.selectedSuggestionIndex = len(m.suggestions) - 1
				}
				// Update input with selected suggestion
				m.input.SetValue(m.suggestions[m.selectedSuggestionIndex])
				return m, nil
			}

			// Normal scroll up
			if m.scrollOffset > 0 {
				m.scrollOffset--
			}
			m.exitConfirm = false
			return m, nil

		case "down":
			// If suggestions visible, navigate them instead of scrolling
			if m.showSuggestions && len(m.suggestions) > 0 {
				m.selectedSuggestionIndex = (m.selectedSuggestionIndex + 1) % len(m.suggestions)
				// Update input with selected suggestion
				m.input.SetValue(m.suggestions[m.selectedSuggestionIndex])
				return m, nil
			}

			// Normal scroll down
			if m.scrollOffset < m.maxScroll {
				m.scrollOffset++
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
			// Clamp to maxScroll
			if m.scrollOffset > m.maxScroll {
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
			if m.maxScroll > 0 {
				m.scrollOffset = m.maxScroll
			}
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

	// Update input (only if wizard is not active)
	if !m.wizardActive {
		oldValue := m.input.Value()
		m.input, cmd = m.input.Update(msg)
		newValue := m.input.Value()

		// Update suggestions if input changed
		if oldValue != newValue {
			m.suggestions = m.getSuggestions()
			m.showSuggestions = len(m.suggestions) > 0
			m.selectedSuggestionIndex = 0
		}
	}

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

	// Calculate suggestions area height (0 if hidden)
	// Note: when wizard is active, we don't show suggestions
	suggestionsHeight := 0
	if !m.wizardActive && m.showSuggestions && len(m.suggestions) > 0 {
		// Base height: 1 (top padding) + suggestions + 1 (bottom padding) + 1 (help text)
		suggestionsHeight = 1 + len(m.suggestions) + 2
	}

	contentHeight := m.height - headerHeight - commandBarHeight - statusBarHeight - suggestionsHeight

	// Header
	header := m.renderHeader()

	// Main content
	content := m.renderContent(contentHeight)

	// Command bar
	commandBar := m.renderCommandBar()

	// Suggestions area (if visible and not in wizard mode)
	var suggestionsArea string
	if !m.wizardActive {
		suggestionsArea = m.renderSuggestionsArea()
	}

	// Status bar
	statusBar := m.renderStatusBar()

	// Join all parts vertically
	if suggestionsArea != "" {
		return lipgloss.JoinVertical(
			lipgloss.Left,
			header,
			content,
			commandBar,
			suggestionsArea,
			statusBar,
		)
	}

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
	case viewTable:
		content = m.renderTableView()
	case viewLongOutput:
		content = m.renderLongOutputView()
	case viewServiceWizard:
		// Render wizard to calculate its actual height (especially important in review mode)
		if m.wizard != nil {
			content = m.wizard.RenderForTUI()
		} else {
			content = ""
		}
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
	case viewTable:
		content = m.renderTableView()
	case viewLongOutput:
		content = m.renderLongOutputView()
	case viewServiceWizard:
		// Render wizard integrated in TUI layout
		if m.wizard != nil {
			// Don't add the message prefix for wizard view
			wizardContent := m.wizard.RenderForTUI()

			// Handle scrolling for wizard content
			lines := strings.Split(wizardContent, "\n")
			totalLines := len(lines)
			visibleLines := height - 4
			if visibleLines < 1 {
				visibleLines = 1
			}

			// Apply scrolling if needed
			startLine := m.scrollOffset
			endLine := startLine + visibleLines

			if endLine > totalLines {
				endLine = totalLines
			}
			if startLine >= totalLines {
				startLine = totalLines - 1
				if startLine < 0 {
					startLine = 0
				}
			}

			var visibleContent string
			if startLine < totalLines {
				visibleContentLines := lines[startLine:endLine]
				visibleContent = strings.Join(visibleContentLines, "\n")
			}

			// Add scroll indicator if content is scrollable
			if totalLines > visibleLines {
				scrollInfo := fmt.Sprintf("\n\n%s Scroll: %d-%d of %d lines (↑/↓ or PgUp/PgDn)",
					newHintStyle.Render("↕"),
					startLine+1,
					endLine,
					totalLines)
				visibleContent += scrollInfo
			}

			// Set height and width for content (full-width minus borders)
			style := newContentStyle.Copy().Height(height).Width(m.width - 2)
			return style.Render(visibleContent)
		}
		content = "Service wizard not initialized"
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
		scrollInfo = fmt.Sprintf("\n\n  [%d-%d of %d lines | ↑/↓ arrows | PgUp/PgDn | Home/End]",
			m.scrollOffset+1, endLine, totalLines)
		visibleContent += scrollInfo
	}

	// Set height and width for content (full-width minus borders)
	style := newContentStyle.Copy().Height(height).Width(m.width - 2)
	return style.Render(visibleContent)
}

func (m tuiModel) renderHomeView() string {
	var b strings.Builder

	b.WriteString("\n")
	b.WriteString("  ╭────────────────────────────────────────────────────────────╮\n")
	b.WriteString("  │                                                            │\n")
	b.WriteString("  │  Welcome to PHPHarbor Terminal User Interface!             │\n")
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

func (m tuiModel) renderTableView() string {
	var b strings.Builder

	b.WriteString("📊 PHP Versions Available\n")
	b.WriteString("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n")

	// Define table styles
	headerCellStyle := lipgloss.NewStyle().
		Bold(true).
		Foreground(lipgloss.Color("#FFFFFF")).
		Background(lipgloss.Color("#874BFD")).
		Padding(0, 2).
		Align(lipgloss.Center)

	cellStyle := lipgloss.NewStyle().
		Padding(0, 2).
		Align(lipgloss.Left)

	cellCenterStyle := lipgloss.NewStyle().
		Padding(0, 2).
		Align(lipgloss.Center)

	altRowStyle := lipgloss.NewStyle().
		Background(lipgloss.Color("#1a1a1a")).
		Padding(0, 2)

	// Define column widths
	colVersion := 10
	colStatus := 12
	colJIT := 8
	colPerf := 18
	colUsage := 20

	// Header row
	headerRow := lipgloss.JoinHorizontal(lipgloss.Top,
		headerCellStyle.Width(colVersion).Render("Version"),
		headerCellStyle.Width(colStatus).Render("Status"),
		headerCellStyle.Width(colJIT).Render("JIT"),
		headerCellStyle.Width(colPerf).Render("Performance"),
		headerCellStyle.Width(colUsage).Render("Common Use"),
	)

	// Data rows
	type phpVersion struct {
		version string
		status  string
		jit     string
		perf    string
		usage   string
	}

	versions := []phpVersion{
		{"PHP 7.3", "Legacy", "No", "⭐⭐⭐", "Old projects"},
		{"PHP 7.4", "EOL", "No", "⭐⭐⭐", "Legacy apps"},
		{"PHP 8.1", "Security", "Yes", "⭐⭐⭐⭐", "Stable production"},
		{"PHP 8.2", "Active", "Yes", "⭐⭐⭐⭐⭐", "Modern apps"},
		{"PHP 8.3", "Active", "Yes", "⭐⭐⭐⭐⭐", "Latest stable"},
		{"PHP 8.4", "Beta", "Yes", "⭐⭐⭐⭐⭐+", "Bleeding edge"},
		{"PHP 8.5", "Dev", "Yes", "⭐⭐⭐⭐⭐+", "Experimental"},
	}

	var rows []string
	rows = append(rows, headerRow)

	for i, v := range versions {
		// Alternate row styling
		rowCellStyle := cellStyle
		rowCenterStyle := cellCenterStyle
		if i%2 == 1 {
			rowCellStyle = altRowStyle.Copy().Align(lipgloss.Left)
			rowCenterStyle = altRowStyle.Copy().Align(lipgloss.Center)
		}

		// Status color coding
		statusStyle := rowCenterStyle.Copy()
		switch v.status {
		case "Active":
			statusStyle = statusStyle.Foreground(lipgloss.Color("#00FF88"))
		case "Beta", "Dev":
			statusStyle = statusStyle.Foreground(lipgloss.Color("#FFAA00"))
		case "Security":
			statusStyle = statusStyle.Foreground(lipgloss.Color("#00AAFF"))
		case "EOL", "Legacy":
			statusStyle = statusStyle.Foreground(lipgloss.Color("#FF4444"))
		}

		// JIT color
		jitStyle := rowCenterStyle.Copy()
		if v.jit == "Yes" {
			jitStyle = jitStyle.Foreground(lipgloss.Color("#00FF88"))
		} else {
			jitStyle = jitStyle.Foreground(lipgloss.Color("#666666"))
		}

		row := lipgloss.JoinHorizontal(lipgloss.Top,
			rowCellStyle.Width(colVersion).Render(v.version),
			statusStyle.Width(colStatus).Render(v.status),
			jitStyle.Width(colJIT).Render(v.jit),
			rowCenterStyle.Width(colPerf).Render(v.perf),
			rowCellStyle.Width(colUsage).Render(v.usage),
		)
		rows = append(rows, row)
	}

	// Join all rows vertically
	table := lipgloss.JoinVertical(lipgloss.Left, rows...)

	// Add table with border
	tableStyle := lipgloss.NewStyle().
		Border(lipgloss.RoundedBorder()).
		BorderForeground(lipgloss.Color("#874BFD")).
		Padding(1, 2)

	b.WriteString(tableStyle.Render(table))

	b.WriteString("\n\n")
	b.WriteString(lipgloss.NewStyle().Foreground(lipgloss.Color("#888888")).Render("💡 Tip: Use /service to configure custom services with these PHP versions"))
	b.WriteString("\n")
	b.WriteString(lipgloss.NewStyle().Foreground(lipgloss.Color("#00d4ff")).Render("Press ESC or type /home to return"))

	return b.String()
}

func (m tuiModel) renderCommandBar() string {
	// When wizard is active, show a disabled command bar
	if m.wizardActive {
		disabledStyle := lipgloss.NewStyle().
			Foreground(lipgloss.Color("#444444")).
			Italic(true)
		content := disabledStyle.Render(" ⊗  Command input disabled during wizard")
		return newCommandBarContainerStyle.Width(m.width).Render(content)
	}

	// Command input with prompt
	prompt := newCommandPromptStyle.Render(" ➜ ")
	content := prompt + m.input.View()

	return newCommandBarContainerStyle.Width(m.width).Render(content)
}

func (m tuiModel) renderSuggestionsArea() string {
	if !m.showSuggestions || len(m.suggestions) == 0 {
		return ""
	}

	var b strings.Builder
	b.WriteString("\n")

	// Get command descriptions for display
	cmdDescriptions := make(map[string]string)
	for _, cmd := range commands {
		cmdDescriptions["/"+cmd.name] = cmd.desc
	}

	// Render each suggestion
	for i, suggestion := range m.suggestions {
		var line string
		desc := cmdDescriptions[suggestion]

		if i == m.selectedSuggestionIndex {
			// Selected item
			line = suggestionItemSelectedStyle.Render(fmt.Sprintf("  ▸ %-12s", suggestion))
			if desc != "" {
				line += suggestionItemSelectedStyle.Render(fmt.Sprintf("  %s", desc))
			}
		} else {
			// Normal item
			line = suggestionItemStyle.Render(fmt.Sprintf("    %-12s", suggestion))
			if desc != "" {
				line += suggestionDescStyle.Render(fmt.Sprintf("  %s", desc))
			}
		}

		b.WriteString(line + "\n")
	}

	b.WriteString("\n")
	b.WriteString(suggestionDescStyle.Render("  ↑/↓ or Tab to navigate | Enter to select | Type to filter"))

	return suggestionsContainerStyle.Render(b.String())
}

func (m tuiModel) renderStatusBar() string {
	// If wizard is active, show wizard-specific status
	if m.wizardActive {
		style := statusBarInfoStyle
		icon := "🔧"
		message := fmt.Sprintf("%s  Service Configuration Wizard Active - Use arrow keys to navigate", icon)
		return style.Width(m.width).Render(message)
	}

	// Check if user is actively typing
	currentInput := strings.TrimSpace(m.input.Value())
	isTyping := currentInput != ""

	// Select style based on status type
	var style lipgloss.Style
	var icon string
	var message string

	// If user is typing, always show hints with info style
	if isTyping {
		style = statusBarInfoStyle
		icon = "ℹ"
		hint := m.getHint()
		message = fmt.Sprintf("%s  %s", icon, hint)
	} else {
		// Not typing - show status message
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

		// Show message or default hint
		if m.statusMessage == "Ready" || m.statusMessage == "" {
			hint := m.getHint()
			message = fmt.Sprintf("%s  Ready - %s", icon, hint)
		} else {
			message = fmt.Sprintf("%s  %s", icon, m.statusMessage)
		}
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
		// Get suggestions
		suggestions := m.getSuggestions()

		if len(suggestions) > 0 {
			return fmt.Sprintf("Suggestions: %s", strings.Join(suggestions, ", "))
		}

		return "Press Enter to execute | ESC to quit"
	}

	// If no "/" prefix, suggest adding it
	return "Commands must start with '/' (e.g., /help, /list)"
}

// getSuggestions returns matching command suggestions based on current input
func (m tuiModel) getSuggestions() []string {
	input := strings.TrimSpace(m.input.Value())

	if input == "" || !strings.HasPrefix(input, "/") {
		return nil
	}

	// Remove the "/" for matching
	searchTerm := strings.ToLower(strings.TrimPrefix(input, "/"))

	// Find matching commands
	var matches []string
	for _, cmd := range commands {
		if strings.HasPrefix(cmd.name, searchTerm) {
			matches = append(matches, "/"+cmd.name)
		}
	}

	return matches
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
	case "table", "data":
		m.view = viewTable
		m.message = "✓ Showing tabular data"
		m.statusType = statusSuccess
		m.statusMessage = "PHP versions table displayed"
		m.scrollOffset = 0
	case "service", "wizard":
		// Launch the service configuration wizard
		wizard := newAdvancedServiceWizard()
		wizard.width = m.width
		wizard.height = m.height
		m.wizard = &wizard
		m.wizardActive = true
		m.view = viewServiceWizard
		m.message = ""
		m.statusType = statusInfo
		m.statusMessage = "Service wizard launched"
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
