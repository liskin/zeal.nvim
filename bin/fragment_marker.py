#!/usr/bin/env -S uv run --script

# /// script
# requires-python = ">=3.10"
# dependencies = [
#     "beautifulsoup4>=4.14",
#     "click>=8.3",
# ]
# ///

import click
from bs4 import BeautifulSoup


@click.command()
@click.option("--marker", type=str, required=True)
@click.option("--fragment", type=str, required=True)
@click.argument("input", type=click.File())
def main(marker, fragment, input) -> None:
    soup = BeautifulSoup(input, "html.parser")

    for anchor in [soup.find(id=fragment), soup.find("a", attrs={"name": fragment})]:
        if anchor:
            marker_tag = soup.new_tag("h6")
            marker_tag.string = marker
            anchor.insert_before(marker_tag)
            print(soup.decode())
            exit(0)

    exit(1)


if __name__ == "__main__":
    main()
