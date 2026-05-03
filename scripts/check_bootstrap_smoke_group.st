| logLine contract runnerClass loadGroup groupSpec requiredPackages workingCopyClass loadedPackages helperClasses missingPackages missingHelpers |

logLine := [ :line |
	Transcript show: line; cr ].

contract := Smalltalk at: #GemStonePharoContract ifAbsent: [ nil ].
runnerClass := Smalltalk at: #GemStonePharoReloadRunner ifAbsent: [ nil ].

(contract isNil or: [ runnerClass isNil ]) ifTrue: [
	logLine value: 'BOOTSTRAP_SMOKE_FAIL missing helper classes'.
	logLine value: 'BOOTSTRAP_SMOKE_FAILED'.
	Smalltalk snapshot: false andQuit: true ].

loadGroup := runnerClass loadGroupNameFromEnvironment: Smalltalk os environment.
groupSpec := contract new groupMemberSpecs
	detect: [ :each | each first = loadGroup ]
	ifNone: [ nil ].
requiredPackages := groupSpec
	ifNil: [ #() ]
	ifNotNil: [ groupSpec second ].
workingCopyClass := Smalltalk at: #MCWorkingCopy ifAbsent: [ nil ].
loadedPackages := workingCopyClass
	ifNil: [ #() asSet ]
	ifNotNil: [ (workingCopyClass allWorkingCopies collect: [ :each | each packageName ]) asSet ].
helperClasses := #(
	#BaselineOfGemStonePharo
	#GemStonePharoContract
	#GemStonePharoReloadBootstrapper
	#GemStonePharoReloadRunner
	#GemStonePharoReloadGuards
	#GemStonePharoLaneRunner).
missingHelpers := helperClasses reject: [ :each | Smalltalk includesKey: each ].
missingPackages := requiredPackages reject: [ :each | loadedPackages includes: each ].

missingHelpers isEmpty
	ifTrue: [ logLine value: 'BOOTSTRAP_SMOKE_HELPERS_OK' ]
	ifFalse: [
		logLine value: 'BOOTSTRAP_SMOKE_FAIL missing helpers: ', missingHelpers asArray printString.
		logLine value: 'BOOTSTRAP_SMOKE_FAILED'.
		Smalltalk snapshot: false andQuit: true ].

missingPackages isEmpty
	ifTrue: [
		requiredPackages do: [ :each |
			logLine value: 'BOOTSTRAP_SMOKE_PACKAGE_OK ', each ].
		logLine value: 'BOOTSTRAP_SMOKE_OK load_group=', loadGroup ]
	ifFalse: [
		logLine value: 'BOOTSTRAP_SMOKE_FAIL missing packages: ', missingPackages asArray printString.
		logLine value: 'BOOTSTRAP_SMOKE_FAILED' ].

Smalltalk snapshot: false andQuit: true.
