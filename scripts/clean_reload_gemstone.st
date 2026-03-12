| packageNames organizer checks classNamesToForceRemove |
[
  organizer := (Smalltalk at: #RPackageOrganizer ifAbsent: [ nil ]).
  classNamesToForceRemove := OrderedCollection new.
  packageNames := #(
    'GemStone-Pharo-Tests'
    'GemStone-GBS-Tools'
    'GemStone-GBS-Converted'
  ).

  organizer ifNotNil: [
    packageNames do: [ :pkgName |
      | pkg |
      pkg := [ organizer default packageNamed: pkgName ] on: Error do: [ nil ].
      pkg ifNotNil: [
        [ pkg definedClasses do: [ :eachClass |
            classNamesToForceRemove add: eachClass name ] ]
          on: Error
          do: [ :ex |
            Transcript
              show: 'UNLOAD_WARN ';
              show: pkgName;
              show: ' classes :: ';
              show: ex messageText;
              cr
          ].
        [ pkg removeFromSystem ] on: Error do: [ :ex |
          Transcript
            show: 'UNLOAD_WARN ';
            show: pkgName;
            show: ' :: ';
            show: ex messageText;
            cr
        ].
      ].
    ].
  ].

  classNamesToForceRemove asSet do: [ :className |
    | cls |
    cls := Smalltalk at: className asSymbol ifAbsent: [ nil ].
    cls ifNotNil: [
      [ cls removeFromSystem ] on: Error do: [ :ex |
        Transcript
          show: 'UNLOAD_WARN class ';
          show: className;
          show: ' :: ';
          show: ex messageText;
          cr
      ].
    ].
  ].

  [ Metacello new
      baseline: 'GemStonePharo';
      repository: 'tonel:///Users/tariq/src/gemtools/GemStone-Pharo-Bridge/src';
      load: 'default' ] on: Error do: [ :ex |
        Transcript show: 'LOAD_ERROR: ', ex messageText; cr ].

  "Force-apply key Tonel definitions to avoid stale cached method bodies
  in long-lived images (observed for GbxDebuggerService)."
  #(
    '/Users/tariq/src/gemtools/GemStone-Pharo-Bridge/src/GemStone-GBS-Tools/GbxDebuggerService.class.st'
    '/Users/tariq/src/gemtools/GemStone-Pharo-Bridge/src/GemStone-GBS-Tools/GbsRemoteDebugger.class.st'
    '/Users/tariq/src/gemtools/GemStone-Pharo-Bridge/src/GemStone-GBS-Tools/GbsConnectorBrowserPresenter.class.st'
    '/Users/tariq/src/gemtools/GemStone-Pharo-Bridge/src/GemStone-GBS-Tools/GbsCreateUserPresenter.class.st'
    '/Users/tariq/src/gemtools/GemStone-Pharo-Bridge/src/GemStone-GBS-Tools/GbsSecurityPoliciesPresenter.class.st'
    '/Users/tariq/src/gemtools/GemStone-Pharo-Bridge/src/GemStone-GBS-Tools/GbsSymbolListBrowserPresenter.class.st'
    '/Users/tariq/src/gemtools/GemStone-Pharo-Bridge/src/GemStone-GBS-Tools/GbsUserInfoPresenter.class.st'
    '/Users/tariq/src/gemtools/GemStone-Pharo-Bridge/src/GemStone-GBS-Tools/GbsNamespacesPresenter.class.st'
    '/Users/tariq/src/gemtools/GemStone-Pharo-Bridge/src/GemStone-GBS-Converted/GbsConfiguration.class.st'
    '/Users/tariq/src/gemtools/GemStone-Pharo-Bridge/src/GemStone-GBS-Converted/GbsConnectorGroup.class.st'
    '/Users/tariq/src/gemtools/GemStone-Pharo-Bridge/src/GemStone-GBS-Converted/GbsSessionManager.class.st'
    '/Users/tariq/src/gemtools/GemStone-Pharo-Bridge/src/GemStone-Pharo-Tests/GbxFakeGbsErrorForService.class.st'
    '/Users/tariq/src/gemtools/GemStone-Pharo-Bridge/src/GemStone-Pharo-Tests/GbxFakeActivationForService.class.st'
    '/Users/tariq/src/gemtools/GemStone-Pharo-Bridge/src/GemStone-Pharo-Tests/GbxFakeContextListPolicyForService.class.st'
    '/Users/tariq/src/gemtools/GemStone-Pharo-Bridge/src/GemStone-Pharo-Tests/GbsTestableUserListPresenter.class.st'
    '/Users/tariq/src/gemtools/GemStone-Pharo-Bridge/src/GemStone-Pharo-Tests/GbxDebuggerServiceTest.class.st'
    '/Users/tariq/src/gemtools/GemStone-Pharo-Bridge/src/GemStone-Pharo-Tests/GbsAdminToolsPresenterTest.class.st'
  ) do: [ :pathString |
    | file defs |
    file := pathString asFileReference.
    file exists ifTrue: [
      [ defs := TonelReader new parseTonelFile: file.
      defs do: [ :def | def load ] ]
        on: Error
        do: [ :ex |
          Transcript
            show: 'FORCE_LOAD_WARN ';
            show: file basename;
            show: ' :: ';
            show: ex messageText;
            cr
        ].
    ].
  ].

  checks := {
    { #GbxDebuggerService. #basicReenterServerContext. 'self selectTopServerContext'. false }.
    { #GbxDebuggerService. #restartLevelFromServerStack. 'respondsTo: #splitOn:'. false }.
    { #GbxDebuggerService. #cutbackToGsProcessOf:. 'terminateProcess'. false }.
    { #GbxDebuggerService. #restartLevelFromServerStack. 'respondsTo: [ #splitOn: ] asSymbol'. true }.
    { #GbxDebuggerService. #basicReenterServerContext. 'Identify the target context for restart'. true }
  }.

  checks do: [ :triple |
    | cls sel snippet mustBeAbsent cm src hasSnippet |
    cls := Smalltalk at: triple first ifAbsent: [ nil ].
    sel := triple second.
    snippet := triple third.
    mustBeAbsent := triple fourth.
    (cls isNil or: [ (cls includesSelector: sel) not ]) ifTrue: [
      Transcript show: 'CHECK_MISSING '; show: triple first asString; show: '>>#'; show: sel asString; cr.
    ] ifFalse: [
      cm := cls >> sel.
      src := cm sourceCode ifNil: [ '' ].
      hasSnippet := src includesSubstring: snippet.
      ((mustBeAbsent and: [ hasSnippet ]) or: [ mustBeAbsent not and: [ hasSnippet not ] ])
        ifTrue: [
          Transcript
            show: 'CHECK_FAIL ';
            show: triple first asString;
            show: '>>#';
            show: sel asString;
            show: (mustBeAbsent ifTrue: [ ' contains forbidden ' ] ifFalse: [ ' missing expected ' ]);
            show: snippet;
            cr
        ]
        ifFalse: [
          Transcript
            show: 'CHECK_OK ';
            show: triple first asString;
            show: '>>#';
            show: sel asString;
            cr
        ].
    ].
  ].

  Transcript show: 'CLEAN_RELOAD_DONE'; cr.
] ensure: [ Smalltalk snapshot: true andQuit: true ].
