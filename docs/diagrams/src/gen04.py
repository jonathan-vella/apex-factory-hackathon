from dlib import *
reset()
# hub
add(sub(620,95,680,178,"Shared services subscription",BL,"#F5FAFF","SHARED BY ALL MEMBERS",190).replace(t(682,129,"Shared services subscription",24,"700"),t(682,129,"Shared services subscription",22,"700")))
add(box(640,135,640,128,BLF,BL,sw=1.8)+ic("vnet",650,140,28)+t(686,162,"rg-hub / vnet-hub  10.100.0.0/16",18,"700",BL,mw=420))
add(box(770,172,380,84,"#FFFFFF",BL,sw=1.5)+t(782,192,"AzureFirewallSubnet  10.100.0.0/26",15,"700",mw=355))
add(card(790,200,340,50,"fw",[("afw-hub: Azure Firewall Standard",1)],BLF,BL,34,sz=(16,14)))
# member sub
add(sub(30,305,1860,510,"Member n workload subscription",TL,"#F2FAF8","REPEATED PER MEMBER",230))
# datacenter
add(rg(55,350,690,450,"rg-datacenter",TL))
add(box(70,390,660,395,"#FFFFFF",TL,sw=1.8)+ic("vnet",80,394,28)+t(116,416,"vnet-datacenter  10.10.n.0/24",18,"700",TL,mw=400))
add(box(90,428,620,236,TLF,TL,sw=1.5)+t(104,452,"snet-servers  10.10.n.0/25",17,"700",mw=300)+ic("rt",104,460,24)+t(134,478,"rt-servers: 10.20.n.0/24 \u2192 afw-hub",14,fill=GR,mw=400))
add(card(110,492,580,66,"vm",[("vm-app01   .4",1),("Legacy Contoso University, SQL Server",0)],"#EEF2F6",SL,40,ls=22,sz=(17,14)))
add(card(110,576,580,66,"vm",[("vm-dev01   .5",1),("Private development workstation",0)],"#FFFFFF",TL,40,ls=22,sz=(17,14)))
add(card(330,690,380,64,"nat",[("NAT Gateway",1),("Associated with snet-servers",0)],TLF,TL,40,ls=22,sz=(17,14)))
add(f'<path d="M520 664V690" stroke="{TL}" stroke-width="2.5"/>'+t(104,722,"Datacenter internet",15,fill=GR)+t(104,742,"egress stays on NAT",15,fill=GR))
# spoke
add(rg(1175,350,690,450,"rg-spoke",TL,70))
add(box(1190,390,660,395,"#FFFFFF",TL,sw=1.8)+ic("vnet",1200,394,28)+t(1236,416,"vnet-spoke  10.20.n.0/24",18,"700",TL,mw=400))
sn=[(487,"snet-sqlmi  10.20.n.128/26","rt-sqlmi: 10.10.n.0/24 \u2192 afw-hub; SQL MI keeps service-managed routes"),(572,"snet-pe  10.20.n.64/26","rt-pe: 0.0.0.0/0 \u2192 afw-hub"),(657,"snet-app  10.20.n.0/26","rt-app: 0.0.0.0/0 \u2192 afw-hub")]
for y,a,b in sn: add(card(1215,y,615,76,"subnet",[(a,1),(b,0)],TLF,TL,36,ls=24,sz=(17,14.5)))
# Internet + destinations
add(box(800,692,200,56,"#FFFFFF",SL,sw=1.8)+t(900,726,"Internet",20,"700",anchor="middle"))
add(box(1400,110,300,70,"#FFFFFF",SL,sw=1.8)+t(1550,140,"Permitted public",17,"700",anchor="middle")+t(1550,162,"endpoints",17,"700",anchor="middle"))
# peering
add(arr("M690 390V263","net",True,True)+arr("M1230 390V263","net",True,True))
add(chip(500,290,280,"VNet peering; forwarded traffic enabled",BL,size=13))
add(chip(1410,290,280,"VNet peering; forwarded traffic enabled",BL,size=13))
# path B (mig, amber) vm-app01 -> fw -> sqlmi
add(arr("M690 525H840V250","mig")+arr("M1080 250V525H1215","mig"))
add(circ(770,525,"B",AM))
# path A
add(arr("M690 609H900V250","net")+arr("M1010 250V609H1215","net"))
add(circ(770,609,"A",BL))
# path D
add(arr("M1215 695H1170V222H1132","net")+arr("M1132 196H1400","net"))
add(circ(1195,695,"D",BL))
# path C
add(arr("M710 722H800","net")); add(circ(755,722,"C",BL))
# key panel
add(box(30,830,1100,175,"#FFFFFF",SL,sw=1.5)+t(50,860,"Example paths",20,"700"))
keys=[("A",BL,"vm-dev01 \u2192 afw-hub \u2192 snet-pe: private backend tools"),("B",AM,"vm-app01 \u2192 afw-hub \u2192 snet-sqlmi: MI link"),("C",BL,"snet-servers \u2192 NAT Gateway \u2192 Internet: datacenter internet egress"),("D",BL,"snet-app \u2192 afw-hub \u2192 permitted public endpoints: controlled app egress")]
for i,(l,c,s) in enumerate(keys): add(circ(60,885+i*31,l,c)+t(84,891+i*31,s,17,mw=1030))
add(box(1150,830,740,175,AMF,AMB,sw=2)+t(1170,868,"Peering is not transitive. Routes and Azure Firewall",19,"700",mw=700)+t(1170,893,"provide the datacenter-to-spoke path.",19,"700")+t(1170,935,"n = assigned member index; repeat this network pair per member.",17,mw=700)+t(1170,965,"No direct datacenter-to-spoke peering, VPN, ExpressRoute or Virtual WAN.",17,mw=700))
finish("diagram-04-hub-and-spoke-routing","Datacenter-to-spoke traffic crosses the hub firewall")

