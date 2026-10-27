from dlib import *
reset()
# Stage 1
add(box(30,100,700,800,"#F5FAFF",BL,sw=2.5)+t(50,135,"Team lead: ALZ-lite foundation",26,"700",BL)+badge(540,112,170,"ONCE PER TEAM",BL))
add(card(50,160,660,52,"code",[("Bicep, run by the pipeline",1)],"#FFFFFF",BL,34))
add(card(50,225,660,70,"mg",[("Management groups",1),("mg-factory, mg-factory-platform, mg-factory-corp",0)],"#FFFFFF",BL,40))
add(card(50,305,660,54,"sub",[("Shared services subscription placed under Platform",1)],"#FFFFFF",BL,36))
add(rg(50,372,325,230,"rg-hub",BL))
for i,(k,a,b) in enumerate([("vnet","vnet-hub",None),("fw","Azure Firewall Standard","DNS proxy"),("fwp","Firewall policy",None),("dns","Central private DNS zones",None)]):
    ys=[418,458,500,540][i]
    add(box(62,ys-4,300,36,BLF,BL,sw=1.2)+ic(k,66,ys-3,28)+t(102,ys+19,a+(" ("+b+")" if b else ""),14 if i==1 else 16,"700" if i==1 else "400",mw=262))
add(rg(385,372,325,230,"rg-management",BL))
add(card(397,418,300,50,"law",[("log-management",1)],BLF,BL,32))
add(card(397,478,300,60,"mi",[("id-sqlmi-directory",1),("Shared SQL MI directory identity",0)],BLF,BL,32,ls=22,sz=(17,14)))
add(box(50,615,660,150,"#FFFFFF",BL,sw=1.5)+ic("pol",62,623,34)+t(106,648,"Core policy assignments at mg-factory-corp",20,"700"))
pol=["Location audits","Private PaaS backends","No VM NIC public IPs","Central DNS registration","Diagnostics"]
for i,p in enumerate(pol):
    cx=62+(i%3)*215; cy=672+(i//3)*46
    add(box(cx,cy,205,36,BLF,BL,sw=1.2)+t(cx+102,cy+24,p,14,"700",anchor="middle",mw=195))
add(box(50,780,660,100,AMF,AMB,sw=2)+ic("user",62,805,38)+t(112,808,"Separate approval step, not a Bicep step",17,"700",AM)+t(112,834,"Tenant administrator grants Graph read permissions to",17)+t(112,858,"the shared SQL MI directory identity",17))
# gap arrows
add(arr("M735 400H825","net")+t(780,348,"Shared",15,"700",anchor="middle")+t(780,366,"foundation",15,"700",anchor="middle")+t(780,384,"ready",15,"700",anchor="middle"))
# Stage 2
add(box(830,100,650,800,"#F2FAF8",TL,sw=2.5)+t(850,135,"Team lead: vend each existing",24,"700",TL)+t(850,163,"workload subscription",24,"700",TL)+badge(1300,112,160,"ONCE PER MEMBER",TL))
steps=[("sub","Place the subscription under mg-factory-corp",""),("vnet","Create rg-spoke / vnet-spoke","with snet-app, snet-pe and snet-sqlmi"),("peer","Peer spoke and existing datacenter to the hub",""),("rt","Add routes, DNS settings and","per-member firewall rules"),("bud","Apply member RBAC and workload budget",""),("pol","Record deliberate datacenter policy exemptions","with an owner and an expiry")]
for i,(k,a,b) in enumerate(steps):
    y=185+i*117
    add(box(850,y,610,88,"#FFFFFF",TL,sw=1.5)+circ(876,y+44,str(i+1),TL)+ic(k,902,y+22,44))
    add(t(960,y+(36 if b else 50),a,18,"700",mw=490)+(t(960,y+62,b,16,fill=GR) if b else ""))
    if i<5: add(arr(f"M1155 {y+88}V{y+117}","net"))
# gap2
add(arr("M1485 400H1585","net")+t(1535,348,"Vended",15,"700",anchor="middle")+t(1535,366,"network",15,"700",anchor="middle")+t(1535,384,"ready",15,"700",anchor="middle"))
# Stage 3
add(box(1590,230,300,330,"#F2FAF8",TL,sw=2.5)+t(1610,265,"Member: deploy",22,"700",TL)+t(1610,292,"CoE archetype, C5",22,"700",TL))
add(card(1606,315,268,110,"app",[("azd consumes the",0),("existing spoke",0)],"#FFFFFF",TL,44))
add(box(1606,440,268,100,"#FFFFFF",TL,sw=1.5)+t(1620,470,"Deploys the application-",16)+t(1620,492,"platform resources.",16)+t(1620,520,"No new network.",16,"700"))
add(box(30,915,1860,56,AMF,AMB,sw=2)+t(960,950,"The pipeline deploys the foundation. Agents do not deploy ALZ-lite or vending.",22,"700",anchor="middle"))
add(box(1300,990,590,36,BLF,BL,sw=1.5)+ic("pol",1310,992,30)+t(1350,1015,"Defender Foundational CSPM only",18,"700",mw=520))
finish("diagram-03-alz-lite-and-vending","ALZ-lite builds the shared platform; vending connects each member")


