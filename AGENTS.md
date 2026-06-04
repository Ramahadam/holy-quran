# AGENTS.md

This file provides guidance to Codex (Codex.ai/code) when working with code in this repository.

Behavioral guidelines to reduce common LLM coding mistakes. Merge with project-specific instructions as needed.

**Tradeoff:** These guidelines bias toward caution over speed. For trivial tasks, use judgment.

## 1. Think Before Coding

**Don't assume. Don't hide confusion. Surface tradeoffs.**

Before implementing:
- State your assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them - don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.

## 2. Simplicity First

**Minimum code that solves the problem. Nothing speculative.**

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.

Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

## 3. Surgical Changes

**Touch only what you must. Clean up only your own mess.**

When editing existing code:
- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it - don't delete it.

When your changes create orphans:
- Remove imports/variables/functions that YOUR changes made unused.
- Don't remove pre-existing dead code unless asked.

The test: Every changed line should trace directly to the user's request.

## 4. Goal-Driven Execution

**Define success criteria. Loop until verified.**

Transform tasks into verifiable goals:
- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after"

For multi-step tasks, state a brief plan:
```
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
```

Strong success criteria let you loop independently. Weak criteria ("make it work") require constant clarification.

## 5. Branch and Issue Discipline

**Every feature gets its own branch and tracking issue. Clean up after merge.**

### Before Starting Feature Work
1. **Create GitHub issue** describing the feature/task with:
   - Clear overview and context
   - Detailed requirements or acceptance criteria
   - Technical notes and considerations
   - Related issues and dependencies
2. **Create local branch** from main:
   ```bash
   git checkout main
   git pull
   git checkout -b feature/descriptive-name
   ```
   Use naming conventions:
   - `feature/` for new features
   - `fix/` for bug fixes
   - `refactor/` for refactoring work
3. **Reference issue number** in all commits (e.g., "feat: Add models (#3)")

### During Development
- Work only on your feature branch
- Never commit directly to main
- Keep commits atomic and focused
- Write clear commit messages

### After PR Merge
**Always clean up branches after merge:**
```bash
# Switch back to main
git checkout main

# Pull the merged changes
git pull

# Delete local feature branch
git branch -d feature/branch-name

# Delete remote branch (if not auto-deleted)
git push origin --delete feature/branch-name
```

This workflow ensures:
- Clean PR reviews with focused changes
- Easy rollback if needed
- Clear work-in-progress tracking
- No stale branches cluttering the repository
- Atomic, reviewable units of work

---

**These guidelines are working if:** fewer unnecessary changes in diffs, fewer rewrites due to overcomplication, and clarifying questions come before implementation rather than after mistakes.
