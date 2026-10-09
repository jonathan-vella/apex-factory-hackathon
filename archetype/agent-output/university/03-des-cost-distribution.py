"""Monthly cost distribution donut for the university Step 2 cost estimate (source: 02-cost-estimate.json)."""

import sys
from pathlib import Path

import matplotlib

matplotlib.use("Agg")
import matplotlib.patches as mpatches  # noqa: E402
import matplotlib.pyplot as plt  # noqa: E402

REPO_ROOT = Path(__file__).resolve().parents[2]
SCRIPTS = REPO_ROOT / ".github/skills/apex-python-diagrams/scripts"
if str(SCRIPTS) not in sys.path:
    sys.path.insert(0, str(SCRIPTS))
from diagram_io import save_figure  # noqa: E402

CATEGORIES = {
    "Messaging (Service Bus)": 677.08,
    "Data Services (SQL MI, Storage)": 498.76,
    "Compute (App Service)": 64.97,
    "Containers (ACR)": 50.69,
    "Networking (private endpoints)": 29.30,
    "Security (Key Vault)": 0.15,
}
TOTAL_MONTHLY = 1320.95
PALETTE = ["#0078D4", "#50E6FF", "#1490DF", "#773ADC", "#FFB900", "#107C10"]


def main() -> None:
    labels = list(CATEGORIES)
    values = list(CATEGORIES.values())
    colors = PALETTE[: len(labels)]
    pcts = [v / TOTAL_MONTHLY * 100 for v in values]

    fig, ax = plt.subplots(figsize=(8, 6))
    fig.patch.set_facecolor("#F8F9FA")
    ax.set_facecolor("#F8F9FA")

    ax.pie(values, colors=colors, wedgeprops={"linewidth": 2, "edgecolor": "#F8F9FA"}, startangle=140)
    ax.add_patch(plt.Circle((0, 0), 0.60, fc="#F8F9FA"))
    ax.text(0, 0.07, f"${TOTAL_MONTHLY:,.2f}", ha="center", va="center", fontsize=17,
            fontweight="bold", color="#1A1A2E")
    ax.text(0, -0.17, "/ month", ha="center", va="center", fontsize=10, color="#666")

    legend_labels = [f"{lbl}  ${val:,.2f}  ({pct:.1f}%)" for lbl, val, pct in zip(labels, values, pcts)]
    patches = [mpatches.Patch(color=c, label=lbl) for c, lbl in zip(colors, legend_labels)]
    ax.legend(handles=patches, loc="lower center", bbox_to_anchor=(0.5, -0.22), ncol=2, fontsize=9,
              framealpha=0.0, columnspacing=1.2)
    ax.set_title("university — Monthly Cost Distribution (workload)", fontsize=13, fontweight="bold",
                 color="#1A1A2E", pad=10)

    plt.tight_layout(pad=1.4)
    save_figure(fig, Path(__file__).with_suffix(".png"), dpi=150, bbox_inches="tight",
                facecolor=fig.get_facecolor())
    plt.close(fig)


if __name__ == "__main__":
    main()
