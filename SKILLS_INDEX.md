# Claude Code Skills Index

A comprehensive guide to all available Claude Code skills for the friendly-outlaw project and ecosystem.

## Table of Contents

- [Project-Specific Skills](#project-specific-skills)
- [Ecosystem Skills](#ecosystem-skills)
- [Usage Guidelines](#usage-guidelines)
- [Contributing New Skills](#contributing-new-skills)

## Project-Specific Skills

### friendly-outlaw Skills

These skills are optimized for the friendly-outlaw codebase:

#### add-template
Create new document templates with placeholders and metadata.
```bash
/add-template "Report Template"
```

#### add-ai-feature
Integrate new AI capabilities using Anthropic Claude API.
```bash
/add-ai-feature "brainstorm ideas"
```

#### add-version-control-op
Implement version control operations for document tracking.
```bash
/add-version-control-op "create-checkpoint"
```

#### add-export-format
Add support for new export formats (.docx, .epub, etc.).
```bash
/add-export-format "docx"
```

#### improve-performance
Optimize code performance with profiling and benchmarking.
```bash
/improve-performance "document search"
```

## Ecosystem Skills

Broader skills available across Claude Code projects:

### Communication Skills
- **slack-integration** - Connect to Slack workspaces
- **email-notifications** - Send email updates
- **github-comments** - Post comments on GitHub PRs/issues

### Development Skills
- **code-review** - Automated code review with findings
- **security-review** - Security analysis and vulnerability scanning
- **test-driven-development** - TDD workflow and test generation
- **debugging** - Systematic debugging and root cause analysis

### Documentation Skills
- **write-docs** - Generate comprehensive documentation
- **api-docs** - Create API reference documentation
- **architecture-docs** - Document system architecture

### Audio/Video Skills
- **video-editing** - Process and edit video content
- **audio-processing** - Enhance and analyze audio

### Publishing Skills
- **markdown-to-html** - Convert Markdown to HTML
- **pdf-generation** - Generate PDF documents
- **publish-to-npm** - Publish packages to NPM registry

### Learning Skills
- **tutorial-generation** - Create step-by-step tutorials
- **example-creation** - Generate code examples
- **concept-explanation** - Explain complex concepts

## Usage Guidelines

### Combining Skills

Chain multiple skills for complex workflows:

```bash
/add-ai-feature "summarize documents" && \
/write-docs "AI Features" && \
/code-review && \
/publish-to-npm
```

### Best Practices

1. **Specify Context:** Always provide project context when invoking skills
2. **Use Drafts:** Create draft PRs first, then refine
3. **Test Changes:** Run tests before merging
4. **Document Impact:** Update CLAUDE.md when adding new capabilities
5. **Review Output:** Review skill-generated code before committing

### Error Handling

If a skill fails:
1. Check the error message for specific issues
2. Verify prerequisites are installed
3. Review the skill's documentation
4. Try with simplified input first

## Contributing New Skills

To add a skill to friendly-outlaw:

### 1. Create Skill Directory

```bash
mkdir -p .claude/skills/your-skill-name
cd .claude/skills/your-skill-name
```

### 2. Create SKILL.md

Document your skill:
```markdown
# Your Skill Name

## Description
What this skill does.

## Usage
```bash
/your-skill "parameters"
```

## Examples
- Example 1
- Example 2

## Prerequisites
What needs to be installed/configured

## Troubleshooting
Common issues and solutions
```

### 3. Implement Hook

Create implementation in `.claude/hooks` or as a plugin module.

### 4. Test Skill

```bash
# Test with sample project
claude-code /your-skill "test input"
```

### 5. Document in CLAUDE.md

Add reference to CLAUDE.md in the Skills section.

### 6. Submit PR

Create a PR with your new skill for review.

## Related Resources

- See CLAUDE.md for project-specific development guidance
- See README.md for project overview
- Visit [Claude Code Docs](https://code.claude.com/docs) for more skills
- Review existing `.claude/skills/` for examples

