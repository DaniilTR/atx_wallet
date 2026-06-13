; Inno Setup script for packaging Flutter Windows build into an installer.
; Требование: сначала соберите приложение: flutter build windows --release
;
; Сборка лежит в: ..\..\build\windows\x64\runner\Release\

#define MyAppName "ATX Wallet"
#define MyAppVersion "1.0.3"
#define MyAppPublisher ""
#define MyAppExeName "atx_wallet.exe"

[Setup]
AppId={{B3C2A5A1-2A77-4D18-9B2A-1BC8B6C6BE0E}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
OutputDir={#SourcePath}
OutputBaseFilename=atx_wallet_setup_{#MyAppVersion}
SetupIconFile=..\..\windows\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\{#MyAppExeName}
Compression=lzma
SolidCompression=yes
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible

[Languages]
Name: "ru"; MessagesFile: "compiler:Languages\Russian.isl"

[Tasks]
Name: "desktopicon"; Description: "Создать значок на рабочем столе"; GroupDescription: "Значки:"; Flags: unchecked

[Files]
; Упаковываем ВСЮ папку релиза (exe, dll, data\ и т.д.)
Source: "..\..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "Запустить {#MyAppName}"; Flags: nowait postinstall skipifsilent
