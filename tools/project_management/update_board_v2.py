import json
import os
import re

def update_project_board():
    metadata_path = "tools/project_management/issue_metadata.json"
    with open(metadata_path, "r") as f:
        metadata = json.load(f)

    with open("PROJECT_BOARD.md", "r") as f:
        content = f.read()

    # Map status to symbols
    status_symbols = {
        "Done": "✅ Done",
        "In progress": "🔄 In progress",
        "Ready": "⏳ Ready",
        "Backlog": "📋 Backlog",
        "In review": "🔄 In review"
    }

    # Groups
    creative_assets_wiring = [str(i) for i in range(299, 307)]
    story_gaps = ["294", "295", "296", "297", "298"]
    playability = ["288", "289", "291"]
    infrastructure = ["290", "292", "307"]
    bugs = ["308", "309", "311", "312", "313", "314", "315", "316", "317"]
    closed = ["293", "310"]

    # 1. Update 5.1b table
    for issue_num in creative_assets_wiring:
        data = metadata[issue_num]
        pattern = rf"(\| .* \| #?{issue_num} \| )[^|]+( \| )[^|]+( \| .* \|)"
        replacement = rf"\1{status_symbols[data['status']]}\2{data['priority']}\3"
        content = re.sub(pattern, replacement, content)

    # 2. Update 5.6 Bugs & Refactoring (if exists, else create)
    bug_section_header = "### 5.6 Bugs & Refactoring"
    if bug_section_header in content:
        # Extract the table and rebuild it
        bug_table_start = content.find(bug_section_header)
        next_section_start = content.find("## Infrastructure Completed", bug_table_start)

        bug_table = [
            f"### 5.6 Bugs & Refactoring ({len(bugs)} issues)\n",
            "\n",
            "| Task | Issue | Status | Priority | Estimate | Blocked By |\n",
            "|----|-----|------|--------|--------|----------|\n"
        ]
        for issue_num in bugs:
            data = metadata[issue_num]
            title = data['title'].replace("[Bug] ", "")
            bug_table.append(f"| {title} | #{issue_num} | {status_symbols[data['status']]} | {data['priority']} | 1d | None |\n")

        content = content[:bug_table_start] + "".join(bug_table) + "\n" + content[next_section_start:]
    else:
        # Should have been created in previous run, but let's be safe
        pass

    # 3. Handle 5.1 Asset Structure (Issue 194 -> 302 rename/sync)
    # Actually 194 is old, 302 is new.
    # Let's check if 302 is in 5.1b, yes it is.

    # 4. Check for unhandled issues and find a home for them
    # Story gaps: 294-298. These should be in 5.4 or 5.5 or a new 5.7
    if "### 5.7 MVP Gaps: Story & Economy" not in content:
        insert_idx = content.find("### 5.6 Bugs & Refactoring")
        story_section = [
            "### 5.7 MVP Gaps: Story & Economy (5 issues)\n",
            "\n",
            "| Task | Issue | Status | Priority | Estimate | Blocked By |\n",
            "|----|-----|------|--------|--------|----------|\n"
        ]
        for issue_num in story_gaps:
            data = metadata[issue_num]
            title = data['title'].replace("[Story] ", "")
            story_section.append(f"| {title} | #{issue_num} | {status_symbols[data['status']]} | {data['priority']} | 2d | None |\n")
        story_section.append("\n")
        content = content[:insert_idx] + "".join(story_section) + content[insert_idx:]

    # 5. Playability & Infrastructure gaps: 288, 289, 290, 291, 292, 307
    if "### 5.8 Playability & Infrastructure" not in content:
        insert_idx = content.find("## Infrastructure Completed")
        pi_issues = playability + infrastructure
        pi_section = [
            "### 5.8 Playability & Infrastructure (6 issues)\n",
            "\n",
            "| Task | Issue | Status | Priority | Estimate | Blocked By |\n",
            "|----|-----|------|--------|--------|----------|\n"
        ]
        for issue_num in pi_issues:
            data = metadata[issue_num]
            title = data['title'].replace("[Playability] ", "").replace("[Infrastructure] ", "")
            pi_section.append(f"| {title} | #{issue_num} | {status_symbols[data['status']]} | {data['priority']} | 1d | None |\n")
        pi_section.append("\n")
        content = content[:insert_idx] + "".join(pi_section) + content[insert_idx:]

    # Final Timestamp
    content = re.sub(r"\*\*Last Updated:\*\* .*", "**Last Updated:** 2026-06-13", content)

    with open("PROJECT_BOARD.md", "w") as f:
        f.write(content)

if __name__ == "__main__":
    update_project_board()
    print("Full sync of PROJECT_BOARD.md complete.")
