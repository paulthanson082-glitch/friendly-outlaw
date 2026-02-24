// Package main demonstrates AI-powered writing assistance using the Anthropic API in Go.
// Inspired by PicoClaw's ultra-lightweight Go design, this example mirrors the functionality
// of the Python and Swift AIService implementations with minimal dependencies.
package main

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
	"strings"
	"time"
)

// AIModel represents available Claude models.
type AIModel string

const (
	Claude3Opus    AIModel = "claude-3-opus-20240229"
	Claude3Sonnet  AIModel = "claude-3-sonnet-20240229"
	Claude35Sonnet AIModel = "claude-3-5-sonnet-20241022"
	Claude3Haiku   AIModel = "claude-3-haiku-20240307"
)

// WritingTone represents different writing tones.
type WritingTone string

const (
	ToneProfessional WritingTone = "professional"
	ToneCasual       WritingTone = "casual"
	ToneFormal       WritingTone = "formal"
	ToneFriendly     WritingTone = "friendly"
	ToneAcademic     WritingTone = "academic"
	ToneCreative     WritingTone = "creative"
)

// AIConfiguration holds configuration for the AI service.
type AIConfiguration struct {
	APIKey      string
	Model       AIModel
	MaxTokens   int
	Temperature float64
}

// AIContext provides optional context for AI requests.
type AIContext struct {
	Genre           string
	TargetAudience  string
	WritingStyle    string
	AdditionalNotes string
}

// Document represents a writing document.
type Document struct {
	ID         string
	Title      string
	Content    string
	Category   string
	WordCount  int
	CreatedAt  time.Time
	ModifiedAt time.Time
}

// DocumentAnalysis holds comprehensive document analysis results.
type DocumentAnalysis struct {
	DocumentID string `json:"document_id"`
	Analysis   string `json:"analysis"`
	Timestamp  string `json:"timestamp"`
}

// WritingInsights holds writing statistics and insights.
type WritingInsights struct {
	DocumentID string `json:"document_id"`
	Insights   string `json:"insights"`
	Timestamp  string `json:"timestamp"`
}

// --- Anthropic API types (raw HTTP, no external SDK required) ---

type apiMessage struct {
	Role    string `json:"role"`
	Content string `json:"content"`
}

type apiRequest struct {
	Model       string       `json:"model"`
	MaxTokens   int          `json:"max_tokens"`
	Temperature float64      `json:"temperature"`
	Messages    []apiMessage `json:"messages"`
}

type apiContentBlock struct {
	Type string `json:"type"`
	Text string `json:"text"`
}

type apiResponse struct {
	Content []apiContentBlock `json:"content"`
	Error   *struct {
		Type    string `json:"type"`
		Message string `json:"message"`
	} `json:"error,omitempty"`
}

// AIService provides AI-powered writing assistance using the Anthropic API.
type AIService struct {
	config     AIConfiguration
	httpClient *http.Client
	apiBase    string
}

// NewAIService creates a new AIService instance.
func NewAIService(config AIConfiguration) *AIService {
	return &AIService{
		config:     config,
		httpClient: &http.Client{Timeout: 60 * time.Second},
		apiBase:    "https://api.anthropic.com/v1",
	}
}

func (s *AIService) createContextString(ctx *AIContext) string {
	if ctx == nil {
		return ""
	}
	var parts []string
	if ctx.Genre != "" {
		parts = append(parts, "Genre: "+ctx.Genre)
	}
	if ctx.TargetAudience != "" {
		parts = append(parts, "Target Audience: "+ctx.TargetAudience)
	}
	if ctx.WritingStyle != "" {
		parts = append(parts, "Writing Style: "+ctx.WritingStyle)
	}
	if ctx.AdditionalNotes != "" {
		parts = append(parts, "Additional Notes: "+ctx.AdditionalNotes)
	}
	return strings.Join(parts, "\n")
}

