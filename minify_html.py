#!/usr/bin/env python3
import re
import sys

def minify_html(content):
    # Remove comments (but keep conditional comments)
    content = re.sub(r'<!--(?!\[).*?-->', '', content, flags=re.DOTALL)

    # Remove extra whitespace between tags
    content = re.sub(r'>\s+<', '><', content)

    # Remove leading/trailing whitespace from lines
    lines = []
    for line in content.split('\n'):
        line = line.strip()
        if line:  # Only add non-empty lines
            lines.append(line)

    return '\n'.join(lines)

if __name__ == "__main__":
    with open('frontend/dist/index.html', 'r') as f:
        content = f.read()

    minified = minify_html(content)

    with open('frontend/dist/index.html', 'w') as f:
        f.write(minified)

    print(f"Minified HTML from {len(content)} to {len(minified)} characters")