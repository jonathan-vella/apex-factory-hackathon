import re,os,subprocess,shutil
ICONS=os.environ.get("DIAGRAM_ICONS",os.path.join(os.getcwd(),"icons"))
OUT=os.environ.get("DIAGRAM_OUT",os.path.join(os.getcwd(),"out"))
BASE=os.path.join(ICONS,"az","Azure_Public_Service_Icons","Icons")
P={"mg":"general/10011-icon-service-Management-Groups.svg","sub":"general/10002-icon-service-Subscriptions.svg","rg":"general/10007-icon-service-Resource-Groups.svg",
"vnet":"networking/10061-icon-service-Virtual-Networks.svg","fw":"networking/10084-icon-service-Firewalls.svg","fwp":"networking/00272-icon-service-Azure-Firewall-Policy.svg","dns":"networking/10064-icon-service-DNS-Zones.svg",
"law":"monitor/00009-icon-service-Log-Analytics-Workspaces.svg","mi":"identity/10227-icon-service-Managed-Identities.svg","ten":"identity/02679-icon-service-Tenant-Properties.svg",
"vm":"compute/10021-icon-service-Virtual-Machine.svg","app":"web/10035-icon-service-App-Services.svg","asp":"app services/00046-icon-service-App-Service-Plans.svg","bas":"networking/02422-icon-service-Bastions.svg","nat":"networking/10310-icon-service-NAT.svg",
"subnet":"networking/02742-icon-service-Subnet.svg","acr":"containers/10105-icon-service-Container-Registries.svg","sqlmi":"databases/10136-icon-service-SQL-Managed-Instance.svg",
"blob":"storage/10086-icon-service-Storage-Accounts.svg","sb":"integration/10836-icon-service-Azure-Service-Bus.svg","kv":"security/10245-icon-service-Key-Vaults.svg","ai":"monitor/00012-icon-service-Application-Insights.svg",
"pol":"management + governance/10316-icon-service-Policy.svg","code":"general/10787-icon-service-Code.svg","peer":"other/01285-Peerings.svg".replace("01285-Peerings","01285-icon-service-Peerings"),
"rt":"networking/10082-icon-service-Route-Tables.svg","bud":"general/10793-icon-service-Cost-Budgets.svg","user":"identity/10230-icon-service-Users.svg","pe":"other/02579-icon-service-Private-Endpoints.svg",
"pip":"networking/10069-icon-service-Public-IP-Addresses.svg","nsg":"networking/10067-icon-service-Network-Security-Groups.svg","arc":"management + governance/00756-icon-service-Azure-Arc.svg",
"sqls":"databases/10132-icon-service-SQL-Server.svg","disk":"compute/10032-icon-service-Disks.svg","mon":"monitor/00001-icon-service-Monitor.svg","arcsql":"other/01850-icon-service-Arc-SQL-Server.svg",
"cli":"other/00559-icon-service-Azure-Cloud-Shell.svg","queue":"general/10840-icon-service-Storage-Queue.svg","cont":"general/10839-icon-service-Storage-Container.svg","dev":"other/03250-icon-service-Microsoft-Dev-Box.svg"}
NAVY="#0B1F3A";GR="#3A4A5A";BL="#0078D4";TL="#008272";AM="#D18B00";AMB="#F2A900";PU="#7B3FA0";SL="#5B6B7B"
BLF="#E6F1FB";TLF="#E3F4F1";AMF="#FFF6DD";GRF="#EEF2F6";PUF="#F3ECF8"
KIND={"net":BL,"id":PU,"dns":TL,"tel":SL,"mig":AM,"off":"#8A98A8"}
o=[]
def reset(): o.clear()
def add(s): o.append(s)
def est(s,size,bold=False):
    s=re.sub(r"<[^>]+>","",s).replace("&lt;","<").replace("&gt;",">").replace("&amp;","&")
    return len(s)*size*(0.56 if bold else 0.52)
def ic(k,x,y,s=36): return f'<use href="#ic-{k}" x="{x}" y="{y}" width="{s}" height="{s}"/>'
def box(x,y,w,h,fill,stroke,ext="",sw=2,rx=8): return f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{rx}" fill="{fill}" stroke="{stroke}" stroke-width="{sw}" {ext}/>'
def t(x,y,s,size=20,w="400",fill=NAVY,anchor="start",mw=None):
    if mw and est(s,size,w=="700")>mw: print("WARN overflow:",s[:50],round(est(s,size,w=="700")),">",mw)
    return f'<text x="{x}" y="{y}" font-size="{size}" font-weight="{w}" fill="{fill}" text-anchor="{anchor}">{s}</text>'
def rg(x,y,w,h,name,col,lx=0,k="rg"): return box(x,y,w,h,"#FFFFFF",col,'stroke-dasharray="7 4"',1.8)+ic(k,x+14+lx,y+8,32)+t(x+56+lx,y+32,name,20,"700",col)
def chip(cx,cy,w,s,stroke,fill="#FFFFFF",size=15,col=NAVY,h=26):
    return box(cx-w/2,cy-h/2,w,h,fill,stroke,sw=1.5,rx=6)+t(cx,cy+size*0.35,s,size,"700",col,"middle",mw=w-8)
def chip2(cx,cy,w,l1,l2,stroke,fill="#FFFFFF",size=14):
    return box(cx-w/2,cy-20,w,40,fill,stroke,sw=1.5,rx=6)+t(cx,cy-3,l1,size,"700",NAVY,"middle",mw=w-8)+t(cx,cy+15,l2,size,"700",NAVY,"middle",mw=w-8)
