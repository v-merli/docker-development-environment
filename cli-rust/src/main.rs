mod tui;

use clap::{Parser, Subcommand};
use colored::Colorize;

#[derive(Parser)]
#[command(name = "phpharbor")]
#[command(about = "PHPHarbor - Docker development environment", long_about = None)]
struct Cli {
    #[command(subcommand)]
    command: Option<Commands>,
}

#[derive(Subcommand)]
enum Commands {
    /// Create a new project
    Create {
        /// Project name
        name: String,
        
        /// Project type (laravel/wordpress/php/html)
        #[arg(short, long)]
        project_type: Option<String>,
        
        /// PHP version
        #[arg(long)]
        php: Option<String>,
    },
    
    /// List all projects
    List,
    
    /// Start a project
    Start {
        /// Project name
        name: String,
    },
    
    /// Show statistics
    Stats {
        /// Stats type (disk)
        #[arg(value_name = "TYPE")]
        stats_type: String,
    },
    
    /// Show version
    Version,
    
    /// Launch interactive TUI mode
    Tui,
}

fn main() {
    let cli = Cli::parse();

    match &cli.command {
        Some(Commands::Create { name, project_type, php }) => {
            println!("{}", "Creating project...".green());
            println!("Name: {}", name);
            if let Some(pt) = project_type {
                println!("Type: {}", pt);
            }
            if let Some(php_ver) = php {
                println!("PHP: {}", php_ver);
            }
            // TODO: Implement project creation
        }
        
        Some(Commands::List) => {
            println!("{}", "Available Projects".cyan().bold());
            println!("───────────────────────────────────────");
            // TODO: Implement project listing
            println!("  • laravel-1 (running)");
            println!("  • laravel-2 (stopped)");
        }
        
        Some(Commands::Start { name }) => {
            println!("{}", format!("Starting project: {}", name).green());
            // TODO: Implement project start
        }
        
        Some(Commands::Stats { stats_type }) => {
            if stats_type == "disk" {
                println!("{}", "📊 PHPHarbor Disk Usage Statistics\n".cyan().bold());
                println!("┌────────────────────┬──────────┬──────────┬──────────┬─────────┐");
                println!("│ Project            │ Size     │ Images   │ Volumes  │ Status  │");
                println!("├────────────────────┼──────────┼──────────┼──────────┼─────────┤");
                println!("│ myapp-1            │ 1.2 GB   │ 3        │ 2        │ running │");
                println!("│ wordpress-blog     │ 856 MB   │ 4        │ 3        │ stopped │");
                println!("│ api-service        │ 445 MB   │ 2        │ 1        │ running │");
                println!("│ test-laravel       │ 1.5 GB   │ 5        │ 4        │ stopped │");
                println!("├────────────────────┼──────────┼──────────┼──────────┼─────────┤");
                println!("│ TOTAL              │ 3.9 GB   │ 14       │ 10       │ 2/4     │");
                println!("└────────────────────┴──────────┴──────────┴──────────┴─────────┘");
                println!("\nShared Services:");
                println!("  • MySQL 8.0      - 512 MB");
                println!("  • Redis 7.2      - 89 MB");
                println!("  • Mailhog        - 45 MB");
                println!("\n{}", "Total Disk Usage: 4.5 GB".green().bold());
            } else {
                println!("{}", format!("Unknown stats type: {}", stats_type).red());
            }
        }
        
        Some(Commands::Version) => {
            println!("PHPHarbor v0.1.0 (Rust experiment)");
        }
        
        Some(Commands::Tui) | None => {
            // Launch TUI mode (default when no command is provided)
            if let Err(e) = tui::run() {
                eprintln!("Error running TUI: {}", e);
                std::process::exit(1);
            }
        }
    }
}
