[Setup]
AppName=Fintel
AppVersion=2.0
AppPublisher=Dohaham Project
DefaultDirName={autopf}\Fintel
DisableProgramGroupPage=yes
OutputDir=C:\Projects\dohaham\Installer
OutputBaseFilename=Fintel_Setup_v2
Compression=lzma
SolidCompression=yes
WizardStyle=modern

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"

[Files]
Source: "C:\Projects\dohaham\build\windows\x64\runner\Release\fintel.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "C:\Projects\dohaham\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\Fintel"; Filename: "{app}\fintel.exe"
Name: "{autodesktop}\Fintel"; Filename: "{app}\fintel.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\fintel.exe"; Description: "{cm:LaunchProgram,Fintel}"; Flags: nowait postinstall skipifsilent