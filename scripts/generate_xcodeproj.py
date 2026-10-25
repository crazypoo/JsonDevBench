#!/usr/bin/env python3
"""Generate a minimal, self-contained Xcode 15+ macOS SwiftUI project."""
from pathlib import Path
from hashlib import sha1
R=Path(__file__).resolve().parent.parent
files=sorted(str(p.relative_to(R/'DevBench')) for p in (R/'DevBench').rglob('*.swift'))
def ID(name): return sha1(name.encode()).hexdigest().upper()[:24]
root=ID('group.root'); app=ID('group.DevBench'); products=ID('group.products')
groups={name: ID('group.'+name) for name in ['App','Core','UI']}
proj=ID('project'); target=ID('target'); product=ID('product')
sources=ID('sources'); resources=ID('resources'); frameworks=ID('frameworks'); asset=ID('asset')
pconfig=ID('project.config'); tconfig=ID('target.config'); pdbg=ID('project.Debug'); prel=ID('project.Release'); tdbg=ID('target.Debug'); trel=ID('target.Release')
objects=[]
def add(i, body): objects.append(f'\t\t{i} = {{ {body} }};')
def ls(items): return '( ' + ', '.join(items) + ', )' if items else '()'
for f in files:
    name=Path(f).name
    add(ID('file.'+f), f'isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = "{name}"; sourceTree = "<group>";')
    add(ID('build.'+f), f'isa = PBXBuildFile; fileRef = {ID("file."+f)};')
add(asset, 'isa = PBXFileReference; lastKnownFileType = folder.assetcatalog; path = Assets.xcassets; sourceTree = "<group>";')
add(ID('asset.build'),f'isa = PBXBuildFile; fileRef = {asset};')
add(product, 'isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = DevBench.app; sourceTree = BUILT_PRODUCTS_DIR;')
for name,g in groups.items():
    children=[ID('file.'+f) for f in files if f.startswith(name+'/')]
    add(g, f'isa = PBXGroup; children = {ls(children)}; path = {name}; sourceTree = "<group>";')
add(app, f'isa = PBXGroup; children = {ls([groups["App"],groups["Core"],groups["UI"],asset])}; path = DevBench; sourceTree = "<group>";')
add(products, f'isa = PBXGroup; children = {ls([product])}; name = Products; sourceTree = "<group>";')
add(root, f'isa = PBXGroup; children = {ls([app, products])}; sourceTree = "<group>";')
add(sources, f'isa = PBXSourcesBuildPhase; buildActionMask = 2147483647; files = {ls([ID("build."+f) for f in files])}; runOnlyForDeploymentPostprocessing = 0;')
add(resources, f'isa = PBXResourcesBuildPhase; buildActionMask = 2147483647; files = {ls([ID("asset.build")])}; runOnlyForDeploymentPostprocessing = 0;')
add(frameworks, 'isa = PBXFrameworksBuildPhase; buildActionMask = 2147483647; files = (); runOnlyForDeploymentPostprocessing = 0;')
add(target, f'''isa = PBXNativeTarget; buildConfigurationList = {tconfig}; buildPhases = {ls([sources,frameworks,resources])}; buildRules = (); dependencies = (); name = DevBench; productName = DevBench; productReference = {product}; productType = "com.apple.product-type.application";''')
add(proj, f'''isa = PBXProject; attributes = {{ BuildIndependentTargetsInParallel = 1; LastUpgradeCheck = 1600; TargetAttributes = {{ {target} = {{ CreatedOnToolsVersion = 16.0; }}; }}; }}; buildConfigurationList = {pconfig}; compatibilityVersion = "Xcode 14.0"; developmentRegion = zh-Hans; hasScannedForEncodings = 0; knownRegions = ( en, "zh-Hans", Base, ); mainGroup = {root}; productRefGroup = {products}; projectDirPath = ""; projectRoot = ""; targets = {ls([target])};''')
add(pconfig, f'isa = XCConfigurationList; buildConfigurations = {ls([pdbg,prel])}; defaultConfigurationIsVisible = 0; defaultConfigurationName = Release;')
add(tconfig, f'isa = XCConfigurationList; buildConfigurations = {ls([tdbg,trel])}; defaultConfigurationIsVisible = 0; defaultConfigurationName = Release;')
add(pdbg, 'isa = XCBuildConfiguration; buildSettings = { ALWAYS_SEARCH_USER_PATHS = NO; CLANG_ENABLE_MODULES = YES; MACOSX_DEPLOYMENT_TARGET = 13.0; SDKROOT = macosx; SWIFT_VERSION = 5.0; }; name = Debug;')
add(prel, 'isa = XCBuildConfiguration; buildSettings = { ALWAYS_SEARCH_USER_PATHS = NO; CLANG_ENABLE_MODULES = YES; MACOSX_DEPLOYMENT_TARGET = 13.0; SDKROOT = macosx; SWIFT_VERSION = 5.0; }; name = Release;')
for name, ident, debug in [('Debug',tdbg,True),('Release',trel,False)]:
    settings = f'''ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon; CODE_SIGNING_ALLOWED = NO; CODE_SIGN_STYLE = Automatic; CURRENT_PROJECT_VERSION = 1; ENABLE_APP_SANDBOX = NO; GENERATE_INFOPLIST_FILE = YES; INFOPLIST_KEY_CFBundleDisplayName = DevBench; INFOPLIST_KEY_LSApplicationCategoryType = "public.app-category.developer-tools"; LD_RUNPATH_SEARCH_PATHS = "$(inherited) @executable_path/../Frameworks"; MACOSX_DEPLOYMENT_TARGET = 13.0; MARKETING_VERSION = 0.1.1; PRODUCT_BUNDLE_IDENTIFIER = "com.example.devbench"; PRODUCT_NAME = "$(TARGET_NAME)"; SDKROOT = macosx; SUPPORTED_PLATFORMS = macosx; SWIFT_STRICT_CONCURRENCY = minimal; SWIFT_VERSION = 5.0; SWIFT_OPTIMIZATION_LEVEL = { '"-Onone"' if debug else '"-O"' };'''
    add(ident, f'isa = XCBuildConfiguration; buildSettings = {{ {settings} }}; name = {name};')
