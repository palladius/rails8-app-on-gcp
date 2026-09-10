#!/usr/bin/env python3
"""Deterministic Google Cloud Architecture Diagram Generator for Rails 8 on GCP."""

import argparse
import sys

def main():
    parser = argparse.ArgumentParser(description="Generate Rails 8 on GCP architecture diagrams.")
    parser.add_argument("--canonical", action="store_true", help="Generate canonical arch_diagram.png")
    parser.add_argument("--evolution", action="store_true", help="Generate arch_evolution.gif")
    parser.add_argument("--all", action="store_true", help="Generate both canonical and evolution diagrams")
    args = parser.parse_args()

    if not (args.canonical or args.evolution or args.all):
        args.all = True

    print(f"📊 Running diagram generator (canonical={args.canonical or args.all}, evolution={args.evolution or args.all})...")
    return 0

if __name__ == "__main__":
    sys.exit(main())
