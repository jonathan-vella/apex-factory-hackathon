from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / ".github" / "skills" / "apex-python-diagrams" / "scripts"))

from diagrams import Cluster, Diagram, Edge
from diagrams.azure.compute import VM, ContainerRegistries
from diagrams.azure.database import SQLManagedInstances
from diagrams.azure.identity import ManagedIdentities
from diagrams.azure.integration import ServiceBus
from diagrams.azure.monitor import ApplicationInsights, LogAnalyticsWorkspaces
from diagrams.azure.network import DNSPrivateZones, Firewall, PrivateEndpoint
from diagrams.azure.security import KeyVaults
from diagrams.azure.storage import BlobStorage
from diagrams.azure.web import AppServices
from diagrams.onprem.client import Users
from diagrams.onprem.network import Internet
from diagram_io import diagram_kwargs, embed_svg_images

base = Path(__file__).with_suffix("")

with Diagram(
    "university - runtime flows (request, auth, secret, event, telemetry)",
    **diagram_kwargs(
        base,
        direction="LR",
        graph_attr={
            "splines": "spline",
            "pad": "0.3",
            "ranksep": "1.0",
            "nodesep": "0.5",
            "fontsize": "18",
            "labelloc": "t",
            "bgcolor": "white",
        },
    ),
):
    users = Users("Attendees\n(anonymous HTTPS)")
    mcr = Internet("mcr.microsoft.com\n(placeholder image)")
    dc = VM("vm-app01\n(datacenter, MI link)")

    with Cluster("Shared services (hub)"):
        fw = Firewall("afwp-hub\napp-to-mcr rule")
        dns = DNSPrivateZones("Central private DNS\n(DINE registration)")
        law = LogAnalyticsWorkspaces("log-management")
        dirid = ManagedIdentities("id-sqlmi-directory\n(Graph read, B08)")

    with Cluster("Workload spoke (vended)"):
        with Cluster("snet-app"):
            web = AppServices("app-university\nUAMI, route-all,\nimagePullTraffic")
        uami = ManagedIdentities("id-university\n(Entra tokens)")
        with Cluster("snet-pe"):
            pe = PrivateEndpoint("PEs: registry,\nblob, namespace, vault")
        with Cluster("snet-sqlmi"):
            mi = SQLManagedInstances("sqlmi-university\nEntra-only")

    acr = ContainerRegistries("cr (Premium)\npublic off")
    blob = BlobStorage("teaching-materials")
    sb = ServiceBus("notifications queue")
    kv = KeyVaults("kv: ConnectionStrings--\nDefaultConnection (C7)")
    appi = ApplicationInsights("appi\nlocal auth off")

    users >> Edge(label="HTTPS 443 (TLS 1.2+)", color="#3a6ea5") >> web
    web >> Edge(label="token request", color="#7a4fb5") >> uami
    web >> Edge(label="DNS query", color="#4d5d9b", style="dashed") >> dns
    web >> Edge(label="image pull, data plane\n(Entra token)", color="#2f6fed") >> pe
    pe >> Edge(label="AcrPull") >> acr
    pe >> Edge(label="Blob Data Contributor") >> blob
    pe >> Edge(label="Sender + Receiver") >> sb
    pe >> Edge(label="Secrets User") >> kv
    web >> Edge(label="TDS, VNet-local host name\n(Entra auth, after C7)", color="#2f6fed") >> mi
    web >> Edge(label="egress (route-all)", color="firebrick") >> fw
    fw >> Edge(label="HTTPS 443, initial image", color="firebrick") >> mcr
    web >> Edge(label="telemetry, Entra-authenticated\n(Monitoring Metrics Publisher)", color="darkgreen") >> appi
    appi >> Edge(label="workspace-based", color="darkgreen") >> law
    dc >> Edge(label="MI link 5022, 11000-11999\n(owner-stated)", color="darkorange") >> fw
    fw >> Edge(label="to snet-sqlmi", color="darkorange") >> mi
    mi >> Edge(label="Entra principal lookup\n(C7 CREATE USER)", color="#7a4fb5") >> dirid

embed_svg_images(base.with_suffix(".svg"))
