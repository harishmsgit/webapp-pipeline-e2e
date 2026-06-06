Branch→Environment mapping
==========================

This directory contains a small mapping and helper used by the Jenkins pipeline to decide which Terraform workspace to use.

Files
- `branch-env-map.yml` — editable YAML mapping file with `mappings:` (exact) and `prefixes:` (prefix rules).
- `parse_branch_env.py` — minimal Python helper (no external deps) that reads the YAML mapping and prints a single environment name.
- `parse_branch_env` — a bash wrapper that executes the Python helper if `python3` or `python` is available. Make it executable on agents.

Make the wrapper executable (recommended)

On Linux agents, after checkout set the executable bit once (or configure Git to preserve it):

```bash
cd <repo-root>/ci
chmod +x parse_branch_env
```

Jenkins behavior
- If `ci/parse_branch_env` is executable, the pipeline will prefer to run it directly.
- If not executable, the pipeline will attempt to run the Python script (`python3 ci/parse_branch_env.py`) if Python is available.
- If neither is available, the pipeline falls back to built-in branch→environment heuristics.

Agent prerequisites
- `python3` or `python` executable available (most agents have one).
- If you want the pipeline to run the wrapper directly, ensure the wrapper is executable in the repo (chmod +x) or configure your checkout to preserve file modes.

Customization
- Edit `branch-env-map.yml` to add or change mappings. The pipeline will use exact matches first, then prefixes, then built-in defaults.
