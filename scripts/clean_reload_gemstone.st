| packageNames organizer checks classNamesToForceRemove |
[
  organizer := (Smalltalk at: #RPackageOrganizer ifAbsent: [ nil ]).
  classNamesToForceRemove := OrderedCollection new.
  packageNames := #(
    'GemStone-Pharo-Tests'
    'GemStone-GBS-Tools'
    'GemStone-GBS-Converted'
  ).

  (Smalltalk at: #GbxOverrideUtility ifAbsent: [ nil ]) ifNotNil: [ :overrideUtility |
    [ overrideUtility removeOverridesForRelease ]
      on: Error
      do: [ :ex |
        Transcript
          show: 'UNLOAD_WARN overrides :: ';
          show: ex messageText;
          cr
      ] ].

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

  (Smalltalk at: #MCWorkingCopy ifAbsent: [ nil ]) ifNotNil: [ :workingCopyClass |
    workingCopyClass allWorkingCopies do: [ :workingCopy |
      (packageNames includes: workingCopy packageName)
        ifTrue: [
          [ workingCopy unregister ] on: Error do: [ :ex |
            Transcript
              show: 'UNLOAD_WARN working copy ';
              show: workingCopy packageName;
              show: ' :: ';
              show: ex messageText;
              cr
          ] ] ] ].

  [ Metacello new
      baseline: 'GemStonePharo';
      repository: 'tonel:///Users/tariq/src/gemtools/GemStone-Pharo-Bridge/src';
      load: 'default' ] on: Error do: [ :ex |
        Transcript show: 'LOAD_ERROR: ', ex messageText; cr ].

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
