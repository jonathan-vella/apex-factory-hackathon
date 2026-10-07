"""Six-month cost projection for the university Step 2 cost estimate (source: 02-cost-estimate.json)."""

import sys
from pathlib import Path

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt  # noqa: E402
import matplotlib.ticker as mticker  # noqa: E402
import numpy as np  # noqa: E402

REPO_ROOT = Path(__file__).resolve().parents[2]
SCRIPTS = REPO_ROOT / ".github/skills/apex-python-diagrams/scripts"
if str(SCRIPTS) not in sys.path:
    sys.path.insert(0, str(SCRIPTS))
from diagram_io import save_figure  # noqa: E402

MONTHS = ["Month 1", "Month 2", "Month 3", "Month 4", "Month 5", "Month 6"]
# Flat: MI link keeps SQL MI at 730 h and no C7 cutover date is set.
COSTS = [1320.95] * 6
# Brief soft budget: ~$1.83/hour x 730 h, as stated in 01-requirements.md.
BUDGET_REFERENCE = 1336.0


def main() -> None:
    fig, ax = plt.subplots(figsize=(10, 5))
    fig.patch.set_facecolor("#F8F9FA")
    ax.set_facecolor("#F8F9FA")

    x = np.arange(len(MONTHS))
    bars = ax.bar(x, COSTS, color="#0078D4", alpha=0.85, edgecolor="white", linewidth=1.5, width=0.55)
    for bar, cost in zip(bars, COSTS):
        ax.text(bar.get_x() + bar.get_width() / 2, bar.get_height() + max(COSTS) * 0.015,
                f"${cost:,.2f}", ha="center", va="bottom", fontsize=9, fontweight="bold", color="#333")

    trend = np.poly1d(np.polyfit(x, COSTS, 1))
    x_smooth = np.linspace(0, len(MONTHS) - 1, 200)
    ax.plot(x_smooth, trend(x_smooth), color="#FF8C00", linewidth=2, linestyle="--", alpha=0.8, label="Trend")
    ax.axhline(BUDGET_REFERENCE, color="#DC3545", linewidth=1.5, linestyle=":", alpha=0.8,
               label=f"Soft budget (brief) ≈ ${BUDGET_REFERENCE:,.0f}")

    ax.set_xticks(x)
    ax.set_xticklabels(MONTHS, fontsize=10, color="#333")
    ax.set_ylabel("Monthly Cost (USD)", fontsize=10, color="#555")
    ax.set_title("university — 6-Month Cost Projection", fontsize=13, fontweight="bold", color="#1A1A2E", pad=22)
    ax.text(0.5, 1.02, "Flat: MI link active, SQL MI 730 h/month; no C7 cutover date set",
            transform=ax.transAxes, ha="center", fontsize=9, color="#888", style="italic")
    ax.yaxis.set_major_formatter(mticker.FuncFormatter(lambda v, _: f"${v:,.0f}"))
    ax.tick_params(axis="y", labelsize=9, colors="#666")
    ax.spines[["top", "right"]].set_visible(False)
    ax.spines[["left", "bottom"]].set_color("#DDD")
    ax.grid(axis="y", color="#E0E0E0", linewidth=0.8, alpha=0.7)
    ax.set_ylim(0, max(COSTS + [BUDGET_REFERENCE]) * 1.25)
    ax.legend(fontsize=9, framealpha=0.9, edgecolor="#CCC", loc="lower right")

    plt.tight_layout(pad=1.4)
    save_figure(fig, Path(__file__).with_suffix(".png"), dpi=150, bbox_inches="tight",
                facecolor=fig.get_facecolor())
    plt.close(fig)


if __name__ == "__main__":
    main()
