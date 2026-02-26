import argparse
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[2]))

from src import generator as gen


def parse_args():
    p = argparse.ArgumentParser()
    p.add_argument(
        "tomls",
        nargs="+",
        type=Path,
        help="TOML config file paths",
    )
    p.add_argument(
        "-o",
        "--output-dir",
        type=Path,
        required=True,
        help="Directory for generated .c/.h files",
    )
    p.add_argument(
        "--name",
        help="Name of the generated LUT files.",
    )
    p.add_argument(
        "--preview",
        action="store_true",
        help="Open interactive plot preview after generation",
    )
    return p.parse_args()


def main():
    """
    Default generation method is linear, any diverse method should be chosen by its LUT TOML.
    """
    args = parse_args()

    args.output_dir.mkdir(parents=True, exist_ok=True)

    gen.generate(
        args.tomls,
        args.output_dir,
        args.name,
        gen.GenMethod.LINEAR,
        args.preview,
    )

    if args.preview:
        print(f"-- CLUTGen preview plots saved to {args.output_dir / 'preview'}")


if __name__ == "__main__":
    main()
