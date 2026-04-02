use crossterm::{
    event::{self, DisableMouseCapture, EnableMouseCapture, Event, KeyCode, KeyEventKind},
    execute,
    terminal::{disable_raw_mode, enable_raw_mode, EnterAlternateScreen, LeaveAlternateScreen},
};
use ratatui::{
    backend::{Backend, CrosstermBackend},
    layout::{Constraint, Direction, Layout},
    style::{Color, Modifier, Style},
    text::{Line, Span},
    widgets::{Block, Borders, List, ListItem, Paragraph},
    Frame, Terminal,
};
use std::io;

pub struct App {
    input: String,
    output: Vec<String>,
    cursor_position: usize,
    should_quit: bool,
    interactive_mode: Option<InteractiveMode>,
}

#[derive(Clone)]
struct InteractiveMode {
    command: String,
    questions: Vec<Question>,
    current_question: usize,
    answers: Vec<String>,
}

#[derive(Clone)]
struct Question {
    prompt: String,
    default: Option<String>,
}

impl App {
    pub fn new() -> App {
        let welcome_msg = vec![
            String::from("Welcome to PHPHarbor - Docker Development Environment"),
            String::from(""),
            String::from("Available commands:"),
            String::from("  • create - Create a new project (interactive)"),
            String::from("  • list - List all projects"),
            String::from("  • start <name> - Start a project"),
            String::from("  • stop <name> - Stop a project"),
            String::from("  • stats disk - Show disk usage statistics"),
            String::from("  • help - Show this help"),
            String::from("  • quit - Exit application"),
            String::from(""),
            String::from("Type a command and press Enter..."),
        ];
        
        App {
            input: String::new(),
            output: welcome_msg,
            cursor_position: 0,
            should_quit: false,
            interactive_mode: None,
        }
    }

    pub fn handle_input(&mut self, c: char) {
        self.input.insert(self.cursor_position, c);
        self.cursor_position += 1;
    }

    pub fn delete_char(&mut self) {
        if self.cursor_position > 0 {
            self.input.remove(self.cursor_position - 1);
            self.cursor_position -= 1;
        }
    }

    pub fn move_cursor_left(&mut self) {
        if self.cursor_position > 0 {
            self.cursor_position -= 1;
        }
    }

    pub fn move_cursor_right(&mut self) {
        if self.cursor_position < self.input.len() {
            self.cursor_position += 1;
        }
    }

    pub fn execute_command(&mut self) {
        let cmd = self.input.trim().to_string();
        
        if cmd.is_empty() {
            return;
        }

        // Handle interactive mode
        if let Some(ref mut mode) = self.interactive_mode {
            self.handle_interactive_answer(cmd);
            return;
        }

        self.output.push(format!("> {}", cmd));
        
        let parts: Vec<&str> = cmd.split_whitespace().collect();
        let command = parts.get(0).unwrap_or(&"");
        
        match *command {
            "quit" | "exit" => {
                self.should_quit = true;
            }
            "help" => {
                self.output.push(String::from(""));
                self.output.push(String::from("Available commands:"));
                self.output.push(String::from("  • create - Create a new project (interactive)"));
                self.output.push(String::from("  • list - List all projects"));
                self.output.push(String::from("  • start <name> - Start a project"));
                self.output.push(String::from("  • stop <name> - Stop a project"));
                self.output.push(String::from("  • stats disk - Show disk usage statistics"));
                self.output.push(String::from("  • help - Show this help"));
                self.output.push(String::from("  • quit - Exit application"));
            }
            "create" => {
                self.start_interactive_create();
            }
            "stats" => {
                if parts.get(1) == Some(&"disk") {
                    self.show_disk_stats();
                } else {
                    self.output.push(String::from(""));
                    self.output.push(String::from("✗ Usage: stats disk"));
                }
            }
            "list" => {
                self.output.push(String::from(""));
                self.output.push(String::from("Projects:"));
                self.output.push(String::from("  • myapp-1 [running] - Laravel 10 (PHP 8.3)"));
                self.output.push(String::from("  • wordpress-blog [stopped] - WordPress 6.4 (PHP 8.2)"));
                self.output.push(String::from("  • api-service [running] - PHP 8.3"));
                self.output.push(String::from(""));
                self.output.push(String::from("Total: 3 projects (2 running)"));
            }
            "start" => {
                if let Some(name) = parts.get(1) {
                    self.output.push(String::from(""));
                    self.output.push(format!("Starting project '{}'...", name));
                    self.output.push(String::from("  ✓ Starting containers..."));
                    self.output.push(String::from("  ✓ Waiting for services..."));
                    self.output.push(format!("✓ Project '{}' is now running!", name));
                    self.output.push(format!("  → https://{}.test", name));
                } else {
                    self.output.push(String::from(""));
                    self.output.push(String::from("✗ Error: Project name required"));
                    self.output.push(String::from("  Usage: start <name>"));
                }
            }
            "stop" => {
                if let Some(name) = parts.get(1) {
                    self.output.push(String::from(""));
                    self.output.push(format!("Stopping project '{}'...", name));
                    self.output.push(String::from("  ✓ Stopping containers..."));
                    self.output.push(format!("✓ Project '{}' stopped", name));
                } else {
                    self.output.push(String::from(""));
                    self.output.push(String::from("✗ Error: Project name required"));
                    self.output.push(String::from("  Usage: stop <name>"));
                }
            }
            _ => {
                self.output.push(String::from(""));
                self.output.push(format!("✗ Unknown command: '{}'", command));
                self.output.push(String::from("  Type 'help' for available commands"));
            }
        }
        
        self.output.push(String::from(""));
        self.input.clear();
        self.cursor_position = 0;
    }

