; ============================================================
;  ReaAutoMIDITune v1.0.0 — NSIS Installer Script
;  Installs the JSFX plugin into the user's REAPER Effects dir.
;  Compatible with NSIS 3.x
; ============================================================

!define APP_NAME        "ReaAutoMIDITune"
!define APP_VERSION     "1.0.1"
!define APP_PUBLISHER   "FalconEYE Software Dev"
!define APP_URL         "https://github.com/FalconEYE"
!define JSFX_FILENAME   "ReaAutoMIDITune.jsfx"
!define UNINSTALL_KEY   "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}"

; ---- Metadata ----
Name            "${APP_NAME} ${APP_VERSION}"
OutFile         "..\dist\${APP_NAME}_Setup_v${APP_VERSION}.exe"
InstallDir      "$APPDATA\REAPER\Effects\FalconEYE"
InstallDirRegKey HKCU "Software\${APP_NAME}" "InstallDir"
RequestExecutionLevel user
SetCompressor   /SOLID lzma
BrandingText    "${APP_PUBLISHER}"

; ---- Modern UI ----
!include "MUI2.nsh"
!include "LogicLib.nsh"
!include "FileFunc.nsh"

!define MUI_ICON                    "..\assets\icon.ico"
!define MUI_UNICON                  "..\assets\icon.ico"
!define MUI_WELCOMEFINISHPAGE_BITMAP "..\assets\banner.bmp"
!define MUI_HEADERIMAGE
!define MUI_HEADERIMAGE_BITMAP      "..\assets\header.bmp"
!define MUI_HEADERIMAGE_RIGHT

!define MUI_ABORTWARNING
!define MUI_FINISHPAGE_RUN
!define MUI_FINISHPAGE_RUN_TEXT     "Open REAPER after installation"
!define MUI_FINISHPAGE_RUN_FUNCTION OpenReaper
!define MUI_FINISHPAGE_LINK         "Visit FalconEYE Software Dev"
!define MUI_FINISHPAGE_LINK_LOCATION "${APP_URL}"

; ---- Pages ----
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_LICENSE       "..\LICENSE.txt"
Page custom DirectoryPage DirectoryPageLeave
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES

; ---- Language ----
!insertmacro MUI_LANGUAGE "English"

; ============================================================
;  Custom Directory Page — auto-detect REAPER Effects folder
; ============================================================
Var REAPEREffectsDir
Var CustomDirDialog

Function .onInit
  ; Try to locate REAPER install path from registry
  ReadRegStr $0 HKCU "Software\REAPER" "InstallPath"
  StrCmp $0 "" TryHKLM FoundPath
  TryHKLM:
    ReadRegStr $0 HKLM "Software\REAPER" "InstallPath"
  FoundPath:
  StrCmp $0 "" UseDefault
    StrCpy $REAPEREffectsDir "$APPDATA\REAPER\Effects\FalconEYE"
    Goto Done
  UseDefault:
    StrCpy $REAPEREffectsDir "$APPDATA\REAPER\Effects\FalconEYE"
  Done:
  StrCpy $INSTDIR $REAPEREffectsDir
FunctionEnd

Function DirectoryPage
  nsDialogs::Create 1018
  Pop $CustomDirDialog
  
  ${NSD_CreateLabel} 0 0 100% 20u "Install ${JSFX_FILENAME} into REAPER Effects folder:"
  Pop $0
  ${NSD_CreateDirRequest} 0 25u 80% 12u $INSTDIR
  Pop $1
  ${NSD_CreateBrowseButton} 82% 24u 18% 14u "Browse..."
  Pop $2
  ${NSD_OnClick} $2 BrowseCallback
  ${NSD_CreateLabel} 0 45u 100% 30u \
    "Default location: %APPDATA%\REAPER\Effects\FalconEYE$\r$\n\
     The FalconEYE subfolder will be created automatically.$\r$\n\
     After install, add the plugin to any MIDI track's FX chain."
  Pop $3
  
  nsDialogs::Show
