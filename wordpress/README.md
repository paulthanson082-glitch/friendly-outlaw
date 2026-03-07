# WordPress Integration

SEO Machine can publish content directly to WordPress via the REST API using the `/publish-draft` and `/landing-publish` commands.

## Setup

### 1. Install the MU-Plugin

Copy `seo-machine-yoast-rest.php` to your WordPress site's MU-plugins directory:

```bash
cp wordpress/seo-machine-yoast-rest.php /path/to/wordpress/wp-content/mu-plugins/
```

This plugin exposes Yoast SEO meta fields via the REST API. It requires Yoast SEO to be installed.

### 2. Create an Application Password

1. Log in to WordPress Admin
2. Go to: **Users → Profile** (or your user profile)
3. Scroll to **Application Passwords**
4. Enter name: `SEO Machine`
5. Click **Add New Application Password**
6. Copy the generated password (you won't see it again)

### 3. Configure Environment Variables

Add to your `.env` file:

```
WP_URL=https://yoursite.com
WP_USERNAME=your_wp_username
WP_APP_PASSWORD=xxxx xxxx xxxx xxxx xxxx xxxx
```

The app password format includes spaces — that's normal. Include them as-is.

### 4. Test the Connection

```bash
curl -X GET \
  "https://yoursite.com/wp-json/wp/v2/posts?status=draft&per_page=1" \
  -H "Authorization: Basic $(echo -n 'username:app_password' | base64)"
```

A successful response returns JSON with post data.

## How Publishing Works

When you run `/publish-draft [file]`:

1. SEO Machine reads the article's frontmatter for meta elements
2. Converts Markdown to HTML
3. Creates a WordPress **draft** post (not published) via REST API
4. Sets Yoast SEO fields: title, description, focus keyword
5. Returns the post ID, draft URL, and edit link

Posts are always created as **drafts** by default. Review in WordPress before publishing.

## API Endpoints Used

| Action | Endpoint |
|--------|---------|
| Create post | `POST /wp-json/wp/v2/posts` |
| Create page | `POST /wp-json/wp/v2/pages` |
| Update post | `PUT /wp-json/wp/v2/posts/{id}` |
| List posts | `GET /wp-json/wp/v2/posts` |

## Troubleshooting

**401 Unauthorized**: Check username and app password in `.env`

**404 Not Found**: Ensure WordPress REST API is enabled (Settings → Permalinks → Save)

**Yoast fields not updating**: Verify the MU-plugin is installed and active

**500 Error**: Check WordPress error logs at `wp-content/debug.log`

## Security Notes

- Never commit `.env` to git
- App passwords can be revoked from WordPress Admin at any time
- The MU-plugin only allows users with `edit_post` capability to update meta fields
- REST API is standard WordPress — no additional security risk beyond normal API usage
