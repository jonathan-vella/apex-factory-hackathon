from dlib import *
reset()
COLX=[330+312*i for i in range(5)]
CW=300
heads=[("T-14","Roster and preflight"),("T-7","Foundation"),("T-3","Datacenters"),("T-1","Vending"),("T+2","Teardown")]
for i,(a,b) in enumerate(heads):
    x=COLX[i]
    add(box(x,92,CW,52,GRF,SL,sw=1.5,rx=8)+t(x+16,126,a,26,"700",NAVY)+t(x+86,126,b,18,"400",GR,mw=CW-100))
LANES=[("TEAM LEAD",BL,BLF,160,230,"tower"),("EACH MEMBER",TL,TLF,400,230,"user"),("A PERSON DOES THIS",AM,AMF,640,230,"user")]
for name,col,fill,y,h,_ in LANES:
    add(box(30,y,1860,h,fill,col,sw=1.8,rx=10)+t(50,y+34,name,16,"700",col))
add(t(50,236,"A colleague your team",15,fill=GR)+t(50,258,"nominates.",15,fill=GR))
add(t(50,476,"Everyone, the team lead",15,fill=GR)+t(50,498,"included.",15,fill=GR))
def stage(col,y,stage,l1,l2,l3=""):
    x=COLX[col]+8; w=CW-16; h=150
    r=box(x,y,w,h,"#FFFFFF",BL,sw=2.5,rx=10)+gh(x+12,y+12,36)
    r+=box(x+58,y+14,w-72,32,BL,BL,sw=1,rx=16)+t(x+58+(w-72)/2,y+36,stage,18,"700","#FFFFFF","middle",mw=w-90)
    r+=t(x+14,y+78,l1,16,"700",NAVY,mw=w-24)+t(x+14,y+102,l2,15,"400",GR,mw=w-24)
    if l3: r+=t(x+14,y+124,l3,15,"400",GR,mw=w-24)
    return r
def person(col,y,title,l1,l2="",l3=""):
    x=COLX[col]+8; w=CW-16; h=150
    r=box(x,y,w,h,"#FFFFFF",AMB,sw=2.5,rx=10)+ic("user",x+12,y+12,34)
    r+=t(x+58,y+36,title,17,"700",NAVY,mw=w-70)
    r+=t(x+14,y+82,l1,15,"400",GR,mw=w-24)
    if l2: r+=t(x+14,y+106,l2,15,"400",GR,mw=w-24)
    if l3: r+=t(x+14,y+130,l3,15,"400",GR,mw=w-24)
    return r
# team lead lane
add(stage(1,205,"whatif, foundation","Builds the shared hub","Management groups, firewall,","policies. About 15 to 25 minutes."))
add(stage(3,205,"vending","Connects every member","Restarts VMs, runs checks.","About 1 hour for 3 members."))
add(stage(4,205,"teardown","Removes every member,","then the foundation.",""))
# member lane
add(stage(0,445,"whatif","Preflight","Checks your subscription and","registers what it needs."))
add(stage(2,445,"member","Deploys your datacenter,","tests it, connects it to Arc.","About 45 minutes."))
add(stage(4,445,"teardown","Removes your datacenter","and your spoke.",""))
# person lane
add(person(0,685,"Share your values","Send the team lead your","subscription ID, index,","object ID and email."))
add(person(1,685,"Graph grant","A Privileged Role Administrator","approves it once per team."))
add(person(2,685,"Finish and check","Arc assessment, vm-dev01","setup, then a coach's","readiness check."))
add(person(4,685,"Remove the identity","An admin runs","Remove-PlatformPipeline.ps1."))
# arrows: readiness check -> vending
x3=COLX[2]+CW-8; xv=COLX[3]+CW/2
add(arr(f"M{x3} 760H{xv}V355","net"))
add(chip2(xv,545,200,"Coach approves,","then vending",BL,BLF,14))
# bottom strip
add(box(30,892,1860,138,"#FFFFFF",NAVY,sw=2,rx=10))
cells=[("gh","One workflow","platform.yml runs in your own repo.","Pick a stage; walk away."),("mi","No passwords or keys","A short-lived sign-in token, scoped to","one repo and one environment."),("user","A guard checks first","Only the subscriptions on your team's","list can be touched.")]
for i,(k,a,b,c) in enumerate(cells):
    x=60+i*610
    add(ic(k,x,918,44) if k!="gh" else gh(x,918,44))
    add(t(x+60,946,a,20,"700",mw=520)+t(x+60,976,b,16,fill=GR,mw=520)+t(x+60,1000,c,16,fill=GR,mw=520))
finish("diagram-13-pipeline-who-runs-what","GitHub Actions deploys it; people do the few steps it can't")
