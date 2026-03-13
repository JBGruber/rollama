#!/usr/bin/env bash

curl -O https://docs.ollama.com/openapi.yaml

PROMPT="You are helping maintain the R package 'rollama', which wraps the Ollama HTTP API.

I just downloaded the latest Ollama OpenAPI spec to @openapi.yaml.

First, create @plan.md with a header and a list of all API endpoints (method + path + summary) from the spec and mark them as either ⏳ tbd.
Then work through each endpoint one by one and, for each:
1. Identify the rollama R function(s) in \`R/\` that implement it (with file name and line numbers).
2. If no function exists, mark the endpoint as ❌ MISSING coverage.
3. If a function exists, check whether all spec-defined parameters are exposed — note any mismatches and mark the endpoint ❌ MISMATCH.
4. Append your findings for that endpoint to @plan.md before moving to the next.

After all endpoints are processed:
5. Scan all R functions that make HTTP calls and flag any that target endpoints no longer present in the spec (potentially stale).
6. Add a prioritised list of recommended changes at the bottom of @plan.md.

Note: we are not using /api/generate on purpose, as it offers no advantages over /api/chat"

claude --permission-mode="acceptEdits" "$PROMPT"
