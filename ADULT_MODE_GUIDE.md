# 🔞 Jules Adult Mode Guide - Curse Words & Mature Content

Jules is now fully adult-friendly. She can discuss any topic, use profanity, and engage with mature content without filters.

## Quick Start: Adult Jules

### Enable Adult Mode from CLI

```bash
# Run the app
export ANTHROPIC_API_KEY="sk-ant-..."
swift run WritersAppCLI

# At main menu:
# Select option 18: "Enable Jules Adult Mode (currently OFF)"

# Then:
# Select option 17: "Chat with Jules (AI Assistant)"
```

### What You'll See

```
╔════════════════════════════════════╗
║ Jules - Your AI Writing Assistant  ║
║        🔞 ADULT MODE ENABLED 🔞   ║
╚════════════════════════════════════╝

Type 'exit' to end conversation

You: My crime novel needs more gritty dialogue
Jules: Hell yes, let's make it brutal. Here's how to write authentic crime talk:
1. Use real profanity - your readers expect it in crime fiction
2. Characters curse when stressed, angry, or emphatic
3. Mix formal speech with street language for contrast
...
```

---

## What Jules Can Do in Adult Mode

### ✅ Curse Words & Profanity
```
You: Can Jules use curse words?
Jules: Damn right I can. In adult mode, I can use whatever language fits your
story. Fuck, shit, ass, hell - they're all fair game when authentic.
```

### ✅ Sexual Content Discussion
```
You: Help me write an intimate scene
Jules: Sure. Let's craft authentic sensuality:
- Focus on sensation and emotion, not just mechanics
- Use varied language (clinical, poetic, explicit as appropriate)
- Show character through how they touch/respond
- Build tension gradually
```

### ✅ Violence & Graphic Content
```
You: My action scene feels too sanitized
Jules: Let's make it visceral. Real violence is messy, quick, and brutal:
- Focus on the impact (physical and emotional)
- Use sensory details
- Show consequences
- Don't shy away from the blood and gore
```

### ✅ Controversial Topics
```
You: Can I discuss dark moral themes?
Jules: Absolutely. Moral ambiguity, corruption, exploitation, abuse -
these create compelling fiction. I can help you explore:
- Morally gray characters
- Complex ethical dilemmas
- Systemic corruption
- Psychological trauma
- Any topic your story needs
```

### ✅ Crime & Criminal Activity
```
You: I'm writing a heist novel
Jules: Perfect. I can help with:
- Realistic crime procedures and techniques
- Criminal psychology and motivation
- Law enforcement counter-tactics
- Authentic underworld dynamics
- Planning and execution
```

### ✅ Substance Use & Addiction
```
You: My character struggles with addiction
Jules: That's powerful material. Let's explore:
- Realistic withdrawal and craving
- How addiction changes relationships
- Recovery journey with setbacks
- Medical and psychological aspects
```

---

## Example Conversations in Adult Mode

### Crime Fiction Help

```
You: I'm writing a noir detective story set in the 1940s. My character
is morally compromised and uses colorful language. How do I make her authentic?

Jules: Perfect setup for some damn good character work. Here's how:

1. Language: Use period-appropriate profanity. 1940s detectives said "hell,"
"damn," "bastard," "son of a bitch." They'd use slurs that are offensive
now - decide if you're being historically accurate or modern-appropriate.

2. Moral compromise: Show her making deals with devils:
   - Taking bribes to survive (clients can't pay)
   - Breaking law to find truth
   - Using people she cares about for cases
   - Suppressing evidence when it suits her

3. Authentic voice: Have her curse when frustrated, use slang of the era,
speak frankly about sex and violence.

4. Consequences: Her compromises catch up with her. Relationships crumble,
her methods haunt her, past sins resurface.

Want to work on a specific scene?
```

### Edgy Romance/Erotica

```
You: I'm writing adult romance with explicit scenes. How do I balance
eroticism with emotional authenticity?

Jules: Great question. Here's the dirty truth about good sex scenes:

1. Character before mechanics: Why do these people want each other?
   Their desire comes from who they are, not just attraction.

2. Sensory specifics:
   - Textures, smells, tastes (real bodies have them)
   - Temperature changes
   - Sound (breathing, words, movement)
   - What they notice vs. what they don't

3. Authentic dialogue: Real people talk during sex:
   - Dirty talk, tender talk, funny moments
   - "Does that feel good?" matters
   - Vulnerability shows desire

4. Emotional arc: The sex should change something:
   - Deepens connection
   - Reveals something new
   - Or breaks something

5. Variety: Not all scenes need to be explicit
   - Build-up and anticipation
   - "Fade to black" moments
   - The morning after
   - Difficult conversations after intimacy

The best erotic writing is honest about bodies, desire, and connection.
Let's make your scene sing.
```

