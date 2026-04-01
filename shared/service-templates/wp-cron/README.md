# WordPress WP-Cron Worker

Dedicated container that runs WordPress cron jobs (`wp-cron.php`) every 5 minutes.

## What it does

- Runs `wp-cron.php` in a separate container
- Executes every 5 minutes (300 seconds)
- Prevents cron from running on every page load
- Better performance for production-like environments

## Why use it?

By default, WordPress runs cron on every page load, which can slow down your site. This container runs cron jobs in the background independently of visitor traffic.

## Configuration

### Disable WordPress built-in cron

Add to your `wp-config.php`:

```php
define('DISABLE_WP_CRON', true);
```

This prevents WordPress from running cron on page loads.

## Customization

### Change execution interval

Edit the `sleep` value in `docker-compose.override.yml`:

```yaml
sleep 300;  # 300 seconds = 5 minutes
sleep 60;   # 1 minute
sleep 3600; # 1 hour
```

### Add custom commands

You can add custom WP-CLI commands:

```yaml
command: >
  sh -c "while true; do
    echo '[WP-Cron] Running at $$(date)';
    php /var/www/html/wp-cron.php;
    wp custom-command --allow-root;
    sleep 300;
  done"
```

## View logs

```bash
docker logs <project-name>-wp-cron -f
```

## Notes

- Requires WordPress to be installed
- Uses the same PHP image as your main app container
- Shares the same database and file system