    fn start_interactive_create(&mut self) {
        self.output.push(String::from(""));
        self.output.push(String::from("🎨 Creating a new project..."));
        self.output.push(String::from(""));
        
        let questions = vec![
            Question {
                prompt: String::from("Project name"),
                default: None,
            },
            Question {
                prompt: String::from("Project type (laravel/wordpress/php/html)"),
                default: Some(String::from("laravel")),
            },
            Question {
                prompt: String::from("PHP version (7.3/7.4/8.0/8.1/8.2/8.3)"),
                default: Some(String::from("8.3")),
            },
            Question {
                prompt: String::from("Enable MySQL? (yes/no)"),
                default: Some(String::from("yes")),
            },
        ];

        self.interactive_mode = Some(InteractiveMode {
            command: String::from("create"),
            questions: questions.clone(),
            current_question: 0,
            answers: Vec::new(),
        });

        self.show_current_question();
    }

    fn show_current_question(&mut self) {
        if let Some(ref mode) = self.interactive_mode {
            if mode.current_question < mode.questions.len() {
                let q = &mode.questions[mode.current_question];
                let prompt = if let Some(ref default) = q.default {
                    format!("❓ {} [{}]: ", q.prompt, default)
                } else {
                    format!("❓ {}: ", q.prompt)
                };
                self.output.push(prompt);
            }
        }
        self.input.clear();
        self.cursor_position = 0;
    }

    fn handle_interactive_answer(&mut self, answer: String) {
        if let Some(ref mut mode) = self.interactive_mode {
            let q = &mode.questions[mode.current_question];
            let final_answer = if answer.is_empty() {
                q.default.clone().unwrap_or(String::from(""))
            } else {
                answer
            };

            self.output.push(format!("  → {}", final_answer));
            mode.answers.push(final_answer);
            mode.current_question += 1;

            if mode.current_question < mode.questions.len() {
                self.show_current_question();
            } else {
                self.finish_interactive_create();
            }
        }
    }

    fn finish_interactive_create(&mut self) {
        if let Some(mode) = self.interactive_mode.take() {
            self.output.push(String::from(""));
            self.output.push(String::from("✓ Creating project with configuration:"));
            
            if let Some(name) = mode.answers.get(0) {
                self.output.push(format!("  • Name: {}", name));
            }
            if let Some(ptype) = mode.answers.get(1) {
                self.output.push(format!("  • Type: {}", ptype));
            }
            if let Some(php) = mode.answers.get(2) {
                self.output.push(format!("  • PHP: {}", php));
            }
            if let Some(mysql) = mode.answers.get(3) {
                self.output.push(format!("  • MySQL: {}", mysql));
            }

            self.output.push(String::from(""));
            self.output.push(String::from("✓ Generating docker-compose.yml..."));
            self.output.push(String::from("✓ Creating project structure..."));
            self.output.push(String::from("✓ Setting up configuration..."));
            
            if let Some(name) = mode.answers.get(0) {
                self.output.push(String::from(""));
                self.output.push(format!("✓ Project '{}' created successfully!", name));
                self.output.push(format!("  → Start with: start {}", name));
            }
            
            self.output.push(String::from(""));
        }
        self.input.clear();
        self.cursor_position = 0;
    }

    fn show_disk_stats(&mut self) {
        self.output.push(String::from(""));
        self.output.push(String::from("📊 PHPHarbor Disk Usage Statistics"));
        self.output.push(String::from(""));
        self.output.push(String::from("┌────────────────────┬──────────┬──────────┬──────────┬─────────┐"));
        self.output.push(String::from("│ Project            │ Size     │ Images   │ Volumes  │ Status  │"));
        self.output.push(String::from("├────────────────────┼──────────┼──────────┼──────────┼─────────┤"));
        self.output.push(String::from("│ myapp-1            │ 1.2 GB   │ 3        │ 2        │ running │"));
        self.output.push(String::from("│ wordpress-blog     │ 856 MB   │ 4        │ 3        │ stopped │"));
        self.output.push(String::from("│ api-service        │ 445 MB   │ 2        │ 1        │ running │"));
        self.output.push(String::from("│ test-laravel       │ 1.5 GB   │ 5        │ 4        │ stopped │"));
        self.output.push(String::from("├────────────────────┼──────────┼──────────┼──────────┼─────────┤"));
        self.output.push(String::from("│ TOTAL              │ 3.9 GB   │ 14       │ 10       │ 2/4     │"));
        self.output.push(String::from("└────────────────────┴──────────┴──────────┴──────────┴─────────┘"));
        self.output.push(String::from(""));
        self.output.push(String::from("Shared Services:"));
        self.output.push(String::from("  • MySQL 8.0      - 512 MB"));
        self.output.push(String::from("  • Redis 7.2      - 89 MB"));
        self.output.push(String::from("  • Mailhog        - 45 MB"));
        self.output.push(String::from(""));
        self.output.push(String::from("Total Disk Usage: 4.5 GB"));
    }
}

