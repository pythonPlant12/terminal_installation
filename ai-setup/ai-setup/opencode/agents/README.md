# Agent Selection Guide

58 agent definitions for use as subagents in code review, research, architecture analysis, and specialized tasks.

## Quick Selection

Pick the most specific agent for your task. If none fits, describe the task to the orchestrator.

### Code Review

| Agent | When to use |
|-------|-------------|
| `kieran-typescript-reviewer` | After implementing or modifying TypeScript code — high bar for type safety and patterns |
| `kieran-python-reviewer` | After implementing or modifying Python code — high bar for Pythonic patterns and type safety |
| `code-simplicity-reviewer` | Final review pass to catch YAGNI violations and simplification opportunities |
| `design-implementation-reviewer` | After writing or modifying HTML/CSS/React components — compares against Figma designs |
| `julik-frontend-races-reviewer` | After implementing frontend controllers or async UI code — catches race conditions |
| `lint` | Before pushing — runs linting and code quality checks on Ruby and ERB files |
| `pr-comment-resolver` | When PR review comments need to be resolved with code changes |

### Security & Privacy

| Agent | When to use |
|-------|-------------|
| `security-sentinel` | When reviewing code for vulnerabilities, input validation, auth, or OWASP compliance |
| `data-integrity-guardian` | When checking migration safety, data constraints, transaction boundaries, or privacy |
| `privacy-architect` | For GDPR compliance, privacy-first architecture, or handling sensitive data |
| `threat-modeler` | For security design reviews, risk assessments, or compliance planning |

### Architecture & Patterns

| Agent | When to use |
|-------|-------------|
| `architecture-strategist` | When reviewing PRs, adding services, or evaluating structural refactors |
| `pattern-recognition-specialist` | When checking codebase consistency or verifying new code follows established patterns |
| `agent-native-reviewer` | After adding UI features, agent tools, or system prompts — ensures agent-native parity |
| `tech-debt-surgeon` | When planning major refactors or systematically eliminating technical debt |

### Research & Documentation

| Agent | When to use |
|-------|-------------|
| `best-practices-researcher` | When you need industry standards, community conventions, or implementation guidance |
| `framework-docs-researcher` | When you need official docs, version-specific constraints, or implementation patterns |
| `repo-research-analyst` | When onboarding to a new codebase or understanding project conventions |
| `learnings-researcher` | Before implementing features — searches knowledge/ai/solutions/ for relevant past solutions |
| `git-history-analyzer` | When you need historical context for code changes — traces code evolution |
| `developer-advocate` | For creating SDKs, documentation, developer programs, or technical writing |

### Data & Database

| Agent | When to use |
|-------|-------------|
| `database-wizard` | For database architecture, query optimization, schema design, or data modeling |
| `data-migration-expert` | When PRs involve ID mappings, column renames, enum conversions, or schema changes |
| `data-detective` | When you need deep data investigation, exploratory analysis, or advanced analytics |
| `data-storyteller` | When data needs to tell a story — visualization, dashboard design, stakeholder presentations |

### Performance & Reliability

| Agent | When to use |
|-------|-------------|
| `performance-oracle` | After implementing features — analyzes for bottlenecks, complexity, memory, scalability |
| `performance-optimizer` | When facing performance issues or preparing for scale — profiles and eliminates bottlenecks |
| `reliability-engineer` | For improving uptime, incident response, or building reliable systems |

### Deployment & DevOps

| Agent | When to use |
|-------|-------------|
| `deployment-verification-agent` | When PRs touch production data, migrations, or risky changes — produces Go/No-Go checklists |
| `devops-maestro` | For deployment issues, CI/CD pipeline optimization, or DevOps transformation |
| `github-actions-pro` | For GitHub automation, workflow optimization, or custom action development |
| `jenkins-expert` | For Jenkins pipeline configuration and optimization |
| `workflow-automator` | For automating repetitive tasks, building integrations, or workflow orchestration |
| `docker-captain` | Containerize everything with Docker expertise — Dockerfile optimization, multi-stage builds, and container orchestration |

### Design & Frontend

