import re,os
from dlib import BASE as base
want={"mg":"general/10011-icon-service-Management-Groups.svg","sub":"general/10002-icon-service-Subscriptions.svg","rg":"general/10007-icon-service-Resource-Groups.svg",
"vnet":"networking/10061-icon-service-Virtual-Networks.svg","fw":"networking/10084-icon-service-Firewalls.svg","dns":"networking/10064-icon-service-DNS-Zones.svg",
"law":"monitor/00009-icon-service-Log-Analytics-Workspaces.svg","mi":"identity/10227-icon-service-Managed-Identities.svg","ten":"identity/02679-icon-service-Tenant-Properties.svg",
"vm":"compute/10021-icon-service-Virtual-Machine.svg","app":"web/10035-icon-service-App-Services.svg","bas":"networking/02422-icon-service-Bastions.svg","nat":"networking/10310-icon-service-NAT.svg",
"subnet":"networking/02742-icon-service-Subnet.svg","acr":"containers/10105-icon-service-Container-Registries.svg","sqlmi":"databases/10136-icon-service-SQL-Managed-Instance.svg",
"blob":"storage/10086-icon-service-Storage-Accounts.svg","sb":"integration/10836-icon-service-Azure-Service-Bus.svg","kv":"security/10245-icon-service-Key-Vaults.svg","ai":"monitor/00012-icon-service-Application-Insights.svg"}
def symbols(want):
    out=""
    for k,p in want.items():
        s=open(os.path.join(base,p.replace("/","\\")),encoding="utf-8").read()
        s=re.sub(r"<\?xml.*?\?>","",s)
        vb=re.search(r'viewBox="([^"]+)"',s).group(1)
        inner=re.search(r"<svg[^>]*>(.*)</svg>",s,re.S).group(1)
        inner=re.sub(r'id="([^"]+)"',lambda m:f'id="{k}-{m.group(1)}"',inner)
        inner=re.sub(r'url\(#([^)]+)\)',lambda m:f'url(#{k}-{m.group(1)})',inner)
        inner=re.sub(r'(xlink:href|href)="#([^"]+)"',lambda m:f'{m.group(1)}="#{k}-{m.group(2)}"',inner)
        out+=f'<symbol id="ic-{k}" viewBox="{vb}">{inner}</symbol>\n'
    return out
def ic(k,x,y,s=36): return f'<use href="#ic-{k}" x="{x}" y="{y}" width="{s}" height="{s}"/>'
def box(x,y,w,h,fill,stroke,ext="",sw=2): return f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="8" fill="{fill}" stroke="{stroke}" stroke-width="{sw}" {ext}/>'
def t(x,y,s,size=22,w="400",fill="#0B1F3A",anchor="start"): return f'<text x="{x}" y="{y}" font-size="{size}" font-weight="{w}" fill="{fill}" text-anchor="{anchor}">{s}</text>'
def rg(x,y,w,h,name,col,lx=0): return f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="8" fill="#FFFFFF" stroke="{col}" stroke-width="1.8" stroke-dasharray="7 4"/>'+ic("rg",x+14+lx,y+8,32)+t(x+56+lx,y+32,name,20,"700",col)
def chip(cx,cy,w,s,stroke,fill="#FFFFFF",size=16,col="#0B1F3A"):
    return f'<rect x="{cx-w/2}" y="{cy-13}" width="{w}" height="26" rx="6" fill="{fill}" stroke="{stroke}" stroke-width="1.5"/>'+t(cx,cy+6,s,size,"700",col,"middle")
