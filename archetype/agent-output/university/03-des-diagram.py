from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / ".github" / "skills" / "apex-python-diagrams" / "scripts"))

from diagrams import Cluster, Diagram, Edge
from diagrams.azure.compute import AKS, VM, AppServices, ContainerRegistries
from diagrams.azure.database import SQLManagedInstances
from diagrams.azure.integration import ServiceBus
from diagrams.azure.monitor import ApplicationInsights
from diagrams.azure.network import DNSPrivateZones, Firewall, PrivateEndpoint, VirtualNetworks
from diagrams.azure.security import KeyVaults
from diagrams.azure.storage import BlobStorage
from diagrams.onprem.client import Users
from diagram_io import diagram_kwargs, embed_svg_images

base = Path(__file__).with_suffix("")

with Diagram(
    "University workload architecture",
    **diagram_kwargs(
        base,
        direction="TB",
        graph_attr={
            "splines": "spline",
            "pad": "0.3",
            "ranksep": "0.9",
            "nodesep": "0.6",
            "fontsize": "18",
            "labelloc": "t",
            "bgcolor": "white",
        },
    ),
):
    users = Users("Training users\n(public HTTPS)")
    vm = VM("vm-app01\nSQL Server 2022\n(datacenter)")

    with Cluster("Shared services hub"):
        hub = VirtualNetworks("Hub VNet")
        fw = Firewall("Hub firewall")
        dns = DNSPrivateZones("Private DNS\n(central zones)")

    with Cluster("Workload spoke (existing, vended)"):
        spoke = VirtualNetworks("Spoke VNet")
        web = AppServices("Linux web app\nApp Service P0v3")
        sql = SQLManagedInstances("SQL MI GP\n(snet-sqlmi)")
        acr = ContainerRegistries("ACR Premium")
        bus = ServiceBus("Service Bus Premium")
        blob = BlobStorage("Blob Storage")
        kv = KeyVaults("Key Vault")
        appi = ApplicationInsights("App Insights")
        pe = PrivateEndpoint("Private endpoints\nACR / Blob / Bus / KV")

    with Cluster("Future archetype"):
        aks = AKS("AKS (future archetype)")

    users >> Edge(label="HTTPS", color="#3a6ea5") >> web
    spoke >> Edge(label="peering", color="#666666") >> hub
    web >> Edge(label="private endpoints", color="#2f6fed") >> pe
    pe >> acr
    pe >> blob
    pe >> bus
    pe >> kv
    web >> Edge(label="reads and writes", color="#2f6fed") >> sql
    web >> Edge(label="telemetry", color="#2f6fed") >> appi
    vm >> Edge(label="MI link", color="darkorange") >> fw
    fw >> Edge(label="to snet-sqlmi", color="darkorange") >> sql
    web >> Edge(label="egress via hub firewall", color="firebrick") >> fw
    web >> Edge(label="DNS resolution", color="#4d5d9b") >> dns
    aks >> Edge(label="future, not designed", style="dashed", color="#666666") >> web

embed_svg_images(base.with_suffix(".svg"))
