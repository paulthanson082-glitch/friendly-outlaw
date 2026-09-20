# Claude Code Skills Index

This is a comprehensive guide to all available Claude Code skills — both project-specific skills for friendly-outlaw and broader ecosystem skills you can use across projects.

## Project-Specific Skills

These skills are tailored for the friendly-outlaw writers app. Use them when working on this project.

### Writing & Content
| Skill | File | Description | When to use |
|-------|------|-------------|-------------|
| **add-template** | `add-template.md` | Add a new writing template to TemplateManager | Creating novel templates, story templates, or new writing formats |
| **add-ai-feature** | `add-ai-feature.md` | Implement AI-assisted writing capabilities | Adding Claude-powered features like brainstorming, editing, suggestions |
| **build-and-test** | `build-and-test.md` | Build the project and run the full test suite | After code changes, before pushing, to validate everything works |

### Architecture & System
| Skill | File | Description | When to use |
|-------|------|-------------|-------------|
| **add-version-control-op** | `add-version-control-op.md` | Extend DoltVersionControlService with new operations | Adding branching, merging, or time-travel features for documents |
| **generate-skill-from-url** | `generate-skill-from-url.md` | Generate a new skill definition from a URL | Creating custom workflows based on external documentation |

### External Integration
| Skill | File | Description | When to use |
|-------|------|-------------|-------------|
| **firecrawl** | `firecrawl.md` | Web scraping, searching, and browser automation | Researching topics, browsing pages, scraping content for writing projects |

---

## Broader Ecosystem Skills

These skills work across many projects and can be used to extend friendly-outlaw with additional capabilities.

### Communication & Messaging
| Skill | Category | Description |
|-------|----------|-------------|
| **whatsapp** | Messaging | WhatsApp automation — send messages, voice notes, images, get group members |
| **gmail** | Email | Gmail automation — send emails, read inbox, create drafts, search messages |
| **get-contact** | Directory | Find contact details by name (email/phone) |

### Calendar & Meetings
| Skill | Category | Description |
|-------|----------|-------------|
| **calendar** | Scheduling | Google Calendar integration — check schedule, add events, view meetings |
| **zoom-meeting** | Video | Schedule Zoom meetings with calendar invites |

### Content Creation
| Skill | Category | Description |
|-------|----------|-------------|
| **nano-banana-poster** | Graphics | Generate images and posters with Google Gemini |
| **presentation-architect** | Presentations | Build fully structured presentation scripts slide by slide |
| **html-to-pdf** | Document Export | Convert HTML to PDF with Hebrew/RTL support |
| **html-to-pptx** | Document Export | Convert HTML to PowerPoint with Hebrew/RTL support |

### Audio & Video
| Skill | Category | Description |
|-------|----------|-------------|
| **speech-generator** | Text-to-Speech | Generate speech audio from text using ElevenLabs TTS |
| **music-generator** | Audio | Generate AI music with ElevenLabs Music API |
| **transcribe** | Audio | Transcribe audio/video to SRT subtitles using ElevenLabs Scribe v2 |
| **youtube-downloader** | Video | Download YouTube videos with quality presets |
| **youtube-uploader** | Video | Upload videos to YouTube with title, description, tags |

### Publishing & Websites
| Skill | Category | Description |
|-------|----------|-------------|
| **gh-pages-deploy** | Web Hosting | Deploy static/interactive frontend content to GitHub Pages |
| **wordpress-publisher** | Publishing | Publish posts to WordPress |

### Learning & Knowledge
| Skill | Category | Description |
|-------|----------|-------------|
| **learn** | Knowledge | Teach Claude any topic — libraries, APIs, tools, methodologies, domains |
| **deep-interview** | Research | Conduct deep adaptive interviews to extract and organize knowledge |

### Utilities & Tools
| Skill | Category | Description |
|-------|----------|-------------|
| **claudability-analyzer** | Analysis | Analyze professions for Claude Code automation opportunities |
| **find-my-project** | Discovery | Help beginners find their first agentic project |
| **aviz-skills-installer** | Package Management | Install additional skills from the AVIZ Skills Library |

---

## How to Use Skills

### Invoke Project-Specific Skills

Use the `/skill` command or ask Claude directly:

```
/add-template
```

Or: *"Use the add-ai-feature skill to implement a new brainstorming feature"*

### Invoke Ecosystem Skills

Most ecosystem skills are accessed through the same mechanism. First, check if the skill is installed:

```bash
/help
```

Then invoke it:

```
/speech-generator
```

Or tell Claude: *"Use the speech-generator skill to convert my document into an audiobook"*

### Install Additional Skills

Use the **aviz-skills-installer** skill to browse and install new skills from the ecosystem:

```
/aviz-skills-installer
```

---

## Tips for Success

1. **Check skill availability first** — Run `/help` to see which skills are currently available in your session
2. **Read skill documentation** — Each skill has detailed instructions; follow them for best results
3. **Combine skills** — Use multiple skills in sequence (e.g., write content with `add-ai-feature`, then export with `html-to-pdf`)
4. **Teach Claude new skills** — If you don't see what you need, use the `learn` skill to teach Claude about a new tool or API

---

## For Project Contributors

When adding a new project-specific skill:

1. Create a new `{skill-name}.md` file in `.claude/skills/`
2. Follow the format of existing skills (title, overview, step-by-step instructions)
3. Document parameters and outputs clearly
4. Add the skill to the "Project-Specific Skills" table above

See `generate-skill-from-url.md` for an example of how to structure a skill.
