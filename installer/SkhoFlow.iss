; SkhoFlow Windows installer (Inno Setup 6+)
; Compile with: iscc installer\SkhoFlow.iss

#define MyAppName        "SkhoFlow"
#define MyAppVersion     "2.0.0"
#define MyAppPublisher   "SkhoFlow"
#define MyAppURL         "https://skhoflow.app"
#define MyAppExeName     "SkhoFlow.exe"
#define MyAppId          "{{B7C0F4F5-9D9F-4F2C-9F2E-7D3C8C6B1A22}"

; Path to the published WinUI 3 build. Produced by:
;   msbuild src\SkhoFlow.Host\SkhoFlow.Host.csproj -t:Publish -p:Configuration=Release ^
;       -p:Platform=x64 -p:RuntimeIdentifier=win-x64 -p:SelfContained=true -restore
#define PublishDir       "..\src\SkhoFlow.Host\bin\x64\Release\net8.0-windows10.0.22621.0\win-x64\publish"

[Setup]
AppId={#MyAppId}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
OutputDir=.\Output
OutputBaseFilename=SkhoFlow-Setup-{#MyAppVersion}
; SetupIconFile=..\src\SkhoFlow.Host\Assets\skhoflow.ico  ; uncomment after generating the .ico
WizardStyle=modern
Compression=lzma2/ultra64
SolidCompression=yes
PrivilegesRequired=admin
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
UninstallDisplayIcon={app}\{#MyAppExeName}
UninstallDisplayName={#MyAppName}
VersionInfoVersion={#MyAppVersion}
VersionInfoProductName={#MyAppName}

; Branded wizard imagery (drop your own 164x314 and 55x55 BMPs alongside this script)
;WizardImageFile=brand-large.bmp
;WizardSmallImageFile=brand-small.bmp

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "Create a &desktop shortcut"; GroupDescription: "Additional shortcuts:"
Name: "startup";     Description: "Start {#MyAppName} when Windows starts"; GroupDescription: "Startup:"

[Files]
Source: "{#PublishDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{group}\Uninstall {#MyAppName}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Registry]
; Autostart on sign-in when the user opts in.
; Installer runs elevated, so HKLM\...\Run is the correct hive for a machine-wide install.
Root: HKLM; Subkey: "Software\Microsoft\Windows\CurrentVersion\Run"; \
    ValueType: string; ValueName: "{#MyAppName}"; ValueData: """{app}\{#MyAppExeName}"""; \
    Flags: uninsdeletevalue; Tasks: startup

[Run]
; Allow the HTTP listener to bind on the LAN without prompting for admin every launch
Filename: "netsh"; Parameters: "http add urlacl url=http://+:47990/ user=Everyone"; \
    StatusMsg: "Configuring local network access..."; Flags: runhidden
; Open Windows Firewall for the pairing + video ports
Filename: "netsh"; Parameters: "advfirewall firewall add rule name=""SkhoFlow Control"" dir=in action=allow protocol=TCP localport=47990"; Flags: runhidden
Filename: "netsh"; Parameters: "advfirewall firewall add rule name=""SkhoFlow Video""   dir=in action=allow protocol=UDP localport=47989"; Flags: runhidden
Filename: "netsh"; Parameters: "advfirewall firewall add rule name=""SkhoFlow Probe""   dir=in action=allow protocol=UDP localport=47988"; Flags: runhidden

Filename: "{app}\{#MyAppExeName}"; Description: "Launch {#MyAppName} now"; Flags: nowait postinstall skipifsilent

[UninstallRun]
Filename: "netsh"; Parameters: "http delete urlacl url=http://+:47990/"; RunOnceId: "DelUrlAcl"; Flags: runhidden
Filename: "netsh"; Parameters: "advfirewall firewall delete rule name=""SkhoFlow Control"""; RunOnceId: "DelFwControl"; Flags: runhidden
Filename: "netsh"; Parameters: "advfirewall firewall delete rule name=""SkhoFlow Video"""; RunOnceId: "DelFwVideo"; Flags: runhidden
Filename: "netsh"; Parameters: "advfirewall firewall delete rule name=""SkhoFlow Probe"""; RunOnceId: "DelFwProbe"; Flags: runhidden

[UninstallDelete]
; Settings stored under %LOCALAPPDATA%\SkhoFlow — leave the user's paired devices intact by default.
; Uncomment to wipe them too:
;Type: filesandordirs; Name: "{localappdata}\SkhoFlow"
