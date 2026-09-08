# Basic Example Project

This is a minimal example showing how to use the Claude Code rootless sandbox.

## Files

- `sample.py` — Simple Python script (adds up numbers from a file)
- `numbers.txt` — Sample data

## Setup

1. Copy the `.claude-sandbox/` and `.claude/` directories from the repository root:

```bash
cp -r ../../.claude-sandbox .
cp -r ../../.claude .
chmod +x .claude-sandbox/run-claude-sandbox.sh
```

2. Start the sandbox:

```bash
./.claude-sandbox/run-claude-sandbox.sh
```

## Try It Out

Inside the sandbox, run:

```bash
cd /project

# Create sample data
echo "10" > numbers.txt
echo "20" >> numbers.txt
echo "30" >> numbers.txt

# Run the Python script
python3 sample.py numbers.txt
# Output: Sum: 60.0

# Try with a bad line
echo "not a number" >> numbers.txt
python3 sample.py numbers.txt
# Output:
#   Warning: skipping non-numeric line: not a number
#   Sum: 60.0
```

## Next Steps

- Modify `sample.py` to do something different
- Use Claude Code to generate new scripts and run them in the sandbox
- Check [../../docs/](../../docs/) for advanced configuration and security details

---

For questions, see the [main documentation](https://github.com/yourusername/claude-code-rootless-sandbox).
