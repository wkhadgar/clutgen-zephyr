import argparse
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "clutgen"))

from src import generator as gen
from src.plot import show_interactive_plot


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
        help="Directory for generated .c/.h files",
    )
    p.add_argument(
        "--name",
        help="Name of the generated LUT files.",
    )
    p.add_argument(
        "--preview",
        action="store_true",
        help="Open interactive view comparing all interpolation methods",
    )
    return p.parse_args()


def main():
    """
    Default generation method is linear, any diverse method should be chosen by its LUT TOML.
    """
    args = parse_args()

    if args.preview:
        configs = gen.parse_configs(args.tomls, gen.GenMethod.LINEAR)
        show_interactive_plot(configs)
    else:
        args.output_dir.mkdir(parents=True, exist_ok=True)
        gen.generate(
            args.tomls,
            args.output_dir,
            args.name,
            gen.GenMethod.LINEAR,
        )


if __name__ == "__main__":
    main()
