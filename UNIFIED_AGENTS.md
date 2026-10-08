# Claude Code Unified Agents

Integration with stretchcloud/claude-code-unified-agents for advanced AI orchestration.

## Overview

Unified agents provide a framework for coordinating multiple AI agents to solve complex tasks through collaboration and specialization.

## Supported Agents

### Core Agents
- **Planner Agent** — Breaks down complex tasks into subtasks
- **Executor Agent** — Executes individual task steps
- **Reviewer Agent** — Validates results and provides feedback
- **Coordinator Agent** — Manages communication between agents

### Specialized Agents
- **Code Review Agent** — Analyzes code quality
- **Documentation Agent** — Generates and maintains docs
- **Testing Agent** — Creates and runs tests
- **Security Agent** — Performs security analysis

## Installation

```bash
# Add to Package.swift
.package(url: "https://github.com/stretchcloud/claude-code-unified-agents.git", from: "1.0.0")

# Or via CocoaPods
pod 'ClaudeCodeUnifiedAgents'
```

## Basic Usage

```swift
import UnifiedAgents

// Create agent pool
let agents = AgentPool(
    planner: PlannerAgent(),
    executor: ExecutorAgent(),
    reviewer: ReviewerAgent(),
    coordinator: CoordinatorAgent()
)

// Execute complex task
let result = await agents.executeTask(
    "Refactor codebase and add comprehensive tests",
    constraints: [
        .timeLimit(hours: 4),
        .maxCost(dollars: 50),
        .qualityThreshold(0.95)
    ]
)

// Monitor progress
for await update in result.progressStream {
    print("Agent: \(update.agent.name)")
    print("Status: \(update.status)")
    print("Progress: \(update.progress)%")
}
```

## Agent Configuration

```swift
let config = AgentConfig(
    model: .claude35Sonnet,
    temperature: 0.7,
    maxTokens: 8000,
    retryPolicy: .exponentialBackoff(maxAttempts: 3),
    logging: .verbose
)

let agents = AgentPool(config: config)
```

## Task Orchestration

### Sequential Execution
```swift
let pipeline = AgentPipeline()
    .add(stage: .planning, agent: plannerAgent)
    .add(stage: .execution, agent: executorAgent)
    .add(stage: .review, agent: reviewerAgent)

let result = await pipeline.execute(task: myTask)
```

### Parallel Execution
```swift
let tasks = [task1, task2, task3]
let results = await agents.executeInParallel(tasks)
```

### Conditional Execution
```swift
let result = await agents.executeWithConditions(
    task: complexTask,
    conditions: [
        .retryIf { $0.qualityScore < 0.8 },
        .escalateIf { $0.error != nil },
        .skipIf { $0.estimatedCost > budget }
    ]
)
```

## Communication Protocol

Agents communicate via:
- **Message Queue** — Async message passing
- **Shared State** — For coordination and context
- **Event Bus** — For pub/sub patterns
- **Direct API** — For synchronous calls

## Error Handling

```swift
do {
    let result = await agents.executeTask(task)
} catch AgentError.timeout {
    print("Task exceeded time limit")
} catch AgentError.costExceeded {
    print("Task exceeded budget")
} catch AgentError.qualityThreshold {
    print("Result did not meet quality requirements")
}
```

## Monitoring & Observability

```swift
// Setup monitoring
let monitor = AgentMonitor(
    metricsCollector: PrometheusCollector(),
    tracer: JaegerTracer(),
    logger: StructuredLogger()
)

agents.attachMonitor(monitor)

// Query metrics
let metrics = await monitor.getMetrics(
    timeWindow: .last24Hours,
    groupBy: .agent
)
```

## Best Practices

1. **Clear Task Definitions** — Provide specific, measurable goals
2. **Agent Specialization** — Match agents to their strengths
3. **Resource Constraints** — Set time and cost limits
4. **Error Handling** — Implement fallback strategies
5. **Monitoring** — Track agent performance
6. **Testing** — Test agent interactions thoroughly

## Integration with friendly-outlaw

Use unified agents for:
- Multi-step document generation
- Collaborative editing workflows
- AI-assisted code review and refactoring
- Automated testing and quality assurance
- Complex content analysis and transformation

## References

- [Unified Agents Documentation](https://github.com/stretchcloud/claude-code-unified-agents)
- [Agent Design Patterns](https://stretchcloud.io/docs/agents/patterns)
- [Orchestration Guide](https://stretchcloud.io/docs/agents/orchestration)
