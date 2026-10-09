from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / ".github" / "skills" / "apex-python-diagrams" / "scripts"))

from diagrams import Cluster, Diagram, Edge
from diagrams.azure.compute import VM, AppServices, ContainerRegistries
from diagrams.azure.database import SQLManagedInstances
from diagrams.azure.integration import ServiceBus
from diagrams.azure.monitor import ApplicationInsights
from diagrams.azure.network import DNSPrivateZones, Firewall, PrivateEndpoint, VirtualNetworks
from diagrams.azure.security import KeyVaults
from diagrams.azure.storage import BlobStorage
from diagrams.onprem.client import Users
from diagrams.onprem.network import Internet
from diagram_io import diagram_kwargs, embed_svg_images

base = Path(__file__).with_suffix("")

with Diagram(
    "University network and data flow",
    **diagram_kwargs(
        base,
        direction="TB",
        graph_attr={
            "splines": "spline",
            "pad": "0.3",
            "ranksep": "1.0",
            "nodesep": "0.6",
            "fontsize": "18",
            "labelloc": "t",
            "bgcolor": "white",
        },
    ),
):
    users = Users("Training users\n(public HTTPS)")

    with Cluster("Datacenter (owner-stated, B07/B08)"):
        vm = VM("vm-app01\nSQL Server 2022")

    with Cluster("Shared-services hub"):
        hub = VirtualNetworks("Hub VNet")
        fw = Firewall("Hub firewall")
        dns = DNSPrivateZones("Private DNS\n(central zones)")

    public = Internet("mcr.microsoft.com")

    with Cluster("Workload spoke (existing, vended)"):
        spoke = VirtualNetworks("Spoke VNet")
        app = AppServices("snet-app\nWeb app")
        sql = SQLManagedInstances("snet-sqlmi\nSQL MI GP")
        pe = PrivateEndpoint("snet-pe\nPrivate endpoints")
        acr = ContainerRegistries("ACR Premium")
        bus = ServiceBus("Service Bus Premium")
        blob = BlobStorage("Blob Storage")
        kv = KeyVaults("Key Vault")
        appi = ApplicationInsights("App Insights")

    users >> Edge(label="HTTPS", color="#3a6ea5") >> app
    spoke >> Edge(label="peering", color="#666666") >> hub
    vm >> Edge(label="MI link TCP 5022, 11000-11999", color="darkorange") >> fw
    fw >> Edge(label="to snet-sqlmi", color="darkorange") >> sql
    app >> Edge(label="egress (allTraffic, image pull)", color="firebrick") >> fw
    fw >> Edge(label="rule app-to-mcr", color="firebrick") >> public
    fw >> Edge(label="Azure Monitor ingestion", color="firebrick") >> appi
    app >> Edge(label="DNS resolution", color="#4d5d9b") >> dns
    app >> Edge(label="in-VNet, no firewall hairpin", color="#2f6fed") >> pe
    pe >> Edge(label="image pull, import", color="darkgreen") >> acr
    pe >> Edge(label="blob", color="#2f6fed") >> blob
    pe >> Edge(label="queue", color="#2f6fed") >> bus
    pe >> Edge(label="secrets", color="#2f6fed") >> kv
    app >> Edge(label="reads and writes", color="#2f6fed") >> sql

embed_svg_images(base.with_suffix(".svg"))