content = f'''// !$*UTF8*$!\n{{\n archiveVersion = 1;\n classes = {{ }};\n objectVersion = 56;\n objects = {{\n{chr(10).join(objects)}\n }};\n rootObject = {proj};\n}}\n'''
(R/'DevBench.xcodeproj'/'project.pbxproj').write_text(content)
print(f'Generated Xcode project with {len(files)} Swift files')

# Keep the scheme shared and reproducible so xcodebuild -scheme DevBench works on CI
# without requiring Xcode to auto-create a user-specific scheme.
scheme = f'''<?xml version="1.0" encoding="UTF-8"?>
<Scheme LastUpgradeVersion="1600" version="1.7">
  <BuildAction parallelizeBuildables="YES" buildImplicitDependencies="YES">
    <BuildActionEntries>
      <BuildActionEntry buildForTesting="YES" buildForRunning="YES" buildForProfiling="YES" buildForArchiving="YES" buildForAnalyzing="YES">
        <BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{target}" BuildableName="DevBench.app" BlueprintName="DevBench" ReferencedContainer="container:DevBench.xcodeproj"/>
      </BuildActionEntry>
    </BuildActionEntries>
  </BuildAction>
  <TestAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" shouldUseLaunchSchemeArgsEnv="YES">
    <Testables/>
  </TestAction>
  <LaunchAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" launchStyle="0" useCustomWorkingDirectory="NO" ignoresPersistentStateOnLaunch="NO" debugDocumentVersioning="YES" debugServiceExtension="internal" allowLocationSimulation="YES">
    <BuildableProductRunnable runnableDebuggingMode="0">
      <BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{target}" BuildableName="DevBench.app" BlueprintName="DevBench" ReferencedContainer="container:DevBench.xcodeproj"/>
    </BuildableProductRunnable>
  </LaunchAction>
  <ProfileAction buildConfiguration="Release" shouldUseLaunchSchemeArgsEnv="YES" savedToolIdentifier="" useCustomWorkingDirectory="NO" debugDocumentVersioning="YES">
    <BuildableProductRunnable runnableDebuggingMode="0">
      <BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{target}" BuildableName="DevBench.app" BlueprintName="DevBench" ReferencedContainer="container:DevBench.xcodeproj"/>
    </BuildableProductRunnable>
  </ProfileAction>
  <AnalyzeAction buildConfiguration="Debug"/>
  <ArchiveAction buildConfiguration="Release" revealArchiveInOrganizer="YES"/>
</Scheme>
'''
scheme_dir = R/'DevBench.xcodeproj'/'xcshareddata'/'xcschemes'
scheme_dir.mkdir(parents=True, exist_ok=True)
(scheme_dir/'DevBench.xcscheme').write_text(scheme, encoding='utf-8')