// callAPI sends a prompt to the Anthropic Messages API and returns the text response.
// Pass a negative temperature to use the service's configured default.
func (s *AIService) callAPI(ctx context.Context, prompt string, temperature float64) (string, error) {
	temp := s.config.Temperature
	if temperature >= 0 {
		temp = temperature
	}

	reqBody := apiRequest{
		Model:       string(s.config.Model),
		MaxTokens:   s.config.MaxTokens,
		Temperature: temp,
		Messages:    []apiMessage{{Role: "user", Content: prompt}},
	}

	body, err := json.Marshal(reqBody)
	if err != nil {
		return "", fmt.Errorf("marshal request: %w", err)
	}

	req, err := http.NewRequestWithContext(ctx, http.MethodPost, s.apiBase+"/messages", bytes.NewReader(body))
	if err != nil {
		return "", fmt.Errorf("create request: %w", err)
	}
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("x-api-key", s.config.APIKey)
	req.Header.Set("anthropic-version", "2023-06-01")

	resp, err := s.httpClient.Do(req)
	if err != nil {
		return "", fmt.Errorf("send request: %w", err)
	}
	defer resp.Body.Close()

	respBytes, err := io.ReadAll(resp.Body)
	if err != nil {
		return "", fmt.Errorf("read response: %w", err)
	}

	var apiResp apiResponse
	if err := json.Unmarshal(respBytes, &apiResp); err != nil {
		return "", fmt.Errorf("decode response: %w", err)
	}

	if apiResp.Error != nil {
		return "", fmt.Errorf("API error (%s): %s", apiResp.Error.Type, apiResp.Error.Message)
	}
	if len(apiResp.Content) == 0 {
		return "", fmt.Errorf("empty response from API")
	}

	return apiResp.Content[0].Text, nil
}

// ContinueWriting continues writing from existing text, matching style and voice.
func (s *AIService) ContinueWriting(ctx context.Context, text string, aiCtx *AIContext) (string, error) {
	contextStr := s.createContextString(aiCtx)
	prompt := fmt.Sprintf(
		"Continue writing from where this text leaves off. Match the style, tone, and voice of the existing text.\n\n%s\n\nExisting Text:\n%s\n\nContinue the writing naturally from where it ends.",
		contextStr, text,
	)
	return s.callAPI(ctx, prompt, -1)
}

// ImproveText improves existing text for clarity, flow, and impact.
func (s *AIService) ImproveText(ctx context.Context, text string, aiCtx *AIContext) (string, error) {
	contextStr := s.createContextString(aiCtx)
	prompt := fmt.Sprintf(
		"Improve this text for clarity, flow, and impact while maintaining its core message and style.\n\n%s\n\nOriginal Text:\n%s\n\nProvide the improved version.",
		contextStr, text,
	)
	return s.callAPI(ctx, prompt, -1)
}

// CheckGrammar checks grammar and spelling, returning the corrected version.
func (s *AIService) CheckGrammar(ctx context.Context, text string) (string, error) {
	prompt := fmt.Sprintf(
		"Check this text for grammar and spelling errors. Provide the corrected version.\n\nText:\n%s\n\nCorrected version:",
		text,
	)
	return s.callAPI(ctx, prompt, 0.3)
}

// GenerateTitles generates title options for the given content.
func (s *AIService) GenerateTitles(ctx context.Context, content string, aiCtx *AIContext, count int) ([]string, error) {
	contextStr := s.createContextString(aiCtx)
	prompt := fmt.Sprintf(
		"Generate %d compelling title options for this content.\n\n%s\n\nContent:\n%s\n\nProvide %d distinct title options, one per line.",
		count, contextStr, content, count,
	)

	result, err := s.callAPI(ctx, prompt, -1)
	if err != nil {
		return nil, err
	}

	lines := strings.Split(strings.TrimSpace(result), "\n")
	titles := make([]string, 0, len(lines))
	for _, line := range lines {
		line = strings.TrimSpace(line)
		if line == "" {
			continue
		}
		// Strip leading numbering (e.g. "1. ", "1) ", "- ")
		line = strings.TrimLeft(line, "0123456789.)- ")
		if line != "" {
			titles = append(titles, strings.TrimSpace(line))
		}
	}
	return titles, nil
}

// BrainstormIdeas brainstorms creative ideas on a topic.
func (s *AIService) BrainstormIdeas(ctx context.Context, topic string, aiCtx *AIContext) (string, error) {
	contextStr := s.createContextString(aiCtx)
	prompt := fmt.Sprintf(
		"Brainstorm creative ideas for this topic. Provide multiple unique angles and approaches.\n\n%s\n\nTopic:\n%s\n\nProvide detailed, creative ideas:",
		contextStr, topic,
	)
	return s.callAPI(ctx, prompt, 0.9)
}

// DevelopCharacter develops a character concept into a fully-realized character.
func (s *AIService) DevelopCharacter(ctx context.Context, concept string, aiCtx *AIContext) (string, error) {
	contextStr := s.createContextString(aiCtx)
	prompt := fmt.Sprintf(
		`Develop this character concept into a fully-realized character with:
- Physical description
- Personality traits
- Background/history
- Motivations and goals
- Conflicts and flaws
- Character arc potential

%s

Character Concept:
%s

Detailed character development:`,
		contextStr, concept,
	)
	return s.callAPI(ctx, prompt, -1)
}

