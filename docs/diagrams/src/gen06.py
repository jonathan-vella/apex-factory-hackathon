from dlib import *
reset()
def vm(x,y,w,n): return card(x,y,w,80,"vm",[(n,1),("snet-servers",0)],"#FFFFFF",TL,40,ls=22,sz=(17,14))
# LEFT
add(box(30,95,910,700,"#F2FAF8",TL,sw=2.5)+t(50,130,"Administrative access: Azure Bastion Standard",24,"700",TL))
add(box(250,150,470,60,"#FFFFFF",SL,sw=1.8)+t(485,175,"Member laptop",19,"700",anchor="middle")+t(485,198,"Azure portal or native RDP client",16,fill=GR,anchor="middle"))
add(card(360,255,250,52,"pip",[("pip-bas-datacenter",1)],"#FFFFFF",SL,32,sz=(15,14)))
add(arr("M485 210V255","net")+chip(485,232,150,"Public HTTPS",BL,size=14,h=24))
add(arr("M485 307V395","net"))
add(box(55,335,860,440,"#FFFFFF",TL,sw=1.8)+ic("vnet",65,340,28)+t(101,361,"vnet-datacenter  10.10.n.0/24",18,"700",TL,mw=400))
add(box(80,380,810,120,TLF,TL,sw=1.5)+t(94,404,"AzureBastionSubnet  10.10.n.192/26",16,"700",mw=380))
add(card(290,418,390,66,"bas",[("bas-datacenter",1),("Azure Bastion Standard, in the datacenter VNet",0)],"#FFFFFF",TL,40,ls=22,sz=(18,13.5)))
add(box(80,560,810,195,TLF,TL,sw=1.5)+t(94,584,"snet-servers  10.10.n.0/25",16,"700",mw=380))
add(vm(110,640,340,"vm-app01")); add(vm(520,640,340,"vm-dev01"))
add(arr("M330 484V640","net")+arr("M620 484V640","net")+chip(475,560,250,"TCP 3389 to private VM address",BL,size=13.5))
add(box(80,505,330,0.1,"#FFFFFF","#FFFFFF","",0.1))
add(chip(740,361,230,"No direct public RDP to a VM",AM,AMF,13.5))
# RIGHT
add(box(980,95,910,700,"#F2FAF8",TL,sw=2.5)+t(1000,130,"VM internet egress: NAT Gateway",24,"700",TL))
add(box(1005,150,860,360,"#FFFFFF",TL,sw=1.8)+ic("vnet",1015,155,28)+t(1051,176,"vnet-datacenter  10.10.n.0/24",18,"700",TL,mw=400))
add(box(1030,195,810,130,TLF,TL,sw=1.5)+t(1044,219,"snet-servers  10.10.n.0/25",16,"700",mw=380))
add(vm(1060,235,340,"vm-app01")); add(vm(1470,235,340,"vm-dev01"))
add(card(1190,405,500,70,"nat",[("nat-datacenter",1),("NAT Gateway, associated with snet-servers",0)],"#FFFFFF",TL,40,ls=22,sz=(18,14)))
add(arr("M1230 315V405","net")+arr("M1650 315V405","net"))
add(f'<path d="M1440 325V405" stroke="{TL}" stroke-width="3"/>'+chip(1440,365,150,"Subnet association",TL,size=13,h=24))
add(card(1330,545,240,52,"pip",[("pip-nat-datacenter",1)],"#FFFFFF",SL,32,sz=(15,14)))
add(arr("M1440 475V545","net"))
add(box(1260,650,360,60,"#FFFFFF",SL,sw=1.8)+t(1440,676,"Public internet services",19,"700",anchor="middle")+t(1440,698,"Outbound only",14,fill=GR,anchor="middle"))
add(arr("M1410 597V650","net")+chip(1300,624,110,"Source NAT",BL,size=13,h=24))
add(arr("M1500 650V597","off")+t(1515,628,"Replies to initiated",13,fill=GR)+t(1515,644,"connections",13,fill=GR))
add(chip(1130,590,250,"Not an inbound access service",AM,AMF,13.5))
add(chip2(1130,645,240,"Default outbound access disabled","on the server subnet",AM,AMF,13))
# bottom strip
cards=[("bas","Azure Bastion","Remote administration",TL,TLF),("nat","NAT Gateway","Outbound source NAT",TL,TLF),("fw","Azure Firewall","Datacenter-to-spoke and controlled app egress: separate path",BL,BLF)]
for i,(k,a,b,c,f) in enumerate(cards):
    x=30+i*625
    add(card(x,820,605,90,k,[(a,1),(b,0)],f,c,46,sz=(20,16)))
add(box(30,930,1860,60,AMF,AMB,sw=2)+t(960,968,"Datacenter-to-spoke: 10.20.n.0/24 uses rt-servers \u2192 hub firewall, not NAT Gateway",21,"700",anchor="middle",mw=1800))
finish("diagram-06-bastion-vs-nat","Bastion brings you in; NAT Gateway takes VM traffic out")