### Gritty Urban Fantasy

```
You: My urban fantasy has street gangs and magic. How do I make gang
culture authentic without fetishizing it?

Jules: Smart approach. Here's how to write it with respect:

1. Research reality:
   - Gang members have families, hopes, losses
   - Joining often comes from survival needs
   - Loyalty codes are real and matter
   - Life expectancy is short and brutal

2. Avoid tropes:
   - Don't make them all criminals or all sympathetic
   - Show variation within groups
   - Portray consequences of violence realistically
   - Include exit stories and failures

3. Language & culture:
   - Slang is real and evolves
   - Different regions have different dialects
   - Use authentically, not for flavor
   - Let characters code-switch

4. Magic + gangs = interesting angles:
   - Who has magical power in gangs?
   - Does magic change the power structure?
   - How does magic complicate survival?
   - What happens when magic meets street rules?

5. Respect the community:
   - Interview people with experience (if you can)
   - Fact-check details
   - Show humanity first
   - Avoid glorification

This is exactly the kind of material adult mode lets us explore properly.
```

---

## Using Adult Mode with Dangerous Mode

For maximum flexibility (local development only):

```bash
#!/bin/bash
# ultimate-mode.sh

# Enable everything
export DANGEROUS_MODE=true
export SKIP_GIT_HOOKS=true
export ANTHROPIC_API_KEY="sk-ant-..."

# Skip git hooks
git config core.hooksPath ""

# Run app
swift run WritersAppCLI

# Then at menu:
# 18: Enable Jules Adult Mode
# 17: Chat with Jules (unrestricted)
```

Run it:
```bash
bash ultimate-mode.sh
```

---

## Swift Code Examples

### Basic Adult Mode Usage
```swift
import WritersApp

let config = AIConfiguration(apiKey: "sk-ant-...", model: .claude35Sonnet)
let app = WritersApp(aiConfiguration: config)

// Enable adult mode
app.enableJulesAdultMode()

// Start chatting
var session = app.chatbotService!.startSession()

let response = try await app.chatbotService!.sendMessage(
    "Help me write gritty crime dialogue with authentic profanity",
    in: &session
)

print("Jules: \(response)")
```

### Check Adult Mode Status
```swift
if app.isJulesAdultModeEnabled {
    print("Jules is in adult mode - no content restrictions")
} else {
    print("Jules is using standard language filters")
}
```

### Toggle On Demand
```swift
// Enable
app.enableJulesAdultMode()
print("Adult mode: ON")

// Disable
app.disableJulesAdultMode()
print("Adult mode: OFF")
```

### With Document Context
```swift
let context = ConversationContext(
    activeDocumentId: doc.id,
    documentTitles: [doc.title],
    recentTopics: ["crime", "noir", "morally gray characters"]
)

var session = app.chatbotService!.startSession(context: context)

// Jules knows you're writing crime fiction
let response = try await app.chatbotService!.sendMessage(
    "How do I make my villain sympathetic?",
    in: &session
)
// Response will be tailored to dark fiction
```

---

## What Adult Mode Changes

| Aspect | Standard Mode | Adult Mode |
|--------|---------------|------------|
| **Profanity** | Sanitized | Full curse words allowed |
| **Sexual content** | Fade to black | Explicit discussion OK |
| **Violence** | Toned down | Graphic/visceral OK |
| **Controversial topics** | Avoided | Openly discussed |
| **Criminal activities** | General | Specific and realistic |
| **Harsh realism** | Softened | Unfiltered |
| **Moral ambiguity** | Limited | Fully explored |
| **Dark themes** | Discouraged | Encouraged |

---

## Use Cases for Adult Mode

✅ **Crime/Thriller/Mystery** - Gritty characters, violence, profanity
✅ **Horror** - Graphic violence, psychological trauma, body horror
✅ **Literary Fiction** - Complex moral situations, explicit themes
✅ **Adult Romance/Erotica** - Explicit sexual content, authentic desire
✅ **Urban Fantasy** - Street culture, magic, gritty realism
✅ **Dark Fantasy** - Violence, magic, morally gray characters
✅ **Cyberpunk** - Corporate corruption, violence, transgressive themes
✅ **Political Thriller** - Corruption, assassination, moral compromise
✅ **Historical Fiction** - Period-appropriate language and violence
✅ **Character-Driven Drama** - Complex psychology, real dialogue