pub fn run() -> Result<(), Box<dyn std::error::Error>> {
    enable_raw_mode()?;
    let mut stdout = io::stdout();
    execute!(stdout, EnterAlternateScreen, EnableMouseCapture)?;
    let backend = CrosstermBackend::new(stdout);
    let mut terminal = Terminal::new(backend)?;

    let mut app = App::new();
    let res = run_app(&mut terminal, &mut app);

    disable_raw_mode()?;
    execute!(
        terminal.backend_mut(),
        LeaveAlternateScreen,
        DisableMouseCapture
    )?;
    terminal.show_cursor()?;

    if let Err(err) = res {
        println!("{:?}", err)
    }

    Ok(())
}

fn run_app<B: Backend>(terminal: &mut Terminal<B>, app: &mut App) -> io::Result<()> {
    loop {
        terminal.draw(|f| ui(f, app))?;

        if let Event::Key(key) = event::read()? {
            if key.kind == KeyEventKind::Press {
                match key.code {
                    KeyCode::Enter => app.execute_command(),
                    KeyCode::Char(c) => app.handle_input(c),
                    KeyCode::Backspace => app.delete_char(),
                    KeyCode::Left => app.move_cursor_left(),
                    KeyCode::Right => app.move_cursor_right(),
                    KeyCode::Esc => app.should_quit = true,
                    _ => {}
                }
            }
        }

        if app.should_quit {
            return Ok(());
        }
    }
}

fn ui(f: &mut Frame, app: &App) {
    let size = f.size();

    let chunks = Layout::default()
        .direction(Direction::Vertical)
        .constraints([
            Constraint::Length(7),  // Logo (5 lines + padding)
            Constraint::Min(1),     // Output
            Constraint::Length(3),  // Input
        ])
        .split(size);

    // Logo with retro terminal gradient (green -> cyan -> blue)
    let logo_lines = vec![
        Line::from(vec![
            Span::styled("    ____  __  ______     __  __           __             ", Style::default().fg(Color::Green)),
        ]),
        Line::from(vec![
            Span::styled("   / __ \\/ / / / __ \\   / / / /___ ______/ /_  ____  _____", Style::default().fg(Color::LightGreen)),
        ]),
        Line::from(vec![
            Span::styled("  / /_/ / /_/ / /_/ /  / /_/ / __ `/ ___/ __ \\/ __ \\/ ___/", Style::default().fg(Color::Cyan)),
        ]),
        Line::from(vec![
            Span::styled(" / ____/ __  / ____/  / __  / /_/ / /  / /_/ / /_/ / /    ", Style::default().fg(Color::LightBlue)),
        ]),
        Line::from(vec![
            Span::styled("/_/   /_/ /_/_/      /_/ /_/\\__,_/_/  /_.___/\\____/_/     ", Style::default().fg(Color::Blue)),
        ]),
        Line::from(vec![
            Span::styled("                    Docker Development Environment", Style::default().fg(Color::DarkGray)),
        ]),
    ];
    
    let logo = Paragraph::new(logo_lines);
    f.render_widget(logo, chunks[0]);

    // Output area
    let output_items: Vec<ListItem> = app
        .output
        .iter()
        .rev()
        .take(chunks[1].height as usize - 2)
        .rev()
        .map(|line| {
            let style = if line.starts_with('>') {
                Style::default().fg(Color::Yellow).add_modifier(Modifier::BOLD)
            } else if line.starts_with('✓') {
                Style::default().fg(Color::Green)
            } else if line.starts_with('✗') {
                Style::default().fg(Color::Red)
            } else if line.starts_with("  →") {
                Style::default().fg(Color::Blue).add_modifier(Modifier::UNDERLINED)
            } else {
                Style::default().fg(Color::White)
            };
            ListItem::new(line.as_str()).style(style)
        })
        .collect();

    let output = List::new(output_items)
        .block(
            Block::default()
                .borders(Borders::ALL)
                .title("Output")
                .style(Style::default().fg(Color::DarkGray)),
        );
    f.render_widget(output, chunks[1]);

    // Input area
    let input = Paragraph::new(app.input.as_str())
        .style(Style::default().fg(Color::Yellow))
        .block(
            Block::default()
                .borders(Borders::ALL)
                .title("Command (ESC to quit)")
                .style(Style::default().fg(Color::DarkGray)),
        );
    f.render_widget(input, chunks[2]);

    // Cursor
    f.set_cursor(
        chunks[2].x + app.cursor_position as u16 + 1,
        chunks[2].y + 1,
    );
}
