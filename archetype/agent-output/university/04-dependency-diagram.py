from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / ".github" / "skills" / "apex-python-diagrams" / "scripts"))

from diagrams import Cluster, Diagram, Edge
from diagrams.azure.compute import ContainerRegistries
from diagrams.azure.database import SQLManagedInstances
from diagrams.azure.general import Resourcegroups
from diagrams.azure.identity import ManagedIdentities
from diagrams.azure.integration import ServiceBus
from diagrams.azure.monitor import ApplicationInsights, LogAnalyticsWorkspaces
from diagrams.azure.network import PrivateEndpoint, Subnets
from diagrams.azure.security import KeyVaults
from diagrams.azure.storage import StorageAccounts
from diagrams.azure.web import AppServices
from diagrams.programming.language import Bash
from diagram_io import diagram_kwargs, embed_svg_images

base = Path(__file__).with_suffix("")

with Diagram(
    "university - module dependency graph (one subscription-scope deployment)",
    **diagram_kwargs(
        base,
        direction="TB",
        graph_attr={
            "splines": "spline",
            "pad": "0.3",
            "ranksep": "0.8",
            "nodesep": "1.0",
            "fontsize": "18",
            "labelloc": "t",
            "bgcolor": "white",
        },
    ),
):
    pre = Bash("Task 12\npreprovision.ps1\n(preflight + derived inputs)")
    post = Bash("Task 13\npostprovision.ps1\n(post-deploy tests)")

    with Cluster("Existing, read only (never declared)"):
        subnets = Subnets("rg-spoke / vnet-spoke\nsnet-app, snet-pe, snet-sqlmi")
        law = LogAnalyticsWorkspaces("log-management\n(shared services)")

    with Cluster("Task 1 main.bicep (targetScope = subscription)"):
        rg = Resourcegroups("rg-university-<suffix>\nAVM resource-group 0.4.4")

        with Cluster("rg-university-<suffix>"):
            uami = ManagedIdentities("Task 2 identity\nid-university-<suffix>")
            appi = ApplicationInsights("Task 3 monitoring\nappi + MMP role")
            acr = ContainerRegistries("Task 4 registry\ncr + AcrPull/Push/Importer")
            st = StorageAccounts("Task 5 storage\nst + container + roles")
            sb = ServiceBus("Task 6 messaging\nsbns + queue + roles")
            kv = KeyVaults("Task 7 keyvault\nkv + roles")
            pe = PrivateEndpoint("Task 8 private-endpoints\n4 PEs + 4 diag (2016-09-01)")
            mi = SQLManagedInstances("Task 9 sql-mi (raw)\nMI + startStopSchedules")
            web = AppServices("Task 10 web\nasp + app (UAMI)")

    pre >> Edge(label="AZURE_LOCATION, shared sub,\ndeployer UPN/objectId", color="#555555") >> rg
    rg >> uami
    rg >> mi
    uami >> Edge(label="principalId", color="#2f6fed") >> appi
    uami >> Edge(label="principalId", color="#2f6fed") >> acr
    uami >> Edge(label="principalId", color="#2f6fed") >> st
    uami >> Edge(label="principalId", color="#2f6fed") >> sb
    uami >> Edge(label="principalId", color="#2f6fed") >> kv
    acr >> Edge(label="resource ID") >> pe
    st >> Edge(label="resource ID") >> pe
    sb >> Edge(label="resource ID") >> pe
    kv >> Edge(label="resource ID") >> pe
    appi >> Edge(label="connection string", color="#2f6fed") >> web
    acr >> Edge(label="roles done", color="#2f6fed") >> web
    st >> Edge(label="blob endpoint", color="#2f6fed") >> web
    sb >> Edge(label="namespace FQDN", color="#2f6fed") >> web
    kv >> Edge(label="vault URI", color="#2f6fed") >> web
    pe >> Edge(label="dependsOn", style="dashed") >> web
    subnets >> Edge(label="resourceId() only:\nsnet IDs to PE, MI, web", style="dashed", color="#666666") >> rg
    law >> Edge(label="resourceId() only:\nworkspace ID to appi, diag", style="dashed", color="#666666") >> rg
    web >> Edge(label="after provision", color="#555555") >> post

embed_svg_images(base.with_suffix(".svg"))
