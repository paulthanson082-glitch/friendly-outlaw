import Foundation

/// Manages template storage, retrieval, and operations
public class TemplateManager {
    private var templates: [UUID: Template]

    public init() {
        self.templates = [:]
        loadDefaultTemplates()
    }

    // MARK: - Template Management

    /// Adds a new template
    public func addTemplate(_ template: Template) {
        templates[template.id] = template
    }

    /// Retrieves a template by ID
    public func getTemplate(id: UUID) -> Template? {
        return templates[id]
    }

    /// Retrieves all templates
    public func getAllTemplates() -> [Template] {
        return Array(templates.values).sorted { $0.name < $1.name }
    }

    /// Retrieves templates by category
    public func getTemplates(for category: TemplateCategory) -> [Template] {
        return templates.values.filter { $0.category == category }
            .sorted { $0.name < $1.name }
    }

    /// Searches templates by name or description
    public func searchTemplates(query: String) -> [Template] {
        // Use localizedCaseInsensitiveContains which handles case conversion internally
        return templates.values.filter { template in
            template.name.localizedCaseInsensitiveContains(query) ||
            template.description.localizedCaseInsensitiveContains(query)
        }.sorted { $0.name < $1.name }
    }

    /// Updates an existing template
    public func updateTemplate(_ template: Template) {
        templates[template.id] = template
    }

    /// Deletes a template
    public func deleteTemplate(id: UUID) {
        templates.removeValue(forKey: id)
    }

    /// Loads and registers the built-in set of default templates into the manager.
    /// 
    /// The catalog includes fiction, nonfiction, script, business, scheduled-task, and content-profile templates such as Novel Chapter, Short Story, Screenplay Scene, Blog Post, Article, Poetry, Business Letter, Morning Inbox Summary, Competitor News Roundup, Weekly Status Report, Email Follow-Up Tracker, Monthly Expense Report, Daily Sales Dashboard, Weekly Content Calendar, and global instruction profiles for Project Manager and Content Writer.

