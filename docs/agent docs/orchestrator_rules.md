# Orchestrator Rules and Coordination Guidelines

As the Orchestrator, this document defines the governance rules for all AI sub-agents working on the SmartClass project.

## Core Coordination Rules

1. **Sequential Execution (Single-Agent Workload)**: 
   Only exactly **one** sub-agent can be active and execute tasks at any given time. No parallel development or conflicting agent runs are permitted.

2. **Scoped Modification Boundary**:
   The active sub-agent must strictly limit its file modifications to the scope of its assigned task. Tampering with or modifying files unrelated to its current task is strictly prohibited.

3. **Documentation Requirement**:
   Once a sub-agent completes its task, it must document its changes, implementation choices, and verification results in a markdown file in [agent docs](file:///d:/Flutter_Projects/smartclass_v2/docs/agent%20docs). The filename should be formatted as `<agent_name>_<task_description>.md`.

4. **Orchestrator Verification**:
   The Orchestrator must verify the changes, review the documentation, and confirm task completion before deactivating the current agent and briefing the next agent.
