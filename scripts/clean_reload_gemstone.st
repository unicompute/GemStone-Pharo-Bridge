| packageNames organizer checks |
[
  organizer := (Smalltalk at: #RPackageOrganizer ifAbsent: [ nil ]).
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

  [ Metacello new
      baseline: 'GemStonePharo';
      repository: 'tonel:///Users/tariq/src/gemtools/GemStone-Pharo-Bridge/src';
      load: 'default' ] on: Error do: [ :ex |
        Transcript show: 'LOAD_ERROR: ', ex messageText; cr ].

  checks := {
    { #GbxDebuggerService. #inspectVariableNamed:. 'withBlanksTrimmed' }.
    { #GbxFakeServiceForRemoteDebugger. #inspectCurrentReceiver. 'raiseOnInspectReceiver ifTrue:' }.
    { #GbxFakeServiceForRemoteDebugger. #initialize. 'recompileShouldSucceed' }
  }.

  checks do: [ :triple |
    | cls sel forbidden cm src |
    cls := Smalltalk at: triple first ifAbsent: [ nil ].
    sel := triple second.
    forbidden := triple third.
    (cls isNil or: [ (cls includesSelector: sel) not ]) ifTrue: [
      Transcript show: 'CHECK_MISSING '; show: triple first asString; show: '>>#'; show: sel asString; cr.
    ] ifFalse: [
      cm := cls >> sel.
      src := cm sourceCode ifNil: [ '' ].
      (src includesSubstring: forbidden)
        ifTrue: [
          Transcript
            show: 'CHECK_FAIL ';
            show: triple first asString;
            show: '>>#';
            show: sel asString;
            show: ' contains ';
            show: forbidden;
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
