---
name: local-llm-offload
description: "将已收集的纯文本批量交给本地 LiteLLM/Ollama 做摘要、清洗和格式转换；适用于长日志、批量文本、双语初稿、注释/样板代码和 JSON/CSV/Markdown 重排；边界：本地弱模型不得规划或执行多步自主 Tool Calling，git、搜索与文件读取由主模型完成，不用于高风险决策或深度推理。"
---
# Local LLM Offload

Use the local LiteLLM gateway at `http://127.0.0.1:4000/v1` for plain-text summarization, cleanup, draft translation, and restructuring. The default LiteLLM model ID is `weak-model` (Qwen2.5 7B); `back-model` (Granite 3B) is configured as fallback.

## Trigger

When a request matches any category or Chinese/English keyword below, prefer this skill for the already-collected plain text:

| Category | 中文触发词 | English triggers |
|---|---|---|
| 日志诊断 | 查日志、看报错、分析日志、提取异常、过滤错误、日志摘要、崩溃原因、排查日志 | check logs, inspect errors, analyze logs, extract exceptions, filter errors, log summary, crash cause, troubleshoot logs |
| 文档归纳 | 总结文档、提炼要点、归纳笔记、整理收件箱、提取待办、会议纪要、长文浓缩、汇总资料、核心观点 | summarize documents, extract key points, consolidate notes, triage inbox, extract action items, meeting minutes, condense long text, consolidate materials, key takeaways |
| 数据清洗 | 清洗数据、提取字段、转成表格、整理成 JSON/CSV、格式化输出、文本去重、分类归档、信息抽取 | clean data, extract fields, convert to table, format as JSON/CSV, format output, deduplicate text, classify and archive, information extraction |
| 代码辅助 | 加注释、生成注释、补全 docstring、写单测、生成测试用例、解释代码、写 README、接口文档初稿 | add comments, generate comments, complete docstrings, write unit tests, generate test cases, explain code, write a README, draft API documentation |
| 翻译本地化 | 批量翻译、双语对照、翻译字幕、润色邮件、英译中、中译英、文案本地化、改写初稿 | batch translation, bilingual alignment, subtitle translation, polish emails, English to Chinese, Chinese to English, copy localization, rewrite a draft |
| 内容变体 | 批量改写、生成标题、提取标签、开发信初稿、文案变体、拆解文案 | batch rewriting, generate headlines, extract tags, outreach email draft, copy variants, break down copy |

Match on intent as well as exact wording. The input to this skill must be plain text already gathered by the main cloud model.

## Tool-calling boundary

The local weak model (`local` profile / `weak-model`) must never plan or run multi-step autonomous Tool Calling. The main cloud model is responsible for `git log`, file reads, searches, and other tool calls. It gathers the required raw text first, then passes only that plain text to this skill for summarization or cleanup. Do not ask the local model to choose tools, inspect a repository, or acquire its own input. For tasks that need no tools, a direct plain-text request may go to the local model.

## Call

Set `LITELLM_MASTER_KEY` in the process environment, then run `python scripts/ask_local.py --prompt "Summarize the following text"` with the collected text included in the prompt. Optional flags: `--system`, `--model weak-model`, `--timeout 180`, and `--max-tokens 2048`. Do not pass file paths as a substitute for the main model's file-reading/tool calls; pass the resulting plain text.

The script returns the model's text to stdout and a nonzero exit code on gateway, timeout, input, or API errors. Keep the input on loopback. Treat the output as a draft; the main model must verify factual claims and validate generated code before use. Escalate only when local execution fails, results do not pass review, or the task needs high-stakes or deep reasoning.
