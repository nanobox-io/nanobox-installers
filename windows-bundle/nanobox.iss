#define MyAppName "Nanobox"
#define MyInstallerName "NanoboxSetup"
#define MyAppPublisher "Pagoda Box Inc."
#define MyAppURL "https://nanobox.io"
#define MyAppContact "https://nanobox.io"

#define nanobox "..\bundle\nanobox.exe"
#define nanoboxUpdater "..\bundle\nanobox-update.exe"
#define nanoboxVpn "..\bundle\nanobox-vpn.exe"
#define nanoboxMachine "..\bundle\nanobox-machine.exe"
#define virtualBoxCommon "..\bundle\common.cab"
#define virtualBoxMsi "..\bundle\VirtualBox_amd64.msi"
#define ansiconexe "..\bundle\ansicon.exe"
#define ansicon32 "..\bundle\ANSI32.dll"
#define ansicon64 "..\bundle\ANSI64.dll"
#define loggerdll "..\bundle\logger.dll"
#define srvstartdll "..\bundle\srvstart.dll"
#define srvstartexe "..\bundle\srvstart.exe"
#define oemvistainf "..\bundle\OemVista.inf"
#define tap0901cat "..\bundle\tap0901.cat"
#define tap0901sys "..\bundle\tap0901.sys"
#define tapinstallexe "..\bundle\tapinstall.exe"

