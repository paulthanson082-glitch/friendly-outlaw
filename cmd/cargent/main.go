// Package main implements cargent — a minimal Claude AI agent with a tool loop.
// It reads a task from command-line arguments, then repeatedly calls the
// Anthropic Messages API (with tool_use support) until Claude stops requesting
// tools and returns a final text answer.
//
// Usage:
//
//	ANTHROPIC_API_KEY="sk-ant-..." go run . "Count the words in: Hello world foo"
//
// Built-in tools:
//
//	word_count      — count words in a string
//	char_count      — count characters in a string
//	reverse_text    — reverse a string
//	repeat_text     — repeat a string N times
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
	"unicode"
)

// ---------------------------------------------------------------------------
// Anthropic API types
// ---------------------------------------------------------------------------

type message struct {
	Role    string `json:"role"`
	Content any    `json:"content"` // string | []contentBlock
}

type contentBlock struct {
	Type      string          `json:"type"`
	Text      string          `json:"text,omitempty"`
	ID        string          `json:"id,omitempty"`
	Name      string          `json:"name,omitempty"`
	Input     json.RawMessage `json:"input,omitempty"`
	ToolUseID string          `json:"tool_use_id,omitempty"`
	Content   string          `json:"content,omitempty"`
}

type toolDef struct {
	Name        string         `json:"name"`
	Description string         `json:"description"`
	InputSchema map[string]any `json:"input_schema"`
}

type apiRequest struct {
	Model     string    `json:"model"`
	MaxTokens int       `json:"max_tokens"`
	Tools     []toolDef `json:"tools"`
	Messages  []message `json:"messages"`
}

type apiResponse struct {
	ID          string         `json:"id"`
	StopReason  string         `json:"stop_reason"`
	Content     []contentBlock `json:"content"`
	Error       *apiError      `json:"error,omitempty"`
}

type apiError struct {
	Type    string `json:"type"`
	Message string `json:"message"`
}

// ---------------------------------------------------------------------------
// Built-in tools
// ---------------------------------------------------------------------------

var tools = []toolDef{
	{
		Name:        "word_count",
		Description: "Count the number of words in a string.",
		InputSchema: map[string]any{
			"type": "object",
			"properties": map[string]any{
				"text": map[string]any{
					"type":        "string",
					"description": "The text to count words in.",
				},
			},
			"required": []string{"text"},
		},
	},
	{
		Name:        "char_count",
		Description: "Count the number of characters (excluding spaces) in a string.",
		InputSchema: map[string]any{
			"type": "object",
			"properties": map[string]any{
				"text": map[string]any{
					"type":        "string",
					"description": "The text to count characters in.",
				},
			},
			"required": []string{"text"},
		},
	},
	{
		Name:        "reverse_text",
		Description: "Reverse the characters in a string.",
		InputSchema: map[string]any{
			"type": "object",
			"properties": map[string]any{
				"text": map[string]any{
					"type":        "string",
					"description": "The text to reverse.",
				},
			},
			"required": []string{"text"},
		},
	},
	{
		Name:        "repeat_text",
		Description: "Repeat a string a given number of times, joined by a separator.",
		InputSchema: map[string]any{
			"type": "object",
			"properties": map[string]any{
				"text": map[string]any{
					"type":        "string",
					"description": "The text to repeat.",
				},
				"times": map[string]any{
					"type":        "integer",
					"description": "How many times to repeat (1–20).",
					"minimum":     1,
					"maximum":     20,
				},
				"separator": map[string]any{
					"type":        "string",
					"description": "String placed between repetitions (default: space).",
				},
			},
			"required": []string{"text", "times"},
		},
	},
}

