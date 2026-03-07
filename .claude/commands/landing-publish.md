# /landing-publish

Publish a landing page to WordPress via REST API.

## Usage
`/landing-publish [file path]`

## What This Command Does

Similar to `/publish-draft` but configured for landing pages:

1. **Read Landing Page**: load file from `landing-pages/`
2. **Prepare WordPress Page** (not post):
   - Convert Markdown to HTML
   - Set as WordPress Page (not Post)
   - Set page template if specified in frontmatter
   - Map Yoast SEO fields
3. **Publish as Draft**: POST to `{WP_URL}/wp-json/wp/v2/pages`
4. **Report**: return page ID, URL, and edit link

## Output

```
Landing page published!
Page ID: [ID]
URL: [URL]
Status: draft
Edit URL: [WP_URL]/wp-admin/post.php?post=[ID]&action=edit
```

## Prerequisites

Same as `/publish-draft` — WordPress REST API, MU-plugin, and `.env` credentials configured.

## Instructions

Publish the landing page at "$ARGUMENTS" to WordPress as a draft Page (not Post). Map all frontmatter meta elements to Yoast SEO fields and report the page URL and edit link when complete.
