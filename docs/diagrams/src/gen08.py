from dlib import *
reset()
add(box(30,175,490,705,"#F2FAF8",TL,sw=2)+ic("rg",44,183,32)+t(86,207,"rg-spoke",20,"700",TL)+t(180,207,"created by vending in C2",15,fill=GR))
add(box(45,225,460,640,"#FFFFFF",TL,sw=1.8)+ic("vnet",55,230,28)+t(91,251,"vnet-spoke  10.20.n.0/24",17,"700",TL))
add(card(60,268,430,92,"subnet",[("snet-app  10.20.n.0/26",1),("Delegated to Microsoft.Web/serverFarms",0)],TLF,TL,36,ls=22,sz=(17,14)))
add(box(60,375,430,400,TLF,TL,sw=1.5)+ic("subnet",68,381,34)+t(110,405,"snet-pe  10.20.n.64/26",17,"700"))
pes=[("pe-acr",455),("pe-blob",545),("pe-sb",635),("pe-kv",725)]
for n,y in pes: add(card(76,y-30,398,60,"pe",[(n,1)],"#FFFFFF",TL,34,sz=(16,14)).replace('"#FFFFFF" stroke','"#FFFFFF" stroke'))
add(card(60,790,430,66,"subnet",[("snet-sqlmi  10.20.n.128/26",1),("Delegated to Microsoft.Sql/managedInstances",0)],TLF,TL,36,ls=22,sz=(17,13.5)))
# right rg
add(box(700,175,800,705,"#F2FAF8",TL,sw=2)+ic("rg",714,183,32)+t(756,207,"rg-university-&lt;suffix&gt;",20,"700",TL)+t(1290,207,"deployed by azd in C5",15,fill=GR))
c1=740; w1=380
add(card(c1,235,w1,80,"app",[("Web app",1),("app-university-&lt;suffix&gt;",0)],TLF,TL,40,ls=22,sz=(18,14)))
add(card(c1,415,w1,80,"acr",[("ACR Premium",1),("cruniversity&lt;suffix&gt;",0)],TLF,TL,40,ls=22,sz=(18,14)))
add(card(c1,505,w1,80,"blob",[("Blob Storage",1),("stuniversity&lt;suffix&gt;, container teaching-materials",0)],TLF,TL,40,ls=22,sz=(18,12.5)))
add(card(c1,595,w1,80,"sb",[("Service Bus Premium",1),("sbns-university-&lt;suffix&gt;, queue notifications",0)],TLF,TL,40,ls=22,sz=(18,12.5)))
add(card(c1,685,w1,80,"kv",[("Key Vault",1),("kv-university-&lt;suffix&gt;",0)],TLF,TL,40,ls=22,sz=(18,14)))
add(card(c1,775,w1,80,"sqlmi",[("SQL Managed Instance",1),("sqlmi-university-&lt;suffix&gt;, General Purpose, 4 vCores",0)],TLF,TL,40,ls=22,sz=(18,12)))
c2=1140; w2=330
add(card(c2,235,w2,80,"asp",[("App Service plan",1),("asp-university-&lt;suffix&gt;, Linux P0v3",0)],TLF,TL,40,ls=22,sz=(18,14)))
add(card(c2,415,w2,80,"ai",[("Application Insights",1),("appi-university-&lt;suffix&gt;",0)],TLF,TL,40,ls=22,sz=(18,14)))
add(card(c2,505,w2,80,"mi",[("User-assigned identity",1),("id-university-&lt;suffix&gt;",0)],TLF,TL,40,ls=22,sz=(18,14)))
# browser
add(box(950,95,280,56,"#FFFFFF",SL,sw=1.8)+t(1090,130,"Browser",20,"700",anchor="middle"))
add(arr("M1090 151V235","net")+chip(1090,193,120,"Public HTTPS",BL,size=13))
# attachments
add(arr("M740 275H490","net")+chip2(615,248,215,"Outbound VNet integration","image pull enabled",BL,size=12))
for n,y in pes: pass
for y in (455,545,635,725): add(f'<path d="M740 {y}H474" stroke="{TL}" stroke-width="2.5" stroke-dasharray="2 5" stroke-linecap="round"/>')
add(chip(615,555,215,"Private endpoint connections",TL,size=12.5) if False else "")
add(arr("M740 815H490","net")+chip2(615,788,215,"VNet injection","public endpoint off",BL,size=12))
add(t(560,858,"",1))
# externals
add(card(1590,415,290,80,"law",[("Shared log-management",1),("Central Log Analytics",0)],BLF,BL,36,ls=22,sz=(16,14)))
add(arr("M1470 455H1590","tel"))
add(t(1535,478,"",1))
add(card(1590,775,290,80,"mi",[("Shared id-sqlmi-directory",1),("Directory identity",0)],BLF,BL,36,ls=22,sz=(16,14)))
add(arr("M1120 815H1590","id"))
add(chip(1300,792,200,"SQL MI directory identity",PU,size=12.5))
add(chip(1530,432,112,"Workspace-based",SL,size=11.5))
add(t(1590,560,"Ownership vs attachment",15,"700",GR)+t(1590,584,"PE resources belong to",14,fill=GR)+t(1590,604,"rg-university; only their NICs",14,fill=GR)+t(1590,624,"occupy snet-pe in rg-spoke.",14,fill=GR))
add(box(30,900,1860,112,AMF,AMB,sw=2))
notes=["No new VNet, subnet, NSG, route table or private DNS zone in C5","C5 deploys the platform and a placeholder image; the modernized app goes live in C7","Application Insights public ingestion and query: Entra-authenticated","ACR trusted-services bypass: placeholder import only; public network access stays off"]
for i,s in enumerate(notes): add(t(50+(i%2)*930,933+(i//2)*40,"\u2022 "+s,16.5,mw=900))
finish("diagram-08-archetype-placement","The CoE archetype consumes the vended network")

