package main

import (
	"fmt"
	"strings"

	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
)

// Table model for displaying tabular data
type tableModel struct {
	title   string
	headers []string
	rows    [][]string
	width   int
	height  int
}

var (
	tableHeaderStyle = lipgloss.NewStyle().
				Bold(true).
				Foreground(lipgloss.Color("#00d4ff")).
				BorderBottom(true).
				BorderForeground(lipgloss.Color("#874BFD"))

	tableRowStyle = lipgloss.NewStyle().
			Foreground(lipgloss.Color("#FFFFFF"))

	tableAltRowStyle = lipgloss.NewStyle().
				Foreground(lipgloss.Color("#CCCCCC"))

	tableTitleStyle = lipgloss.NewStyle().
			Bold(true).
			Foreground(lipgloss.Color("#00d4ff")).
			MarginBottom(1)

	tableBorderStyle = lipgloss.NewStyle().
				Foreground(lipgloss.Color("#874BFD"))
)

// Create a new stats table (simulating ./phpharbor stats disk output)
func newStatsTable() tableModel {
	return tableModel{
		title: "📊 PHPHarbor Disk Usage Statistics",
		headers: []string{
			"COMPONENT",
			"TYPE",
			"SIZE",
			"STATUS",
			"CONTAINERS",
		},
		rows: [][]string{
			{"nginx-proxy", "System", "142 MB", "running", "1"},
			{"php-8.5-shared", "Shared Service", "523 MB", "running", "1"},
			{"php-8.3-shared", "Shared Service", "498 MB", "running", "1"},
			{"mysql-8.0-shared", "Shared Service", "456 MB", "running", "1"},
			{"redis-7-shared", "Shared Service", "78 MB", "running", "1"},
			{"mailpit", "System", "37 MB", "running", "1"},
			{"laravel-1", "Project", "12 MB", "running", "2"},
			{"laravel-2", "Project", "12 MB", "stopped", "2"},
			{"volumes/mysql", "Volume", "2.3 GB", "-", "-"},
			{"volumes/redis", "Volume", "45 MB", "-", "-"},
		},
	}
}

// Create a project list table
func newProjectsTable() tableModel {
	return tableModel{
		title: "📦 PHPHarbor Projects",
		headers: []string{
			"NAME",
			"TYPE",
			"PHP VERSION",
			"STATUS",
			"DOMAIN",
			"CONTAINERS",
		},
		rows: [][]string{
			{"laravel-1", "Laravel", "8.5", "running", "laravel-1.test", "2/2"},
			{"laravel-2", "Laravel", "8.3", "stopped", "laravel-2.test", "0/2"},
			{"wordpress-site", "WordPress", "8.2", "running", "wordpress-site.test", "2/2"},
			{"api-backend", "PHP", "8.4", "running", "api-backend.test", "2/2"},
			{"legacy-app", "PHP", "7.4", "stopped", "legacy-app.test", "0/2"},
		},
	}
}

func (m tableModel) Init() tea.Cmd {
	return nil
}

func (m tableModel) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.KeyMsg:
		switch msg.String() {
		case "q", "esc", "ctrl+c":
			return m, tea.Quit
		}

	case tea.WindowSizeMsg:
		m.width = msg.Width
		m.height = msg.Height
	}

	return m, nil
}

