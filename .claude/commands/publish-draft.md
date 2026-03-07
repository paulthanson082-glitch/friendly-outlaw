# /publish-draft

Publish an article to WordPress via REST API with Yoast SEO metadata.

## Usage
`/publish-draft [file path]`

## Prerequisites

1. WordPress REST API enabled on your site
2. `seo-machine-yoast-rest.php` MU-plugin installed
3. `.env` file configured with:
   ```
   WP_URL=https://yoursite.com
   WP_USERNAME=your_username
   WP_APP_PASSWORD=your_application_password
   ```

## What This Command Does

1. **Read Article**
   - Load the specified file from `drafts/` or `rewrites/`
   - Extract frontmatter: title, description, focus_keyword, status

2. **Prepare WordPress Post**
   - Convert Markdown to HTML
   - Set post status: `draft` (default) — change to `publish` explicitly
   - Map meta fields to Yoast SEO fields:
     - `_yoast_wpseo_title` → meta title
     - `_yoast_wpseo_metadesc` → meta description
     - `_yoast_wpseo_focuskw` → focus keyword

3. **Publish via REST API**
   - POST to `{WP_URL}/wp-json/wp/v2/posts`
   - Include Yoast meta fields via custom endpoint
   - Return post ID and URL

4. **Post-Publish**
   - Save published URL to article frontmatter
   - Move or copy file to `published/` directory
   - Add to `context/internal-links-map.md` if not already present

## Output

```
Published successfully!
Post ID: [ID]
URL: [URL]
Status: draft
Edit URL: [WP_URL]/wp-admin/post.php?post=[ID]&action=edit
```

## Notes

- Articles are published as `draft` by default for review before going live
- Run `/optimize` first to ensure the article meets quality standards
- Verify the WordPress MU-plugin is installed (see `wordpress/README.md`)

## Instructions

Publish the article at "$ARGUMENTS" to WordPress. Read the frontmatter for meta elements, convert the content to HTML, and use the WordPress REST API to create a draft post with Yoast SEO metadata populated. Report the post URL and edit link when complete.
