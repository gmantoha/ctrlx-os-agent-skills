# Prompts, skills and user-facing behavior

Scope: supplied User Manual, **AI Agent Usage** and **Header Widget**. See [sources](sources.md).

## Custom system prompt

`.agents/SystemPrompt.md` **supplements**, rather than replaces, the built-in prompt in 0.5.0. The built-in prompt is embedded in the application and includes shared instructions and current ctrlX OS deployment context. Keep only the user's machine/task-specific additions in the custom file. Custom text cannot remove application permissions or approval gates.

- The launcher creates a template only if the file is missing; existing files are preserved. Template updates do not create `.new` files for this prompt, and `.new` prompt files are never loaded.
- The file is read before **every model request**, including tool-result follow-ups. A saved change applies on the next request, not to an in-flight one. There is no watcher and no restart is needed.
- Use atomic saves to avoid partial reads. Read errors or unclosed comments prevent startup if detected there, or fail the current chat request. Fix the file and retry.
- The loader replaces every HTML comment `<!-- ... -->` with a newline before trimming/appending the remaining text, **including comments inside code fences**. Comments do not nest; the first closing marker ends a block. An unmatched closing marker is ordinary text; an unclosed opening marker is an error.
- Missing, empty or comment-only content uses built-ins only. Limited AskRexroth mode ignores the file altogether.
- Standalone: `CTRLX_AGENT_CONTEXT_DIR` points to the containing folder, default `.agents`, not a Markdown filename. A standalone user can copy `defaults/.agents/SystemPrompt.md` into that context folder.

## Custom skills and overrides

```text
.agents/skills/
  builtin/                  # app-owned; replaced on every app start
  custom/
    machine-helper/
      SKILL.md
      references/           # optional
      scripts/              # optional
```

Minimal example:

```markdown
---
name: machine-helper
description: Explain the machine's documented operating checks and troubleshooting steps.
---

# Machine helper

Inspect the relevant status before proposing changes. Do not modify real-device
configuration without explicit confirmation. Read supporting references as needed.
```

The folder name must match frontmatter `name`, otherwise the skill is rejected. To adapt a shipped skill, copy it with its supporting resources to `custom/<same-name>/SKILL.md`. A same-named custom skill takes precedence over builtin. Do not edit `builtin/`; changes disappear on the next app start. Legacy flat Markdown skills have lower priority; migrate them rather than recommending the old flat layout for new skills.

Distinguish installation destinations:

- Installing this repository's `ctrlx-ai` skill into a workstation agent teaches that agent how to configure iXi; it does not deploy anything to a ctrlX device.
- Deploying a custom skill into iXi writes to the device's active configuration and needs confirmation on a real target. Verify allowed filesystem roots first; do not assume an absolute solution path or copy the entire repository into the device.

After deploying a custom skill, verify its name/path and test that it is available through the installed version's skill tools. The manual does not specify a universal skill hot-reload mechanism; do not invent one. Prompt instructions and skill text do not grant additional tool permissions.

## Limited mode and model switching

Without valid model configuration, AskRexroth limited mode shows a warning banner, answers only the latest message without history, cannot use tools, skills or attachments, and ignores `SystemPrompt.md`. Fix model configuration before diagnosing missing skills or complex workflows.

`/model` lists available models; `/model <provider/model-or-role>` switches for the next message. The widget picker is available with two or more configured models, searches model/provider/role case-insensitively and groups results by provider. If a selected model is removed, the conversation uses `default_model`; role selections track role changes.

## Conversations, uploads and privacy

- `+` creates a conversation; the conversation list supports search and date sorting. Stop aborts a response including pending tool calls. `/clear` deletes all messages in the current conversation; do not invoke it as a harmless diagnosis step.
- Conversations live on the device and are deleted after **30 days without activity**. HTML export opens a readable view; ZIP export includes JSON, HTML and images; import restores an exported ZIP. Exports can contain sensitive device/user data.
- Up to **4 attachments per message**: images (`png`, `jpg`, `jpeg`, `webp`, `gif`), text/data (`txt`, `md`, `json`, `yaml`, `yml`, `xml`, `csv`, `log`) and PDF.
- Images go directly to an image-capable model. Other files are stored in `.agents/attachments/` for file-tool access. Attachments are accessible to AI file tools of **all conversations on the device**; do not promise per-conversation file isolation.
- Messages, tool results and attachments go to the configured LLM provider; limited-mode messages go to AskRexroth. Confirm the provider is approved for the data before uploading or using sensitive content.
- Camera and speech input require browser permissions. Microphone language **Auto** uses the browser language.

## Hosted web apps

Store generated/manual web pages in `.agents/www/`, served through:

```text
https://<device-hostname>/ctrlx-ai-agent/serve/
```

The pages use the ctrlX web-interface login; log in there first. Creating an HMI/dashboard is not authorization to change control values or add broad network access. Treat page writes and any control actions as real-device changes when applicable.

## Widget status and token/cost panel

- The header widget is installed automatically; it can remain open across navigation, be moved/resized and minimized.
- A blue number means unread responses (capped at `99+`). Red `!` means a pending tool approval and takes precedence. Conversation-list and burger badges aggregate relevant inactive sessions independently of filters.
- Status refreshes every **five seconds while the browser page is visible**. Opening a conversation marks responses read, not approvals. **Read all** includes search-hidden conversations; it does not approve or clear pending tool calls. Read state persists in that browser.
- The context percentage concerns the **last request**, not a guarantee of total remaining conversation capacity. The panel estimates prompt/tools/tool calls/skills/messages/free space, scaled to provider-reported input tokens.
- Last-request counts include cached input; session totals sum all model requests including tool follow-ups. Costs appear only with configured pricing and remain estimates. An unknown context window shows counts only; a partially priced session shows cost as a lower bound (`≥`).
