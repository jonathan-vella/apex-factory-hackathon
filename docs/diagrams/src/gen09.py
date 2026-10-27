from dlib import *
reset()
add(box(30,90,1860,345,"#FFFFFF",SL,sw=2)+t(50,122,"Modernized app on App Service",24,"700",TL))
lg=[("id","Identity / authorization",PU),("net","Request",BL),("tel","Telemetry",SL)]
x=1130
for k,l,c in lg:
    add(arr(f"M{x} 114H{x+50}",k)+t(x+60,120,l,16,mw=170)); x+=250 if k=="id" else 150
add(card(50,135,290,56,"app",[("App Service",1)],TLF,TL,36))
add(card(380,135,360,56,"mi",[("id-university-&lt;suffix&gt;",1),("AZURE_CLIENT_ID selects it",0)],"#FFFFFF",PU,36,ls=20,sz=(16,13)))
add(arr("M340 163H380","id"))
tg=[("acr","ACR","AcrPull"),("blob","Blob Storage","Storage Blob Data Contributor"),("sb","Service Bus","Data Sender and Data Receiver"),("kv","Key Vault","Key Vault Secrets User"),("ai","Application Insights","Monitoring Metrics Publisher"),("sqlmi","SQL MI","")]
add(f'<path d="M560 191V218M{50+135} 218H{50+5*305+135}" stroke="{PU}" stroke-width="3" stroke-dasharray="9 6" fill="none"/>')
for i,(k,n,r) in enumerate(tg):
    cx=50+i*305+135
    add(card(50+i*305,290,270,76,k,[(n,1)] if k!="sqlmi" else [(n,1),("ContosoUniversity database",0)],"#FFFFFF",PU,40,ls=22,sz=(17,13)))
    add(arr(f"M{cx} 218V290","id"))
    if r: add(chip(cx,254,255,r,PU,PUF,13,h=24))
    else: add(chip2(cx,254,255,"Contained database user","created after cutover",PU,PUF,12.5))
add(arr("M50 163H38V380H1100V368","net")+chip(450,380,340,"Read ConnectionStrings--DefaultConnection",BL,size=13,h=24))
add(arr("M38 380V408H1710V368","net")+chip(900,408,540,"Authentication=Active Directory Default; no SQL username or password",BL,size=13,h=24))
# middle band
add(box(30,450,1860,215,"#FFFFFF",SL,sw=2)+t(50,482,"SQL MI directory lookup is a different identity",24,"700",PU))
add(card(50,520,260,70,"sqlmi",[("SQL Managed Instance",1)],"#FFFFFF",TL,38,sz=(17,14)))
add(card(400,520,330,70,"mi",[("id-sqlmi-directory",1),("Shared, in rg-management",0)],"#FFFFFF",PU,38,ls=22,sz=(17,14)))
add(card(1130,520,300,70,"user",[("Microsoft Graph",1),("Directory lookup",0)],"#FFFFFF",PU,38,ls=22,sz=(17,14)))
add(arr("M310 555H400","id")+chip(355,533,76,"uses",PU,PUF,12,h=20))
add(arr("M730 555H1130","id")+chip2(930,555,330,"User.Read.All | GroupMember.Read.All","Application.Read.All",PU,PUF,13))
add(box(1470,465,405,190,AMF,AMB,sw=2)+t(1485,492,"Tenant administrator approval;",15,"700",mw=380)+t(1485,512,"shared per team",15,"700")+t(1485,543,"Directory lookup for Entra principals;",15,mw=380)+t(1485,563,"not the app's data-access identity",15)+t(1485,594,"Accepted lab risk: attachable shared",15,mw=380)+t(1485,614,"directory identity; not a production",15)+t(1485,634,"recommendation",15))
# bottom band
add(box(30,680,1860,335,"#FFFFFF",SL,sw=2)+t(50,712,"Local development and observability",24,"700",SL))
add(card(50,745,290,80,"dev",[("App on vm-dev01",1),("Local .NET app",0)],"#FFFFFF",TL,40,ls=22,sz=(17,14)))
add(card(450,726,400,88,"cli",[("Member's Azure CLI sign-in",1),("DefaultAzureCredential with",0),("AZURE_TOKEN_CREDENTIALS=AzureCliCredential",0)],"#FFFFFF",PU,40,ls=20,sz=(16,12.5)))
add(card(450,826,400,66,"sqls",[("Source SQL Server on vm-app01",1),("Development only: SQL login in user secrets",0)],"#FFFFFF",SL,40,ls=22,sz=(16,12.5)))
add(arr("M340 775H395V770H450","id")); add(arr("M340 795H395V857H450","net"))
add(card(900,745,280,76,"app",[("App Service app",1),("Cloud execution location",0)],TLF,TL,40,ls=22,sz=(17,14)))
add(card(1290,740,240,80,"ai",[("Application Insights",1)],"#FFFFFF",SL,40,sz=(17,14)))
add(card(1640,740,240,80,"law",[("log-management",1)],BLF,BL,40,sz=(17,14)))
add(arr("M1180 780H1290","tel")+chip(1235,757,92,"Telemetry",SL,size=12,h=22))
add(arr("M1530 780H1640","tel")+chip(1585,757,100,"Workspace",SL,size=12,h=22))
add(arr("M70 825V990H1410V820","tel")+chip(760,990,520,"Azure Monitor OpenTelemetry; Entra-authenticated telemetry",SL,size=13,h=24))
add(card(1560,885,320,60,"mon",[("Platform resources",1)],"#FFFFFF",SL,34,sz=(16,14)))
add(arr("M1880 915H1900V780H1880","tel") if False else arr("M1760 885V820","tel")+chip(1760,853,130,"Diagnostic settings",SL,size=11.5,h=22))
add(box(100,895,700,75,AMF,AMB,sw=1.8)+t(112,918,"Do not use the dev VM's policy-added identity for app data access",14.5,"700",mw=720)+t(112,941,"Telemetry ingestion/query endpoints are public; local authentication is off",14,mw=720)+t(112,962,"Managed identity authenticates the app to Azure; it does not authenticate website visitors",14,mw=720))
finish("diagram-09-identities-secrets-telemetry","Separate application identity, directory lookup and telemetry")