| Agent | When to use |
|-------|-------------|
| `design-iterator` | When design changes aren't coming together — iteratively refines UI through screenshot-analyze-improve cycles |
| `figma-design-sync` | When syncing implementation to match Figma specs — detects and fixes visual differences |
| `visual-architect` | For UI/UX design, component libraries, responsive design, or visual system creation |
| `tailwind-artist` | For Tailwind CSS development, utility-first design, or design system creation |
| `storybook-artist` | For component libraries, visual testing, or design system documentation |

### Specification & QA

| Agent | When to use |
|-------|-------------|
| `spec-flow-analyzer` | When a spec, plan, or feature description needs flow analysis or edge case discovery |
| `bug-reproduction-validator` | When you receive a bug report that needs verification — systematically reproduces issues |
| `playwright-pro` | For browser automation, cross-browser E2E testing, or web scraping |
| `pytest-master` | For Python testing, TDD, test automation, or advanced pytest usage |

### Language & Framework Specialists

| Agent | When to use |
|-------|-------------|
| `typescript-sage` | For advanced TypeScript type system design, generics, or JavaScript migration |
| `python-alchemist` | For Python data science, automation, or Pythonic pattern excellence |
| `nodejs-ninja` | For Node.js backend services, async patterns, streams, or server optimization |
| `fastapi-expert` | For FastAPI development and configuration |
| `flask-artisan` | For Flask development, blueprints, extensions, or microservices |
| `vue-virtuoso` | For Vue.js 3, Nuxt, Composition API, or Vue ecosystem development |
| `webgl-wizard` | For 3D graphics, WebGL, Three.js, shaders, or 3D web experiences |

### Infrastructure & Cloud

| Agent | When to use |
|-------|-------------|
| `gcp-architect` | For GCP architecture, migration planning, or cloud-native development |
| `linux-admin` | For Linux system administration, performance tuning, security hardening |
| `nginx-wizard` | For NGINX configuration, reverse proxy setup, load balancing, or optimization |

### Business & Strategy

| Agent | When to use |
|-------|-------------|
| `startup-cto` | For technical leadership, architecture decisions, or startup scaling challenges |
| `market-researcher` | For competitive analysis, user research, or market validation |
| `growth-hacker` | For user growth strategies, A/B testing, retention optimization |
| `game-designer` | For game mechanics, progression systems, gamification, or interactive experiences |

### Mobile Development

| Agent | When to use |
|-------|-------------|
| `mobile-architect` | For iOS/Android/cross-platform mobile development — Swift, Kotlin, React Native, Flutter, app store strategy, mobile performance |

## Using Agents via Routers

12 **router agents** distribute tasks to 57 specialists via a "read and role-play" pattern. When you invoke a router, it analyzes your request, picks the right specialist(s), and delegates. Use routers when your task crosses multiple domains or you want automatic specialist selection.

### Routers and Their Specialist Coverage

| Router | Model | Specialists |
|--------|-------|-------------|
| `code-review-router` | sonnet | kieran-typescript-reviewer, kieran-python-reviewer, code-simplicity-reviewer, design-implementation-reviewer, julik-frontend-races-reviewer, lint, pr-comment-resolver |
| `security-router` | **opus** | security-sentinel, data-integrity-guardian, privacy-architect, threat-modeler |
| `architecture-router` | sonnet | architecture-strategist, pattern-recognition-specialist, agent-native-reviewer, tech-debt-surgeon |
| `research-router` | sonnet | best-practices-researcher, framework-docs-researcher, repo-research-analyst, learnings-researcher, git-history-analyzer, developer-advocate |
| `data-router` | **opus** | database-wizard, data-migration-expert, data-detective, data-storyteller |
| `performance-router` | **opus** | performance-oracle, performance-optimizer, reliability-engineer |
| `devops-router` | sonnet | deployment-verification-agent, devops-maestro, github-actions-pro, jenkins-expert, workflow-automator, docker-captain |
| `design-frontend-router` | sonnet | design-iterator, figma-design-sync, visual-architect, tailwind-artist, storybook-artist |
| `qa-router` | sonnet | spec-flow-analyzer, bug-reproduction-validator, playwright-pro, pytest-master |
| `language-router` | sonnet | typescript-sage, python-alchemist, nodejs-ninja, fastapi-expert, flask-artisan, vue-virtuoso, webgl-wizard |
| `infra-router` | sonnet | gcp-architect, linux-admin, nginx-wizard |
| `business-strategy-router` | sonnet | startup-cto, market-researcher, growth-hacker, game-designer |