// executeTool runs the named tool with the provided JSON input and returns
// executeTool parses rawInput JSON for the named built-in tool, executes the tool, and returns the resulting string or an error.
// Supported tools:
// - "word_count": returns the number of words in the "text" field using whitespace splitting.
// - "char_count": returns the count of runes in "text" excluding Unicode whitespace.
// - "reverse_text": returns the rune-reversed "text" string.
// - "repeat_text": returns "text" repeated `times` times joined by "separator" (default: " "); `times` is clamped to the range 1–20.
// Returns an error if the input JSON is invalid or the tool name is unknown.
func executeTool(name string, rawInput json.RawMessage) (string, error) {
	var input map[string]any
	if err := json.Unmarshal(rawInput, &input); err != nil {
		return "", fmt.Errorf("bad input JSON: %w", err)
	}

	getString := func(key string) (string, bool) {
		v, ok := input[key]
		if !ok {
			return "", false
		}
		s, ok := v.(string)
		return s, ok
	}

	switch name {
	case "word_count":
		text, _ := getString("text")
		count := len(strings.Fields(text))
		return fmt.Sprintf("%d", count), nil

	case "char_count":
		text, _ := getString("text")
		count := 0
		for _, r := range text {
			if !unicode.IsSpace(r) {
				count++
			}
		}
		return fmt.Sprintf("%d", count), nil

	case "reverse_text":
		text, _ := getString("text")
		runes := []rune(text)
		for i, j := 0, len(runes)-1; i < j; i, j = i+1, j-1 {
			runes[i], runes[j] = runes[j], runes[i]
		}
		return string(runes), nil

	case "repeat_text":
		text, _ := getString("text")
		sep := " "
		if s, ok := getString("separator"); ok {
			sep = s
		}
		times := 1
		if v, ok := input["times"]; ok {
			switch n := v.(type) {
			case float64:
				times = int(n)
			case int:
				times = n
			}
		}
		if times < 1 {
			times = 1
		}
		if times > 20 {
			times = 20
		}
		parts := make([]string, times)
		for i := range parts {
			parts[i] = text
		}
		return strings.Join(parts, sep), nil

	default:
		return "", fmt.Errorf("unknown tool: %s", name)
	}
}

// ---------------------------------------------------------------------------
// API client
// ---------------------------------------------------------------------------

const (
	apiURL   = "https://api.anthropic.com/v1/messages"
	apiVer   = "2023-06-01"
	model    = "claude-3-5-sonnet-20241022"
	maxToks  = 1024
	maxIter  = 10
)

// callAPI sends the provided conversation messages and the package's tool definitions to the Anthropic
// Messages API and returns the parsed API response.
//
// It uses the package-level model, token limit, and tools, includes the given apiKey and the required
// headers, and honors ctx for cancellation; the HTTP client enforces a 60-second timeout. If the API
// returns an error payload, callAPI returns an error containing the API error type and message.
func callAPI(ctx context.Context, apiKey string, msgs []message) (*apiResponse, error) {
	req := apiRequest{
		Model:     model,
		MaxTokens: maxToks,
		Tools:     tools,
		Messages:  msgs,
	}

	body, err := json.Marshal(req)
	if err != nil {
		return nil, fmt.Errorf("marshal: %w", err)
	}

	httpReq, err := http.NewRequestWithContext(ctx, http.MethodPost, apiURL, bytes.NewReader(body))
	if err != nil {
		return nil, fmt.Errorf("new request: %w", err)
	}
	httpReq.Header.Set("Content-Type", "application/json")
	httpReq.Header.Set("x-api-key", apiKey)
	httpReq.Header.Set("anthropic-version", apiVer)

	client := &http.Client{Timeout: 60 * time.Second}
	resp, err := client.Do(httpReq)
	if err != nil {
		return nil, fmt.Errorf("http: %w", err)
	}
	defer resp.Body.Close()

	data, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("read body: %w", err)
	}

	var ar apiResponse
	if err := json.Unmarshal(data, &ar); err != nil {
		return nil, fmt.Errorf("unmarshal: %w", err)
	}
	if ar.Error != nil {
		return nil, fmt.Errorf("API error (%s): %s", ar.Error.Type, ar.Error.Message)
	}
	return &ar, nil
}

