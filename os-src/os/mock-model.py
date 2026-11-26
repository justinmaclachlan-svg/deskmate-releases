#!/usr/bin/env python3
"""A scripted stand-in for a local model (OpenAI-compatible), for the boot test.

It lets a Bot in the test VM do real work without a real model: depending on
what the user asked, it answers with one tool call, then with a short reply.
Usage: mock-model.py <port> <log file>
"""
import json
import sys
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

PORT, LOG = int(sys.argv[1]), sys.argv[2]


def log(line):
    with open(LOG, "a") as f:
        f.write(line + "\n")


def text_of(content):
    if isinstance(content, str):
        return content
    if isinstance(content, list):
        return " ".join(p.get("text", "") for p in content if isinstance(p, dict))
    return ""


def decide(body):
    msgs = body.get("messages", [])
    tools = [t.get("function", {}).get("name", "") for t in body.get("tools", [])]
    last_user = max((i for i, m in enumerate(msgs) if m.get("role") == "user"), default=-1)
    ask = text_of(msgs[last_user].get("content")).lower() if last_user >= 0 else ""
    after = msgs[last_user + 1:]
    tool_results = [text_of(m.get("content")) for m in after if m.get("role") == "tool"]
    if msgs and msgs[0].get("role") == "system":
        with open(LOG + ".system-prompt.txt", "w") as f:
            f.write(text_of(msgs[0].get("content")))
    if tool_results:
        return "text", "Done. " + tool_results[-1][:300]
    if "asked for a plan first" in ask:
        log("PLAN_NOTE seen")
        return "text", "Plan: 1. List the folder. 2. Group the files by type. 3. Move them. Nothing risky. Shall I go ahead?"
    if "gruvbox" in ask:
        return "tool", ("os_customize", {"what": "theme", "args": ["set", "gruvbox"]})
    if "whoami" in ask:
        shell = "run_shell" if "run_shell" in tools or not tools else "run_powershell"
        return "tool", (shell, {"command": "id -un > who-bot.txt; id -un"})
    if "fetch the page" in ask:
        return "tool", ("http_get", {"url": "https://example.com/"})
    if "send it out" in ask:
        shell = "run_shell" if "run_shell" in tools or not tools else "run_powershell"
        return "tool", (shell, {"command": "curl -s -m 8 --noproxy '*' -o /dev/null http://10.0.2.2:11434/v1/models; echo \"direct: $?\"; curl -s -m 10 http://example.com/ | head -c 90; echo; curl -s -m 25 -o /dev/null -w 'ai: %{http_code}' https://api.anthropic.com/"})
    if "notes" in ask:
        return "tool", ("write_file", {"path": "notes/today.txt", "content": "Line one\nLine two\n"})
    return "text", "Hello from the test model."


class Handler(BaseHTTPRequestHandler):
    def log_message(self, *args):
        pass

    def do_GET(self):
        data = json.dumps({"object": "list", "data": [{"id": "mock", "object": "model"}]}).encode()
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def do_POST(self):
        body = json.loads(self.rfile.read(int(self.headers.get("Content-Length", "0"))) or b"{}")
        kind, what = decide(body)
        tools = [t.get("function", {}).get("name", "") for t in body.get("tools", [])]
        log(f"{kind}: {what if kind == 'text' else what[0]} | tools offered: {len(tools)} | os_customize offered: {'os_customize' in tools}")
        if kind == "text":
            chunks = [
                {"choices": [{"index": 0, "delta": {"role": "assistant", "content": what}, "finish_reason": None}]},
                {"choices": [{"index": 0, "delta": {}, "finish_reason": "stop"}]},
            ]
        else:
            name, args = what
            call = {"index": 0, "id": "call_test_1", "type": "function", "function": {"name": name, "arguments": json.dumps(args)}}
            chunks = [
                {"choices": [{"index": 0, "delta": {"role": "assistant", "tool_calls": [call]}, "finish_reason": None}]},
                {"choices": [{"index": 0, "delta": {}, "finish_reason": "tool_calls"}]},
            ]
        if body.get("stream"):
            self.send_response(200)
            self.send_header("Content-Type", "text/event-stream")
            self.end_headers()
            for c in chunks:
                self.wfile.write(b"data: " + json.dumps(c).encode() + b"\n\n")
            self.wfile.write(b"data: [DONE]\n\n")
        else:
            msg = {"role": "assistant", "content": what if kind == "text" else None}
            if kind == "tool":
                msg["tool_calls"] = [{k: v for k, v in chunks[0]["choices"][0]["delta"]["tool_calls"][0].items() if k != "index"}]
            data = json.dumps({"choices": [{"index": 0, "message": msg, "finish_reason": "stop" if kind == "text" else "tool_calls"}]}).encode()
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(data)))
            self.end_headers()
            self.wfile.write(data)


ThreadingHTTPServer(("0.0.0.0", PORT), Handler).serve_forever()
