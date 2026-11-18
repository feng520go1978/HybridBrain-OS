#!/usr/bin/env python3
"""Send a prompt (and optionally a UTF-8 file) to the local LiteLLM gateway."""
import argparse
import json
import os
import sys
import urllib.error
import urllib.request

DEFAULT_URL = "http://127.0.0.1:4000/v1/chat/completions"


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--prompt", default="", help="User prompt")
    parser.add_argument("--prompt-file", help="UTF-8 file containing the prompt")
    parser.add_argument("--file", help="UTF-8 input file appended to the prompt")
    parser.add_argument("--system", default="", help="Optional system instruction")
    parser.add_argument("--model", default="weak-model", help="LiteLLM model ID (default: weak-model)")
    parser.add_argument("--timeout", type=float, default=180.0, help="Request timeout in seconds")
    parser.add_argument("--max-tokens", type=int, default=2048)
    parser.add_argument("--url", default=DEFAULT_URL)
    args = parser.parse_args()

    prompt = args.prompt
    try:
        if args.prompt_file:
            with open(args.prompt_file, "r", encoding="utf-8-sig") as f:
                prompt = f.read() + ("\n\n" + prompt if prompt else "")
        if args.file:
            with open(args.file, "r", encoding="utf-8-sig") as f:
                prompt += "\n\n--- Input file: " + os.path.basename(args.file) + " ---\n" + f.read()
    except OSError as exc:
        print(f"Input error: {exc}", file=sys.stderr)
        return 2
    if not prompt.strip():
        parser.error("provide --prompt or --prompt-file")
    if not args.url.startswith("http://127.0.0.1:") and not args.url.startswith("http://localhost:"):
        print("Refusing non-loopback URL; sensitive input must stay local.", file=sys.stderr)
        return 2

    key = os.environ.get("LITELLM_MASTER_KEY", "")
    headers = {"Content-Type": "application/json"}
    if key:
        headers["Authorization"] = "Bearer " + key
    messages = []
    if args.system:
        messages.append({"role": "system", "content": args.system})
    messages.append({"role": "user", "content": prompt})
    body = json.dumps({"model": args.model, "messages": messages, "max_tokens": args.max_tokens}).encode("utf-8")
    request = urllib.request.Request(args.url, data=body, headers=headers, method="POST")
    try:
        with urllib.request.urlopen(request, timeout=args.timeout) as response:
            data = json.loads(response.read().decode("utf-8"))
        print(data["choices"][0]["message"]["content"])
        return 0
    except (urllib.error.URLError, TimeoutError, json.JSONDecodeError, KeyError, IndexError) as exc:
        reason = getattr(exc, "reason", exc)
        print(f"Local gateway request failed: {reason}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