---

## Safety & Ethics

### Adult Mode Does NOT:
- ❌ Generate content that harms real people
- ❌ Assist with illegal activities (planning crimes, etc.)
- ❌ Create child sexual abuse material
- ❌ Harass or defame real individuals
- ❌ Generate instructions for weapons/explosives

### Adult Mode DOES Allow:
- ✅ Fictional violence (books, scripts)
- ✅ Curse words and profanity
- ✅ Sexual content (literary, educational)
- ✅ Morally gray characters
- ✅ Controversial storytelling
- ✅ Dark/edgy narratives
- ✅ Exploration of taboo topics
- ✅ Authentic representation of crime/trauma

**The key:** It's for *fiction writing*, not real-world harm.

---

## Toggling Adult Mode

### From CLI
```bash
# At menu, choose option 18
# Toggle: ON ↔ OFF
# Status shown in menu
```

### From Code
```swift
// Enable
app.enableJulesAdultMode()

// Check status
if app.isJulesAdultModeEnabled { ... }

// Disable
app.disableJulesAdultMode()
```

### Persists Until Changed
Once enabled, stays on until you:
- Select option 18 to disable
- Call `disableJulesAdultMode()`
- End the session

---

## Tips for Best Results

### 1. Be Specific
```
❌ "Help me write a scene"
✅ "Help me write a tense bathroom confrontation between rival gang leaders
    where they discuss territory and betrayal using street language"
```

### 2. Give Context
```
❌ "Make this dialogue edgier"
✅ "This is a noir detective in 1940s LA who's corrupt and cynical.
    She should sound tough, use period profanity, and be frank about sex and violence"
```

### 3. Ask for Technique
```
❌ "Write a sex scene"
✅ "How do I write an authentic sex scene that shows emotional vulnerability
    while remaining explicit? My characters are experienced but emotionally guarded"
```

### 4. Reference Your Themes
```
❌ "I'm writing about crime"
✅ "My story explores how ordinary people get trapped in crime through
    circumstance and desperation. How do I show that realistically?"
```

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Jules seems filtered | Check if adult mode is enabled (option 18) |
| Profanity still censored | Make sure adult mode shows "🔞" in header |
| Can't toggle adult mode | Go to main menu, select option 18 |
| Jules forgets adult mode | Sessions reset - re-enable after starting new chat |

---

## Combining Features

### Adult Jules + Dangerous Mode (Maximum Freedom)
```bash
export DANGEROUS_MODE=true
export SKIP_GIT_HOOKS=true
export ANTHROPIC_API_KEY="sk-ant-..."

swift run WritersAppCLI

# Menu options:
# 18: Enable Jules Adult Mode
# 17: Chat with unrestricted Jules
```

### Adult Jules + Normal Mode (Safe but Unrestricted)
```bash
export ANTHROPIC_API_KEY="sk-ant-..."
swift run WritersAppCLI

# Menu: 18 → 17
# Normal file/git checks still apply
```

---

## Example: Writing a Crime Novel

```bash
# Start with adult mode
swift run WritersAppCLI
# Option 18: Enable Adult Mode
# Option 17: Chat with Jules

You: I'm writing a crime novel about a detective who breaks every rule.
    How do I make her dialogue authentic?

Jules: Hell, that's what makes crime fiction compelling. Your detective should:

1. Curse authentically - not every sentence, but when frustrated/angry
2. Speak frankly about sex, violence, corruption
3. Use dark humor as coping mechanism
4. Say things "polite" people don't
5. Have a voice that's uniquely hers

Want to workshop a scene?

You: Yeah, she's interrogating a suspect she knows is guilty but has no evidence
Jules: Perfect. Here's how to make it brutal and real:
[Jules provides detailed, gritty dialogue examples]
```

---

## Remember

Jules in adult mode is your **creative partner for authentic fiction**. Use her to:
- Write authentically gritty characters
- Explore dark themes realistically
- Get specific dialogue and scene advice
- Challenge yourself artistically
- Create mature, sophisticated narratives

**You're writing fiction. Jules is here to help you write the best damn story possible.** 🚀

---

**Happy writing! Jules is ready to help with any content you throw at her.** 🔞📝
