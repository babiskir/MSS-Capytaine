"""Run an offset-point Capytaine case."""

import argparse
import logging
from pathlib import Path

from src.hydrodynamics import run


ROOT = Path(__file__).resolve().parent
CATALOGUE = ROOT / "vessels_capytaine"


def _arguments() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Run an MSS-Capytaine vessel configuration."
    )
    parser.add_argument(
        "case",
        nargs="?",
        default="testShip",
        help=(
            "catalogue vehicle name or path to a configuration file "
            "(default: testShip)"
        ),
    )
    parser.add_argument(
        "--list",
        action="store_true",
        help="list available catalogue vehicles and exit",
    )
    return parser.parse_args()


def _config_path(case: str) -> Path:
    path = Path(case)
    if path.suffix.lower() == ".json" or len(path.parts) > 1:
        return path
    return CATALOGUE / case / "config.json"


if __name__ == "__main__":
    logging.basicConfig(level=logging.WARNING, format="%(levelname)s: %(message)s")
    arguments = _arguments()
    if arguments.list:
        cases = sorted(path.parent.name for path in CATALOGUE.glob("*/config.json"))
        print("\n".join(cases))
    else:
        print(f"Wrote results to {run(_config_path(arguments.case))}")
