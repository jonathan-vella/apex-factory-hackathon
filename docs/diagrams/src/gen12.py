from dlib import *
reset()
def lane(x,w,title,col,fill): return box(x,165,w,680,fill,col,sw=2.5)+t(x+16,196,title,21,"700",col,mw=w-30)
add(lane(30,590,"Member laptop: VS Code dev container",TL,"#F2FAF8")+lane(650,600,"Private workstation: vm-dev01 through Bastion",SL,"#F5F7FA")+lane(1280,610,"Azure application platform",BL,"#F5FAFF"))
add(box(560,92,800,56,"#FFFFFF",NAVY,sw=2)+gh(572,100,40)+t(624,118,"GitHub: the member's private repository",18,"700",mw=700)+t(624,139,"Source and evidence storage, not a deployment runner",14,fill=GR,mw=700))
add(arr("M600 148V165","tel",False,False)+arr("M1300 148V165","tel",False,False))
# lane1
L1=[("gh","Member's private APEX-based repo","factory/ imported"),("code","Kit Bicep and pipeline","Datacenter, foundation, vending"),("dev","Adapt the packaged archetype","Review azd provision --preview"),("cli","Member runs azd provision","C5: deploys the platform"),("law","As-Built documents the platform","Documentation of what was deployed"),("folder","Evidence on main","factory/evidence/cNN/")]
for i,(k,a,b) in enumerate(L1):
    y=215+i*75
    if k=="gh": add(box(45,y,560,64,"#FFFFFF",TL,sw=1.5)+gh(55,y+10,44)+t(115,y+28,a,17,"700",mw=480)+t(115,y+50,b,14,fill=GR))
    elif k=="folder": add(box(45,y,560,64,"#FFFFFF",TL,sw=1.5)+folder(57,y+16,32)+t(115,y+28,a,17,"700")+t(115,y+50,b,14,fill=GR))
    else: add(card(45,y,560,64,k,[(a,1),(b,0)],"#FFFFFF",TL,38,ls=22,sz=(17,14)))
add(box(45,690,560,90,AMF,AMB,sw=2)+t(62,722,"Agents adapt and document;",18,"700")+t(62,748,"the member initiates Azure changes.",18,"700"))
# lane2
add(card(665,215,570,64,"dev","VS Code Upgrade agent".split("|") and [("VS Code Upgrade agent",1),("Assess in C3; modernize in C6",0)],"#FFFFFF",SL,38,ls=22,sz=(17,14)))
def two(y,name,l1,l2,fill="#FFFFFF",st=SL):
    return box(665,y,570,84,fill,st,sw=1.5)+folder(677,y+26,32)+t(725,y+28,name,17,"700",mw=500)+t(725,y+50,l1,14,fill=GR,mw=500)+t(725,y+68,l2,14,fill=GR,mw=500)
add(two(290,"C:\\src\\factory","App work on branch vm-dev01-work, pushed to the","member repo; never merged into main"))
add(two(390,"C:\\src\\&lt;your-repo&gt;","Separate plain clone of the same private member","repo; evidence on main",TLF,TL))
add(card(665,495,570,64,"app",[("Local .NET 10 app",1),("Modernization work",0)],"#FFFFFF",SL,38,ls=22,sz=(17,14)))
add(card(665,590,570,64,"sqls",[("Source SQL Server on vm-app01",1),("Development validation target",0)],"#FFFFFF",SL,38,ls=22,sz=(17,14)))
add(arr("M950 559V590","net")+chip(1110,575,250,"Development validation",BL,size=13,h=22))
add(card(665,690,570,70,"cont",[(".NET SDK container publishing",1),("Build and push contoso-university:c6",0)],"#FFFFFF",TL,40,ls=22,sz=(17,14)))
add(chip(950,790,500,"No Dockerfile; no Docker daemon for app image publishing",AM,AMF,13.5,h=26))
# lane3
add(card(1295,215,360,84,"acr",[("ACR Premium",1),("Private endpoint in snet-pe",0)],"#FFFFFF",BL,40,ls=24,sz=(18,14)))
add(box(1380,335,495,95,AMF,AMB,sw=2)+t(1395,362,"C7 prerequisite gate",17,"700",AM)+t(1395,386,"DB cutover complete + database user created +",14,mw=470)+t(1395,406,"Key Vault connection secret written",14))
add(card(1295,470,360,84,"app",[("App Service Linux",1),("VNet integration, managed identity",0)],TLF,TL,40,ls=24,sz=(18,14)))
add(box(1700,484,175,56,"#FFFFFF",SL,sw=1.8)+t(1787,518,"Browser",18,"700",anchor="middle"))
add(card(1295,595,360,64,"sqlmi",[("SQL Managed Instance",1)],"#FFFFFF",BL,38,sz=(17,14)))
add(card(1295,680,360,64,"kv",[("Key Vault",1)],"#FFFFFF",BL,38,sz=(17,14)))
# connectors
add(arr("M605 507H635V868H1585V744","net")+circ(635,540,"1"))
add(arr("M1235 725H1265V257H1295","net")+circ(1265,490,"2"))
add(arr("M1335 299V470","net")+circ(1335,385,"3"))
add(circ(1360,382,"4",AM))
add(arr("M1640 430V470","net")+circ(1640,450,"5"))
add(arr("M1700 512H1657","net")+circ(1678,495,"6"))
# key
add(box(30,880,1860,150,"#FFFFFF",SL,sw=1.5))
ks=["C5: member deploys platform with azd","C6: SDK image publish over private network","Image pull; AcrPull managed identity; VNet image pull","C7 prerequisite gate before image switch","C7: switch from placeholder to contoso-university:c6","Public HTTPS; modernized app live"]
for i,s in enumerate(ks):
    x=50+(i//3)*620; y=905+(i%3)*30
    add(circ(x+13,y,str(i+1),AM if i==3 else BL)+t(x+34,y+6,s,16,mw=560))
add(t(1300,925,"C6 publishes the image.",19,"700")+t(1300,953,"C7 makes the app live.",19,"700")+t(1300,981,"These are different milestones.",19,"700"))
finish("diagram-12-working-locations-go-live","Where you work: dev container, private dev VM and App Service")