### Direct Opus Agents

For precision work, invoke these 4 agents directly (or via their parent routers):

- **`data-detective`** — Deep data investigation, exploratory analysis, advanced analytics
- **`performance-optimizer`** — Profiling, bottleneck elimination, scale preparation
- **`privacy-architect`** — GDPR compliance, privacy-first design, sensitive data handling
- **`threat-modeler`** — Security design reviews, risk assessments, compliance modeling

### Example Invocations

```javascript
// Route a multi-language code review
task(subagent_type="code-review-router", prompt="Review this TypeScript PR for type safety")

// Security-focused audit
task(subagent_type="security-router", prompt="OWASP compliance review for this auth module")

// Direct opus agent for deep analysis
task(subagent_type="data-detective", prompt="Investigate user engagement drop in Q4")
```

## All Agents (Alphabetical)

| Agent | Category |
|-------|----------|
| `agent-native-reviewer` | Architecture & Patterns |
| `architecture-strategist` | Architecture & Patterns |
| `best-practices-researcher` | Research & Documentation |
| `bug-reproduction-validator` | Specification & QA |
| `code-simplicity-reviewer` | Code Review |
| `data-detective` | Data & Database |
| `data-integrity-guardian` | Security & Privacy |
| `data-migration-expert` | Data & Database |
| `data-storyteller` | Data & Database |
| `database-wizard` | Data & Database |
| `deployment-verification-agent` | Deployment & DevOps |
| `docker-captain` | Deployment & DevOps |
| `design-implementation-reviewer` | Code Review |
| `design-iterator` | Design & Frontend |
| `developer-advocate` | Research & Documentation |
| `devops-maestro` | Deployment & DevOps |
| `fastapi-expert` | Language & Framework Specialists |
| `figma-design-sync` | Design & Frontend |
| `flask-artisan` | Language & Framework Specialists |
| `framework-docs-researcher` | Research & Documentation |
| `game-designer` | Business & Strategy |
| `gcp-architect` | Infrastructure & Cloud |
| `git-history-analyzer` | Research & Documentation |
| `github-actions-pro` | Deployment & DevOps |
| `growth-hacker` | Business & Strategy |
| `jenkins-expert` | Deployment & DevOps |
| `julik-frontend-races-reviewer` | Code Review |
| `kieran-python-reviewer` | Code Review |
| `kieran-typescript-reviewer` | Code Review |
| `learnings-researcher` | Research & Documentation |
| `lint` | Code Review |
| `linux-admin` | Infrastructure & Cloud |
| `market-researcher` | Business & Strategy |
| `nginx-wizard` | Infrastructure & Cloud |
| `mobile-architect` | Mobile Development |
| `nodejs-ninja` | Language & Framework Specialists |
| `pattern-recognition-specialist` | Architecture & Patterns |
| `performance-optimizer` | Performance & Reliability |
| `performance-oracle` | Performance & Reliability |
| `playwright-pro` | Specification & QA |
| `pr-comment-resolver` | Code Review |
| `privacy-architect` | Security & Privacy |
| `pytest-master` | Specification & QA |
| `python-alchemist` | Language & Framework Specialists |
| `reliability-engineer` | Performance & Reliability |
| `repo-research-analyst` | Research & Documentation |
| `security-sentinel` | Security & Privacy |
| `spec-flow-analyzer` | Specification & QA |
| `startup-cto` | Business & Strategy |
| `storybook-artist` | Design & Frontend |
| `tailwind-artist` | Design & Frontend |
| `tech-debt-surgeon` | Architecture & Patterns |
| `threat-modeler` | Security & Privacy |
| `typescript-sage` | Language & Framework Specialists |
| `visual-architect` | Design & Frontend |
| `vue-virtuoso` | Language & Framework Specialists |
| `webgl-wizard` | Language & Framework Specialists |
| `workflow-automator` | Deployment & DevOps |