// ---------------------------------------------------------------------------
// Agent loop
// run executes the agent loop for the provided task using the Anthropic Messages API.
// 
// It starts the conversation with a single user message containing task, repeatedly
// calls the API, and reacts to assistant responses that request tool executions.
// If the assistant response does not request tools, any text content blocks are
// printed to stdout and run returns nil. If tool executions are requested, each
// tool is executed locally and its result is appended to the conversation as a
// `tool_result` user message, after which the loop continues. The function returns
// an error if an API call fails or if the loop exceeds the configured iteration limit.

func run(ctx context.Context, apiKey, task string) error {
	msgs := []message{
		{Role: "user", Content: task},
	}

	for i := 0; i < maxIter; i++ {
		resp, err := callAPI(ctx, apiKey, msgs)
		if err != nil {
			return err
		}

		// Collect tool-use blocks.
		var toolUseBlocks []contentBlock
		for _, blk := range resp.Content {
			if blk.Type == "tool_use" {
				toolUseBlocks = append(toolUseBlocks, blk)
			}
		}

		// If no tool use, print the final text and exit.
		if resp.StopReason != "tool_use" || len(toolUseBlocks) == 0 {
			for _, blk := range resp.Content {
				if blk.Type == "text" {
					fmt.Println(blk.Text)
				}
			}
			return nil
		}

		// Append the assistant's full response to the conversation.
		msgs = append(msgs, message{Role: "assistant", Content: resp.Content})

		// Execute each tool and build tool_result blocks.
		var resultBlocks []contentBlock
		for _, tb := range toolUseBlocks {
			result, execErr := executeTool(tb.Name, tb.Input)
			if execErr != nil {
				resultBlocks = append(resultBlocks, contentBlock{
					Type:      "tool_result",
					ToolUseID: tb.ID,
					Content:   fmt.Sprintf("error: %v", execErr),
				})
			} else {
				resultBlocks = append(resultBlocks, contentBlock{
					Type:      "tool_result",
					ToolUseID: tb.ID,
					Content:   result,
				})
			}
		}

		msgs = append(msgs, message{Role: "user", Content: resultBlocks})
	}

	return fmt.Errorf("agent loop exhausted after %d iterations", maxIter)
}

// ---------------------------------------------------------------------------
// Entry point
// main is the entry point of the cargent CLI. It reads ANTHROPIC_API_KEY, validates and formats the command-line task argument, invokes run with a background context, and prints usage or error messages to stderr and exits nonzero on failure.

func main() {
	apiKey := os.Getenv("ANTHROPIC_API_KEY")
	if apiKey == "" {
		fmt.Fprintln(os.Stderr, "error: ANTHROPIC_API_KEY environment variable not set")
		os.Exit(1)
	}

	if len(os.Args) < 2 {
		fmt.Fprintf(os.Stderr, "usage: %s <task>\n", os.Args[0])
		fmt.Fprintln(os.Stderr, "")
		fmt.Fprintln(os.Stderr, "cargent — Claude AI agent with tool-loop support")
		fmt.Fprintln(os.Stderr, "")
		fmt.Fprintln(os.Stderr, "Available tools: word_count, char_count, reverse_text, repeat_text")
		fmt.Fprintln(os.Stderr, "")
		fmt.Fprintln(os.Stderr, "Example:")
		fmt.Fprintf(os.Stderr, "  ANTHROPIC_API_KEY=sk-ant-... %s \"How many words are in 'the quick brown fox'?\"\n", os.Args[0])
		os.Exit(1)
	}

	task := strings.Join(os.Args[1:], " ")
	ctx := context.Background()

	if err := run(ctx, apiKey, task); err != nil {
		fmt.Fprintf(os.Stderr, "error: %v\n", err)
		os.Exit(1)
	}
}
