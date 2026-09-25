#!/usr/bin/env python3
"""Render the design document and validate local documentation links."""

import argparse
from html import escape
from html.parser import HTMLParser
from pathlib import Path
import sys
from urllib.parse import unquote, urlsplit

try:
    from markdown_it import MarkdownIt
except ImportError:
    sys.exit("Missing documentation dependency. Install requirements-docs.txt using the README instructions.")


ROOT = Path(__file__).resolve().parent.parent


class DocumentLinks(HTMLParser):
    def __init__(self):
        super().__init__()
        self.links = []
        self.ids = set()

    def handle_starttag(self, tag, attrs):
        attributes = dict(attrs)
        if "id" in attributes:
            self.ids.add(attributes["id"])
        for key in ("href", "src"):
            if key in attributes:
                self.links.append(attributes[key])


def validate_links(name, html):
    parsed = DocumentLinks()
    parsed.feed(html)
    for link in parsed.links:
        url = urlsplit(link)
        if url.scheme or url.netloc:
            continue
        if url.path:
            target = ROOT / unquote(url.path)
            if not target.is_file():
                raise ValueError(f"{name}: missing local target {link}")
        elif url.fragment and unquote(url.fragment) not in parsed.ids:
            raise ValueError(f"{name}: missing section anchor {link}")


def render():
    markdown = MarkdownIt("commonmark", {"html": False}).enable("table")
    source = (ROOT / "GAME_DESIGN.md").read_text(encoding="utf-8")
    tokens = markdown.parse(source)
    contents = []
    for index, token in enumerate(tokens):
        if token.type == "heading_open" and token.tag == "h2":
            anchor = f"section-{len(contents) + 1}"
            token.attrSet("id", anchor)
            title = escape(tokens[index + 1].content)
            contents.append(f'<li><a href="#{anchor}">{title}</a></li>')
    template = (ROOT / "scripts/game_design.template.html").read_text(encoding="utf-8")
    for marker in ("{{CONTENTS}}", "{{DOCUMENT}}"):
        if template.count(marker) != 1:
            raise ValueError(f"Template must contain exactly one {marker}")
    html = template.replace("{{CONTENTS}}", "".join(contents)).replace(
        "{{DOCUMENT}}", markdown.renderer.render(tokens, markdown.options, {})
    )
    validate_links("GAME_DESIGN.html", html)
    validate_links("index.html", (ROOT / "index.html").read_text(encoding="utf-8"))
    for path in sorted(ROOT.glob("*.md")):
        # GAME_DESIGN has generated heading IDs; its rendered output was checked above.
        if path.name != "GAME_DESIGN.md":
            validate_links(path.name, markdown.render(path.read_text(encoding="utf-8")))
    return html


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="Check without writing generated output")
    args = parser.parse_args()
    try:
        html = render()
        destination = ROOT / "GAME_DESIGN.html"
        if args.check:
            if not destination.exists() or destination.read_text(encoding="utf-8") != html:
                sys.exit("GAME_DESIGN.html is stale. Run npm run docs:build.")
            print("Design document is current; local documentation links and section anchors are valid.")
        else:
            destination.write_text(html, encoding="utf-8")
            print("Built GAME_DESIGN.html; local documentation links and section anchors are valid.")
    except (OSError, ValueError) as error:
        sys.exit(str(error))


if __name__ == "__main__":
    main()
