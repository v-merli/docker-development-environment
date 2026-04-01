# Mailhog - Email Testing

Mailhog is an email testing tool that captures all outgoing emails without sending them.

## What it does

- Captures all SMTP emails sent by your application
- Provides a web interface to view captured emails
- No real emails are sent (perfect for development)

## Access

- **Web UI**: http://localhost:8025
- **SMTP Server**: mailhog:1025 (from within containers)

## Configuration

### Laravel

In your `.env` file or `app/.env`:

```env
MAIL_MAILER=smtp
MAIL_HOST=mailhog
MAIL_PORT=1025
MAIL_USERNAME=null
MAIL_PASSWORD=null
MAIL_ENCRYPTION=null
```

### WordPress

Install a SMTP plugin (e.g., WP Mail SMTP) and configure:

- **SMTP Host**: mailhog
- **SMTP Port**: 1025
- **Encryption**: None
- **Authentication**: None

### Generic PHP

```php
ini_set('SMTP', 'mailhog');
ini_set('smtp_port', '1025');
```

Or use a library like PHPMailer:

```php
$mail = new PHPMailer();
$mail->isSMTP();
$mail->Host = 'mailhog';
$mail->Port = 1025;
$mail->SMTPAuth = false;
```

## Usage

1. Send emails from your application
2. Open http://localhost:8025 in your browser
3. View all captured emails in the Mailhog interface

## Notes

- Port 8025 must be available on your host machine
- Emails are NOT persisted when the container restarts
- Perfect for testing email functionality during development
