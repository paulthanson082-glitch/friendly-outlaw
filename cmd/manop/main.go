// Ubuntu Manpage Operator (manop)
// A CLI tool to browse, search, and inspect Ubuntu man pages.
package main

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"sort"
	"strconv"
	"strings"
)

// MARK: - Entry point

func main() {
	args := os.Args[1:]
	if len(args) == 0 {
		printUsage()
		os.Exit(0)
	}

	cmd := args[0]
	rest := args[1:]

	switch cmd {
	case "show":
		runShow(rest)
	case "search":
		runSearch(rest)
	case "whatis":
		runWhatis(rest)
	case "list":
		runList(rest)
	case "sections":
		runSections()
	case "--version", "-v", "version":
		fmt.Println("manop version 1.0.0 — Ubuntu Manpage Operator")
	case "--help", "-h", "help":
		printUsage()
	default:
		// Treat bare argument as 'show <cmd>'
		runShow(args)
	}
}

// MARK: - show

func runShow(args []string) {
	var command string
	var section string
	plain := false

	i := 0
	for i < len(args) {
		switch args[i] {
		case "--section", "-s":
			i++
			if i < len(args) {
				section = args[i]
			}
		case "--plain":
			plain = true
		case "--help", "-h":
			fmt.Println("Usage: manop show <command> [--section N] [--plain]")
			return
		default:
			if command == "" {
				command = args[i]
			}
		}
		i++
	}

	if command == "" {
		fatalf("manop show: missing command name\nUsage: manop show <command> [--section N] [--plain]")
	}

	manPath := resolveExecutable("man")
	if manPath == "" {
		fatalf("'man' not found. Install with: sudo apt install man-db")
	}

	var manArgs []string
	if plain {
		manArgs = append(manArgs, "--no-hyphenation", "--no-justification")
	}
	if section != "" {
		manArgs = append(manArgs, section)
	}
	manArgs = append(manArgs, command)

	env := append(os.Environ(), "PAGER=cat")
	if plain {
		env = append(env, "MANPAGER=cat")
	}

	out, code := runCmd(manPath, manArgs, env)
	if code != 0 {
		lower := strings.ToLower(out)
		if strings.Contains(lower, "no manual entry") || strings.TrimSpace(out) == "" {
			fatalf("No man page found for '%s'", command)
		}
		fatalf("%s", strings.TrimSpace(out))
	}

	if plain {
		fmt.Print(stripManFormatting(out))
	} else {
		fmt.Print(out)
	}
}

// MARK: - search (apropos)

func runSearch(args []string) {
	var query string
	var section string
	exact := false

	i := 0
	for i < len(args) {
		switch args[i] {
		case "--section", "-s":
			i++
			if i < len(args) {
				section = args[i]
			}
		case "--exact", "-e":
			exact = true
		case "--help", "-h":
			fmt.Println("Usage: manop search <query> [--section N] [--exact]")
			return
		default:
			if query == "" {
				query = args[i]
			}
		}
		i++
	}

	if query == "" {
		fatalf("manop search: missing query\nUsage: manop search <query> [--section N] [--exact]")
	}

	aproposPath := resolveExecutable("apropos")
	if aproposPath == "" {
		fatalf("'apropos' not found. Install with: sudo apt install man-db")
	}

	var aproposArgs []string
	if exact {
		aproposArgs = append(aproposArgs, "--exact")
	}
	if section != "" {
		aproposArgs = append(aproposArgs, "--section", section)
	}
	aproposArgs = append(aproposArgs, query)

	out, code := runCmd(aproposPath, aproposArgs, nil)
	if code != 0 || strings.TrimSpace(out) == "" {
		fatalf("No man pages found for '%s'", query)
	}

	lines := nonEmptyLines(out)
	fmt.Printf("Found %d result(s) for '%s':\n\n", len(lines), query)
	for _, line := range lines {
		fmt.Printf("  %s\n", line)
	}
}

// MARK: - whatis

func runWhatis(args []string) {
	var commands []string

	for _, a := range args {
		switch a {
		case "--help", "-h":
			fmt.Println("Usage: manop whatis <command> [command...]")
			return
		default:
			commands = append(commands, a)
		}
	}

	if len(commands) == 0 {
		fatalf("manop whatis: provide at least one command name\nUsage: manop whatis <command> [command...]")
	}

	whatisPath := resolveExecutable("whatis")
	if whatisPath == "" {
		fatalf("'whatis' not found. Install with: sudo apt install man-db")
	}

	out, code := runCmd(whatisPath, commands, nil)
	if code != 0 || strings.TrimSpace(out) == "" {
		fatalf("No descriptions found for: %s", strings.Join(commands, ", "))
	}
	fmt.Print(out)
}

// MARK: - list

func runList(args []string) {
	var section string
	limit := 50
	countOnly := false

	i := 0
	for i < len(args) {
		switch args[i] {
		case "--section", "-s":
			i++
			if i < len(args) {
				section = args[i]
			}
		case "--limit", "-l":
			i++
			if i < len(args) {
				n, err := strconv.Atoi(args[i])
				if err == nil {
					limit = n
				}
			}
		case "--count":
			countOnly = true
		case "--help", "-h":
			fmt.Println("Usage: manop list [--section N] [--limit N] [--count]")
			return
		}
		i++
	}

	manRoot := "/usr/share/man"
	entries, err := gatherManPages(manRoot, section)
	if err != nil {
		fatalf("Could not read man pages: %v", err)
	}

	if countOnly {
		fmt.Printf("Total man pages available: %d\n", len(entries))
		return
	}

	displayed := entries
	if len(displayed) > limit {
		displayed = displayed[:limit]
	}

	sectionLabel := "all sections"
	if section != "" {
		sectionLabel = "section " + section
	}
	fmt.Printf("Man pages (%s) — showing %d of %d:\n\n", sectionLabel, len(displayed), len(entries))

	lastSection := ""
	for _, e := range displayed {
		if e.section != lastSection {
			fmt.Printf("  Section %s:\n", e.section)
			lastSection = e.section
		}
		fmt.Printf("    %s(%s)\n", e.name, e.section)
	}

	if len(entries) > limit {
		fmt.Printf("\n  ... and %d more. Use --limit to show more.\n", len(entries)-limit)
	}
}

