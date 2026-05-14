Class {
	#name : 'GbsRemoteDebuggerMethodNavigator',
	#superclass : 'Object',
	#instVars : [
		'debugger'
	],
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'instance creation' }
GbsRemoteDebuggerMethodNavigator class >> on: aDebugger [
	^ self new
		debugger: aDebugger;
		yourself
]

{ #category : 'local browsing' }
GbsRemoteDebuggerMethodNavigator >> browseLocalHierarchyImplementors [
	^ self browseLocalHierarchyImplementorsFor: self selectedServerSelector
]

{ #category : 'local browsing' }
GbsRemoteDebuggerMethodNavigator >> browseLocalHierarchyImplementorsFor: aSelector [
	| className behavior methods |
	className := self selectedServerClassName.
	(aSelector isNil or: [ className isNil ]) ifTrue: [ ^ false ].
	behavior := self localBehaviorFromServerClassName: className.
	behavior ifNil: [ ^ false ].
	methods := (behavior withAllSuperclasses , behavior withAllSubclasses)
		collect: [ :cls | cls compiledMethodAt: aSelector ifAbsent: [ nil ] ]
		thenReject: #isNil.
	^ self browseOrInspectMethods: methods
]

{ #category : 'local browsing' }
GbsRemoteDebuggerMethodNavigator >> browseLocalHierarchySenders [
	^ self browseLocalHierarchySendersFor: self selectedServerSelector
]

{ #category : 'local browsing' }
GbsRemoteDebuggerMethodNavigator >> browseLocalHierarchySendersFor: aSelector [
	| className behavior methods |
	className := self selectedServerClassName.
	(aSelector isNil or: [ className isNil ]) ifTrue: [ ^ false ].
	behavior := self localBehaviorFromServerClassName: className.
	behavior ifNil: [ ^ false ].
	methods := OrderedCollection new.
	(behavior withAllSuperclasses , behavior withAllSubclasses) do: [ :cls |
		methods addAll: (cls whichSelectorsReferTo: aSelector) collect: [ :sel |
			cls compiledMethodAt: sel ifAbsent: [ nil ] ] ].
	^ self browseOrInspectMethods: (methods thenReject: #isNil)
]

{ #category : 'local browsing' }
GbsRemoteDebuggerMethodNavigator >> browseLocalImplementors [
	^ self browseLocalImplementorsFor: self selectedServerSelector
]

{ #category : 'local browsing' }
GbsRemoteDebuggerMethodNavigator >> browseLocalImplementorsFor: aSelector [
	aSelector ifNil: [ ^ false ].
	(SystemNavigation default respondsTo: #browseAllImplementorsOf:)
		ifTrue: [ SystemNavigation default browseAllImplementorsOf: aSelector. ^ true ].
	^ false
]

{ #category : 'local browsing' }
GbsRemoteDebuggerMethodNavigator >> browseLocalSenders [
	^ self browseLocalSendersFor: self selectedServerSelector
]

{ #category : 'local browsing' }
GbsRemoteDebuggerMethodNavigator >> browseLocalSendersFor: aSelector [
	aSelector ifNil: [ ^ false ].
	(SystemNavigation default respondsTo: #browseAllSendersOf:)
		ifTrue: [ SystemNavigation default browseAllSendersOf: aSelector. ^ true ].
	^ false
]

{ #category : 'private' }
GbsRemoteDebuggerMethodNavigator >> browseOrInspectMethods: methods [
	methods isEmpty ifTrue: [ ^ false ].
	methods size = 1
		ifTrue: [ methods first browse ]
		ifFalse: [ methods inspect ].
	^ true
]

{ #category : 'remote browsing' }
GbsRemoteDebuggerMethodNavigator >> browseSelectedMethod [
	(self service respondsTo: #browseMethod)
		ifTrue: [ ^ debugger safeServiceCall: [ self service browseMethod ] default: false ].
	^ self openServerMethodReference: self selectedServerMethodReference
]

{ #category : 'accessing' }
GbsRemoteDebuggerMethodNavigator >> debugger [
	^ debugger
]

{ #category : 'accessing' }
GbsRemoteDebuggerMethodNavigator >> debugger: aDebugger [
	debugger := aDebugger
]

{ #category : 'remote browsing' }
GbsRemoteDebuggerMethodNavigator >> gsBrowseAllHierarchyImplementors [
	^ self gsBrowseQueryFor: self selectedServerSelector hierarchyOnly: true senders: false
]

{ #category : 'remote browsing' }
GbsRemoteDebuggerMethodNavigator >> gsBrowseAllHierarchyImplementorsFor: aSelector [
	^ self gsBrowseQueryFor: aSelector hierarchyOnly: true senders: false
]

{ #category : 'remote browsing' }
GbsRemoteDebuggerMethodNavigator >> gsBrowseAllHierarchyReferences [
	^ self gsBrowseQueryFor: self selectedServerSelector hierarchyOnly: true senders: true
]

{ #category : 'remote browsing' }
GbsRemoteDebuggerMethodNavigator >> gsBrowseAllHierarchyReferencesFor: aSelector [
	^ self gsBrowseQueryFor: aSelector hierarchyOnly: true senders: true
]

{ #category : 'remote browsing' }
GbsRemoteDebuggerMethodNavigator >> gsBrowseAllImplementors [
	^ self gsBrowseQueryFor: self selectedServerSelector hierarchyOnly: false senders: false
]

{ #category : 'remote browsing' }
GbsRemoteDebuggerMethodNavigator >> gsBrowseAllImplementorsFor: aSelector [
	^ self gsBrowseQueryFor: aSelector hierarchyOnly: false senders: false
]

{ #category : 'remote browsing' }
GbsRemoteDebuggerMethodNavigator >> gsBrowseAllReferences [
	^ self gsBrowseQueryFor: self selectedServerSelector hierarchyOnly: false senders: true
]

{ #category : 'remote browsing' }
GbsRemoteDebuggerMethodNavigator >> gsBrowseAllReferencesFor: aSelector [
	^ self gsBrowseQueryFor: aSelector hierarchyOnly: false senders: true
]

{ #category : 'remote browsing' }
GbsRemoteDebuggerMethodNavigator >> gsBrowseQueryFor: aSelector hierarchyOnly: hierarchyOnly senders: sendersOnly [
	| references selected |
	aSelector ifNil: [ ^ false ].
	references := self serverMethodReferencesFor: aSelector hierarchyOnly: hierarchyOnly senders: sendersOnly.
	references isEmpty ifTrue: [
		UIManager default inform: 'No matching GemStone methods found.'.
		^ false ].
	selected := debugger chooseMethodReferenceFrom: references title: 'GemStone Methods'.
	selected ifNil: [ ^ false ].
	^ self openServerMethodReference: selected
]

{ #category : 'private' }
GbsRemoteDebuggerMethodNavigator >> localBehaviorFromServerClassName: classNameString [
	| baseName |
	classNameString ifNil: [ ^ nil ].
	baseName := classNameString asString.
	(baseName endsWith: ' class')
		ifTrue: [ baseName := baseName copyFrom: 1 to: baseName size - 6 ].
	^ Smalltalk at: baseName asSymbol ifAbsent: [ nil ]
]

{ #category : 'remote browsing' }
GbsRemoteDebuggerMethodNavigator >> openServerMethodReference: aReferenceString [
	| split classPart selectorPart browser classSide className |
	(aReferenceString isString and: [ aReferenceString includesSubstring: '>>' ]) ifFalse: [ ^ false ].
	split := aReferenceString findString: '>>' startingAt: 1.
	classPart := (aReferenceString copyFrom: 1 to: split - 1) trimBoth.
	selectorPart := (aReferenceString copyFrom: split + 2 to: aReferenceString size) trimBoth.
	classSide := classPart endsWith: ' class'.
	className := classSide
		ifTrue: [ classPart copyFrom: 1 to: classPart size - 6 ]
		ifFalse: [ classPart ].
	browser := GbsBrowser openOn: debugger session.
	(browser respondsTo: #selectClassNamed:classSide:method:)
		ifTrue: [ browser selectClassNamed: className classSide: classSide method: selectorPart ].
	^ true
]

{ #category : 'accessing' }
GbsRemoteDebuggerMethodNavigator >> selectedServerClassName [
	self service ifNil: [ ^ nil ].
	^ debugger safeServiceCall: [ self service selectedMethodClassName ] default: nil
]

{ #category : 'accessing' }
GbsRemoteDebuggerMethodNavigator >> selectedServerMethodReference [
	| className selector |
	className := self selectedServerClassName.
	selector := self selectedServerSelector.
	(className isNil or: [ selector isNil ]) ifTrue: [ ^ nil ].
	^ className asString , '>>' , selector asString
]

{ #category : 'accessing' }
GbsRemoteDebuggerMethodNavigator >> selectedServerSelector [
	self service ifNil: [ ^ nil ].
	^ debugger safeServiceCall: [ self service selectedMethodSelector ] default: nil
]

{ #category : 'menus' }
GbsRemoteDebuggerMethodNavigator >> selectorCandidatesForQueryMenus [
	| source tokens selectors current |
	selectors := OrderedCollection new.
	current := self selectedServerSelector.
	current ifNotNil: [ selectors add: current ].
	source := debugger selectedSourceOrAll ifNil: [ '' ].
	tokens := source findTokens: ' [](){}|.,;''"!?+-*/<>=\t\r\n'.
	tokens do: [ :tok |
		| s |
		s := tok asString trimBoth.
		(s isEmpty or: [ s first isDigit ]) ifFalse: [
			(s allSatisfy: [ :ch | ch isAlphaNumeric or: [ ch = $_ or: [ ch = $: ] ] ])
				ifTrue: [ [ selectors add: s asSymbol ] on: Error do: [ ] ] ] ].
	^ selectors asSet asArray asSortedCollection
]

{ #category : 'menus' }
GbsRemoteDebuggerMethodNavigator >> selectorQuerySubMenuUsing: aBlock [
	| selectors menu |
	selectors := self selectorCandidatesForQueryMenus.
	menu := debugger newMenu.
	selectors isEmpty ifTrue: [
		menu addItem: [ :item | item name: '<none>'; action: [ false ] ].
		^ menu ].
	selectors do: [ :sel |
		menu addItem: [ :item |
			item name: sel asString.
			item action: [ aBlock value: sel ] ] ].
	^ menu
]

{ #category : 'accessing' }
GbsRemoteDebuggerMethodNavigator >> service [
	^ debugger service
]

{ #category : 'remote browsing' }
GbsRemoteDebuggerMethodNavigator >> serverMethodReferencesFor: aSelector hierarchyOnly: hierarchyOnly senders: sendersOnly [
	| className raw |
	debugger session ifNil: [ ^ #( ) ].
	className := self selectedServerClassName.
	raw := [
		GbsRemoteExecutionDispatcher
			fetchCommandBody: '
		| classes root stream |
		stream := WriteStream on: String new.
		classes := IdentitySet new.
		System myUserProfile symbolList do: [ :dict |
			dict keysAndValuesDo: [ :k :v |
				(v isBehavior) ifTrue: [ classes add: v ] ] ].
		root := nil.
		className isEmpty ifFalse: [
			(className endsWith: '' class'')
				ifTrue: [ | baseName |
					baseName := className copyFrom: 1 to: className size - 6.
					root := (System myUserProfile symbolList objectNamed: baseName asSymbol) class ]
				ifFalse: [ root := (System myUserProfile symbolList objectNamed: className asSymbol) ] ].
		hierarchyOnly ifTrue: [
			root notNil ifTrue: [
				classes := (root withAllSuperclasses , root withAllSubclasses) asIdentitySet ] ].
		classes asArray do: [ :cls |
			| sels |
			sendersOnly
				ifTrue: [ sels := [ cls whichSelectorsReferTo: selector ] on: Error do: [ #() ] ]
				ifFalse: [ sels := (cls includesSelector: selector) ifTrue: [ Array with: selector ] ifFalse: [ #() ] ].
			sels do: [ :s |
				stream nextPutAll: cls name asString; nextPutAll: ''>>''; nextPutAll: s asString; lf ].
			sendersOnly
				ifTrue: [ sels := [ cls class whichSelectorsReferTo: selector ] on: Error do: [ #() ] ]
				ifFalse: [ sels := (cls class includesSelector: selector) ifTrue: [ Array with: selector ] ifFalse: [ #() ] ].
			sels do: [ :s |
				stream nextPutAll: cls name asString; nextPutAll: '' class>>''; nextPutAll: s asString; lf ] ].
		stream contents
	'
			literalBindings: (Dictionary new
				at: 'className' put: (className ifNil: [ '' ]) asString;
				at: 'hierarchyOnly' put: hierarchyOnly;
				at: 'selector' put: aSelector asSymbol;
				at: 'sendersOnly' put: sendersOnly;
				yourself)
			oopBindings: Dictionary new
			in: debugger session
			context: 20 ] on: Error do: [ '' ].
	(raw respondsTo: #asLocalString) ifTrue: [ raw := raw asLocalString ].
	^ (raw splitOn: Character lf) collect: #trimBoth thenReject: #isEmpty
]

{ #category : 'local browsing' }
GbsRemoteDebuggerMethodNavigator >> showContainingPackage [
	| className behavior package |
	className := self selectedServerClassName.
	className ifNil: [ ^ false ].
	behavior := self localBehaviorFromServerClassName: className.
	behavior ifNil: [ ^ false ].
	package := behavior package ifNil: [ ^ false ].
	(UIManager default respondsTo: #inform:)
		ifTrue: [ UIManager default inform: package name ].
	^ true
]