// GenerateOutline creates a detailed outline from a concept.
func (s *AIService) GenerateOutline(ctx context.Context, concept string, aiCtx *AIContext) (string, error) {
	contextStr := s.createContextString(aiCtx)
	prompt := fmt.Sprintf(
		"Create a detailed outline for this concept with clear structure and progression.\n\n%s\n\nConcept:\n%s\n\nDetailed outline:",
		contextStr, concept,
	)
	return s.callAPI(ctx, prompt, -1)
}

// ChangeTone rewrites text in a different tone while preserving its core message.
func (s *AIService) ChangeTone(ctx context.Context, text string, tone WritingTone, aiCtx *AIContext) (string, error) {
	contextStr := s.createContextString(aiCtx)
	prompt := fmt.Sprintf(
		"Rewrite this text in a %s tone while maintaining its core message.\n\n%s\n\nOriginal Text:\n%s\n\nRewritten in %s tone:",
		tone, contextStr, text, tone,
	)
	return s.callAPI(ctx, prompt, -1)
}

// AnalyzeDocument performs a comprehensive analysis of a document.
func (s *AIService) AnalyzeDocument(ctx context.Context, doc *Document) (*DocumentAnalysis, error) {
	prompt := fmt.Sprintf(
		`Analyze this document comprehensively and provide:
1. Overall assessment
2. Strengths (3-5 points)
3. Areas for improvement (3-5 points)
4. Specific suggestions for enhancement
5. Target audience suitability

Document Title: %s
Category: %s
Word Count: %d

Content:
%s

Provide the analysis in a structured format.`,
		doc.Title, doc.Category, doc.WordCount, doc.Content,
	)

	result, err := s.callAPI(ctx, prompt, -1)
	if err != nil {
		return nil, err
	}

	return &DocumentAnalysis{
		DocumentID: doc.ID,
		Analysis:   result,
		Timestamp:  time.Now().Format(time.RFC3339),
	}, nil
}

// GetWritingInsights returns writing statistics and stylistic insights for a document.
func (s *AIService) GetWritingInsights(ctx context.Context, doc *Document) (*WritingInsights, error) {
	prompt := fmt.Sprintf(
		`Analyze this text and provide insights:
1. Reading level (Flesch-Kincaid grade)
2. Tone analysis
3. Pacing assessment
4. Vocabulary richness
5. Sentence structure variety

Text:
%s

Provide specific metrics and observations.`,
		doc.Content,
	)

	result, err := s.callAPI(ctx, prompt, 0.3)
	if err != nil {
		return nil, err
	}

	return &WritingInsights{
		DocumentID: doc.ID,
		Insights:   result,
		Timestamp:  time.Now().Format(time.RFC3339),
	}, nil
}

// CustomRequest handles a custom AI request with arbitrary instructions.
func (s *AIService) CustomRequest(ctx context.Context, text, instruction string, aiCtx *AIContext) (string, error) {
	contextStr := s.createContextString(aiCtx)
	prompt := fmt.Sprintf(
		"%s\n\n%s\n\nText:\n%s\n\nResponse:",
		instruction, contextStr, text,
	)
	return s.callAPI(ctx, prompt, -1)
}

// separator prints a visual divider.
func separator() {
	fmt.Println("\n" + strings.Repeat("=", 50))
}

func main() {
	apiKey := os.Getenv("ANTHROPIC_API_KEY")
	if apiKey == "" {
		fmt.Fprintln(os.Stderr, "Error: ANTHROPIC_API_KEY environment variable not set")
		os.Exit(1)
	}

	config := AIConfiguration{
		APIKey:      apiKey,
		Model:       Claude35Sonnet,
		MaxTokens:   4096,
		Temperature: 0.7,
	}

	service := NewAIService(config)
	ctx := context.Background()

	sampleText := "The old house stood at the end of the winding road, its windows dark and mysterious."
	aiCtx := &AIContext{
		Genre:          "Mystery",
		TargetAudience: "Adult",
		WritingStyle:   "Suspenseful",
	}

	// --- Continue writing ---
	fmt.Println("Original text:")
	fmt.Println(sampleText)

	fmt.Println("\nContinued text:")
	continuation, err := service.ContinueWriting(ctx, sampleText, aiCtx)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error continuing text: %v\n", err)
		os.Exit(1)
	}
	fmt.Println(continuation)

	// --- Generate titles ---
	separator()
	fmt.Println("Generated titles:")
	titles, err := service.GenerateTitles(ctx, sampleText, aiCtx, 5)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error generating titles: %v\n", err)
		os.Exit(1)
	}
	for i, title := range titles {
		fmt.Printf("%d. %s\n", i+1, title)
	}

	// --- Improve text ---
	separator()
	fmt.Println("Improved text:")
	improved, err := service.ImproveText(ctx, sampleText, aiCtx)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error improving text: %v\n", err)
		os.Exit(1)
	}
	fmt.Println(improved)
}
