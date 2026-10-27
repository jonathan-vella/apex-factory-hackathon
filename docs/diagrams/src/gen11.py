from dlib import *
reset()
def lane(y,h,label): return box(30,y,1860,h,"#FAFBFC",SL,sw=1.5)+t(50,y+26,label,15,"700",SL)
add(lane(90,175,"UPSTREAM AND COE")+lane(280,230,"PUBLISHED KIT")+lane(525,410,"MEMBER WORKSPACE"))
def repo(x,y,w,h,name,desc,fill="#FFFFFF",stroke=NAVY):
    return box(x,y,w,h,fill,stroke,sw=2)+gh(x+12,y+14,44)+t(x+70,y+38,name,19,"700",mw=w-80)+t(x+70,y+62,desc,15,fill=GR,mw=w-80)
add(repo(40,125,520,100,"jonathan-vella/apex-accelerator","Public APEX template; agents and dev-container tooling"))
add(repo(900,125,600,100,"jonathan-vella/apex-factory-coe","Public CoE authoring repo; APEX steps 1-5"))
add(arr("M560 175H900","net")+chip(730,175,310,"CoE authors the reusable archetype with APEX",BL,size=12.5))
add(box(900,315,600,185,"#FFFFFF",NAVY,sw=2)+gh(912,329,44)+t(970,353,"jonathan-vella/apex-factory-hackathon",19,"700",mw=520)+t(970,377,"Public hackathon kit",15,fill=GR))
for i,s in enumerate(["infra/ and scripts/","app/","db/","archetype/","site and guidance"]):
    cx=[1010,1175,1272,1375,1430][i]
    pos=[(930,410,190),(1130,410,70),(1210,410,70),(1290,410,110),(1410,410,0)][i]
x=920
rows=[(["infra/ and scripts/","app/","db/"],428),(["archetype/","site and guidance"],468)]
for lst,y in rows:
    x=920
    for s in lst:
        w=est(s,14,True)+24
        add(box(x,y-14,w,28,BLF,BL,sw=1.2,rx=6)+t(x+w/2,y+5,s,14,"700",anchor="middle")); x+=w+10
add(t(920,404,"Kit contents",13,"700",GR))
add(arr("M1200 225V315","net")+chip(1200,270,260,"Packaged, reviewed CoE output",BL,size=12.5))
add(chip2(640,395,300,"Packaging is a reviewed step,","not continuous synchronization",AM,AMF,13))
# member repo
add(box(30,585,1470,340,"#FFFFFF",NAVY,sw=2.5)+gh(44,595,36)+t(90,620,"Member's private repository: created from apex-accelerator; repeated per member",19,"700",mw=1380))
add(arr("M300 225V585","net")+chip(300,560,150,"Use this template",BL,size=13,h=24))
add(arr("M1200 500V585","net")+chip(1200,545,130,"Import-Kit.ps1",BL,size=13,h=24))
def fc(x,y,w,h,name,desc,fill=GRF): return box(x,y,w,h,fill,SL,sw=1.5)+folder(x+12,y+h/2-14,30)+t(x+56,y+32,name,17,"700",mw=w-64)+t(x+56,y+56,desc,13.5,fill=GR,mw=w-64)
add(fc(60,645,600,95,"factory/","Imported kit: scripts, infra, legacy app and challenge assets"))
add(fc(60,775,600,90,"factory/evidence/cNN/","Member challenge evidence",TLF))
add(fc(800,645,670,80,"agent-output/university/","Imported CoE artifacts"))
add(fc(800,745,670,80,"infra/bicep/university/","Imported CoE IaC and azd entrypoint"))
add(fc(800,845,670,70,".github/skills/apex-adapt-archetype/","Adaptation skill"))
add(arr("M660 685H800","mig")+arr("M730 685V785H800","mig"))
add(chip2(730,735,126,"Archetype","import",AM,AMF,12.5))
add(box(1540,585,330,230,"#F2FAF8",TL,sw=2)+ic("user",1556,605,40)+t(1606,632,"Coach",19,"700")+t(1556,672,"Coach reads each member's",16)+t(1556,696,"evidence in that member's",16)+t(1556,720,"private repository.",16))
add(arr("M1540 700H1502","off") if False else "")
add(box(30,946,1860,88,AMF,AMB,sw=2))
for i,s in enumerate(["One member repo, not separate APEX and hackathon work repos","Team documents are copied into each member's evidence; no shared team evidence repo","IDs and local settings stay gitignored; no secrets in Git"]): add(t(50,970+i*26,"\u2022 "+s,17,"700",mw=1800))
finish("diagram-11-github-repositories","Reusable CoE assets, one private working repository per member")

