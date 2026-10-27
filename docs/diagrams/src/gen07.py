from dlib import *
reset()
add(box(30,90,1860,465,"#FFFFFF",SL,sw=2)+t(50,122,"1. Resolve the name",24,"700"))
add(box(50,140,280,95,"#F2FAF8",TL,sw=1.5)+t(62,160,"vnet-datacenter",14,"700",TL)+card(60,168,260,58,"vm",[("vm-dev01",1)],"#FFFFFF",TL,32))
add(box(50,258,280,100,"#F2FAF8",TL,sw=1.5)+t(62,278,"Workload spoke (outbound VNet integration)",11.5,"700",TL,mw=260)+card(60,288,260,60,"app",[("App Service workload",1)],"#FFFFFF",TL,32))
add(t(50,382,"Both caller networks use the private IP",14,"700",GR)+t(50,402,"of afw-hub as their DNS server",14,"700",GR))
add(rg(420,130,1460,260,"rg-hub",BL))
add(box(440,175,680,200,BLF,BL,sw=1.8)+ic("vnet",450,180,26)+t(484,200,"vnet-hub",17,"700",BL))
add(card(460,238,260,84,"fw",[("afw-hub",1),("Azure Firewall DNS proxy",0)],"#FFFFFF",BL,40,ls=22,sz=(18,14.5)))
add(card(790,238,310,84,"dns",[("Azure-provided DNS",1),("Hub VNet context",0)],"#FFFFFF",BL,40,ls=22,sz=(18,14.5)))
add(box(1170,175,690,200,TLF,TL,sw=1.8)+ic("dns",1180,180,28)+t(1216,201,"Central private DNS zones (outside the VNet)",16,"700",TL,mw=470))
for i,z in enumerate(["privatelink.blob.core.windows.net","privatelink.servicebus.windows.net","privatelink.azurecr.io","privatelink.vaultcore.azure.net"]):
    add(box(1185+(i%2)*335,215+(i//2)*50,325,42,"#FFFFFF",TL,sw=1.2)+t(1185+(i%2)*335+162,241+(i//2)*50,z,13,"700",anchor="middle",mw=310))
add(chip(1520,330,420,"Azure Policy registers private endpoint DNS zone groups",TL,"#FFFFFF",12.5))
add(arr("M330 190H395V268H460","dns")+arr("M320 318H395V298H460","dns")+circ(395,230,"1",TL))
add(arr("M720 280H790","dns")+circ(755,258,"2",TL))
add(arr("M1170 280H1102","dns",True,True)+circ(1136,258,"3",TL)+chip(1140,342,215,"VNet link / resolution context",TL,size=12))
add(arr("M590 322V352H365V200H332","dns")+arr("M365 328H322","dns")+circ(470,352,"4",TL))
# key
for i,(n,s) in enumerate([("1","Caller sends the standard service hostname query to the afw-hub DNS proxy"),("2","The DNS proxy forwards it to Azure-provided DNS in the hub VNet context"),("3","Hub-linked central private DNS zones supply the private endpoint record"),("4","Answer returned to the caller: a private address in 10.20.n.64/26")]):
    x=50+(i%2)*930; y=440+(i//2)*50
    add(circ(x+13,y,n,TL)+t(x+36,y+6,s,17,mw=880))
# lower lane
add(box(30,575,1860,285,"#FFFFFF",SL,sw=2)+t(50,607,"2. Connect to the service",24,"700"))
add(card(60,675,230,70,"vm",[("vm-dev01",1)],"#FFFFFF",TL,40))
add(card(370,675,250,70,"fw",[("Hub firewall",1),("afw-hub",0)],"#FFFFFF",BL,40,ls=22,sz=(18,14.5)))
add(box(700,650,360,130,TLF,TL,sw=1.5)+t(714,674,"snet-pe  10.20.n.64/26",16,"700",mw=330)+card(714,690,332,70,"pe",[("Blob private endpoint",1),("In snet-pe",0)],"#FFFFFF",TL,40,ls=22,sz=(17,14)))
add(card(1140,675,260,70,"blob",[("Blob Storage",1),("Standard Blob hostname",0)],"#FFFFFF",TL,40,ls=22,sz=(18,14)))
add(arr("M290 710H370","net")+arr("M620 710H714","net")+arr("M1046 725H1140","net"))
add(chip(780,635,480,"HTTPS to standard Blob hostname; private destination IP",BL,size=14))
add(t(60,820,"Other endpoint-backed services in snet-pe:",16,"700",GR)+t(420,820,"ACR  |  Service Bus  |  Key Vault",17,"700"))
add(ic("acr",760,800,30)+ic("sb",800,800,30)+ic("kv",840,800,30))
add(box(1450,610,420,230,AMF,AMB,sw=2)+t(1470,642,"SQL MI is different",18,"700",AM)+t(1470,670,"Delegated subnet, standard MI FQDN,",16)+t(1470,692,"no private endpoint or custom SQL",16)+t(1470,714,"private-link zone in this kit.",16)+t(1470,752,"Applications use normal service",16,"700")+t(1470,774,"hostnames. Never configure privatelink",16,"700")+t(1470,796,"names or raw endpoint IPs.",16,"700"))
add(box(30,880,1860,100,BLF,BL,sw=1.5)+t(60,915,"DNS answers are not data packets: step 1-4 resolve a name, then the caller connects over the network to the private endpoint address.",18,"700",mw=1800)+t(60,945,"Peering and routing for these connections are shown in diagrams 04 and 08.",17,fill=GR))
finish("diagram-07-private-dns","Standard service names resolve through central private DNS")