[Setup]
AppCopyright={#MyAppPublisher}
AppId={#MyAppName}
AppContact={#MyAppContact}
AppComments={#MyAppURL}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
ArchitecturesAllowed=x64
ArchitecturesInstallIn64BitMode=x64
DefaultDirName={pf}\{#MyAppName}
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
DisableWelcomePage=no
OutputBaseFilename={#MyInstallerName}
Compression=lzma
SolidCompression=yes
WizardImageFile=windows-installer-side.bmp
WizardSmallImageFile=windows-installer-logo.bmp
WizardImageStretch=yes
UninstallDisplayIcon={app}\unins000.exe
SetupIconFile=nanobox.ico
ChangesEnvironment=true

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Types]
Name: "full"; Description: "Full installation"
Name: "custom"; Description: "Custom installation"; Flags: iscustom

[Tasks]
Name: modifypath; Description: "Add nanobox binaries to &PATH"
Name: upgradevm; Description: "Upgrade Boot2Docker VM"
Name: vbox_ndis5; Description: "Install VirtualBox with NDIS5 driver[default NDIS6]"; Components: VirtualBox; Flags: unchecked
Name: ansicon; Description: "Install ANSI escape sequences for console programs"

[Components]
Name: "Nanobox"; Description: "Nanobox for Windows" ; Types: full custom; Flags: fixed
Name: "VirtualBox"; Description: "VirtualBox"; Types: full custom; Flags: disablenouninstallwarning

[Files]
Source: "{#nanobox}"; DestDir: "{app}"; Flags: ignoreversion; Components: "Nanobox"
Source: "{#nanoboxUpdater}"; DestDir: "{app}"; Flags: ignoreversion; Components: "Nanobox"
Source: "{#nanoboxVpn}"; DestDir: "{app}"; Flags: ignoreversion; Components: "Nanobox"
Source: "{#nanoboxMachine}"; DestDir: "{app}"; Flags: ignoreversion; Components: "Nanobox"
Source: "{#virtualBoxCommon}"; DestDir: "{app}\installers\virtualbox"; Components: "VirtualBox"
Source: "{#virtualBoxMsi}"; DestDir: "{app}\installers\virtualbox"; DestName: "virtualbox.msi"; AfterInstall: RunInstallVirtualBox(); Components: "VirtualBox"
Source: "{#ansiconexe}"; DestDir: "{app}"; Components: "Nanobox"
Source: "{#ansicon32}"; DestDir: "{app}"; Components: "Nanobox"
Source: "{#ansicon64}"; DestDir: "{app}"; Components: "Nanobox"
Source: "{#loggerdll}"; DestDir: "{app}"; Components: "Nanobox"
Source: "{#srvstartdll}"; DestDir: "{app}"; Components: "Nanobox"
Source: "{#srvstartexe}"; DestDir: "{app}"; Components: "Nanobox"
Source: "{#oemvistainf}"; DestDir: "{app}"; Components: "Nanobox"
Source: "{#tap0901cat}"; DestDir: "{app}"; Components: "Nanobox"
Source: "{#tap0901sys}"; DestDir: "{app}"; Components: "Nanobox"
Source: "{#tapinstallexe}"; DestDir: "{app}"; Components: "Nanobox"

[UninstallRun]
Filename: "{app}\nanobox.exe"; Parameters: "implode"
Filename: "{app}\ansicon.exe"; Parameters: "-U"
Filename: "{app}\tapinstall.exe"; Parameters: "remove tap0901"

[Registry]
Root: HKCU; Subkey: "Environment"; ValueType:string; ValueName:"NANOBOX_INSTALL_PATH"; ValueData:"{app}" ; Flags: preservestringtype uninsdeletevalue;

[Code]
#include "base64.iss"
#include "guid.iss"

function uuid(): String;
var
  dirpath: String;
  filepath: String;
  ansiresult: AnsiString;
begin
  dirpath := ExpandConstant('{userappdata}\Nanobox');
  filepath := dirpath + '\id.txt';
  ForceDirectories(dirpath);

  Result := '';
  if FileExists(filepath) then
    LoadStringFromFile(filepath, ansiresult);
    Result := String(ansiresult)

  if Length(Result) = 0 then
    Result := GetGuid('');
    StringChangeEx(Result, '{', '', True);
    StringChangeEx(Result, '}', '', True);
    SaveStringToFile(filepath, AnsiString(Result), False);
end;

function WindowsVersionString(): String;
var
  ResultCode: Integer;
  lines : TArrayOfString;
begin
  if not Exec(ExpandConstant('{cmd}'), ExpandConstant('/c wmic os get caption | more +1 > C:\windows-version.txt'), '', SW_HIDE, ewWaitUntilTerminated, ResultCode) then begin
    Result := 'N/A';
    exit;
  end;

  if LoadStringsFromFile(ExpandConstant('C:\windows-version.txt'), lines) then begin
    Result := lines[0];
  end else begin
    Result := 'N/A'
  end;
end;

function NeedToInstallVirtualBox(): Boolean;
begin
  // TODO: Also compare versions
  Result := (
    (GetEnv('VBOX_INSTALL_PATH') = '')
    and
    (GetEnv('VBOX_MSI_INSTALL_PATH') = '')
  );
end;

function VBoxPath(): String;
begin
  if GetEnv('VBOX_INSTALL_PATH') <> '' then
    Result := GetEnv('VBOX_INSTALL_PATH')
  else
    Result := GetEnv('VBOX_MSI_INSTALL_PATH')
end;

procedure InitializeWizard;
var
  WelcomePage: TWizardPage;
begin

  WelcomePage := PageFromID(wpWelcome)

  WizardForm.WelcomeLabel2.AutoSize := True;

  Wizardform.ComponentsList.ItemEnabled[1] := not NeedToInstallVirtualBox();
end;

procedure RunInstallVirtualBox();
var
  ResultCode: Integer;
begin
  WizardForm.FilenameLabel.Caption := 'installing VirtualBox'
  if IsTaskSelected('vbox_ndis5') then begin
    if not Exec(ExpandConstant('msiexec'), ExpandConstant('/qn /i "{app}\installers\virtualbox\virtualbox.msi" NETWORKTYPE=NDIS5 /norestart'), '', SW_HIDE, ewWaitUntilTerminated, ResultCode) then
      MsgBox('virtualbox install failure', mbInformation, MB_OK);
  end else begin
    if not Exec(ExpandConstant('msiexec'), ExpandConstant('/qn /i "{app}\installers\virtualbox\virtualbox.msi" /norestart'), '', SW_HIDE, ewWaitUntilTerminated, ResultCode) then
      MsgBox('virtualbox install failure', mbInformation, MB_OK);
	end;
end;

function CanUpgradeVM(): Boolean;
var
  ResultCode: Integer;
begin
  if NeedToInstallVirtualBox() or not FileExists(ExpandConstant('{app}\nanobox-machine.exe')) then begin
    Result := false
    exit
  end;

  ExecAsOriginalUser(VBoxPath() + 'VBoxManage.exe', 'showvminfo default', '', SW_HIDE, ewWaitUntilTerminated, ResultCode)
  if ResultCode <> 0 then begin
    Result := false
    exit
  end;

  if not DirExists(ExpandConstant('{userdocs}\..\.docker\machine\machines\default')) then begin
    Result := false
    exit
  end;

  Result := true
end;

function UpgradeVM() : Boolean;
var
  ResultCode: Integer;
begin
  WizardForm.StatusLabel.Caption := 'Upgrading Docker Toolbox VM...'
  ExecAsOriginalUser(ExpandConstant('{app}\nanobox-machine.exe'), 'stop default', '', SW_HIDE, ewWaitUntilTerminated, ResultCode)
  if not ((ResultCode = 0) or (ResultCode = 1)) then
  begin
    MsgBox('VM Upgrade Failed because the VirtualBox VM could not be stopped.', mbCriticalError, MB_OK);
    Result := false
    WizardForm.Close;
    exit;
  end;
  Result := true
end;

const
  ModPathName = 'modifypath';
  ModPathType = 'user';

function ModPathDir(): TArrayOfString;
begin
  setArrayLength(Result, 1);
  Result[0] := ExpandConstant('{app}');
end;

procedure RunInstallAnsicon();
var
  ResultCode: Integer;
begin
  WizardForm.FilenameLabel.Caption := 'installing Ansicon'
  if not Exec(ExpandConstant('{app}\ansicon'), ExpandConstant('-I'), '', SW_HIDE, ewWaitUntilTerminated, ResultCode) then
    MsgBox('ansicon install failure', mbInformation, MB_OK);
end;

procedure RunInstallTapWindows();
var
  ExecStdout: AnsiString;
  ResultCode: Integer;
begin
  WizardForm.FilenameLabel.Caption := 'installing Tap Windows Driver'
  if Exec(ExpandConstant('{cmd}'), '/C "' + ExpandConstant('"{app}\tapinstall.exe"') + ' find tap0901 > ' + ExpandConstant('"{tmp}\taplist.txt"') + '"', '', SW_HIDE, ewWaitUntilTerminated, ResultCode) then
  begin
    if LoadStringFromFile(ExpandConstant('{tmp}\taplist.txt'), ExecStdout) then
    begin
      if Pos('No matching devices found', String(ExecStdout)) > 0 then
      begin
        if not Exec(ExpandConstant('{app}\tapinstall.exe'), ExpandConstant('install "{app}/OemVista.inf" tap0901'), '', SW_HIDE, ewWaitUntilTerminated, ResultCode) then
          MsgBox('Tap install failure', mbInformation, MB_OK);
      end;
    end;
  end;
end;

#include "modpath.iss"

procedure CurStepChanged(CurStep: TSetupStep);
var
  Success: Boolean;
begin
  Success := True;
  if CurStep = ssPostInstall then
  begin
    RunInstallTapWindows();
    if isTaskSelected('ansicon') then
      RunInstallAnsicon();
    if IsTaskSelected(ModPathName) then
      ModPath();
    if not WizardSilent() then
    begin
      if IsTaskSelected('upgradevm') then
      begin
        if CanUpgradeVM() then begin
          Success := UpgradeVM();
        end;
      end;
    end;
  end;
end;
