from dlib import *
reset()
W=300; STEP=385; X0=40
steps=[("gh","Run a stage",["In your own repo:","gh workflow run","platform.yml"]),
       ("gh","Environment gh-lab",["Only the branches you list.","A reviewer, where your","plan allows it."]),
       ("user","Guard",["Checks the subscription","and prefix against your","team's list. Stops if","it isn't on it."]),
       ("mi","Microsoft Entra",["A short-lived GitHub token","proves which repo and","environment is asking."]),
       ("sub","Azure",["The managed identity runs","the kit's scripts. There","is no stored secret."])]
for i,(k,title,lines) in enumerate(steps):
    x=X0+i*STEP; y=110
    add(box(x,y,W,220,"#FFFFFF",BL,sw=2.5,rx=10)+(gh(x+14,y+16,44) if k=="gh" else ic(k,x+14,y+16,44))+t(x+70,y+48,title,20,"700",mw=W-80))
    add(circ(x+W-24,y+26,str(i+1)))
    for j,l in enumerate(lines): add(t(x+16,y+96+j*26,l,16,fill=GR,mw=W-28))
    if i<4: add(arr(f"M{x+W} {y+110}H{x+STEP}","net"))# profiles
def panel(x,w,name,col,fill,rows):
    r=box(x,370,w,420,fill,col,sw=2.5,rx=10)+t(x+22,412,name,26,"700",col)
    y=455
    for lab,l1,l2 in rows:
        r+=t(x+22,y,lab,15,"700",col)+t(x+22,y+26,l1,17,"700",NAVY,mw=w-44)
        if l2: r+=t(x+22,y+50,l2,16,fill=GR,mw=w-44)
        y+=90
    return r
add(panel(40,900,"Member profile",TL,TLF,[
 ("LIVES IN","Your own repo","One profile per repo"),
 ("IDENTITY","id-factory-pipeline in rg-cicd","In your own workload subscription"),
 ("OWNER ON","Your workload subscription only","No management group, no other subscription"),
 ("RUNS","whatif, member, teardown","Preflight, datacenter, test, Arc")]))
add(panel(980,900,"Team lead profile",BL,BLF,[
 ("LIVES IN","The team lead's repo","With the roster as an environment secret"),
 ("IDENTITY","id-factory-pipeline in rg-cicd","In the shared services subscription"),
 ("OWNER AT","Tenant Root","Needed to create management groups and move subscriptions"),
 ("RUNS","whatif, foundation, member, vending, teardown","For every member on the roster")]))
# notes
add(box(40,820,1840,200,AMF,AMB,sw=2,rx=10))
notes=[("Why Owner?","The kit assigns roles and policies, which Contributor can't do. Anyone who can run a workflow in the environment can use the identity, so use a non-production tenant only."),
       ("What is protected","Subscription IDs and the roster are environment secrets, never in the repo. Run logs show GUIDs as &lt;id:abcd&gt;."),
       ("Taking it down","The workflow can't remove its own identity. An admin runs Remove-PlatformPipeline.ps1 after the teardown stage.")]
for i,(a,b) in enumerate(notes):
    x=64+i*600
    add(t(x,862,a,20,"700",AM,mw=560))
    words=b.split(); lines=[]; cur=""
    for w_ in words:
        if est(cur+" "+w_,16)>540: lines.append(cur); cur=w_
        else: cur=(cur+" "+w_).strip()
    lines.append(cur)
    for j,l in enumerate(lines): add(t(x,894+j*24,l,16,fill=NAVY,mw=560))
finish("diagram-14-pipeline-sign-in","How the pipeline signs in without a password")
