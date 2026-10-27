from dlib import *
reset()
def stop(x,y): return f'<circle cx="{x}" cy="{y}" r="14" fill="#FFFFFF" stroke="{SL}" stroke-width="2.5"/><path d="M{x-7} {y-7}L{x+7} {y+7}M{x+7} {y-7}L{x-7} {y+7}" stroke="{SL}" stroke-width="3"/>'
# Panel A
add(box(30,95,510,650,"#F5F7FA",SL,sw=2)+t(50,128,"Before migration",24,"700",SL))
add(card(50,150,470,92,"sqls",[("SQL Server 2022 on vm-app01",1),("ContosoUniversity: source, read/write",0)],"#FFFFFF",SL,44,ls=24,sz=(18,15)))
add(card(50,310,225,70,"app",[("Legacy IIS app",1),("on vm-app01",0)],"#FFFFFF",SL,36,ls=22,sz=(16,14)))
add(card(295,310,225,70,"vm",[("Workload generator",1),("on vm-dev01",0)],"#FFFFFF",TL,36,ls=22,sz=(16,14)))
add(arr("M162 310V242","net")+arr("M407 310V242","net")+chip(285,278,120,"read/write",BL,size=13,h=22))
add(card(50,450,470,80,"sqlmi",[("SQL MI in snet-sqlmi",1),("Provisioned in the spoke, waiting",0)],"#EEF2F6",SL,44,ls=24,sz=(18,15)))
add(card(50,600,470,100,"arc",[("Azure Arc",1),("Portal assessment and",0),("migration orchestration",0)],"#FFFFFF",SL,44,ls=22,sz=(18,14.5)))
add(arr("M50 650H38V196H50","tel"))
add(chip2(285,560,330,"Management relationship only","not in the data path",SL,"#FFFFFF",13))
# Panel B
add(box(570,95,760,650,"#FFF9EC",AMB,sw=2)+t(590,128,"Replication and validation",24,"700",AM))
add(card(590,150,230,92,"sqls",[("Source SQL Server",1),("Read/write",0)],"#FFFFFF",SL,40,ls=24,sz=(17,15)))
add(card(895,150,150,92,"fw",[("Hub firewall",1),("afw-hub",0)],"#FFFFFF",BL,34,ls=24,sz=(14,13)))
add(card(1100,150,210,92,"sqlmi",[("SQL MI",1),("Read-only replica",0)],"#FFFFFF",TL,40,ls=24,sz=(17,14)))
add(arr("M820 196H895","mig",sw=5)+arr("M1045 196H1100","mig",sw=5))
add(chip(960,270,300,"MI link: real-time replication",AM,AMF,14))
add(box(590,310,340,92,"#FFFFFF",AM,sw=1.5)+t(604,336,"Source to MI: TCP 5022 and 11000-11999",14.5,"700",mw=320)+t(604,362,"MI to source: TCP 5022",14.5,"700")+t(604,388,"Replication goes through the hub firewall",13,fill=GR,mw=320))
add(box(590,440,300,140,"#FFFFFF",AM,sw=1.5)+t(604,466,"Validation",18,"700",AM))
for i,s in enumerate(["Row counts","Checksums","Objects","Replication lag"]): add(t(612,492+i*24,"\u2022 "+s,16))
d=f'<polygon points="1060,450 1130,505 1060,560 990,505" fill="{AMF}" stroke="{AMB}" stroke-width="2.5"/>'+t(1060,510,"Go / no-go",15,"700",anchor="middle")
add(d+arr("M890 505H990","mig"))
add(arr("M1130 505H1250","mig")+t(1190,492,"Go",15,"700","#8A5A00","middle")+t(1250,508,"",1))
add(box(1250,450,70,110,AMF,AMB,sw=1.5)+t(1285,495,"Planned",12.5,"700",anchor="middle")+t(1285,512,"cutover",12.5,"700",anchor="middle"))
add(arr("M1060 560V620","mig")+t(1076,596,"No-go",15,"700","#8A5A00"))
add(box(910,620,410,100,"#FFFFFF",AM,sw=1.5)+t(925,650,"Abort before cutover",17,"700",mw=380)+t(925,676,"Clean the target copy and reseed if needed",14.5,mw=380)+t(925,700,"Source remains read/write",14.5,mw=380))
add(box(590,610,300,110,"#FFFFFF",SL,sw=1.2)+t(604,640,"Target database",15,"700")+t(604,664,"Read-only replica",15)+t(604,690,"Source stays read/write",15))
# Panel C
add(box(1360,95,530,650,"#F2FAF8",TL,sw=2)+t(1380,128,"After planned cutover",24,"700",TL))
add(card(1380,150,235,70,"app",[("Legacy IIS app",1),("Stopped",0)],"#EEF2F6",SL,34,ls=22,sz=(16,14)))
add(card(1635,150,235,70,"vm",[("Workload generator",1),("Stopped",0)],"#EEF2F6",SL,34,ls=22,sz=(16,14)))
add(stop(1598,162)+stop(1853,162))
add(card(1380,260,490,70,"sqls",[("Source SQL Server",1),("Retained; writers stopped",0)],"#EEF2F6",SL,40,ls=22,sz=(17,14.5)))
add(arr("M1625 330V450","off")+f'<rect x="1595" y="372" width="60" height="16" fill="#F2FAF8"/>'+chip(1625,395,200,"MI link removed at cutover",SL,"#FFFFFF",12.5,h=24))
add(card(1380,450,490,80,"sqlmi",[("SQL MI",1),("Live: read/write",0)],TLF,TL,44,ls=24,sz=(18,15)))
add(card(1380,610,490,80,"app",[("App Service Linux",1),("Modernized Contoso University",0)],TLF,TL,44,ls=24,sz=(18,15)))
add(arr("M1625 610V530","id")+chip(1740,570,130,"Managed identity",PU,PUF,13,h=24))
# strip
steps=["Prepare and seed","Validate replica","Stop all source writers","Confirm no lag and perform planned portal cutover","Create app database user and write Key Vault connection secret","Switch App Service to the modernized image"]
for i,s in enumerate(steps):
    x=30+i*312
    add(box(x,765,300,100,"#FFFFFF",AM,sw=1.8)+circ(x+24,790,str(i+1),AM))
    words=s.split(" "); lines=[]; cur=""
    for w in words:
        if len(cur+" "+w)>26: lines.append(cur); cur=w
        else: cur=(cur+" "+w).strip()
    lines.append(cur)
    for j,l in enumerate(lines[:4]): add(t(x+46 if j<1 else x+14,796+j*21 if j<1 else 818+(j-1)*21,l,15,"700",mw=250))
add(box(30,890,1860,110,AMF,AMB,sw=2))
for i,s in enumerate(["The source is not automatically made read-only by cutover","Abort before cutover is not automatic post-cutover rollback","The modernized app first runs on App Service at the end of C7"]):
    add(t(50,925+i*30,"\u2022 "+s,19,"700",mw=1800))
finish("diagram-10-migration-cutover","MI link: replicate, validate, stop writers, then cut over")

