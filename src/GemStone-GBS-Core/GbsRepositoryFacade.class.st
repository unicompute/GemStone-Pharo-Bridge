Class {
	#name : 'GbsRepositoryFacade',
	#superclass : 'Object',
	#instVars : [
		'session'
	],
	#category : 'GemStone-GBS-Core',
	#package : 'GemStone-GBS-Core'
}

{ #category : 'instance creation' }
GbsRepositoryFacade class >> on: aSession [
	^ self new
		session: aSession;
		yourself
]

{ #category : 'querying' }
GbsRepositoryFacade >> allInstancesOf: aClassOrName [
	^ self
		fetchClassReference: aClassOrName
		variableName: 'cls'
		body: 'cls ifNil: [ nil ] ifNotNil: [ cls allInstances ]'
		literalAssignments: Dictionary new
		oopAssignments: Dictionary new
]

{ #category : 'querying' }
GbsRepositoryFacade >> allInstancesOfNamed: aClassName [
	^ self allInstancesOf: aClassName
]

{ #category : 'querying' }
GbsRepositoryFacade >> classHistoryOf: aClassOrName [
	^ GbsClassHistoryFacade
		on: session
		class: aClassOrName
]

{ #category : 'querying' }
GbsRepositoryFacade >> classHistoryOfNamed: aClassName [
	^ self classHistoryOf: aClassName
]

{ #category : 'querying' }
GbsRepositoryFacade >> classMethodMirrorForClass: aClassOrName selector: aSelector [
	^ GbsRemoteMethodMirror
		on: session
		class: aClassOrName
		selector: aSelector
		classSide: true
]

{ #category : 'querying' }
GbsRepositoryFacade >> classMethodMirrorForClassNamed: aClassName selector: aSelector [
	^ self
		classMethodMirrorForClass: aClassName
		selector: aSelector
]

{ #category : 'querying' }
GbsRepositoryFacade >> classMethodObjectForClass: aClassOrName selector: aSelector [
	^ GbsRemoteMethodObject
		onMirror: (self
			classMethodMirrorForClass: aClassOrName
			selector: aSelector)
]

{ #category : 'querying' }
GbsRepositoryFacade >> classUnboundMethodObjectForClass: aClassOrName selector: aSelector [
	^ GbsRemoteUnboundMethodObject
		onMirror: (self
			classMethodMirrorForClass: aClassOrName
			selector: aSelector)
]

{ #category : 'querying' }
GbsRepositoryFacade >> classMethodObjectForClassNamed: aClassName selector: aSelector [
	^ self
		classMethodObjectForClass: aClassName
		selector: aSelector
]

{ #category : 'querying' }
GbsRepositoryFacade >> classUnboundMethodObjectForClassNamed: aClassName selector: aSelector [
	^ self
		classUnboundMethodObjectForClass: aClassName
		selector: aSelector
]

{ #category : 'querying' }
GbsRepositoryFacade >> classMirrorOf: aClassOrName [
	^ GbsRemoteClassMirror
		on: session
		class: aClassOrName
]

{ #category : 'querying' }
GbsRepositoryFacade >> classMirrorOfNamed: aClassName [
	^ self classMirrorOf: aClassName
]

{ #category : 'querying' }
GbsRepositoryFacade >> namespaceMirrors [
	| rows |
	rows := self
		fetchCommandBody: self namespaceMirrorEntriesCommandBody
		literalAssignments: Dictionary new
		oopAssignments: Dictionary new.
	rows ifNil: [ ^ #() ].
	^ rows collect: [ :each |
		GbsRemoteNamespaceMirror
			on: session
			symbolListIndex: (each at: 1)
			metadata: (each copyFrom: 2 to: each size) ]
]

{ #category : 'querying' }
GbsRepositoryFacade >> namespaceMirrorAtSymbolListIndex: anInteger [
	^ GbsRemoteNamespaceMirror
		on: session
		symbolListIndex: anInteger
]

{ #category : 'querying' }
GbsRepositoryFacade >> topLevelNamespaceMirror [
	^ GbsRemoteNamespaceMirror topLevelOn: session
]

{ #category : 'querying' }
GbsRepositoryFacade >> namespaceMirrorForClass: aClassOrName [
	^ GbsRemoteNamespaceMirror
		on: session
		classOrModule: aClassOrName
]

{ #category : 'querying' }
GbsRepositoryFacade >> namespaceMirrorForClassNamed: aClassName [
	^ self namespaceMirrorForClass: aClassName
]

{ #category : 'querying' }
GbsRepositoryFacade >> namespaceMirrorForObject: anObjectOrProxy [
	^ GbsRemoteNamespaceMirror
		on: session
		object: anObjectOrProxy
]

{ #category : 'querying' }
GbsRepositoryFacade >> namespaceMirrorForFullName: aString [
	^ GbsRemoteNamespaceMirror
		on: session
		fullName: aString
]

{ #category : 'querying' }
GbsRepositoryFacade >> allInstancesOopOf: aClassOrName [
	^ self
		returnOopClassReference: aClassOrName
		variableName: 'cls'
		body: 'cls ifNil: [ nil ] ifNotNil: [ cls allInstances ]'
		literalAssignments: Dictionary new
		oopAssignments: Dictionary new
]

{ #category : 'querying' }
GbsRepositoryFacade >> allInstancesOopOfNamed: aClassName [
	^ self allInstancesOopOf: aClassName
]

{ #category : 'private' }
GbsRepositoryFacade >> bindRemoteReference: anObject as: variableName literalAssignments: literalDictionary oopAssignments: oopDictionary [
	| value |
	value := anObject.
	(value respondsTo: #proxy) ifTrue: [ value := value proxy ].
	(value isKindOf: GbsProxy)
		ifTrue: [ oopDictionary at: variableName put: value oop ]
		ifFalse: [ literalDictionary at: variableName put: value ]
]

{ #category : 'private' }
GbsRepositoryFacade >> classReferencePreambleFor: aClassOrName variableName: variableName literalAssignments: literalDictionary oopAssignments: oopDictionary tempNames: tempNames [
	| reference nameBinding |
	reference := aClassOrName.
	(reference respondsTo: #proxy) ifTrue: [ reference := reference proxy ].
	(reference isKindOf: GbsProxy) ifTrue: [
		oopDictionary at: variableName put: reference oop.
		^ '' ].
	(reference isBehavior or: [
		reference class name asString includesSubstring: 'Behavior' ]) ifTrue: [
		reference := reference name ].
	((reference isString) or: [ reference isSymbol ]) ifTrue: [
		nameBinding := variableName, 'Name'.
		literalDictionary at: nameBinding put: reference asString.
		tempNames add: variableName.
		^ variableName, ' := System myUserProfile symbolList objectNamed: ', nameBinding, ' asSymbol. ' ].
	self error: 'Unsupported class reference: ', reference printString
]

{ #category : 'private' }
GbsRepositoryFacade >> copyDictionary: aDictionary [
	| copy |
	copy := Dictionary new.
	aDictionary ifNil: [ ^ copy ].
	aDictionary keysAndValuesDo: [ :key :value |
		copy at: key put: value ].
	^ copy
]

{ #category : 'private' }
GbsRepositoryFacade >> fetchClassReference: aClassOrName variableName: variableName body: bodyString literalAssignments: literalDictionary oopAssignments: oopDictionary [
	^ self
		fetchCommandForClassReferences: { variableName -> aClassOrName }
		body: bodyString
		literalAssignments: literalDictionary
		oopAssignments: oopDictionary
]

{ #category : 'private' }
GbsRepositoryFacade >> fetchCommandBody: bodyString literalAssignments: literalDictionary oopAssignments: oopDictionary [
	^ session fetchRemoteCommand: (GbsRemoteCommand
		blockBody: bodyString
		literalBindings: literalDictionary
		oopBindings: oopDictionary)
]

{ #category : 'private' }
GbsRepositoryFacade >> fetchCommandForClassReferences: referenceAssociations body: bodyString literalAssignments: literalDictionary oopAssignments: oopDictionary [
	^ session fetchRemoteCommand: (self
		remoteCommandForClassReferences: referenceAssociations
		body: bodyString
		literalAssignments: literalDictionary
		oopAssignments: oopDictionary)
]

{ #category : 'private' }
GbsRepositoryFacade >> remoteCommandForClassReferences: referenceAssociations body: bodyString literalAssignments: literalDictionary oopAssignments: oopDictionary [
	| literals oops tempNames preamble |
	literals := self copyDictionary: literalDictionary.
	oops := self copyDictionary: oopDictionary.
	tempNames := OrderedCollection new.
	preamble := ''.
	referenceAssociations do: [ :association |
		preamble := preamble, (self
			classReferencePreambleFor: association value
			variableName: association key
			literalAssignments: literals
			oopAssignments: oops
			tempNames: tempNames) ].
	^ GbsRemoteCommand
		blockBody: (self tempDeclarationFor: tempNames), preamble, bodyString
		literalBindings: literals
		oopBindings: oops
]

{ #category : 'private' }
GbsRepositoryFacade >> returnOopClassReference: aClassOrName variableName: variableName body: bodyString literalAssignments: literalDictionary oopAssignments: oopDictionary [
	^ session returnRemoteCommandOop: (self
		remoteCommandForClassReferences: { variableName -> aClassOrName }
		body: bodyString
		literalAssignments: literalDictionary
		oopAssignments: oopDictionary)
]

{ #category : 'private' }
GbsRepositoryFacade >> tempDeclarationFor: tempNames [
	| declaration |
	tempNames isEmpty ifTrue: [ ^ '' ].
	declaration := '| '.
	tempNames do: [ :each |
		declaration := declaration, each asString, ' ' ].
	^ declaration, '| '
]

{ #category : 'private' }
GbsRepositoryFacade >> namespaceMirrorEntriesCommandBody [
	^ '| sl entries | sl := System myUserProfile symbolList. entries := OrderedCollection new. 1 to: sl size do: [ :index | | ns name fullName myClassName | ns := sl at: index. name := [ (ns respondsTo: #name) ifTrue: [ ns name ] ifFalse: [ nil ] ] on: Error do: [ nil ]. fullName := [ (ns respondsTo: #fullName) ifTrue: [ ns fullName ] ifFalse: [ nil ] ] on: Error do: [ nil ]. myClassName := [ (ns respondsTo: #myClass) ifTrue: [ ns myClass ifNil: [ nil ] ifNotNil: [ ns myClass name asString ] ] ifFalse: [ nil ] ] on: Error do: [ nil ]. entries add: (Array with: index with: ns asOop with: (name ifNil: [ nil ] ifNotNil: [ name asString ]) with: (fullName ifNil: [ nil ] ifNotNil: [ fullName asString ]) with: ns class name asString with: myClassName) ]. entries asArray'
]

{ #category : 'querying' }
GbsRepositoryFacade >> loadedClasses [
	^ self
		fetchCommandBody: self loadedClassesCommandBody
		literalAssignments: Dictionary new
		oopAssignments: Dictionary new
]

{ #category : 'mutating' }
GbsRepositoryFacade >> migrateInstancesFrom: aSourceClassOrName to: aTargetClassOrName [
	^ self
		migrateInstancesFrom: aSourceClassOrName
		to: aTargetClassOrName
		allowAbort: false
]

{ #category : 'querying' }
GbsRepositoryFacade >> previewMigrationFrom: aSourceClassOrName to: aTargetClassOrName [
	^ self
		previewMigrationFrom: aSourceClassOrName
		to: aTargetClassOrName
		allowAbort: false
]

{ #category : 'querying' }
GbsRepositoryFacade >> previewMigrationFrom: aSourceClassOrName to: aTargetClassOrName allowAbort: aBoolean [
	| rawEntries |
	self prepareForRepositoryScanAllowAbort: aBoolean.
	rawEntries := self
		fetchCommandForClassReferences: {
			'fromClass' -> aSourceClassOrName.
			'toClass' -> aTargetClassOrName }
		body: self previewMigrationFromToCommandBody
		literalAssignments: Dictionary new
		oopAssignments: Dictionary new.
	^ GbsMigrationPlan
		on: session
		rawEntries: rawEntries
		source: aSourceClassOrName
		target: aTargetClassOrName
		includesSubclasses: false
]

{ #category : 'querying' }
GbsRepositoryFacade >> previewMigrationWithSubclassesOf: aTopClassOrName [
	^ self
		previewMigrationWithSubclassesOf: aTopClassOrName
		allowAbort: false
]

{ #category : 'querying' }
GbsRepositoryFacade >> previewMigrationWithSubclassesOf: aTopClassOrName allowAbort: aBoolean [
	| rawEntries |
	self prepareForRepositoryScanAllowAbort: aBoolean.
	rawEntries := self
		fetchClassReference: aTopClassOrName
		variableName: 'topClass'
		body: self previewMigrationWithSubclassesCommandBody
		literalAssignments: Dictionary new
		oopAssignments: Dictionary new.
	^ GbsMigrationPlan
		on: session
		rawEntries: rawEntries
		source: aTopClassOrName
		target: aTopClassOrName
		includesSubclasses: true
]

{ #category : 'mutating' }
GbsRepositoryFacade >> migrateInstancesFrom: aSourceClassOrName to: aTargetClassOrName allowAbort: aBoolean [
	self prepareForRepositoryScanAllowAbort: aBoolean.
	^ self
		fetchCommandForClassReferences: {
			'fromClass' -> aSourceClassOrName.
			'toClass' -> aTargetClassOrName }
		body: self migrateInstancesFromToCommandBody
		literalAssignments: Dictionary new
		oopAssignments: Dictionary new
]

{ #category : 'mutating' }
GbsRepositoryFacade >> migrateInstancesWithSubclassesOf: aTopClassOrName [
	^ self
		migrateInstancesWithSubclassesOf: aTopClassOrName
		allowAbort: false
]

{ #category : 'mutating' }
GbsRepositoryFacade >> migrateInstancesWithSubclassesOf: aTopClassOrName allowAbort: aBoolean [
	self prepareForRepositoryScanAllowAbort: aBoolean.
	^ self
		fetchClassReference: aTopClassOrName
		variableName: 'topClass'
		body: self migrateInstancesWithSubclassesCommandBody
		literalAssignments: Dictionary new
		oopAssignments: Dictionary new
]

{ #category : 'querying' }
GbsRepositoryFacade >> listInstancesOf: aClassOrName [
	^ self
		listInstancesOf: aClassOrName
		limit: 0
		allowAbort: false
]

{ #category : 'querying' }
GbsRepositoryFacade >> listInstancesOf: aClassOrName allowAbort: aBoolean [
	^ self
		listInstancesOf: aClassOrName
		limit: 0
		allowAbort: aBoolean
]

{ #category : 'querying' }
GbsRepositoryFacade >> listInstancesOf: aClassOrName limit: aSmallInteger [
	^ self
		listInstancesOf: aClassOrName
		limit: aSmallInteger
		allowAbort: false
]

{ #category : 'querying' }
GbsRepositoryFacade >> listInstancesOf: aClassOrName limit: aSmallInteger allowAbort: aBoolean [
	self prepareForRepositoryScanAllowAbort: aBoolean.
	^ self
		fetchClassReference: aClassOrName
		variableName: 'cls'
		body: self listInstancesCommandBody
		literalAssignments: (Dictionary new
			at: 'limitValue' put: aSmallInteger;
			yourself)
		oopAssignments: Dictionary new
]

{ #category : 'querying' }
GbsRepositoryFacade >> listInstancesOfNamed: aClassName [
	^ self listInstancesOf: aClassName
]

{ #category : 'querying' }
GbsRepositoryFacade >> listInstancesOfNamed: aClassName allowAbort: aBoolean [
	^ self listInstancesOf: aClassName allowAbort: aBoolean
]

{ #category : 'querying' }
GbsRepositoryFacade >> listInstancesOfNamed: aClassName limit: aSmallInteger [
	^ self listInstancesOf: aClassName limit: aSmallInteger
]

{ #category : 'querying' }
GbsRepositoryFacade >> listInstancesOfNamed: aClassName limit: aSmallInteger allowAbort: aBoolean [
	^ self
		listInstancesOf: aClassName
		limit: aSmallInteger
		allowAbort: aBoolean
]

{ #category : 'querying' }
GbsRepositoryFacade >> methodMirrorForClass: aClassOrName selector: aSelector [
	^ GbsRemoteMethodMirror
		on: session
		class: aClassOrName
		selector: aSelector
		classSide: false
]

{ #category : 'querying' }
GbsRepositoryFacade >> methodMirrorForClassNamed: aClassName selector: aSelector [
	^ self
		methodMirrorForClass: aClassName
		selector: aSelector
]

{ #category : 'querying' }
GbsRepositoryFacade >> methodObjectForClass: aClassOrName selector: aSelector [
	^ GbsRemoteMethodObject
		onMirror: (self
			methodMirrorForClass: aClassOrName
			selector: aSelector)
]

{ #category : 'querying' }
GbsRepositoryFacade >> unboundMethodObjectForClass: aClassOrName selector: aSelector [
	^ GbsRemoteUnboundMethodObject
		onMirror: (self
			methodMirrorForClass: aClassOrName
			selector: aSelector)
]

{ #category : 'querying' }
GbsRepositoryFacade >> methodObjectForClassNamed: aClassName selector: aSelector [
	^ self
		methodObjectForClass: aClassName
		selector: aSelector
]

{ #category : 'querying' }
GbsRepositoryFacade >> unboundMethodObjectForClassNamed: aClassName selector: aSelector [
	^ self
		unboundMethodObjectForClass: aClassName
		selector: aSelector
]

{ #category : 'querying' }
GbsRepositoryFacade >> implementorMethodReferenceStringsForSelector: aSelectorOrString [
	^ self
		methodReferenceStringsForSearchBody: '[ organizer implementorsOf: selectorValue ] on: Error do: [ #() ]'
		literalAssignments: (Dictionary new
			at: 'selectorValue' put: aSelectorOrString asString asSymbol;
			yourself)
		oopAssignments: Dictionary new
]

{ #category : 'querying' }
GbsRepositoryFacade >> hierarchyImplementorMethodReferenceStringsForSelector: aSelectorOrString rootClassName: aRootClassName scope: aScopeString [
	^ self
		hierarchyImplementorMethodReferenceStringsForSelector: aSelectorOrString
		rootClassName: aRootClassName
		scope: aScopeString
		includeClassSide: false
]

{ #category : 'querying' }
GbsRepositoryFacade >> hierarchyImplementorMethodReferenceStringsForSelector: aSelectorOrString rootClassName: aRootClassName scope: aScopeString includeClassSide: includeClassSideBoolean [
	^ self
		hierarchyMethodReferenceStringsForSelector: aSelectorOrString
		rootClassName: aRootClassName
		scope: aScopeString
		senders: false
		includeClassSide: includeClassSideBoolean
]

{ #category : 'querying' }
GbsRepositoryFacade >> hierarchySenderMethodReferenceStringsForSelector: aSelectorOrString rootClassName: aRootClassName scope: aScopeString [
	^ self
		hierarchySenderMethodReferenceStringsForSelector: aSelectorOrString
		rootClassName: aRootClassName
		scope: aScopeString
		includeClassSide: false
]

{ #category : 'querying' }
GbsRepositoryFacade >> hierarchySenderMethodReferenceStringsForSelector: aSelectorOrString rootClassName: aRootClassName scope: aScopeString includeClassSide: includeClassSideBoolean [
	^ self
		hierarchyMethodReferenceStringsForSelector: aSelectorOrString
		rootClassName: aRootClassName
		scope: aScopeString
		senders: true
		includeClassSide: includeClassSideBoolean
]

{ #category : 'querying' }
GbsRepositoryFacade >> methodReferenceStringsToObject: anObject [
	| literals oops |
	literals := Dictionary new.
	oops := Dictionary new.
	self
		bindRemoteReference: anObject
		as: 'targetObject'
		literalAssignments: literals
		oopAssignments: oops.
	^ self
		methodReferenceStringsForSearchBody: '[ organizer referencesToObject: targetObject ] on: Error do: [ #() ]'
		literalAssignments: literals
		oopAssignments: oops
]

{ #category : 'querying' }
GbsRepositoryFacade >> methodReferenceStringsToSymbol: aSymbolOrString [
	^ self
		methodReferenceStringsForSearchBody: '[ organizer referencesTo: symbolValue ] on: Error do: [ #() ]'
		literalAssignments: (Dictionary new
			at: 'symbolValue' put: aSymbolOrString asString asSymbol;
			yourself)
		oopAssignments: Dictionary new
]

{ #category : 'querying' }
GbsRepositoryFacade >> senderMethodReferenceStringsForSelector: aSelectorOrString [
	^ self
		methodReferenceStringsForSearchBody: '[ organizer sendersOf: selectorValue ] on: Error do: [ #() ]'
		literalAssignments: (Dictionary new
			at: 'selectorValue' put: aSelectorOrString asString;
			yourself)
		oopAssignments: Dictionary new
]

{ #category : 'private' }
GbsRepositoryFacade >> hierarchyMethodReferenceStringsForSelector: aSelectorOrString rootClassName: aRootClassName scope: aScopeString senders: sendersOnly includeClassSide: includeClassSideBoolean [
	^ self
		fetchCommandBody: self hierarchyMethodReferenceStringsCommandBody
		literalAssignments: (Dictionary new
			at: 'selectorValue' put: aSelectorOrString asString asSymbol;
			at: 'rootClassName' put: (aRootClassName ifNil: [ '' ] ifNotNil: [ aRootClassName asString ]);
			at: 'scopeValue' put: (aScopeString ifNil: [ 'full' ] ifNotNil: [ aScopeString asString ]);
			at: 'sendersOnlyValue' put: sendersOnly;
			at: 'includeClassSideValue' put: includeClassSideBoolean;
			yourself)
		oopAssignments: Dictionary new
]

{ #category : 'private' }
GbsRepositoryFacade >> hierarchyMethodReferenceStringsCommandBody [
	^ '| sel className classes rootClass scope stream sendersOnly includeClassSide |
sel := selectorValue.
className := rootClassName.
scope := scopeValue.
sendersOnly := sendersOnlyValue.
includeClassSide := includeClassSideValue.
stream := WriteStream on: String new.
classes := IdentitySet new.
rootClass := nil.
className isEmpty ifFalse: [
	(className endsWith: '' class'')
		ifTrue: [ | baseName |
			baseName := className copyFrom: 1 to: className size - 6.
			rootClass := (System myUserProfile symbolList objectNamed: baseName asSymbol) class ]
		ifFalse: [ rootClass := (System myUserProfile symbolList objectNamed: className asSymbol) ] ].
System myUserProfile symbolList do: [ :dict |
	dict keysAndValuesDo: [ :k :v | (v isBehavior) ifTrue: [ classes add: v ] ] ].
rootClass notNil ifTrue: [
	classes := (rootClass withAllSuperclasses , rootClass withAllSubclasses) asIdentitySet ].
classes asArray do: [ :cls |
	| sels |
	sels := sendersOnly
		ifTrue: [ [ cls whichSelectorsReferTo: sel ] on: Error do: [ #() ] ]
		ifFalse: [ (cls includesSelector: sel) ifTrue: [ Array with: sel ] ifFalse: [ #() ] ].
	(rootClass notNil) ifTrue: [
		| withinHierarchy isSuper isThis isSub |
		withinHierarchy := (cls withAllSuperclasses includes: rootClass)
			or: [ rootClass withAllSuperclasses includes: cls ].
		isSuper := (cls ~~ rootClass) and: [ rootClass withAllSuperclasses includes: cls ].
		isThis := cls == rootClass.
		isSub := (cls ~~ rootClass) and: [ cls withAllSuperclasses includes: rootClass ].
		withinHierarchy ifFalse: [ sels := #() ].
		withinHierarchy ifTrue: [
			(scope = ''super'' and: [ isSuper not ]) ifTrue: [ sels := #() ].
			(scope = ''this'' and: [ isThis not ]) ifTrue: [ sels := #() ].
			(scope = ''sub'' and: [ isSub not ]) ifTrue: [ sels := #() ] ] ].
	sels do: [ :s |
		stream nextPutAll: cls name asString; nextPutAll: ''>>''; nextPutAll: s asString; lf ].
	includeClassSide ifTrue: [
		| classSels |
		classSels := sendersOnly
			ifTrue: [ [ cls class whichSelectorsReferTo: sel ] on: Error do: [ #() ] ]
			ifFalse: [ (cls class includesSelector: sel) ifTrue: [ Array with: sel ] ifFalse: [ #() ] ].
		classSels do: [ :s |
			stream nextPutAll: cls name asString; nextPutAll: '' class>>''; nextPutAll: s asString; lf ] ] ].
(stream contents splitOn: Character lf) collect: #trimBoth thenReject: #isEmpty'
]

{ #category : 'private' }
GbsRepositoryFacade >> methodReferenceStringsForSearchBody: searchBody literalAssignments: literalDictionary oopAssignments: oopDictionary [
	^ self
		fetchCommandBody: (self methodReferenceStringsCommandBodyForSearchBody: searchBody)
		literalAssignments: literalDictionary
		oopAssignments: oopDictionary
]

{ #category : 'private' }
GbsRepositoryFacade >> methodReferenceStringsCommandBodyForSearchBody: searchBody [
	^ '| organizer searchResults methods entries |
organizer := ClassOrganizer new.
searchResults := ', searchBody, '.
methods := ((searchResults isArray and: [ searchResults size = 2 ])
	ifTrue: [ searchResults first ]
	ifFalse: [ searchResults ]) ifNil: [ #() ].
entries := OrderedCollection new.
methods do: [ :m |
	| cls isMeta className selectorString |
	cls := [ m inClass ] on: Error do: [ nil ].
	cls ifNotNil: [
		isMeta := [ cls isMeta ] on: Error do: [ false ].
		className := [
			(isMeta
				ifTrue: [ cls theNonMetaClass ]
				ifFalse: [ cls ]) name asString ]
			on: Error
			do: [ nil ].
		selectorString := [ m selector asString ] on: Error do: [ nil ].
		(className notNil and: [ selectorString notNil ]) ifTrue: [
			entries
				add: className
					, (isMeta
						ifTrue: [ '' class>>'' ]
						ifFalse: [ ''>>'' ])
					, selectorString ] ] ].
entries asSet asArray asSortedCollection asArray'
]

{ #category : 'private' }
GbsRepositoryFacade >> listInstancesCommandBody [
	^ 'cls ifNil: [ #() ] ifNotNil: [
	limitValue > 0
		ifTrue: [ (SystemRepository listInstances: { cls } limit: limitValue) at: 1 ]
		ifFalse: [ (SystemRepository listInstances: { cls }) at: 1 ] ]'
]

{ #category : 'private' }
GbsRepositoryFacade >> loadedClassesCommandBody [
	^ '[
		| names |
		names := Set new.
		System myUserProfile symbolList do: [ :dict |
			dict keysAndValuesDo: [ :key :value |
				value isBehavior ifTrue: [ names add: key asString ] ] ].
		names asSortedCollection asArray
	] value'
]

{ #category : 'private' }
GbsRepositoryFacade >> migrateInstancesFromToCommandBody [
	^ '| instances | (fromClass isNil or: [ toClass isNil ]) ifTrue: [ 0 ] ifFalse: [ fromClass == toClass ifTrue: [ 0 ] ifFalse: [ instances := (SystemRepository listInstances: { fromClass }) at: 1. fromClass migrateInstances: instances to: toClass. instances size ] ]'
]

{ #category : 'private' }
GbsRepositoryFacade >> migrateInstancesWithSubclassesCommandBody [
	^ '| oldClasses targetClasses instances migratedCount | topClass ifNil: [ 0 ] ifNotNil: [ oldClasses := OrderedCollection new. targetClasses := OrderedCollection new. topClass withAllSubclasses do: [ :newClass | 1 to: newClass classHistory size - 1 do: [ :index | oldClasses add: (newClass classHistory at: index). targetClasses add: newClass ] ]. oldClasses isEmpty ifTrue: [ 0 ] ifFalse: [ instances := SystemRepository listInstances: oldClasses asArray. migratedCount := 0. 1 to: oldClasses size do: [ :index | | oldClass migratedInstances | oldClass := oldClasses at: index. migratedInstances := instances at: index. migratedCount := migratedCount + migratedInstances size. oldClass migrateInstances: migratedInstances to: (targetClasses at: index) ]. migratedCount ] ]'
]

{ #category : 'private' }
GbsRepositoryFacade >> previewMigrationFromToCommandBody [
	^ '| instances history version total | (fromClass isNil or: [ toClass isNil ]) ifTrue: [ #() ] ifFalse: [ history := [ fromClass classHistory ] on: Error do: [ Array with: fromClass ]. version := [ history indexOf: fromClass ] on: Error do: [ 1 ]. total := history size. instances := (SystemRepository listInstances: { fromClass }) at: 1. Array with: (Array with: fromClass asOop with: fromClass name asString with: version with: total with: toClass asOop with: toClass name asString with: instances size) ]'
]

{ #category : 'private' }
GbsRepositoryFacade >> previewMigrationWithSubclassesCommandBody [
	^ '| oldClasses targetClasses versionIndices totals instances entries history | topClass ifNil: [ #() ] ifNotNil: [ oldClasses := OrderedCollection new. targetClasses := OrderedCollection new. versionIndices := OrderedCollection new. totals := OrderedCollection new. topClass withAllSubclasses do: [ :newClass | history := newClass classHistory. 1 to: history size - 1 do: [ :index | oldClasses add: (history at: index). targetClasses add: newClass. versionIndices add: index. totals add: history size ] ]. oldClasses isEmpty ifTrue: [ #() ] ifFalse: [ instances := SystemRepository listInstances: oldClasses asArray. entries := OrderedCollection new. 1 to: oldClasses size do: [ :index | | oldClass targetClass instanceSet | oldClass := oldClasses at: index. targetClass := targetClasses at: index. instanceSet := instances at: index. entries add: (Array with: oldClass asOop with: oldClass name asString with: (versionIndices at: index) with: (totals at: index) with: targetClass asOop with: targetClass name asString with: instanceSet size) ]. entries asArray ] ]'
]

{ #category : 'querying' }
GbsRepositoryFacade >> namedObjectAt: aName [
	^ session namedObjectAt: aName
]

{ #category : 'querying' }
GbsRepositoryFacade >> namedObjectAt: aName ifAbsent: aBlock [
	^ session namedObjectAt: aName ifAbsent: aBlock
]

{ #category : 'accessing' }
GbsRepositoryFacade >> session [
	^ session
]

{ #category : 'accessing' }
GbsRepositoryFacade >> session: aSession [
	session := aSession
]

{ #category : 'querying' }
GbsRepositoryFacade >> symbolList [
	^ session symbolList
]

{ #category : 'private' }
GbsRepositoryFacade >> prepareForRepositoryScanAllowAbort: aBoolean [
	session needsCommit ifFalse: [ ^ self ].
	aBoolean
		ifFalse: [ GbsError signal: 'Repository scan would abort the current transaction and lose uncommitted changes. Commit or abort first, or pass allowAbort: true.' ].
	session abortTransaction
]

{ #category : 'querying' }
GbsRepositoryFacade >> root [
	^ session
		repositoryRootFacadeForKey: self rootKey
		path: #()
]

{ #category : 'querying' }
GbsRepositoryFacade >> rootAt: aKey [
	^ self root at: aKey
]

{ #category : 'querying' }
GbsRepositoryFacade >> rootAt: aKey ifAbsent: aBlock [
	^ self root at: aKey ifAbsent: aBlock
]

{ #category : 'querying' }
GbsRepositoryFacade >> rootAt: aKey put: aValue [
	^ self root at: aKey put: aValue
]

{ #category : 'private' }
GbsRepositoryFacade >> rootKey [
	^ #GbsBridgeRoot
]