FunctionEnd

Function BrowseCallback
  Pop $0
  nsDialogs::SelectFolderDialog "Select your REAPER Effects folder" $INSTDIR
  Pop $1
  ${If} $1 != "error"
    ${NSD_SetText} $0 $1
  ${EndIf}
FunctionEnd

Function DirectoryPageLeave
  ; Read whatever the user typed/chose
  FindWindow $0 "#32770" "" $HWNDPARENT
  GetDlgItem $1 $0 1019  ; dir request control ID from nsDialogs
  System::Call 'user32::GetWindowText(i $1, t .r2, i 256)'
  StrCmp $2 "" 0 +2
    StrCpy $2 $INSTDIR
  StrCpy $INSTDIR $2
FunctionEnd

; ============================================================
;  Main Install Section
; ============================================================
Section "Core Plugin (required)" SecCore
  SectionIn RO

  SetOutPath "$INSTDIR"
  File "..\${JSFX_FILENAME}"

  ; Write uninstaller
  WriteUninstaller "$INSTDIR\Uninstall_${APP_NAME}.exe"

  ; Registry entries
  WriteRegStr   HKCU "${UNINSTALL_KEY}" "DisplayName"     "${APP_NAME} ${APP_VERSION}"
  WriteRegStr   HKCU "${UNINSTALL_KEY}" "UninstallString" "$INSTDIR\Uninstall_${APP_NAME}.exe"
  WriteRegStr   HKCU "${UNINSTALL_KEY}" "DisplayVersion"  "${APP_VERSION}"
  WriteRegStr   HKCU "${UNINSTALL_KEY}" "Publisher"       "${APP_PUBLISHER}"
  WriteRegStr   HKCU "${UNINSTALL_KEY}" "URLInfoAbout"    "${APP_URL}"
  WriteRegStr   HKCU "${UNINSTALL_KEY}" "InstallLocation" "$INSTDIR"
  WriteRegDWORD HKCU "${UNINSTALL_KEY}" "NoModify"        1
  WriteRegDWORD HKCU "${UNINSTALL_KEY}" "NoRepair"        1

  ; Estimate size
  ${GetSize} "$INSTDIR" "/S=0K" $0 $1 $2
  IntFmt $0 "0x%08X" $0
  WriteRegDWORD HKCU "${UNINSTALL_KEY}" "EstimatedSize" "$0"

  ; Record install dir for next run
  WriteRegStr HKCU "Software\${APP_NAME}" "InstallDir" "$INSTDIR"
SectionEnd

; ============================================================
;  Finish Page — optionally launch REAPER
; ============================================================
Function OpenReaper
  ReadRegStr $0 HKCU "Software\REAPER" "InstallPath"
  StrCmp $0 "" TryHKLM2 DoLaunch
  TryHKLM2:
    ReadRegStr $0 HKLM "Software\REAPER" "InstallPath"
  DoLaunch:
  StrCmp $0 "" +2
    Exec '"$0\reaper.exe"'
FunctionEnd

; ============================================================
;  Uninstaller
; ============================================================
Section "Uninstall"
  Delete "$INSTDIR\${JSFX_FILENAME}"
  Delete "$INSTDIR\Uninstall_${APP_NAME}.exe"
  RMDir  "$INSTDIR"

  DeleteRegKey HKCU "${UNINSTALL_KEY}"
  DeleteRegKey HKCU "Software\${APP_NAME}"
SectionEnd

; ============================================================
;  Section Descriptions  (future: add MUI_PAGE_COMPONENTS
;  and uncomment the block below to show per-section tooltips)
; ============================================================
; LangString DESC_SecCore ${LANG_ENGLISH} "..."
; !insertmacro MUI_FUNCTION_DESCRIPTION_BEGIN
;   !insertmacro MUI_DESCRIPTION_TEXT ${SecCore} $(DESC_SecCore)
; !insertmacro MUI_FUNCTION_DESCRIPTION_END
