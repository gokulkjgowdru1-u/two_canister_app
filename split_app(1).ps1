# =============================================================================
# split_app.ps1
# Run this from inside your project folder:
#   C:\Users\vijai\Desktop\zulu button app
#
# It patches lib\main.dart (adds a "forcedProject" option) and creates
# two new tiny entry files so you can run/build 2 CANISTER and 9 CANISTER
# as separate windows, without touching any other logic.
#
# Usage:
#   powershell -ExecutionPolicy Bypass -File split_app.ps1
# =============================================================================

$ErrorActionPreference = "Stop"

$mainPath = "lib\main.dart"

if (-not (Test-Path $mainPath)) {
    Write-Host "ERROR: $mainPath not found. Run this script from your project root (the folder containing 'lib\')." -ForegroundColor Red
    exit 1
}

Write-Host "Backing up original main.dart to lib\main.dart.bak ..." -ForegroundColor Cyan
Copy-Item $mainPath "lib\main.dart.bak" -Force

$content = Get-Content $mainPath -Raw
# Normalize CRLF to LF so our multi-line patterns match reliably,
# regardless of the file's original line endings.
$content = $content -replace "`r`n", "`n"

$patchesApplied = 0
$patchesSkipped = @()

function Apply-Patch {
    param(
        [string]$Find,
        [string]$Replace,
        [string]$Name
    )
    if ($script:content.Contains($Find)) {
        $script:content = $script:content.Replace($Find, $Replace)
        $script:patchesApplied++
        Write-Host "  [OK] $Name" -ForegroundColor Green
    } else {
        $script:patchesSkipped += $Name
        Write-Host "  [SKIP] $Name (pattern not found)" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "Applying patches to main.dart ..." -ForegroundColor Cyan

$find1 = "class HomePage extends StatefulWidget {`n  const HomePage({super.key});`n`n  @override`n  State<HomePage> createState() => _HomePageState();`n}"
$replace1 = "class HomePage extends StatefulWidget {`n  final int? forcedProject;`n  const HomePage({super.key, this.forcedProject});`n`n  @override`n  State<HomePage> createState() => _HomePageState();`n}"
Apply-Patch -Find $find1 -Replace $replace1 -Name "HomePage: add forcedProject param"

$find2 = "  int _selectedProject = 0;`n`n  @override`n  void initState() {`n    super.initState();`n    _bootstrap();`n  }"
$replace2 = "  late int _selectedProject;`n`n  @override`n  void initState() {`n    super.initState();`n    _selectedProject = widget.forcedProject ?? 0;`n    _bootstrap();`n  }"
Apply-Patch -Find $find2 -Replace $replace2 -Name "_HomePageState: initState respects forcedProject"

$find3 = "      body: Stack(`n        children: [`n          Row(`n            children: [`n              _buildSidebar(),`n              Expanded("
$replace3 = "      body: Stack(`n        children: [`n          Row(`n            children: [`n              if (widget.forcedProject == null) _buildSidebar(),`n              Expanded("
Apply-Patch -Find $find3 -Replace $replace3 -Name "build(): hide sidebar when forcedProject is set"

$find4 = "class PuneApp extends StatelessWidget {`n  const PuneApp({super.key});`n`n  @override`n  Widget build(BuildContext context) {`n    return MaterialApp(`n      title: 'Zulu Buttons',"
$replace4 = "class PuneApp extends StatelessWidget {`n  final int? forcedProject;`n  const PuneApp({super.key, this.forcedProject});`n`n  @override`n  Widget build(BuildContext context) {`n    return MaterialApp(`n      title: 'Zulu Buttons',"
Apply-Patch -Find $find4 -Replace $replace4 -Name "PuneApp: add forcedProject param"

$find5 = "      home: const HomePage(),"
$replace5 = "      home: HomePage(forcedProject: forcedProject),"
Apply-Patch -Find $find5 -Replace $replace5 -Name "PuneApp: pass forcedProject to HomePage"

$content = $content -replace "`n", "`r`n"
Set-Content -Path $mainPath -Value $content -NoNewline -Encoding UTF8

Write-Host ""
Write-Host "Creating lib\main_two_canister.dart ..." -ForegroundColor Cyan
$twoCanisterContent = "import 'package:flutter/material.dart';`r`nimport 'main.dart';`r`n`r`nvoid main() {`r`n  WidgetsFlutterBinding.ensureInitialized();`r`n  runApp(const PuneApp(forcedProject: 0));`r`n}`r`n"
Set-Content -Path "lib\main_two_canister.dart" -Value $twoCanisterContent -NoNewline -Encoding UTF8
Write-Host "  [OK] Created lib\main_two_canister.dart" -ForegroundColor Green

Write-Host ""
Write-Host "Creating lib\main_nine_canister.dart ..." -ForegroundColor Cyan
$nineCanisterContent = "import 'package:flutter/material.dart';`r`nimport 'main.dart';`r`n`r`nvoid main() {`r`n  WidgetsFlutterBinding.ensureInitialized();`r`n  runApp(const PuneApp(forcedProject: 1));`r`n}`r`n"
Set-Content -Path "lib\main_nine_canister.dart" -Value $nineCanisterContent -NoNewline -Encoding UTF8
Write-Host "  [OK] Created lib\main_nine_canister.dart" -ForegroundColor Green

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "Patches applied: $patchesApplied / 5" -ForegroundColor Cyan
if ($patchesSkipped.Count -gt 0) {
    Write-Host "Skipped patches:" -ForegroundColor Yellow
    foreach ($p in $patchesSkipped) {
        Write-Host "  - $p" -ForegroundColor Yellow
    }
    Write-Host ""
    Write-Host "If any were skipped, main.dart may differ from what this script expects." -ForegroundColor Yellow
    Write-Host "A backup was saved at lib\main.dart.bak -- you can restore it with:" -ForegroundColor Yellow
    Write-Host "  Copy-Item lib\main.dart.bak lib\main.dart -Force" -ForegroundColor Yellow
} else {
    Write-Host "All patches applied successfully!" -ForegroundColor Green
}
Write-Host "============================================================" -ForegroundColor Cyan

Write-Host ""
Write-Host "Now run either of these to launch each screen separately:" -ForegroundColor Cyan
Write-Host "  flutter run -d windows -t lib\main_two_canister.dart"
Write-Host "  flutter run -d windows -t lib\main_nine_canister.dart"
Write-Host ""
Write-Host "(Your original all-in-one entry point still works too: flutter run -d windows)"
