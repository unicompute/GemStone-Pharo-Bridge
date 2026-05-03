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
	^ session
		executeScriptAndFetchObject: (self allInstancesScriptFor: aClassOrName)
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
	rows := session executeScriptAndFetchObject: self namespaceMirrorEntriesScript.
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
	^ session
		executeScriptAndReturnOop: (self allInstancesScriptFor: aClassOrName)
]

{ #category : 'querying' }
GbsRepositoryFacade >> allInstancesOopOfNamed: aClassName [
	^ self allInstancesOopOf: aClassName
]

{ #category : 'private' }
GbsRepositoryFacade >> allInstancesScriptFor: aClassOrName [
	^ String streamContents: [ :stream |
		stream
			nextPutAll: '| cls | cls := ';
			nextPutAll: (self classExpressionFor: aClassOrName);
			nextPutAll: '. cls ifNil: [ nil ] ifNotNil: [ cls allInstances ]' ]
]

{ #category : 'private' }
GbsRepositoryFacade >> classExpressionFor: aClassOrName [
	(aClassOrName respondsTo: #proxy) ifTrue: [
		^ self classExpressionFor: aClassOrName proxy ].
	(aClassOrName isKindOf: GbsProxy) ifTrue: [
		^ '(Object _objectForOop: ', aClassOrName oop printString, ')' ].
	(aClassOrName isBehavior or: [
		aClassOrName class name asString includesSubstring: 'Behavior' ]) ifTrue: [
		^ self classExpressionFor: aClassOrName name ].
	((aClassOrName isString) or: [ aClassOrName isSymbol ]) ifTrue: [
		^ String streamContents: [ :stream |
			stream
				nextPutAll: '[:name | System myUserProfile symbolList objectNamed: name asSymbol] value: ';
				nextPutAll: (session marshalArgumentToScript: aClassOrName) ] ].
	self error: 'Unsupported class reference: ', aClassOrName printString
]

{ #category : 'private' }
GbsRepositoryFacade >> namespaceMirrorEntriesScript [
	^ '| sl entries | sl := System myUserProfile symbolList. entries := OrderedCollection new. 1 to: sl size do: [ :index | | ns name fullName myClassName | ns := sl at: index. name := [ (ns respondsTo: #name) ifTrue: [ ns name ] ifFalse: [ nil ] ] on: Error do: [ nil ]. fullName := [ (ns respondsTo: #fullName) ifTrue: [ ns fullName ] ifFalse: [ nil ] ] on: Error do: [ nil ]. myClassName := [ (ns respondsTo: #myClass) ifTrue: [ ns myClass ifNil: [ nil ] ifNotNil: [ ns myClass name asString ] ] ifFalse: [ nil ] ] on: Error do: [ nil ]. entries add: (Array with: index with: ns asOop with: (name ifNil: [ nil ] ifNotNil: [ name asString ]) with: (fullName ifNil: [ nil ] ifNotNil: [ fullName asString ]) with: ns class name asString with: myClassName) ]. entries asArray'
]

{ #category : 'querying' }
GbsRepositoryFacade >> loadedClasses [
	^ session executeScriptAndFetchObject: self loadedClassesScript
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
	rawEntries := session
		executeScriptAndFetchObject: (self
			previewMigrationScriptFrom: aSourceClassOrName
			to: aTargetClassOrName).
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
	rawEntries := session
		executeScriptAndFetchObject: (self
			previewMigrationWithSubclassesScriptFor: aTopClassOrName).
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
	^ session
		executeScriptAndFetchObject: (self
			migrateInstancesScriptFrom: aSourceClassOrName
			to: aTargetClassOrName)
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
	^ session
		executeScriptAndFetchObject: (self
			migrateInstancesWithSubclassesScriptFor: aTopClassOrName)
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
	^ session
		executeScriptAndFetchObject: (self listInstancesScriptFor: aClassOrName limit: aSmallInteger)
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
	^ session
		executeScriptAndFetchObject: (self implementorMethodReferenceStringsScriptFor: aSelectorOrString)
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
	^ session
		executeScriptAndFetchObject:
			(self
				hierarchyMethodReferenceStringsScriptFor: aSelectorOrString
				rootClassName: aRootClassName
				scope: aScopeString
				senders: false
				includeClassSide: includeClassSideBoolean)
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
	^ session
		executeScriptAndFetchObject:
			(self
				hierarchyMethodReferenceStringsScriptFor: aSelectorOrString
				rootClassName: aRootClassName
				scope: aScopeString
				senders: true
				includeClassSide: includeClassSideBoolean)
]

{ #category : 'querying' }
GbsRepositoryFacade >> methodReferenceStringsToObject: anObject [
	^ session
		executeScriptAndFetchObject: (self methodReferenceStringsToObjectScriptFor: anObject)
]

{ #category : 'querying' }
GbsRepositoryFacade >> methodReferenceStringsToSymbol: aSymbolOrString [
	^ session
		executeScriptAndFetchObject: (self methodReferenceStringsToSymbolScriptFor: aSymbolOrString)
]

{ #category : 'querying' }
GbsRepositoryFacade >> senderMethodReferenceStringsForSelector: aSelectorOrString [
	^ session
		executeScriptAndFetchObject: (self senderMethodReferenceStringsScriptFor: aSelectorOrString)
]

{ #category : 'private' }
GbsRepositoryFacade >> implementorMethodReferenceStringsScriptFor: aSelectorOrString [
	^ self
		methodReferenceStringsScriptForSearchExpression:
			(String streamContents: [ :stream |
				stream
					nextPutAll: '[ organizer implementorsOf: ';
					nextPutAll: (session marshalArgumentToScript: aSelectorOrString asString asSymbol);
					nextPutAll: ' ] on: Error do: [ #() ]' ])
]

{ #category : 'private' }
GbsRepositoryFacade >> hierarchyMethodReferenceStringsScriptFor: aSelectorOrString rootClassName: aRootClassName scope: aScopeString senders: sendersOnly includeClassSide: includeClassSideBoolean [
	| escapedSelector escapedRootClass escapedScope selectorExpr classFilterExpr classSideExpr |
	escapedSelector := aSelectorOrString asString copyReplaceAll: '''' with: ''''''.
	escapedRootClass := (aRootClassName ifNil: [ '' ] ifNotNil: [ aRootClassName asString ]) copyReplaceAll: '''' with: ''''''.
	escapedScope := (aScopeString ifNil: [ 'full' ] ifNotNil: [ aScopeString asString ]) copyReplaceAll: '''' with: ''''''.
	selectorExpr := sendersOnly
		ifTrue: [ 'sels := [ cls whichSelectorsReferTo: sel ] on: Error do: [ #() ]' ]
		ifFalse: [ 'sels := (cls includesSelector: sel) ifTrue: [ Array with: sel ] ifFalse: [ #() ]' ].
	classFilterExpr := '
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
					(scope = ''sub'' and: [ isSub not ]) ifTrue: [ sels := #() ] ] ]'.
	classSideExpr := includeClassSideBoolean
		ifTrue: [
			String streamContents: [ :stream |
				stream
					nextPutAll: '
			';
					nextPutAll: (sendersOnly
						ifTrue: [ 'sels := [ cls class whichSelectorsReferTo: sel ] on: Error do: [ #() ]' ]
						ifFalse: [ 'sels := (cls class includesSelector: sel) ifTrue: [ Array with: sel ] ifFalse: [ #() ]' ]);
					nextPutAll: '.
			sels do: [ :s |
				stream nextPutAll: cls name asString; nextPutAll: '' class>>''; nextPutAll: s asString; lf ]' ] ]
		ifFalse: [ '' ].
	^ String streamContents: [ :stream |
		stream
			nextPutAll: '[
		| sel className classes rootClass scope stream |
		sel := #''';
			nextPutAll: escapedSelector;
			nextPutAll: '''.
		className := ''';
			nextPutAll: escapedRootClass;
			nextPutAll: '''.
		scope := ''';
			nextPutAll: escapedScope;
			nextPutAll: '''.
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
			';
			nextPutAll: selectorExpr;
			nextPutAll: '.
			';
			nextPutAll: classFilterExpr;
			nextPutAll: '.
			sels do: [ :s |
				stream nextPutAll: cls name asString; nextPutAll: ''>>''; nextPutAll: s asString; lf ].';
			nextPutAll: classSideExpr;
			nextPutAll: '
		].
		(stream contents splitOn: Character lf) collect: #trimBoth thenReject: #isEmpty
	] value' ]
]

{ #category : 'private' }
GbsRepositoryFacade >> methodReferenceStringsScriptForSearchExpression: searchExpression [
	^ String streamContents: [ :stream |
		stream
			nextPutAll: '| organizer searchResults methods entries |
organizer := ClassOrganizer new.
searchResults := ';
			nextPutAll: searchExpression;
			nextPutAll: '.
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
entries asSet asArray asSortedCollection asArray' ]
]

{ #category : 'private' }
GbsRepositoryFacade >> methodReferenceStringsToObjectScriptFor: anObject [
	^ self
		methodReferenceStringsScriptForSearchExpression:
			(String streamContents: [ :stream |
				stream
					nextPutAll: '[ organizer referencesToObject: ';
					nextPutAll: (session marshalArgumentToScript: anObject);
					nextPutAll: ' ] on: Error do: [ #() ]' ])
]

{ #category : 'private' }
GbsRepositoryFacade >> methodReferenceStringsToSymbolScriptFor: aSymbolOrString [
	^ self
		methodReferenceStringsScriptForSearchExpression:
			(String streamContents: [ :stream |
				stream
					nextPutAll: '[ organizer referencesTo: ';
					nextPutAll: (session marshalArgumentToScript: aSymbolOrString asString asSymbol);
					nextPutAll: ' ] on: Error do: [ #() ]' ])
]

{ #category : 'private' }
GbsRepositoryFacade >> senderMethodReferenceStringsScriptFor: aSelectorOrString [
	^ self
		methodReferenceStringsScriptForSearchExpression:
			(String streamContents: [ :stream |
				stream
					nextPutAll: '[ organizer sendersOf: ';
					nextPutAll: (session marshalArgumentToScript: aSelectorOrString asString);
					nextPutAll: ' ] on: Error do: [ #() ]' ])
]

{ #category : 'private' }
GbsRepositoryFacade >> listInstancesScriptFor: aClassOrName limit: aSmallInteger [
	^ String streamContents: [ :stream |
		stream
			nextPutAll: '| cls | cls := ';
			nextPutAll: (self classExpressionFor: aClassOrName);
			nextPutAll: '. cls ifNil: [ #() ] ifNotNil: [ (SystemRepository listInstances: { cls }'.
		aSmallInteger > 0 ifTrue: [
			stream
				nextPutAll: ' limit: ';
				nextPutAll: aSmallInteger printString ].
		stream nextPutAll: ') at: 1 ]' ]
]

{ #category : 'private' }
GbsRepositoryFacade >> loadedClassesScript [
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
GbsRepositoryFacade >> migrateInstancesScriptFrom: aSourceClassOrName to: aTargetClassOrName [
	^ String streamContents: [ :stream |
		stream
			nextPutAll: '| fromClass toClass instances | fromClass := ';
			nextPutAll: (self classExpressionFor: aSourceClassOrName);
			nextPutAll: '. toClass := ';
			nextPutAll: (self classExpressionFor: aTargetClassOrName);
			nextPutAll: '. (fromClass isNil or: [ toClass isNil ]) ifTrue: [ 0 ] ifFalse: [ fromClass == toClass ifTrue: [ 0 ] ifFalse: [ instances := (SystemRepository listInstances: { fromClass }) at: 1. fromClass migrateInstances: instances to: toClass. instances size ] ]' ]
]

{ #category : 'private' }
GbsRepositoryFacade >> migrateInstancesWithSubclassesScriptFor: aTopClassOrName [
	^ String streamContents: [ :stream |
		stream
			nextPutAll: '| topClass oldClasses targetClasses instances migratedCount | topClass := ';
			nextPutAll: (self classExpressionFor: aTopClassOrName);
			nextPutAll: '. topClass ifNil: [ 0 ] ifNotNil: [ oldClasses := OrderedCollection new. targetClasses := OrderedCollection new. topClass withAllSubclasses do: [ :newClass | 1 to: newClass classHistory size - 1 do: [ :index | oldClasses add: (newClass classHistory at: index). targetClasses add: newClass ] ]. oldClasses isEmpty ifTrue: [ 0 ] ifFalse: [ instances := SystemRepository listInstances: oldClasses asArray. migratedCount := 0. 1 to: oldClasses size do: [ :index | | oldClass migratedInstances | oldClass := oldClasses at: index. migratedInstances := instances at: index. migratedCount := migratedCount + migratedInstances size. oldClass migrateInstances: migratedInstances to: (targetClasses at: index) ]. migratedCount ] ]' ]
]

{ #category : 'private' }
GbsRepositoryFacade >> previewMigrationScriptFrom: aSourceClassOrName to: aTargetClassOrName [
	^ String streamContents: [ :stream |
		stream
			nextPutAll: '| fromClass toClass instances history version total | fromClass := ';
			nextPutAll: (self classExpressionFor: aSourceClassOrName);
			nextPutAll: '. toClass := ';
			nextPutAll: (self classExpressionFor: aTargetClassOrName);
			nextPutAll: '. (fromClass isNil or: [ toClass isNil ]) ifTrue: [ #() ] ifFalse: [ history := [ fromClass classHistory ] on: Error do: [ Array with: fromClass ]. version := [ history indexOf: fromClass ] on: Error do: [ 1 ]. total := history size. instances := (SystemRepository listInstances: { fromClass }) at: 1. Array with: (Array with: fromClass asOop with: fromClass name asString with: version with: total with: toClass asOop with: toClass name asString with: instances size) ]' ]
]

{ #category : 'private' }
GbsRepositoryFacade >> previewMigrationWithSubclassesScriptFor: aTopClassOrName [
	^ String streamContents: [ :stream |
		stream
			nextPutAll: '| topClass oldClasses targetClasses versionIndices totals instances entries history | topClass := ';
			nextPutAll: (self classExpressionFor: aTopClassOrName);
			nextPutAll: '. topClass ifNil: [ #() ] ifNotNil: [ oldClasses := OrderedCollection new. targetClasses := OrderedCollection new. versionIndices := OrderedCollection new. totals := OrderedCollection new. topClass withAllSubclasses do: [ :newClass | history := newClass classHistory. 1 to: history size - 1 do: [ :index | oldClasses add: (history at: index). targetClasses add: newClass. versionIndices add: index. totals add: history size ] ]. oldClasses isEmpty ifTrue: [ #() ] ifFalse: [ instances := SystemRepository listInstances: oldClasses asArray. entries := OrderedCollection new. 1 to: oldClasses size do: [ :index | | oldClass targetClass instanceSet | oldClass := oldClasses at: index. targetClass := targetClasses at: index. instanceSet := instances at: index. entries add: (Array with: oldClass asOop with: oldClass name asString with: (versionIndices at: index) with: (totals at: index) with: targetClass asOop with: targetClass name asString with: instanceSet size) ]. entries asArray ] ]' ]
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