func (m tableModel) View() string {
	if m.width == 0 {
		return "Loading..."
	}

	// Title
	title := tableTitleStyle.Render(m.title)

	// Calculate column widths based on content
	colWidths := m.calculateColumnWidths()

	// Render header
	headerParts := make([]string, len(m.headers))
	for i, h := range m.headers {
		headerParts[i] = padString(h, colWidths[i])
	}
	header := tableHeaderStyle.Render(strings.Join(headerParts, "  "))

	// Render rows
	var rows []string
	for i, row := range m.rows {
		rowParts := make([]string, len(row))
		for j, cell := range row {
			rowParts[j] = padString(cell, colWidths[j])
		}
		rowText := strings.Join(rowParts, "  ")

		// Alternate row colors
		if i%2 == 0 {
			rows = append(rows, tableRowStyle.Render(rowText))
		} else {
			rows = append(rows, tableAltRowStyle.Render(rowText))
		}
	}

	// Top border
	totalWidth := 0
	for i, w := range colWidths {
		totalWidth += w
		if i < len(colWidths)-1 {
			totalWidth += 2 // Space between columns
		}
	}
	topBorder := tableBorderStyle.Render(strings.Repeat("─", totalWidth))

	// Summary
	summary := fmt.Sprintf("\nTotal entries: %d", len(m.rows))
	help := wizardHelpStyle.Render("Press 'q' or 'Esc' to return")

	// Combine everything
	content := lipgloss.JoinVertical(
		lipgloss.Left,
		title,
		"",
		topBorder,
		header,
		strings.Join(rows, "\n"),
		topBorder,
		summary,
		"",
		help,
	)

	return content
}

// Calculate optimal column widths based on content
func (m tableModel) calculateColumnWidths() []int {
	if len(m.headers) == 0 {
		return []int{}
	}

	widths := make([]int, len(m.headers))

	// Start with header widths
	for i, h := range m.headers {
		widths[i] = len(h)
	}

	// Check each row
	for _, row := range m.rows {
		for i, cell := range row {
			if i < len(widths) && len(cell) > widths[i] {
				widths[i] = len(cell)
			}
		}
	}

	// Add some padding
	for i := range widths {
		widths[i] += 2
	}

	return widths
}

// Pad string to specified width
func padString(s string, width int) string {
	if len(s) >= width {
		return s[:width]
	}
	return s + strings.Repeat(" ", width-len(s))
}

// Table with summary statistics
type statsOverviewModel struct {
	sections []statsSection
	width    int
	height   int
}

type statsSection struct {
	title string
	items []statsItem
}

type statsItem struct {
	label string
	value string
}

func newStatsOverview() statsOverviewModel {
	return statsOverviewModel{
		sections: []statsSection{
			{
				title: "🐳 Docker Resources",
				items: []statsItem{
					{"Total Images", "23"},
					{"Total Containers", "15 (8 running)"},
					{"Total Volumes", "12"},
					{"Networks", "3"},
				},
			},
			{
				title: "💾 Disk Usage",
				items: []statsItem{
					{"Images", "3.2 GB"},
					{"Containers", "124 MB"},
					{"Volumes", "4.8 GB"},
					{"Build Cache", "890 MB"},
					{"Total", "9.0 GB"},
				},
			},
			{
				title: "📦 PHPHarbor Projects",
				items: []statsItem{
					{"Total Projects", "5"},
					{"Running", "3"},
					{"Stopped", "2"},
					{"Shared Services", "4 running"},
				},
			},
		},
	}
}

func (m statsOverviewModel) Init() tea.Cmd {
	return nil
}

func (m statsOverviewModel) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.KeyMsg:
		switch msg.String() {
		case "q", "esc", "ctrl+c":
			return m, tea.Quit
		}

	case tea.WindowSizeMsg:
		m.width = msg.Width
		m.height = msg.Height
	}

	return m, nil
}

func (m statsOverviewModel) View() string {
	title := tableTitleStyle.Render("📊 PHPHarbor System Overview")

	var sections []string
	for _, section := range m.sections {
		sectionTitle := wizardTitleStyle.Render(section.title)
		var items []string
		for _, item := range section.items {
			items = append(items, fmt.Sprintf("  %-25s %s", item.label+":", item.value))
		}
		sectionContent := strings.Join(items, "\n")
		sections = append(sections, sectionTitle+"\n"+sectionContent)
	}

	help := wizardHelpStyle.Render("\nPress 'q' or 'Esc' to return")

	content := lipgloss.JoinVertical(
		lipgloss.Left,
		title,
		"",
		strings.Join(sections, "\n\n"),
		help,
	)

	return content
}
