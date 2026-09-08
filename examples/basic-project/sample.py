#!/usr/bin/env python3
"""
Simple example script: sum all numbers in a file.

This script demonstrates running Python in the Claude Code rootless sandbox.
"""

import sys


def sum_numbers(filename: str) -> float:
    """Read numbers from file and return their sum."""
    total = 0
    with open(filename, "r") as f:
        for line in f:
            try:
                total += float(line.strip())
            except ValueError:
                print(f"Warning: skipping non-numeric line: {line.strip()}", file=sys.stderr)
    return total


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python3 sample.py <filename>", file=sys.stderr)
        sys.exit(1)

    filename = sys.argv[1]
    result = sum_numbers(filename)
    print(f"Sum: {result}")