def card(x,y,w,h,k,lines,fill,stroke,isz=44):
    r=box(x,y,w,h,fill,stroke,sw=1.5)+ic(k,x+10,y+(h-isz)//2,isz)
    n=len(lines); y0=y+h/2-(n-1)*14+6
    for i,(s,b) in enumerate(lines): r+=t(x+isz+20,y0+i*28,s,18 if b else 16,"700" if b else "400","#0B1F3A" if b else "#3A4A5A")
    return r
BL="#0078D4";TL="#008272";AM="#F2A900"
o=[]
o.append(f'''<svg xmlns="http://www.w3.org/2000/svg" width="3840" height="2160" viewBox="0 0 1920 1080" font-family="Segoe UI, Arial, sans-serif"><defs>{symbols(want)}
<marker id="mb" viewBox="0 0 10 10" refX="8" refY="5" markerWidth="8" markerHeight="8" orient="auto-start-reverse"><path d="M0 0L10 5L0 10z" fill="{BL}"/></marker>
<marker id="ma" viewBox="0 0 10 10" refX="8" refY="5" markerWidth="8" markerHeight="8" orient="auto-start-reverse"><path d="M0 0L10 5L0 10z" fill="#D18B00"/></marker></defs>
<rect width="1920" height="1080" fill="#FFFFFF"/>''')
o.append(t(960,56,"From simulated datacenter to modernized application",40,"700",anchor="middle"))
o.append('<rect x="30" y="80" width="1860" height="940" rx="14" fill="none" stroke="#0B1F3A" stroke-width="3"/>')
o.append(ic("ten",50,92,40)+t(100,121,"Team Microsoft Entra tenant",26,"700"))
o.append(t(60,172,"Legend",18,"700"))
o.append(f'<path d="M64 200H134" stroke="{BL}" stroke-width="3" marker-start="url(#mb)" marker-end="url(#mb)"/>'+t(146,206,"VNet peering",17))
o.append(f'<path d="M64 236H134" stroke="#D18B00" stroke-width="3.5" marker-end="url(#ma)"/>'+t(146,242,"MI link during C7",17))
o.append(f'<path d="M64 272H134" stroke="{BL}" stroke-width="3" marker-end="url(#mb)"/>'+t(146,278,"Public HTTPS",17))
o.append(f'<path d="M64 308H134" stroke="{TL}" stroke-width="3" stroke-dasharray="2 6" stroke-linecap="round"/>'+t(146,314,"DNS zone link",17))
o.append(f'<path d="M64 344H134" stroke="{BL}" stroke-width="2.5"/>'+t(146,350,"Attachment",17))
# shared sub
o.append(box(300,132,1320,225,"#F5FAFF",BL,sw=2.5)+ic("sub",318,138,36)+t(364,165,"Shared services subscription - one per team",24,"700"))
o.append(box(1340,140,262,28,BL,BL)+t(1471,160,"SHARED BY ALL MEMBERS",15,"700","#FFFFFF","middle"))
o.append(rg(320,180,800,167,"rg-hub",BL))
o.append(box(335,222,500,118,"#E6F1FB",BL,sw=1.8)+ic("vnet",347,226,28)+t(383,247,"vnet-hub",20,"700",BL))
o.append(card(355,254,460,70,"fw",[("Azure Firewall Standard",1),("DNS proxy",0)],"#FFFFFF",BL,46))
o.append(box(880,222,225,118,"#E3F4F1",TL,sw=1.8)+ic("dns",892,232,40)+t(940,252,"Central private",18,"700")+t(940,274,"DNS zones",18,"700")+t(892,320,"Linked to vnet-hub",16,fill="#3A4A5A"))
o.append(f'<path d="M880 281H835" stroke="{TL}" stroke-width="3" stroke-dasharray="2 6" stroke-linecap="round"/>')
o.append(rg(1140,180,460,167,"rg-management",BL))
o.append(card(1155,222,430,54,"law",[("Central Log Analytics",1)],"#E6F1FB",BL,36))
o.append(card(1155,284,430,54,"mi",[("id-sqlmi-directory",1)],"#E6F1FB",BL,36))
# member sub
o.append(box(60,410,1800,505,"#F2FAF8",TL,sw=2.5)+ic("sub",78,418,38)+t(126,447,"Member workload subscription",24,"700"))
o.append(box(1380,419,230,28,TL,TL)+t(1495,439,"REPEATED PER MEMBER",15,"700","#FFFFFF","middle"))
o.append('<g transform="translate(0,30)">')
o.append(rg(75,440,600,440,"rg-datacenter",TL))
o.append(box(90,485,570,350,"#FFFFFF",TL,sw=1.8)+ic("vnet",102,490,30)+t(140,513,"vnet-datacenter",20,"700",TL))
o.append(card(105,545,265,120,"vm",[("vm-dev01",1),("Windows 11",0),("Development tools",0)],"#E3F4F1",TL,46))
o.append(card(385,545,265,120,"vm",[("vm-app01",1),("Legacy Contoso University",0),("on IIS + SQL Server 2022",0)],"#EEF2F6","#5B6B7B",46))
o.append(card(105,685,265,110,"bas",[("Bastion Standard",1),("Private RDP access",0)],"#E3F4F1",TL,46))
o.append(card(385,685,265,110,"nat",[("NAT Gateway",1),("Outbound internet",0)],"#E3F4F1",TL,46))
o.append(t(375,864,"Simulated on-premises estate",17,"700","#3A4A5A","middle"))
o.append(rg(760,440,330,440,"rg-spoke",TL,120))
o.append(box(775,485,300,362,"#FFFFFF",TL,sw=1.8)+ic("vnet",787,490,30)+t(825,513,"vnet-spoke",20,"700",TL))
for y,n,c in [(548,"snet-sqlmi","Delegated to SQL MI"),(650,"snet-pe","Private endpoints"),(752,"snet-app","App Service integration")]:
    o.append(card(790,y,270,84,"subnet",[(n,1),(c,0)],"#E3F4F1",TL,40))
o.append(t(925,868,"Workload network, vended in C2",17,"700","#3A4A5A","middle"))
o.append(rg(1330,440,510,440,"rg-university-&lt;suffix&gt;",TL))
o.append(t(1608,472,"CoE archetype, C5",16,"700","#3A4A5A"))
items=[("sqlmi","SQL Managed Instance"),("acr","ACR Premium"),("blob","Blob Storage"),("sb","Service Bus Premium"),("kv","Key Vault"),("app","App Service Linux"),("ai","Application Insights")]
for i,(k,l) in enumerate(items):
    cy=522+52*i
    o.append(card(1372,cy-22,350,44,k,[(l,1)],"#E3F4F1",TL,32))
o.append('</g>')
# cross-boundary connectors (absolute coordinates)
o.append(f'<path d="M560 338V515" stroke="{BL}" stroke-width="3" marker-start="url(#mb)" marker-end="url(#mb)" fill="none"/>')
o.append(f'<path d="M800 338V515" stroke="{BL}" stroke-width="3" marker-start="url(#mb)" marker-end="url(#mb)" fill="none"/>')
o.append(chip(632,392,112,"VNet peering",BL,size=15)); o.append(chip(872,392,112,"VNet peering",BL,size=15))
o.append(f'<path d="M520 575V326" stroke="#D18B00" stroke-width="3.5" marker-end="url(#ma)" fill="none"/>')
o.append(f'<path d="M700 324V372H1030V578" stroke="#D18B00" stroke-width="3.5" marker-end="url(#ma)" fill="none"/>')
o.append(chip(1030,440,170,"MI link during C7","#D18B00","#FFF6DD"))
o.append(t(512,392,"Source SQL Server",16,"700","#8A5A00","end"))
o.append(f'<path d="M1372 552H1262V620H1064" stroke="{BL}" stroke-width="2.5" fill="none" marker-end="url(#mb)"/>'+t(1105,611,"VNet injection",16,"700"))
o.append(f'<path d="M1358 582V782M1358 582H1366M1358 782H1366" stroke="{BL}" stroke-width="2.5" fill="none"/><path d="M1358 682H1262V722H1062" stroke="{BL}" stroke-width="2.5" fill="none"/>'+t(1105,714,"4 private endpoints",16,"700"))
o.append(f'<path d="M1372 812H1064" stroke="{BL}" stroke-width="2.5" fill="none" marker-end="url(#mb)"/>'+t(1105,803,"Outbound VNet integration",16,"700"))
o.append(chip(1215,496,200,"Uses the vended spoke",BL,"#E6F1FB",15))
o.append(box(1660,185,200,64,"#FFFFFF","#5B6B7B")+t(1760,224,"External browser",20,"700",anchor="middle"))
o.append(f'<path d="M1760 249V344M1760 372V812H1726" stroke="{BL}" stroke-width="3" fill="none" marker-end="url(#mb)"/>')
o.append(chip(1760,358,112,"Public HTTPS",BL,size=15))
steps=[("Deploy","Datacenter"),("Deploy","Foundation and vending"),("C5","Archetype"),("C6","Modernize and publish image"),("C7","Cut over and go live")]
for i,(c,s) in enumerate(steps):
    x=60+i*360; w=352
    o.append(f'<polygon points="{x},937 {x+w-22},937 {x+w},959 {x+w-22},981 {x},981" fill="#E6F1FB" stroke="{BL}" stroke-width="1.8"/>'+t(x+16,965,f'<tspan font-weight="700" fill="{BL}">{c}</tspan>  {s}',18))
o.append(chip(960,1003,640,"Modernized app first runs on App Service at the end of C7","#D18B00","#FFF6DD",17))
o.append(t(960,1058,"Partner Modernization Factory | Non-production lab",18,fill="#4A5A6A",anchor="middle"))
o.append("</svg>")
open("diagram-02-end-to-end-overview.svg","w",encoding="utf-8").write("\n".join(o))


