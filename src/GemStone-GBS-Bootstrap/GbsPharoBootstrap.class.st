Class {
	#name : 'GbsPharoBootstrap',
	#superclass : 'Object',
	#instVars : [
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Bootstrap',
	#package : 'GemStone-GBS-Bootstrap'
}

{ #category : 'bootstrap' }
GbsPharoBootstrap class >> installCompatibilityAliases
[
	self installPharoAliases.
	self installGlobalCompatibilityPlaceholders
]

{ #category : 'bootstrap' }
GbsPharoBootstrap class >> activateCompatibilityInCurrentImage
[
	self installCompatibilityAliases.
	self publishConvertedRuntimeGlobals.
	self refreshWorldMenuIfPossible
]

{ #category : 'class initialization' }
GbsPharoBootstrap class >> initialize
[
	"Allow direct package loads to install placeholder globals before Converted compiles."

	self installCompatibilityAliases
]

{ #category : 'bootstrap' }
GbsPharoBootstrap class >> installPharoAliases
[
	Smalltalk at: #TwoByteString put: WideString.
	Smalltalk at: #FourByteString put: WideString.
	Smalltalk at: #TwoByteSymbol put: WideSymbol.
	Smalltalk at: #FourByteSymbol put: WideSymbol.
	Smalltalk at: #Timestamp put: DateAndTime.
	Smalltalk at: #LimitedPrecisionReal put: Float.
	Smalltalk at: #GbxArray put: Array.
	Smalltalk at: #NoModificationError put: Error.
	Smalltalk at: #RedefinitionNotification put: Notification.
	(Smalltalk at: #GbxFilename ifAbsent: [ nil ])
		ifNotNil: [ :filenameClass | Smalltalk at: #Filename put: filenameClass ]
]

{ #category : 'bootstrap' }
GbsPharoBootstrap class >> installGlobalCompatibilityPlaceholders
[
	| specials |
	specials := self specialGemStoneObjects.

	self
		installPlaceholderGlobal: #NotCachedToken
		value: [ 'Not cached' copy ];
		installPlaceholderGlobal: #ClassesNotToCreateOnServer value: [ nil ];
		installPlaceholderGlobal: #GSClipboard value: [ nil ];
		installPlaceholderGlobal: #GScursor value: [ nil ];
		installPlaceholderGlobal: #LastKernelOopNumber value: [ 1318 ];
		installPlaceholderGlobal: #MinTraversalBufferSize value: [ 2048 ];
		installPlaceholderGlobal: #SmallTraversalBufferSize value: [ 5000 ];
		installPlaceholderGlobal: #Pointers value: [ 0 ];
		installPlaceholderGlobal: #Bytes value: [ 1 ];
		installPlaceholderGlobal: #NSC value: [ 2 ];
		installPlaceholderGlobal: #Special value: [ 3 ];
		installPlaceholderGlobal: #StoreValuesFinishUpdates value: [ 8 ];
		installPlaceholderGlobal: #NameSlot value: [ 11 ].

	self installPlaceholderGlobalsNamed: self runtimePlaceholderGlobalNames.

	specials
		at: #NotCachedToken put: (Smalltalk at: #NotCachedToken);
		at: #GSClipboard put: (Smalltalk at: #GSClipboard ifAbsent: [ nil ]);
		at: #GScursor put: (Smalltalk at: #GScursor ifAbsent: [ nil ])
]

{ #category : 'bootstrap' }
GbsPharoBootstrap class >> installPlaceholderGlobal: aSymbol value: aBlock
[
	(Smalltalk globals includesKey: aSymbol)
		ifFalse: [ Smalltalk at: aSymbol put: aBlock value ]
]

{ #category : 'bootstrap' }
GbsPharoBootstrap class >> installPlaceholderGlobalsNamed: symbolCollection
[
	symbolCollection do: [ :each |
		self installPlaceholderGlobal: each value: [ nil ] ]
]

{ #category : 'bootstrap' }
GbsPharoBootstrap class >> runtimePlaceholderGlobalNames
[
	^#(
		CRC32Function
		Exceptions
		GbxVwVersion
		OAbstractDictionary
		OCharacter
		OCharacterCollection
		OClientForwarder
		OCollection
		OFalse
		OGemStoneErrorCategory
		OGsCurrentSession
		OGsProcess
		OIdentityBag
		OIllegal
		OInteger
		OInterval
		ONil
		OObject
		OSequenceableCollection
		OSmallInteger
		OSymbol
		OSystem
		OTimeZone
		OTrue
		OUserProfile
		Ofalse
		Onil
		Otrue
		OSHandle
		ObjectMemory
		InputState
		MethodDefinition
		Override
		Policies
		ProcessHandle
		Registry
		SocketAccessor
		StObjTable
		Store
		SystemUtils
		SystemVariable
		Workspace
		Zero
	)
]

{ #category : 'bootstrap' }
GbsPharoBootstrap class >> publishConvertedRuntimeGlobals
[
	| kernelClass specialClass sessionManagerClass |
	self installGlobalCompatibilityPlaceholders.

	kernelClass := Smalltalk at: #GbxKernelPomOop ifAbsent: [ nil ].
	kernelClass ifNotNil: [
		kernelClass initialize.
		self publishClassVariablesOf: kernelClass ].

	specialClass := Smalltalk at: #GbxSpecialOop ifAbsent: [ nil ].
	specialClass ifNotNil: [
		specialClass initialize.
		self publishClassVariablesOf: specialClass ].

	sessionManagerClass := Smalltalk at: #GbsSessionManager ifAbsent: [ nil ].
	sessionManagerClass ifNotNil: [ sessionManagerClass initializeMiscConstants ].

	self publishGciCompatibilityGlobals.
	self publishSpecialGemStoneObjects
]

{ #category : 'bootstrap' }
GbsPharoBootstrap class >> publishClassVariablesOf: aClass
[
	aClass classVarNames do: [ :each |
		| symbol |
		symbol := each asSymbol.
		(aClass classPool includesKey: symbol)
			ifTrue: [ Smalltalk at: symbol put: (aClass classPool at: symbol) ] ]
]

{ #category : 'bootstrap' }
GbsPharoBootstrap class >> publishGciCompatibilityGlobals
[
	| sequencerClass specials |
	sequencerClass := Smalltalk at: #GbxGciCallSequencer ifAbsent: [ nil ].
	sequencerClass ifNil: [ ^ self ].

	specials := self specialGemStoneObjects.
	(sequencerClass classPool includesKey: #SpecialGemStoneObjects)
		ifTrue: [ sequencerClass classPool at: #SpecialGemStoneObjects put: specials ].

	[ sequencerClass initializeGemCursor ]
		on: Error
		do: [ ].

	Smalltalk
		at: #GScursor
		put: (specials at: #GScursor ifAbsent: [ Smalltalk at: #GScursor ifAbsent: [ nil ] ])
]

{ #category : 'bootstrap' }
GbsPharoBootstrap class >> publishSpecialGemStoneObjects
[
	| names specials |
	specials := self specialGemStoneObjects.
	names := OrderedCollection new.
	names
		addAll: #(NotCachedToken GScursor LastKernelOopNumber MinTraversalBufferSize SmallTraversalBufferSize Pointers Bytes NSC Special StoreValuesFinishUpdates NameSlot ClassesNotToCreateOnServer).

	(Smalltalk at: #GbxKernelPomOop ifAbsent: [ nil ])
		ifNotNil: [ :cls | names addAll: (cls classVarNames collect: #asSymbol) ].
	(Smalltalk at: #GbxSpecialOop ifAbsent: [ nil ])
		ifNotNil: [ :cls | names addAll: (cls classVarNames collect: #asSymbol) ].

	names asSet do: [ :each |
		(Smalltalk globals includesKey: each)
			ifTrue: [ specials at: each put: (Smalltalk at: each) ] ]
]

{ #category : 'bootstrap' }
GbsPharoBootstrap class >> specialGemStoneObjects
[
	| existing namespace |
	existing := Smalltalk at: #SpecialGemStoneObjects ifAbsent: [ nil ].
	(existing isKindOf: GbsCompatibilityNamespace)
		ifTrue: [ ^ existing ].

	namespace := GbsCompatibilityNamespace new.
	existing ifNotNil: [
		(existing respondsTo: #bindingsDo:)
			ifTrue: [ existing bindingsDo: [ :assoc | namespace at: assoc key put: assoc value ] ]
			ifFalse: [
				(existing respondsTo: #keysAndValuesDo:)
					ifTrue: [ existing keysAndValuesDo: [ :key :value | namespace at: key put: value ] ] ] ].
	Smalltalk at: #SpecialGemStoneObjects put: namespace.
	^ namespace
]

{ #category : 'icons' }
GbsPharoBootstrap class >> iconNamed: aSymbol
[
	^ [ UIManager default iconNamed: aSymbol ]
		on: Error
		do: [ nil ]
]

{ #category : 'menus' }
GbsPharoBootstrap class >> loadGemStoneTools
[
	[
		Metacello new
			baseline: 'GemStonePharo';
			repository: 'tonel:///Users/tariq/src/gemtools/GemStone-Pharo-Bridge/src';
			load: 'Tools'.
		self refreshWorldMenuIfPossible.
		UIManager default inform: 'GemStone tools loaded.'
	] on: Error do: [ :ex |
		UIManager default inform: 'GemStone tools load failed: ', ex messageText ]
]

{ #category : 'menus' }
GbsPharoBootstrap class >> menuCommandGemStoneOn: aBuilder
[
	<worldMenu>
	| launcherClass |
	launcherClass := Smalltalk at: #GbsClassicLauncher ifAbsent: [ nil ].
	(launcherClass notNil and: [ launcherClass respondsTo: #menuCommandGemStoneOn: ])
		ifTrue: [ ^ launcherClass menuCommandGemStoneOn: aBuilder ].

	(aBuilder item: #GemStone)
		order: 79.9;
		label: 'GemStone';
		icon: (self iconNamed: #smallConfiguration);
		with: [
			(aBuilder item: #LoadGemStoneTools)
				label: 'Load GemStone Tools';
				action: [ self loadGemStoneTools ].
			(aBuilder item: #GemStoneMenuUnavailable)
				label: 'Launcher unavailable';
				action: [
					UIManager default inform:
						'GemStone tools are not loaded in this image yet.' ].
			(aBuilder item: #AboutGemBuilder)
				label: 'About GemBuilder...';
				action: [
					UIManager default
						inform: 'GemBuilder for Pharo (GemStone-Pharo-Bridge)' ] ]
]

{ #category : 'menus' }
GbsPharoBootstrap class >> refreshWorldMenuIfPossible
[
	| refreshBlock |
	refreshBlock := [
		| menubarClass world state |
		world := Smalltalk at: #World ifAbsent: [ nil ].
		world ifNotNil: [
			world := (world respondsTo: #currentWorld)
				ifTrue: [ world currentWorld ]
				ifFalse: [ world ] ].
		state := [ world ifNotNil: [ world worldState ] ] on: Error do: [ nil ].
		state ifNotNil: [
			[ state worldMenu ] on: Error do: [ ] ].
		menubarClass := Smalltalk at: #MenubarMorph ifAbsent: [ nil ].
		menubarClass ifNotNil: [
			[
				(menubarClass respondsTo: #showMenubar:)
					ifTrue: [ menubarClass showMenubar: true ]
			] on: Error do: [ ].
			[
				(menubarClass respondsTo: #reset)
					ifTrue: [ menubarClass reset ]
			] on: Error do: [ ] ] ].

	[ UIManager default defer: refreshBlock ]
		on: Error
		do: [ ].
	refreshBlock value
]