    private func loadDefaultTemplates() {
        // Novel Chapter Template
        let novelTemplate = Template(
            name: "Novel Chapter",
            category: .novel,
            description: "Standard chapter template for novel writing",
            content: """
            # Chapter {{chapter_number}}: {{chapter_title}}

            {{opening_scene}}

            ---

            {{main_content}}

            ---

            {{closing_scene}}
            """,
            placeholders: [
                Placeholder(key: "chapter_number", label: "Chapter Number"),
                Placeholder(key: "chapter_title", label: "Chapter Title"),
                Placeholder(key: "opening_scene", label: "Opening Scene"),
                Placeholder(key: "main_content", label: "Main Content"),
                Placeholder(key: "closing_scene", label: "Closing Scene")
            ],
            metadata: TemplateMetadata(tags: ["fiction", "novel", "chapter"])
        )

        // Short Story Template
        let shortStoryTemplate = Template(
            name: "Short Story",
            category: .shortStory,
            description: "Three-act structure for short stories",
            content: """
            # {{title}}
            by {{author}}

            ## Act I: Setup
            {{act_one}}

            ## Act II: Confrontation
            {{act_two}}

            ## Act III: Resolution
            {{act_three}}

            ---

            Word Count: ~{{target_words}} words
            """,
            placeholders: [
                Placeholder(key: "title", label: "Story Title"),
                Placeholder(key: "author", label: "Author Name"),
                Placeholder(key: "act_one", label: "Act I Content"),
                Placeholder(key: "act_two", label: "Act II Content"),
                Placeholder(key: "act_three", label: "Act III Content"),
                Placeholder(key: "target_words", label: "Target Word Count", defaultValue: "5000")
            ],
            metadata: TemplateMetadata(tags: ["fiction", "short-story"])
        )

        // Screenplay Scene Template
        let screenplayTemplate = Template(
            name: "Screenplay Scene",
            category: .screenplay,
            description: "Standard screenplay scene format",
            content: """
            {{scene_heading}}

            {{action}}

            {{character}}
            {{dialogue}}

            {{character_2}}
            ({{parenthetical}})
            {{dialogue_2}}

            {{transition}}
            """,
            placeholders: [
                Placeholder(key: "scene_heading", label: "Scene Heading", description: "INT/EXT. LOCATION - TIME"),
                Placeholder(key: "action", label: "Action/Description"),
                Placeholder(key: "character", label: "Character Name"),
                Placeholder(key: "dialogue", label: "Dialogue"),
                Placeholder(key: "character_2", label: "Second Character", required: false),
                Placeholder(key: "parenthetical", label: "Parenthetical", required: false),
                Placeholder(key: "dialogue_2", label: "Second Dialogue", required: false),
                Placeholder(key: "transition", label: "Transition", defaultValue: "CUT TO:")
            ],
            metadata: TemplateMetadata(tags: ["screenplay", "script", "scene"])
        )

        // Blog Post Template
        let blogTemplate = Template(
            name: "Blog Post",
            category: .blogPost,
            description: "SEO-optimized blog post structure",
            content: """
            # {{title}}

            **Published:** {{date}}
            **Author:** {{author}}
            **Tags:** {{tags}}

            ## Introduction
            {{introduction}}

            ## {{section_1_title}}
            {{section_1_content}}

            ## {{section_2_title}}
            {{section_2_content}}

            ## {{section_3_title}}
            {{section_3_content}}

            ## Conclusion
            {{conclusion}}

            ---

            **Call to Action:** {{cta}}
            """,
            placeholders: [
                Placeholder(key: "title", label: "Post Title"),
                Placeholder(key: "date", label: "Publication Date"),
                Placeholder(key: "author", label: "Author"),
                Placeholder(key: "tags", label: "Tags"),
                Placeholder(key: "introduction", label: "Introduction"),
                Placeholder(key: "section_1_title", label: "Section 1 Title"),
                Placeholder(key: "section_1_content", label: "Section 1 Content"),
                Placeholder(key: "section_2_title", label: "Section 2 Title"),
                Placeholder(key: "section_2_content", label: "Section 2 Content"),
                Placeholder(key: "section_3_title", label: "Section 3 Title"),
                Placeholder(key: "section_3_content", label: "Section 3 Content"),
                Placeholder(key: "conclusion", label: "Conclusion"),
                Placeholder(key: "cta", label: "Call to Action")
            ],
            metadata: TemplateMetadata(tags: ["blog", "article", "seo"])
        )

        // Article Template
        let articleTemplate = Template(
            name: "Article",
            category: .article,
            description: "Professional article with research structure",
            content: """
            # {{title}}
            ## {{subtitle}}

            **Author:** {{author}}
            **Date:** {{date}}

            ### Abstract
            {{abstract}}

            ### Introduction
            {{introduction}}

            ### Background
            {{background}}

            ### Main Discussion
            {{main_discussion}}

            ### Analysis
            {{analysis}}

            ### Conclusion
            {{conclusion}}

            ### References
            {{references}}
            """,
            placeholders: [
                Placeholder(key: "title", label: "Article Title"),
                Placeholder(key: "subtitle", label: "Subtitle", required: false),
                Placeholder(key: "author", label: "Author"),
                Placeholder(key: "date", label: "Date"),
                Placeholder(key: "abstract", label: "Abstract"),
                Placeholder(key: "introduction", label: "Introduction"),
                Placeholder(key: "background", label: "Background"),
                Placeholder(key: "main_discussion", label: "Main Discussion"),
                Placeholder(key: "analysis", label: "Analysis"),
                Placeholder(key: "conclusion", label: "Conclusion"),
                Placeholder(key: "references", label: "References")
            ],
            metadata: TemplateMetadata(tags: ["article", "research", "academic"])
        )

        // Poetry Template
        let poetryTemplate = Template(
            name: "Poetry",
            category: .poetry,
            description: "Structured poetry template",
            content: """
            # {{title}}
            *by {{author}}*

            {{stanza_1}}

            {{stanza_2}}

            {{stanza_3}}

            {{stanza_4}}

            ---
            *{{dedication}}*
            """,
            placeholders: [
                Placeholder(key: "title", label: "Poem Title"),
                Placeholder(key: "author", label: "Poet Name"),
                Placeholder(key: "stanza_1", label: "First Stanza"),
                Placeholder(key: "stanza_2", label: "Second Stanza"),
                Placeholder(key: "stanza_3", label: "Third Stanza", required: false),
                Placeholder(key: "stanza_4", label: "Fourth Stanza", required: false),
                Placeholder(key: "dedication", label: "Dedication", required: false)
            ],
            metadata: TemplateMetadata(tags: ["poetry", "verse"])
        )

        // Business Letter Template
        let businessLetterTemplate = Template(
            name: "Business Letter",
            category: .businessLetter,
            description: "Professional business letter format",
            content: """
            {{sender_name}}
            {{sender_address}}
            {{sender_city_state_zip}}
            {{sender_email}}
            {{sender_phone}}

            {{date}}

            {{recipient_name}}
            {{recipient_title}}
            {{recipient_company}}
            {{recipient_address}}
            {{recipient_city_state_zip}}

            Dear {{salutation}},

            {{opening_paragraph}}

            {{body_paragraph_1}}

            {{body_paragraph_2}}

            {{closing_paragraph}}

            Sincerely,

            {{sender_name}}
            {{sender_title}}
            """,
            placeholders: [
                Placeholder(key: "sender_name", label: "Your Name"),
                Placeholder(key: "sender_address", label: "Your Address"),
                Placeholder(key: "sender_city_state_zip", label: "Your City, State ZIP"),
                Placeholder(key: "sender_email", label: "Your Email"),
                Placeholder(key: "sender_phone", label: "Your Phone"),
                Placeholder(key: "date", label: "Date"),
                Placeholder(key: "recipient_name", label: "Recipient Name"),
                Placeholder(key: "recipient_title", label: "Recipient Title"),
                Placeholder(key: "recipient_company", label: "Company Name"),
                Placeholder(key: "recipient_address", label: "Company Address"),
                Placeholder(key: "recipient_city_state_zip", label: "City, State ZIP"),
                Placeholder(key: "salutation", label: "Salutation", defaultValue: "Mr./Ms. Last Name"),
                Placeholder(key: "opening_paragraph", label: "Opening Paragraph"),
                Placeholder(key: "body_paragraph_1", label: "Body Paragraph 1"),
                Placeholder(key: "body_paragraph_2", label: "Body Paragraph 2", required: false),
                Placeholder(key: "closing_paragraph", label: "Closing Paragraph"),
                Placeholder(key: "sender_title", label: "Your Title")
            ],
            metadata: TemplateMetadata(tags: ["business", "letter", "professional"])
        )

        // Morning Inbox Summary Template
        let inboxSummaryTemplate = Template(
            name: "Morning Inbox Summary",
            category: .scheduledTask,
            description: "Daily email triage and prioritisation report",
            content: """
            # Morning Inbox Summary — {{report_date}}

            ## Urgent Items
            {{urgent_items}}

            ## Hot (Reply Today)
            {{hot_items}}

            ## Warm (Reply This Week)
            {{warm_items}}

            ## Cold (FYI)
            {{cold_items}}

            ---

            **Report folder:** {{report_folder}}
            """,
            placeholders: [
                Placeholder(key: "report_date", label: "Report Date",
                            description: "Date of the inbox summary, e.g. 2026-03-13",
                            defaultValue: "YYYY-MM-DD"),
                Placeholder(key: "urgent_items", label: "Urgent Items",
                            description: "Emails from customers, investors, or marked URGENT"),
                Placeholder(key: "hot_items", label: "Hot Items",
                            description: "Emails that need a reply today"),
                Placeholder(key: "warm_items", label: "Warm Items",
                            description: "Emails that need a reply this week"),
                Placeholder(key: "cold_items", label: "Cold Items",
                            description: "FYI emails that need no immediate reply"),
                Placeholder(key: "report_folder", label: "Report Folder",
                            description: "Folder where this report is saved",
                            defaultValue: "~/Daily-Reports/")
            ],
            metadata: TemplateMetadata(tags: ["scheduled", "email", "daily", "inbox"])
        )

        // Competitor News Roundup Template
        let competitorRoundupTemplate = Template(
            name: "Competitor News Roundup",
            category: .scheduledTask,
            description: "Weekly competitive intelligence report",
            content: """
            # Competitor News Roundup — Week of {{week_start_date}}

            ## {{competitor_1}}
            {{competitor_1_news}}

            ## {{competitor_2}}
            {{competitor_2_news}}

            ## {{competitor_3}}
            {{competitor_3_news}}

            ---

            ## Strategic Analysis
            {{strategic_analysis}}

            **Sources:** {{sources}}
            """,
            placeholders: [
                Placeholder(key: "week_start_date", label: "Week Start Date",
                            description: "Monday of the reporting week, e.g. 2026-03-09",
                            defaultValue: "YYYY-MM-DD"),
                Placeholder(key: "competitor_1", label: "Competitor 1 Name",
                            description: "Name of the first competitor"),
                Placeholder(key: "competitor_1_news", label: "Competitor 1 News",
                            description: "Product updates, funding, hires, or customer wins"),
                Placeholder(key: "competitor_2", label: "Competitor 2 Name",
                            description: "Name of the second competitor"),
                Placeholder(key: "competitor_2_news", label: "Competitor 2 News",
                            description: "Product updates, funding, hires, or customer wins"),
                Placeholder(key: "competitor_3", label: "Competitor 3 Name",
                            description: "Name of the third competitor"),
                Placeholder(key: "competitor_3_news", label: "Competitor 3 News",
                            description: "Product updates, funding, hires, or customer wins"),
                Placeholder(key: "strategic_analysis", label: "Strategic Analysis",
                            description: "How these developments affect your positioning"),
                Placeholder(key: "sources", label: "Sources",
                            description: "Links or references for the reported news")
            ],
            metadata: TemplateMetadata(tags: ["scheduled", "competitors", "weekly", "intelligence"])
        )

        // Weekly Status Report Template
        let weeklyStatusTemplate = Template(
            name: "Weekly Status Report",
            category: .scheduledTask,
            description: "Friday end-of-week progress and planning summary",
            content: """
            # Weekly Status Report — {{report_date}}

            **Project:** {{project_name}}

            ## Accomplishments This Week
            {{accomplishments}}

            ## Planned Work for Next Week
            {{next_week_plan}}

            ## Blockers & Risks
            {{blockers}}

            ## Asks from Leadership
            {{leadership_asks}}
            """,
            placeholders: [
                Placeholder(key: "report_date", label: "Report Date",
                            description: "Friday date of the reporting week, e.g. 2026-03-13",
                            defaultValue: "YYYY-MM-DD"),
                Placeholder(key: "project_name", label: "Project Name",
                            description: "Name of the project being reported on"),
                Placeholder(key: "accomplishments", label: "Accomplishments",
                            description: "What was completed or progressed this week"),
                Placeholder(key: "next_week_plan", label: "Next Week Plan",
                            description: "Work planned for the coming week"),
                Placeholder(key: "blockers", label: "Blockers & Risks",
                            description: "Issues blocking progress or risks to the timeline"),
                Placeholder(key: "leadership_asks", label: "Asks from Leadership",
                            description: "Decisions or support needed from leadership",
                            required: false)
            ],
            metadata: TemplateMetadata(tags: ["scheduled", "status", "weekly", "project"])
        )

        // Email Follow-Up Tracker Template
        let followUpTrackerTemplate = Template(
            name: "Email Follow-Up Tracker",
            category: .scheduledTask,
            description: "Weekly tracker for unanswered outreach emails and follow-up drafts",
            content: """
            # Email Follow-Up Tracker — {{week_of}}

            ## Unanswered Outreach (3+ Days Old)
            {{unanswered_emails}}

            ## Follow-Up Drafts
            {{followup_drafts}}

            ---

            **Drafts saved to:** {{drafts_folder}}
            **Note:** Review and send drafts manually — do not auto-send.
            """,
            placeholders: [
                Placeholder(key: "week_of", label: "Week Of",
                            description: "Week this tracker covers, e.g. 2026-03-09",
                            defaultValue: "YYYY-MM-DD"),
                Placeholder(key: "unanswered_emails", label: "Unanswered Emails",
                            description: "Prospect name, company, subject, and days since sent"),
                Placeholder(key: "followup_drafts", label: "Follow-Up Drafts",
                            description: "Draft follow-up messages with a different angle from the original"),
                Placeholder(key: "drafts_folder", label: "Drafts Folder",
                            description: "Folder where drafts are saved for review",
                            defaultValue: "~/Drafts/")
            ],
            metadata: TemplateMetadata(tags: ["scheduled", "email", "followup", "weekly", "sales"])
        )

        // Monthly Expense Report Template
        let expenseReportTemplate = Template(
            name: "Monthly Expense Report",
            category: .scheduledTask,
            description: "Month-end expense categorisation and summary",
            content: """
            # Expense Report — {{report_month}}

            ## Travel (Flights, Hotels, Meals)
            {{travel_expenses}}

            ## Software & Subscriptions
            {{software_expenses}}

            ## Office Supplies
            {{office_expenses}}

            ## Client Entertainment
            {{entertainment_expenses}}

            ---

            ## Totals by Category
            {{category_totals}}

            **Grand Total:** {{grand_total}}

            **Output file:** {{output_file}}
            """,
            placeholders: [
                Placeholder(key: "report_month", label: "Report Month",
                            description: "Month covered by this report, e.g. 2026-03",
                            defaultValue: "YYYY-MM"),
                Placeholder(key: "travel_expenses", label: "Travel Expenses",
                            description: "Date, vendor, and amount for travel receipts"),
                Placeholder(key: "software_expenses", label: "Software & Subscriptions",
                            description: "Date, vendor, and amount for software costs"),
                Placeholder(key: "office_expenses", label: "Office Supplies",
                            description: "Date, vendor, and amount for office purchases"),
                Placeholder(key: "entertainment_expenses", label: "Client Entertainment",
                            description: "Date, vendor, and amount for entertainment costs",
                            required: false),
                Placeholder(key: "category_totals", label: "Category Totals",
                            description: "Sum per expense category"),
                Placeholder(key: "grand_total", label: "Grand Total",
                            description: "Total of all expenses for the month"),
                Placeholder(key: "output_file", label: "Output File",
                            description: "CSV file path for the expense data",
                            defaultValue: "~/Expense-Reports/expenses-YYYY-MM.csv")
            ],
            metadata: TemplateMetadata(tags: ["scheduled", "expenses", "monthly", "finance"])
        )

        // Daily Sales Dashboard Template
        let salesDashboardTemplate = Template(
            name: "Daily Sales Dashboard",
            category: .scheduledTask,
            description: "Weekday sales pipeline snapshot and action items",
            content: """
            # Sales Dashboard — {{dashboard_date}}

            ## Key Numbers
            - Pipeline Value: {{pipeline_value}}
            - Deals per Stage: {{deals_per_stage}}
            - New Inbound Leads (Yesterday): {{new_leads}}

            ## Deals Closing This Week
            {{closing_deals}}

            ## Stalled Deals (5+ Days Without Movement)
            {{stalled_deals}}

            ## Suggested Actions
            {{suggested_actions}}
            """,
            placeholders: [
                Placeholder(key: "dashboard_date", label: "Dashboard Date",
                            description: "Date of this dashboard snapshot, e.g. 2026-03-13",
                            defaultValue: "YYYY-MM-DD"),
                Placeholder(key: "pipeline_value", label: "Pipeline Value",
                            description: "Total value of all open deals"),
                Placeholder(key: "deals_per_stage", label: "Deals Per Stage",
                            description: "Count of deals in each pipeline stage"),
                Placeholder(key: "new_leads", label: "New Inbound Leads",
                            description: "New leads that arrived yesterday"),
                Placeholder(key: "closing_deals", label: "Closing Deals",
                            description: "Deals expected to close this week"),
                Placeholder(key: "stalled_deals", label: "Stalled Deals",
                            description: "Deals with no movement in 5 or more days"),
                Placeholder(key: "suggested_actions", label: "Suggested Actions",
                            description: "Recommended next steps for stalled or high-priority deals")
            ],
            metadata: TemplateMetadata(tags: ["scheduled", "sales", "daily", "pipeline"])
        )

        // Weekly Content Calendar Template
        let contentCalendarTemplate = Template(
            name: "Weekly Content Calendar",
            category: .scheduledTask,
            description: "Friday content planning for the following week",
            content: """
            # Content Calendar — Week of {{week_start_date}}

            ## Idea 1: {{idea_1_headline}}
            - **Key Points:** {{idea_1_points}}
            - **Platform:** {{idea_1_platform}}
            - **Publish Date:** {{idea_1_publish_date}}

            ## Idea 2: {{idea_2_headline}}
            - **Key Points:** {{idea_2_points}}
            - **Platform:** {{idea_2_platform}}
            - **Publish Date:** {{idea_2_publish_date}}

            ## Idea 3: {{idea_3_headline}}
            - **Key Points:** {{idea_3_points}}
            - **Platform:** {{idea_3_platform}}
            - **Publish Date:** {{idea_3_publish_date}}

            ---

            **Output file:** {{output_file}}
            """,
            placeholders: [
                Placeholder(key: "week_start_date", label: "Week Start Date",
                            description: "Monday of the content week, e.g. 2026-03-16",
                            defaultValue: "YYYY-MM-DD"),
                Placeholder(key: "idea_1_headline", label: "Idea 1 Headline",
                            description: "Hook or headline for the first content idea"),
                Placeholder(key: "idea_1_points", label: "Idea 1 Key Points",
                            description: "3–5 bullet points outlining the content"),
                Placeholder(key: "idea_1_platform", label: "Idea 1 Platform",
                            description: "Target platform: Blog, Twitter, or LinkedIn",
                            defaultValue: "Blog"),
                Placeholder(key: "idea_1_publish_date", label: "Idea 1 Publish Date",
                            description: "Planned publish date for idea 1"),
                Placeholder(key: "idea_2_headline", label: "Idea 2 Headline",
                            description: "Hook or headline for the second content idea"),
                Placeholder(key: "idea_2_points", label: "Idea 2 Key Points",
                            description: "3–5 bullet points outlining the content"),
                Placeholder(key: "idea_2_platform", label: "Idea 2 Platform",
                            description: "Target platform: Blog, Twitter, or LinkedIn",
                            defaultValue: "LinkedIn"),
                Placeholder(key: "idea_2_publish_date", label: "Idea 2 Publish Date",
                            description: "Planned publish date for idea 2"),
                Placeholder(key: "idea_3_headline", label: "Idea 3 Headline",
                            description: "Hook or headline for the third content idea"),
                Placeholder(key: "idea_3_points", label: "Idea 3 Key Points",
                            description: "3–5 bullet points outlining the content"),
                Placeholder(key: "idea_3_platform", label: "Idea 3 Platform",
                            description: "Target platform: Blog, Twitter, or LinkedIn",
                            defaultValue: "Twitter"),
                Placeholder(key: "idea_3_publish_date", label: "Idea 3 Publish Date",
                            description: "Planned publish date for idea 3"),
                Placeholder(key: "output_file", label: "Output File",
                            description: "Markdown file path for this content calendar",
                            defaultValue: "~/Content-Calendar/calendar-YYYY-MM-DD.md")
            ],
            metadata: TemplateMetadata(tags: ["scheduled", "content", "weekly", "calendar"])
        )

        // Global Instructions — Data Analyst Profile Template
        let dataAnalystProfileTemplate = Template(
            name: "Global Instructions — Data Analyst Profile",
            category: .contentProfile,
            description: "AI system instructions for a data or business analyst — defines role, tools, analysis rules, data quality standards, and file organisation",
            content: """
            # About Me
            - Role: {{role}} at {{company}}
            - Timezone: {{timezone}}
            - Primary tools: {{primary_tools}}

            # Communication Preferences
            - Show me summary statistics before diving into analysis
            - Use clean, minimal visualizations (no chartjunk)
            - Always include axis labels and titles on plots
            - Explain methodology before showing results

            # Analysis Rules
            - Use descriptive variable names, not abbreviations
            - For visualizations, save as both .png (for sharing) and .svg (for editing)
            - Always check for: nulls, duplicates, outliers before analysis
            - Include sample sizes and confidence intervals where relevant
            - When comparing groups, run appropriate statistical tests
            - Round numbers to 2 decimal places unless more precision is needed

            # Default Behaviors
            - Start every analysis with data quality summary (rows, columns, nulls, types)
            - Include a TL;DR with key findings at the top of every report
            - Save intermediate outputs so I can verify each step
            - Use consistent date formats: YYYY-MM-DD

            # File Organisation
            - Save outputs to {{output_folder}}
            - Name files: analysis-YYYY-MM-DD-[description].ext
            - Keep raw data separate from processed data

            # Never Do
            - Don't delete or overwrite source data files
            - Don't make causal claims from correlational data without flagging
            - Don't round numbers in intermediate calculations
            - Don't skip data validation steps
            """,
            placeholders: [
                Placeholder(key: "role", label: "Your Role",
                            description: "Your job title, e.g. Data Analyst, Business Analyst, Analytics Manager",
                            defaultValue: "Data Analyst"),
                Placeholder(key: "company", label: "Company Name",
                            description: "Name of the company or organisation"),
                Placeholder(key: "timezone", label: "Timezone",
                            description: "Your timezone for scheduling references, e.g. US Eastern, US Pacific",
                            defaultValue: "US Eastern"),
                Placeholder(key: "primary_tools", label: "Primary Tools",
                            description: "Languages and libraries you work with, e.g. Python (pandas, matplotlib), SQL, Excel",
                            defaultValue: "Python (pandas, matplotlib, seaborn), SQL, Excel"),
                Placeholder(key: "output_folder", label: "Output Folder",
                            description: "Base folder path where analysis outputs are saved",
                            defaultValue: "~/Analysis/[project-name]/")
            ],
            metadata: TemplateMetadata(tags: ["data", "analytics", "profile", "instructions", "python", "sql"])
        )

        // Global Instructions — Project Manager Profile Template
        let projectManagerProfileTemplate = Template(
            name: "Global Instructions — Project Manager Profile",
            category: .contentProfile,
            description: "AI system instructions for a project or program manager — defines role, communication preferences, PM rules, meeting support, and file structure",
            content: """
            # About Me
            - Role: {{role}} at {{company}}
            - Timezone: {{timezone}}
            - Work style: Structured, action-oriented, always thinking about deadlines and blockers

            # Communication Preferences
            - Use bullet points and headers for readability
            - Keep status updates concise — executives skim
            - Rank items by priority (P0 = critical, P1 = high, P2 = medium, P3 = low)
            - When presenting options, include trade-offs for each

            # Project Management Rules
            - For any status report, use this structure: Accomplishments / Planned / Blockers / Asks
            - Always include owners and due dates when listing action items
            - Flag risks early — I'd rather know about a potential problem than be surprised
            - Track decisions with: what was decided, who decided, when, and why

            # Meeting Support
            - When prepping for meetings, include: agenda, attendee context, talking points, and desired outcomes
            - After meetings, help me create structured notes with action items
            - Time-box agenda items (suggest durations based on importance)

            # Default Behaviors
            - For any document, include a TL;DR at the top
            - Use YYYY-MM-DD format for all dates
            - When creating project documents, follow this file structure:
              - {{docs_folder}} for documentation
              - {{status_folder}} for status reports
              - {{meetings_folder}} for meeting notes
              - {{decisions_folder}} for decision logs

            # Never Do
            - Don't commit to timelines on my behalf
            - Don't send communications to stakeholders without my review
            - Don't delete project files without confirmation
            - Don't assume project context — ask if you're missing background
            """,
            placeholders: [
                Placeholder(key: "role", label: "Your Role",
                            description: "Your job title, e.g. Project Manager, Product Manager, Program Manager",
                            defaultValue: "Project Manager"),
                Placeholder(key: "company", label: "Company Name",
                            description: "Name of the company or organisation"),
                Placeholder(key: "timezone", label: "Timezone",
                            description: "Your timezone for scheduling references, e.g. US Eastern, US Pacific",
                            defaultValue: "US Eastern"),
                Placeholder(key: "docs_folder", label: "Docs Folder",
                            description: "Folder path for project documentation",
                            defaultValue: "/docs/"),
                Placeholder(key: "status_folder", label: "Status Reports Folder",
                            description: "Folder path for status reports",
                            defaultValue: "/status/"),
                Placeholder(key: "meetings_folder", label: "Meeting Notes Folder",
                            description: "Folder path for meeting notes",
                            defaultValue: "/meeting-notes/"),
                Placeholder(key: "decisions_folder", label: "Decisions Folder",
                            description: "Folder path for decision logs",
                            defaultValue: "/decisions/")
            ],
            metadata: TemplateMetadata(tags: ["project-management", "profile", "instructions", "pm", "meetings"])
        )

        // Global Instructions — Content Writer Profile Template
        let contentWriterProfileTemplate = Template(
            name: "Global Instructions — Content Writer Profile",
            category: .contentProfile,
            description: "AI system instructions for a content writer or marketer — defines role, audience, style, SEO rules, and content guardrails",
            content: """
            # About Me
            - Role: {{role}} at {{company}}
            - Audience: {{audience}}
            - Timezone: {{timezone}}

            # Writing Style
            - Tone: conversational, friendly, occasionally witty
            - Sentence length: mix of short and medium (avoid long complex sentences)
            - Paragraph length: 2–3 sentences max
            - Use subheadings every 200–300 words
            - Include examples and analogies to explain concepts
            - Use active voice, not passive

            # Content Rules
            - Start every piece with a hook (question, stat, bold claim, or story)
            - Include a clear CTA at the end of every piece
            - Optimize for scannability: headers, bold key phrases, bullet points
            - When repurposing content, adjust tone for the platform:
              - Blog: educational, longer form
              - Twitter/X: punchy, direct, numbered lists
              - LinkedIn: professional but personable, include a takeaway
              - Email: conversational, personal, short paragraphs

            # SEO Guidelines
            - Include target keyword in the first 100 words
            - Use H2 and H3 headers with keyword variations
            - Write meta descriptions under 160 characters
            - Internal link to related content when relevant

            # Default Behaviors
            - For any content piece, show me an outline before writing the full draft
            - Include word count at the end of every draft
            - Save outputs to {{output_folder}}

            # Never Do
            - Don't publish or post anything without my review
            - Don't use clickbait or misleading headlines
            - Don't plagiarize — always create original content
            - Don't use corporate jargon: "leverage," "synergize," "circle back"
            - Don't include emojis unless I specifically ask for them
            """,
            placeholders: [
                Placeholder(key: "role", label: "Your Role",
                            description: "Your job title, e.g. Content Writer, Marketing Manager, Content Strategist",
                            defaultValue: "Content Writer"),
                Placeholder(key: "company", label: "Company Name",
                            description: "Name of the company or brand you write for"),
                Placeholder(key: "audience", label: "Target Audience",
                            description: "Who you are writing for, e.g. B2C non-technical, B2B decision-makers, developers",
                            defaultValue: "B2C non-technical readers"),
                Placeholder(key: "timezone", label: "Timezone",
                            description: "Your timezone for scheduling references, e.g. US Eastern, US Pacific",
                            defaultValue: "US Eastern"),
                Placeholder(key: "output_folder", label: "Output Folder",
                            description: "Base folder path where drafts are saved, organised by platform",
                            defaultValue: "~/Content/[platform]/YYYY-MM-DD-[topic].md")
            ],
            metadata: TemplateMetadata(tags: ["content", "marketing", "profile", "instructions", "seo"])
        )

        // Add all templates
        addTemplate(novelTemplate)
        addTemplate(shortStoryTemplate)
        addTemplate(screenplayTemplate)
        addTemplate(blogTemplate)
        addTemplate(articleTemplate)
        addTemplate(poetryTemplate)
        addTemplate(businessLetterTemplate)
        addTemplate(inboxSummaryTemplate)
        addTemplate(competitorRoundupTemplate)
        addTemplate(weeklyStatusTemplate)
        addTemplate(followUpTrackerTemplate)
        addTemplate(expenseReportTemplate)
        addTemplate(salesDashboardTemplate)
        addTemplate(contentCalendarTemplate)
        addTemplate(contentWriterProfileTemplate)
        addTemplate(projectManagerProfileTemplate)
        addTemplate(dataAnalystProfileTemplate)
    }
}