def card(x,y,w,h,k,lines,fill,stroke,isz=40,ls=26,sz=(18,16)):
    r=box(x,y,w,h,fill,stroke,sw=1.5)
    tx=x+10
    if k: r+=ic(k,x+10,y+(h-isz)/2,isz); tx=x+isz+20
    n=len(lines); y0=y+h/2-(n-1)*ls/2+6
    for i,(s,b) in enumerate(lines): r+=t(tx,y0+i*ls,s,sz[0] if b else sz[1],"700" if b else "400",NAVY if b else GR,mw=x+w-tx-8)
    return r
def arr(d,kind="net",start=False,end=True,sw=3):
    c=KIND[kind]; dash={"id":'stroke-dasharray="9 6"',"dns":'stroke-dasharray="2 6" stroke-linecap="round"',"tel":'stroke-dasharray="9 6"',"off":'stroke-dasharray="6 6"'}.get(kind,"")
    ms=f' marker-start="url(#m-{kind})"' if start else ""; me=f' marker-end="url(#m-{kind})"' if end else ""
    return f'<path d="{d}" stroke="{c}" stroke-width="{sw}" fill="none" {dash}{ms}{me}/>'
def circ(x,y,n,col=BL): return f'<circle cx="{x}" cy="{y}" r="13" fill="{col}"/>'+t(x,y+6,n,16,"700","#FFFFFF","middle")
def badge(x,y,w,s,col): return box(x,y,w,28,col,col)+t(x+w/2,y+20,s,15,"700","#FFFFFF","middle",mw=w-8)
def sub(x,y,w,h,name,col,fill,badgetxt=None,bw=230):
    r=box(x,y,w,h,fill,col,sw=2.5)+ic("sub",x+16,y+6,36)+t(x+62,y+34,name,24,"700")
    if badgetxt: r+=badge(x+w-bw-14,y+10,bw,badgetxt,col)
    return r
def folder(x,y,s=30): return f'<path d="M{x} {y+6}h{s*0.4}l{s*0.12} {s*0.14}h{s*0.48}v{s*0.7}h{-s}z" fill="#F2C94C" stroke="#B8901C" stroke-width="1.2"/>'
def gh(x,y,s=40): return f'<use href="#ic-gh" x="{x}" y="{y}" width="{s}" height="{s}"/>'
def symbols(used):
    out=""
    for k in sorted(used):
        if k=="gh":
            d=re.search(r' d="([^"]+)"',open(os.path.join(ICONS,"github.svg")).read()).group(1)
            out+=f'<symbol id="ic-gh" viewBox="0 0 24 24"><path fill="{NAVY}" d="{d}"/></symbol>\n'; continue
        s=open(os.path.join(BASE,P[k]),encoding="utf-8").read()
        s=re.sub(r"<\?xml.*?\?>","",s)
        vb=re.search(r'viewBox="([^"]+)"',s).group(1)
        inner=re.search(r"<svg[^>]*>(.*)</svg>",s,re.S).group(1)
        inner=re.sub(r'id="([^"]+)"',lambda m:f'id="{k}-{m.group(1)}"',inner)
        inner=re.sub(r'url\(#([^)]+)\)',lambda m:f'url(#{k}-{m.group(1)})',inner)
        inner=re.sub(r'(xlink:href|href)="#([^"]+)"',lambda m:f'{m.group(1)}="#{k}-{m.group(2)}"',inner)
        out+=f'<symbol id="ic-{k}" viewBox="{vb}">{inner}</symbol>\n'
    return out
def finish(name,title):
    body="\n".join(o)
    used=set(re.findall(r'#ic-(\w+)"',body))
    mk="".join(f'<marker id="m-{k}" viewBox="0 0 10 10" refX="8" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse"><path d="M0 0L10 5L0 10z" fill="{c}"/></marker>' for k,c in KIND.items())
    svg=f'<svg xmlns="http://www.w3.org/2000/svg" width="3840" height="2160" viewBox="0 0 1920 1080" font-family="Segoe UI, Arial, sans-serif"><defs>{symbols(used)}{mk}</defs><rect width="1920" height="1080" fill="#FFFFFF"/>'
    svg+=t(960,56,title,40,"700",anchor="middle")+body+t(960,1058,"Partner Modernization Factory | Non-production lab",18,fill="#4A5A6A",anchor="middle")+"</svg>"
    os.makedirs(OUT,exist_ok=True); p=os.path.join(OUT,name+".svg"); open(p,"w",encoding="utf-8").write(svg)
    tmp=os.path.join(os.environ["TEMP"],"r_"+name+".png")
    if os.path.exists(tmp): os.remove(tmp)
    e=r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
    if not os.path.exists(e): e=r"C:\Program Files\Microsoft\Edge\Application\msedge.exe"
    for attempt in range(4):
        pr=subprocess.Popen([e,"--headless=new","--disable-gpu","--hide-scrollbars","--no-first-run","--user-data-dir="+os.path.join(os.environ["TEMP"],"ed_"+name),"--window-size=3840,2160","--screenshot="+tmp,"file:///"+p.replace("\\","/")],stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
        for _ in range(25):
            if os.path.exists(tmp) and os.path.getsize(tmp)>1000: break
            if pr.poll() is not None: break
            import time; time.sleep(1)
        subprocess.run(["taskkill","/F","/T","/PID",str(pr.pid)],capture_output=True)
        if os.path.exists(tmp) and os.path.getsize(tmp)>1000: break
    shutil.copyfile(tmp,os.path.join(OUT,name+".png")); print("rendered",name)

