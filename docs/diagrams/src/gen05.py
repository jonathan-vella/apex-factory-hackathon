from dlib import *
reset()
add(sub(30,95,1370,915,"Member n workload subscription",TL,"#F2FAF8","SIMULATED ON AZURE VMs",230))
add(rg(50,145,1330,845,"rg-datacenter",TL))
add(box(65,190,1300,785,"#FFFFFF",TL,sw=1.8)+ic("vnet",75,194,28)+t(111,216,"vnet-datacenter  10.10.n.0/24",19,"700",TL,mw=420))
add(box(80,235,935,610,TLF,TL,sw=1.5)+t(95,262,"snet-servers  10.10.n.0/25",18,"700",mw=330)+ic("nsg",430,238,32)+t(466,262,"nsg-servers attached",16,fill=GR,mw=200))
# vm-app01
add(box(95,330,420,495,"#FFFFFF",SL,sw=2)+ic("vm",105,338,44)+t(160,362,"vm-app01   10.10.n.4",19,"700",mw=330)+t(160,384,"Windows Server 2022",16,fill=GR))
items=[("app","IIS: Contoso University","ASP.NET MVC 5 / .NET Framework 4.8"),("sqls","SQL Server 2022 Developer","ContosoUniversity database"),("disk","Data disk","SQL data and logs"),("folder","Local teaching-material uploads",""),("queue","MSMQ private queue",""),("arcsql","Arc-enabled server","and SQL assessment")]
y=405
for k,a,b in items:
    if k=="folder": add(folder(108,y+8,30))
    else: add(ic(k,106,y+4,34))
    add(t(152,y+(18 if b else 26),a,16,"700",mw=350)+(t(152,y+38,b,14,fill=GR,mw=350) if b else ""))
    y+=68 if b else 56
# vm-dev01
add(box(545,330,455,495,"#FFFFFF",TL,sw=2)+ic("vm",555,338,44)+t(610,362,"vm-dev01   10.10.n.5",19,"700",mw=330)+t(610,384,"Windows 11 Enterprise",16,fill=GR))
dv=[("code","VS Code and GitHub Copilot","Upgrade agent"),("dev",".NET 10 SDK and","\u002eNET Framework 4.8 developer pack"),("sqls","SQL tooling and workload generator",""),("cli","Git, Azure CLI and PowerShell","")]
y=410
for k,a,b in dv:
    add(ic(k,556,y+2,34)+t(602,y+(18 if b else 26),a,16,"700",mw=380)+(t(602,y+38,b,14,fill=GR,mw=380) if b else ""))
    y+=68 if b else 56
add(box(555,690,435,115,TLF,TL,sw=1.2)+t(572,722,"Role",15,"700",TL)+t(572,748,"App modernization and",17,"700")+t(572,772,"private data-plane tools",17,"700"))
# bastion subnet
add(box(1035,235,315,260,"#FFFFFF",TL,sw=1.5)+t(1049,262,"AzureBastionSubnet",17,"700",mw=280)+t(1049,284,"10.10.n.192/26",16,fill=GR))
add(card(1047,300,291,70,"bas",[("Bastion Standard",1),("bas-datacenter",0)],TLF,TL,40,ls=22,sz=(17,14)))
add(card(1047,386,291,62,"pip",[("Public IP",1),("pip-bas-datacenter",0)],"#FFFFFF",SL,34,ls=22,sz=(16,14)))
# NAT
add(box(1035,520,315,190,"#FFFFFF",TL,sw=1.5)+t(1049,547,"Associated with snet-servers",15,"700",mw=290))
add(card(1047,565,291,70,"nat",[("NAT Gateway",1),("nat-datacenter",0)],TLF,TL,40,ls=22,sz=(17,14)))
add(card(1047,645,291,54,"pip",[("pip-nat-datacenter",1)],"#FFFFFF",SL,32,sz=(15,14)))
# external right
add(box(1440,520,440,120,"#FFFFFF",SL,sw=1.8)+t(1660,568,"Internet",22,"700",anchor="middle")+t(1660,600,"Outbound only",17,fill=GR,anchor="middle"))
add(box(1440,690,440,110,BLF,BL,sw=1.8)+ic("vnet",1452,720,36)+t(1500,730,"Shared hub",19,"700")+t(1500,754,"Added in C2",16,fill=GR)+t(1500,778,"Peered with the datacenter VNet",14,fill=GR,mw=370))
add(box(1440,850,440,110,"#FFFFFF",SL,sw=1.8)+ic("arc",1452,880,40)+t(1505,892,"Azure Arc control plane",18,"700",mw=360)+t(1505,918,"Onboarding and migration assessment",14,fill=GR,mw=360))
# flows
add(arr("M1047 335H1000","net"))  # placeholder removed below
o.pop()
add(arr("M1047 335H1002","net")); o.pop()
add(arr("M1047 345H1003","net")); o.pop()
add(arr("M1045 310H1030V440H1003","net")); o.pop()
add(arr("M1047 330H1025V345H1002","net"))
add(arr("M1047 330H1025V300H305V330","net"))
add(chip(700,300,130,"Private RDP",BL))
# dev -> app SQL
add(arr("M775 825V890H305V825","net"))
add(chip(540,890,330,"Local development and DB workload",BL))
# NAT egress
add(arr("M1015 600H1047","net"));add(arr("M1338 600H1440","net"))
# peering
add(arr("M1350 745H1440","net",True,True))
# arc management
add(arr("M200 825V925H1440","tel")); add(chip(820,925,330,"Management only, not database replication",SL))

add(box(1440,95,440,270,AMF,AMB,sw=2)+t(1460,130,"Notes",20,"700",AM)+t(1460,165,"Deployed before the event",16,mw=400)+t(1460,195,"Simulated on-premises estate",16,mw=400)+t(1460,215,"hosted on Azure VMs",16)+t(1460,250,"No VM public IPs",16,"700")+t(1460,285,"Arc on Azure VMs is lab-only,",16)+t(1460,305,"not a customer deployment",16)+t(1460,325,"recommendation",16))
finish("diagram-05-simulated-datacenter","The member datacenter: legacy estate and private development workstation")