// MARK: - sections

func runSections() {
	sectionDescriptions := []struct {
		num, desc string
	}{
		{"1", "Executable programs and shell commands"},
		{"2", "System calls (kernel functions)"},
		{"3", "Library calls (functions in program libraries)"},
		{"4", "Special files (usually in /dev)"},
		{"5", "File formats and conventions"},
		{"6", "Games and screensavers"},
		{"7", "Miscellaneous (macro packages, conventions)"},
		{"8", "System administration commands (root only)"},
		{"9", "Kernel routines (non-standard)"},
	}

	manRoot := "/usr/share/man"
	fmt.Println("Ubuntu Manual Sections:\n")
	for _, s := range sectionDescriptions {
		dirName := "man" + s.num
		dirPath := filepath.Join(manRoot, dirName)
		files, err := os.ReadDir(dirPath)
		count := 0
		exists := err == nil
		if exists {
			count = len(files)
		}
		status := fmt.Sprintf("(%d pages)", count)
		if !exists {
			status = "(not installed)"
		}
		fmt.Printf("  Section %s: %s\n", s.num, s.desc)
		fmt.Printf("             %s\n\n", status)
	}
}

// MARK: - Helpers

type manEntry struct {
	section string
	name    string
}

func gatherManPages(manRoot, section string) ([]manEntry, error) {
	dirs, err := os.ReadDir(manRoot)
	if err != nil {
		return nil, err
	}

	var sections []string
	if section != "" {
		sections = []string{"man" + section}
	} else {
		for _, d := range dirs {
			if d.IsDir() && strings.HasPrefix(d.Name(), "man") && len(d.Name()) == 4 {
				sections = append(sections, d.Name())
			}
		}
		sort.Strings(sections)
	}

	var entries []manEntry
	for _, sectionDir := range sections {
		sectionNum := strings.TrimPrefix(sectionDir, "man")
		sectionPath := filepath.Join(manRoot, sectionDir)
		files, err := os.ReadDir(sectionPath)
		if err != nil {
			continue
		}
		var names []string
		for _, f := range files {
			names = append(names, stripManExtensions(f.Name()))
		}
		sort.Strings(names)
		for _, n := range names {
			entries = append(entries, manEntry{section: sectionNum, name: n})
		}
	}
	return entries, nil
}

// stripManFormatting removes nroff backspace-based bold/underline (char BS char).
func stripManFormatting(text string) string {
	runes := []rune(text)
	var result []rune
	for i := 0; i < len(runes); {
		if i+2 < len(runes) && runes[i+1] == 8 { // ASCII backspace
			result = append(result, runes[i+2])
			i += 3
		} else {
			result = append(result, runes[i])
			i++
		}
	}
	return string(result)
}

// stripManExtensions removes file extensions: ls.1.gz -> ls
func stripManExtensions(filename string) string {
	name := filename
	if strings.HasSuffix(name, ".gz") {
		name = name[:len(name)-3]
	} else if strings.HasSuffix(name, ".bz2") {
		name = name[:len(name)-4]
	}
	if idx := strings.LastIndex(name, "."); idx >= 0 {
		name = name[:idx]
	}
	return name
}

// resolveExecutable finds a binary in common PATH locations.
func resolveExecutable(name string) string {
	searchPaths := []string{"/usr/bin", "/bin", "/usr/sbin", "/sbin", "/usr/local/bin"}
	for _, dir := range searchPaths {
		path := filepath.Join(dir, name)
		if _, err := os.Stat(path); err == nil {
			return path
		}
	}
	// Also try PATH
	if path, err := exec.LookPath(name); err == nil {
		return path
	}
	return ""
}

// runCmd executes a command and returns combined output and exit code.
func runCmd(binary string, args []string, env []string) (string, int) {
	cmd := exec.Command(binary, args...)
	if env != nil {
		cmd.Env = env
	}
	out, err := cmd.CombinedOutput()
	code := 0
	if err != nil {
		if exitErr, ok := err.(*exec.ExitError); ok {
			code = exitErr.ExitCode()
		} else {
			code = -1
		}
	}
	return string(out), code
}

func nonEmptyLines(s string) []string {
	var result []string
	for _, line := range strings.Split(s, "\n") {
		if strings.TrimSpace(line) != "" {
			result = append(result, line)
		}
	}
	return result
}

func fatalf(format string, args ...interface{}) {
	fmt.Fprintf(os.Stderr, "manop: "+format+"\n", args...)
	os.Exit(1)
}

func printUsage() {
	fmt.Print(`Ubuntu Manpage Operator (manop) v1.0.0
Browse, search, and inspect Ubuntu manual pages.

Usage:
  manop show <command> [--section N] [--plain]   Show a man page
  manop search <query> [--section N] [--exact]   Search man pages (apropos)
  manop whatis <command> [command...]             One-line descriptions
  manop list [--section N] [--limit N] [--count] List available man pages
  manop sections                                 List manual sections

Examples:
  manop show ls
  manop show ls --section 1
  manop show passwd --section 5
  manop search "copy files"
  manop whatis tar grep awk
  manop list --section 1 --limit 20
  manop sections

`)
}
