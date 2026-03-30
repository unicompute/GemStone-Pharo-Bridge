Class {
	#name : 'GbxOverrideUtility',
	#superclass : 'Object',
	#classInstVars : [
		'InstalledClassOverrides',
		'InstalledMethodOverrides'
	],
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'applying' }
GbxOverrideUtility class >> applyOverrideSet: anOverrideSet [
	(anOverrideSet isNil or: [ anOverrideSet hasNoEffect ]) ifTrue: [ ^ nil ].
	anOverrideSet allOverridesInPackage isEmpty ifFalse: [
		OverrideFailureWarning
			raiseSignal: 'Overrides not applied for ', anOverrideSet packageName,
				'. There are already overrides loaded in the image.'.
		^ nil ].
	^ anOverrideSet apply
		ifTrue: [ anOverrideSet ]
		ifFalse: [ nil ]
]

{ #category : 'accessing' }
GbxOverrideUtility class >> allOverridesInPackage: aPackage [
	| packageName result |
	packageName := self packageNameOf: aPackage.
	packageName isEmpty ifTrue: [ ^ #() ].
	result := OrderedCollection new.
	(self installedClassOverrides at: packageName ifAbsent: [ Dictionary new ]) valuesDo: [ :metadata |
		| behavior currentInstVarString |
		behavior := self behaviorFromMetadata: metadata.
		behavior ifNotNil: [
			currentInstVarString := self instVarStringFor: behavior.
			result add: (GbxClassOverride
				behavior: behavior
				from: (metadata at: #originalInstVarString)
				to: currentInstVarString) ] ].
	(self installedMethodOverrides at: packageName ifAbsent: [ Dictionary new ]) valuesDo: [ :metadata |
		| behavior compiledMethod |
		behavior := self behaviorFromMetadata: metadata.
		behavior ifNotNil: [
			compiledMethod := behavior
				compiledMethodAt: (metadata at: #selector)
				ifAbsent: [ nil ].
			compiledMethod ifNotNil: [
				result add: (GbxMethodOverride
					behavior: behavior
					selector: (metadata at: #selector)
					from: (metadata at: #originalSource)
					to: compiledMethod sourceCode asString) ] ] ].
	result sort: [ :left :right | left printString <= right printString ].
	^ result
]

{ #category : 'registry' }
GbxOverrideUtility class >> behaviorFromMetadata: metadata [
	| behaviorName baseBehavior |
	behaviorName := metadata at: #behaviorName ifAbsent: [ ^ nil ].
	baseBehavior := Smalltalk globals at: behaviorName asSymbol ifAbsent: [ ^ nil ].
	^ (metadata at: #isMeta ifAbsent: [ false ])
		ifTrue: [ baseBehavior classSide ]
		ifFalse: [ baseBehavior ]
]

{ #category : 'registry' }
GbxOverrideUtility class >> clearInstalledOverrideMetadata [
	InstalledClassOverrides := Dictionary new.
	InstalledMethodOverrides := Dictionary new
]

{ #category : 'registry' }
GbxOverrideUtility class >> clearInstalledOverrideMetadataForPackageName: aPackageName [
	| packageName |
	packageName := self packageNameOf: aPackageName.
	self installedClassOverrides removeKey: packageName ifAbsent: [ ].
	self installedMethodOverrides removeKey: packageName ifAbsent: [ ]
]

{ #category : 'utilities' }
GbxOverrideUtility class >> compileSpecMethodFor: anOverrideSet in: specClass [
	^ self
		compileSpecSource: (self specMethodSourceFor: anOverrideSet in: specClass)
		inClass: specClass
		oldSource: specClass specMethodSource
]

{ #category : 'utilities' }
GbxOverrideUtility class >> compileSpecSource: newSource inClass: specClass oldSource: oldSource [
	newSource = oldSource ifTrue: [ ^ false ].
	specClass class compile: newSource classified: 'generated'.
	^ true
]

{ #category : 'utilities' }
GbxOverrideUtility class >> crc32OfString: aString [
	| crc polynomial bytes |
	polynomial := 16rEDB88320.
	bytes := (aString isKindOf: ByteArray)
		ifTrue: [ aString ]
		ifFalse: [ aString asString asGemStoneUTF8Bytes ].
	crc := 16rFFFFFFFF.
	bytes do: [ :byte |
		crc := (crc bitXor: byte asInteger) bitAnd: 16rFFFFFFFF.
		1 to: 8 do: [ :ignored |
			crc := ((crc bitAnd: 1) = 1
				ifTrue: [ ((crc bitShift: -1) bitXor: polynomial) ]
				ifFalse: [ crc bitShift: -1 ]) bitAnd: 16rFFFFFFFF ] ].
	^ (crc bitXor: 16rFFFFFFFF) bitAnd: 16rFFFFFFFF
]

{ #category : 'utilities' }
GbxOverrideUtility class >> generateOverrideSpecs [
	| generated |
	generated := false.
	self overrideSpecClasses do: [ :specClass |
		| overrideSet |
		overrideSet := GbxOverrideSet fromPackage: specClass overridesPackage.
		overrideSet hasEffect ifTrue: [
			generated := (self compileSpecMethodFor: overrideSet in: specClass) or: [ generated ] ] ].
	^ generated
]

{ #category : 'registry' }
GbxOverrideUtility class >> installedClassOverrides [
	^ InstalledClassOverrides ifNil: [ InstalledClassOverrides := Dictionary new ]
]

{ #category : 'registry' }
GbxOverrideUtility class >> installedClassOverridesForPackageName: aPackageName [
	^ self installedClassOverrides
		at: aPackageName
		ifAbsentPut: [ Dictionary new ]
]

{ #category : 'registry' }
GbxOverrideUtility class >> installedMethodOverrides [
	^ InstalledMethodOverrides ifNil: [ InstalledMethodOverrides := Dictionary new ]
]

{ #category : 'registry' }
GbxOverrideUtility class >> installedMethodOverridesForPackageName: aPackageName [
	^ self installedMethodOverrides
		at: aPackageName
		ifAbsentPut: [ Dictionary new ]
]

{ #category : 'registry' }
GbxOverrideUtility class >> instVarStringFor: aBehavior [
	^ String streamContents: [ :stream |
		aBehavior instVarNames
			do: [ :each | stream nextPutAll: each asString ]
			separatedBy: [ stream space ] ]
]

{ #category : 'registry' }
GbxOverrideUtility class >> methodKeyForBehavior: aBehavior selector: aSelector [
	^ Array
		with: aBehavior instanceSide name asString
		with: aBehavior isMeta
		with: aSelector
]

{ #category : 'registry' }
GbxOverrideUtility class >> noteInstalledClassOverride: aClassOverride originalInstVarString: instVarString originalPackageName: originalPackageName [
	| packageName key existing metadata |
	packageName := self packageNameOf: aClassOverride package.
	packageName isEmpty ifTrue: [ ^ aClassOverride ].
	key := self classKeyForBehavior: aClassOverride behavior.
	existing := (self installedClassOverridesForPackageName: packageName)
		at: key
		ifAbsent: [ Dictionary new ].
	metadata := Dictionary new
		at: #behaviorName put: key first;
		at: #isMeta put: key second;
		at: #originalInstVarString put: (existing at: #originalInstVarString ifAbsent: [ instVarString ]);
		at: #originalPackageName put: (existing at: #originalPackageName ifAbsent: [ originalPackageName ]);
		yourself.
	(self installedClassOverridesForPackageName: packageName)
		at: key
		put: metadata.
	^ aClassOverride
]

{ #category : 'registry' }
GbxOverrideUtility class >> noteInstalledMethodOverride: aMethodOverride originalSource: sourceString protocol: protocolName [
	| packageName key existing metadata |
	packageName := self packageNameOf: aMethodOverride package.
	packageName isEmpty ifTrue: [ ^ aMethodOverride ].
	key := self
		methodKeyForBehavior: aMethodOverride behavior
		selector: aMethodOverride selector.
	existing := (self installedMethodOverridesForPackageName: packageName)
		at: key
		ifAbsent: [ Dictionary new ].
	metadata := Dictionary new
		at: #behaviorName put: key first;
		at: #isMeta put: key second;
		at: #selector put: aMethodOverride selector;
		at: #originalSource put: (existing at: #originalSource ifAbsent: [ sourceString ]);
		at: #originalProtocol put: (existing at: #originalProtocol ifAbsent: [ protocolName ifNil: [ 'as yet unclassified' ] ]);
		yourself.
	(self installedMethodOverridesForPackageName: packageName)
		at: key
		put: metadata.
	^ aMethodOverride
]

{ #category : 'utilities' }
GbxOverrideUtility class >> prepareOverridesForRelease [
	| generated removed |
	generated := self generateOverrideSpecs.
	removed := self removeOverridesForRelease.
	^ generated or: [ removed ]
]

{ #category : 'accessing' }
GbxOverrideUtility class >> overrideSpecClasses [
	^ GbxAbstractOverrideSpec allSubclasses asSortedCollection: [ :left :right |
		left name <= right name ]
]

{ #category : 'accessing' }
GbxOverrideUtility class >> packageNameOf: aPackageOrName [
	aPackageOrName ifNil: [ ^ '' ].
	((aPackageOrName respondsTo: #name)
		and: [ (aPackageOrName isString or: [ aPackageOrName isSymbol ]) not ])
		ifTrue: [ ^ aPackageOrName name asString ].
	^ aPackageOrName asString
]

{ #category : 'utilities' }
GbxOverrideUtility class >> removeAllOverridesFromPackage: aPackage [
	| packageName removedAny methodMetadata classMetadata |
	packageName := self packageNameOf: aPackage.
	packageName isEmpty ifTrue: [ ^ false ].
	removedAny := false.
	methodMetadata := (self installedMethodOverrides at: packageName ifAbsent: [ Dictionary new ]) values asArray.
	methodMetadata do: [ :metadata |
		removedAny := (self restoreMethodOverrideFromMetadata: metadata) or: [ removedAny ] ].
	classMetadata := (self installedClassOverrides at: packageName ifAbsent: [ Dictionary new ]) values asArray.
	classMetadata do: [ :metadata |
		removedAny := (self restoreClassOverrideFromMetadata: metadata) or: [ removedAny ] ].
	self clearInstalledOverrideMetadataForPackageName: packageName.
	^ removedAny
]

{ #category : 'utilities' }
GbxOverrideUtility class >> removeOverridesForRelease [
	| removed |
	removed := false.
	self overrideSpecClasses do: [ :specClass |
		removed := (self removeAllOverridesFromPackage: specClass overridesPackage) or: [ removed ] ].
	^ removed
]

{ #category : 'accessing' }
GbxOverrideUtility class >> resolvePackageName: aPackageName ifFail: failBlock [
	(aPackageName isNil or: [ aPackageName asString isEmpty ]) ifTrue: [ ^ failBlock value ].
	(aPackageName respondsTo: #name)
		ifTrue: [ ^ aPackageName ].
	(Smalltalk globals at: #PackageOrganizer ifAbsent: [ nil ]) ifNotNil: [ :organizerClass |
		^ organizerClass default
			packageNamed: aPackageName asString
			ifAbsent: [ aPackageName asString ] ].
	^ aPackageName asString
]

{ #category : 'registry' }
GbxOverrideUtility class >> restoreClassOverrideFromMetadata: metadata [
	| behavior originalInstVarString originalPackageName |
	behavior := self behaviorFromMetadata: metadata.
	behavior ifNil: [ ^ false ].
	originalInstVarString := metadata at: #originalInstVarString ifAbsent: [ ^ false ].
	originalPackageName := metadata at: #originalPackageName ifAbsent: [ behavior package name asString ].
	[
		Smalltalk classInstaller make: [ :builder |
			builder
				superclass: behavior superclass;
				name: behavior name asSymbol;
				slots: (self slotSymbolsFromString: originalInstVarString);
				package: originalPackageName ] ]
		on: Error
		do: [ :ex |
			OverrideFailureWarning
				raiseSignal: 'Cannot restore class override for ', behavior name asString,
					': ', ex messageText.
			^ false ].
	^ true
]

{ #category : 'registry' }
GbxOverrideUtility class >> restoreMethodOverrideFromMetadata: metadata [
	| behavior sourceString protocolName selector |
	behavior := self behaviorFromMetadata: metadata.
	behavior ifNil: [ ^ false ].
	sourceString := metadata at: #originalSource ifAbsent: [ ^ false ].
	protocolName := metadata at: #originalProtocol ifAbsent: [ 'as yet unclassified' ].
	selector := metadata at: #selector ifAbsent: [ ^ false ].
	[
		behavior compile: sourceString classified: protocolName ]
		on: Error
		do: [ :ex |
			OverrideFailureWarning
				raiseSignal: 'Cannot restore method override for ', behavior name asString,
					'>>#', selector asString, ': ', ex messageText.
			^ false ].
	^ true
]

{ #category : 'utilities' }
GbxOverrideUtility class >> specMethodSourceFor: anOverrideSet in: specClass [
	^ String streamContents: [ :stream |
		stream
			nextPutAll: specClass specMethodSelector asString;
			cr;
			tab;
			nextPutAll: '<version: ''';
			nextPutAll: specClass specMethodVersion;
			nextPutAll: '''>';
			cr;
			tab;
			nextPutAll: '^ '.
		anOverrideSet storeOn: stream ]
]

{ #category : 'registry' }
GbxOverrideUtility class >> slotSymbolsFromString: instVarString [
	instVarString ifNil: [ ^ #() ].
	instVarString isEmpty ifTrue: [ ^ #() ].
	^ (instVarString substrings: ' ')
		collect: [ :each | each asSymbol ]
]

{ #category : 'registry' }
GbxOverrideUtility class >> classKeyForBehavior: aBehavior [
	^ Array
		with: aBehavior instanceSide name asString
		with: aBehavior isMeta
]
