Extension { #name : 'InspectorShell' }

{ #category : '*GbsTrippy-Extensions' }
InspectorShell >> gbxDoItAgent
[
	
	^installedNavigator gbxDoItAgent
]

{ #category : '*GbsTrippy-Extensions' }
InspectorShell >> gbxInstalledNavigator
[

	^installedNavigator
]

{ #category : '*GbsTrippy-Extensions' }
InspectorShell >> gbxShell
[
	^self
]

{ #category : '*GbsTrippy-Extensions' }
InspectorShell >> gbxDoveIntoGemStoneObject
[

	^(trail detect: [:visit | visit object gbxIsWrapped] ifNone: []) notNil
]

{ #category : '*GbsTrippy-Extensions' }
InspectorShell >> gbxIsReplicateInspector
[
	"Is inspector showing objects from the client and GemStone"

	^installedNavigator gbxHasGemStoneTabs
		and: [installedNavigator gbxHasNonGemStoneTabs]
]

{ #category : '*GbsTrippy-Extensions' }
InspectorShell >> gbxHasShell
[

	^true	"For lo, I am a shell"
]

{ #category : '*GbsTrippy-Extensions' }
InspectorShell >> gbxHasNonGemStoneTabs
[

	^installedNavigator gbxHasNonGemStoneTabs
]

{ #category : '*GbsTrippy-Extensions' }
InspectorShell >> gbxHasGemStoneTabs
[

	^installedNavigator
		ifNil: [false]
		ifNotNil: [:nav | nav gbxHasGemStoneTabs]
]

{ #category : '*GbsTrippy-Extensions' }
InspectorShell >> gbxNoDives
[

	^trail size = 1
]

{ #category : '*GbsTrippy-Extensions' }
InspectorShell >> isGemStoneInspector
[

	^self gbxHasGemStoneTabs
]

{ #category : '*GbsTrippy-Extensions' }
InspectorShell >> addExploreItemsTo: aMenu
[
	| hierarchies |
	hierarchies := (GemStone.Gbs.GbxReflection isProxy: self object)
				ifTrue: [Array new]
				ifFalse: 
					[GemStone.Gbs.GbxReflection
						send: #inspectorHierarchies
						to: self object
						ifNotUnderstood: [^self]].
	hierarchies isEmpty
		ifFalse: 
			[aMenu addLine.
			hierarchies do: 
					[:each |
					| item |
					item := MenuItem labeled: each label.
					item value: [self exploreHierarchy: each].
					self navigator vicinity = each id ifTrue: [item beOn].
					aMenu addItem: item]]
]

{ #category : '*GbsTrippy-Extensions' }
InspectorShell >> addCollaboratorItemsTo: aMenu
[
	| collaborators item |
	collaborators := (GemStone.Gbs.GbxReflection isProxy: self object)
				ifTrue: [Array new]
				ifFalse: 
					[GemStone.Gbs.GbxReflection
						send: #inspectorCollaborators
						to: self object
						ifNotUnderstood: [^self]].
	collaborators do: 
			[:each |
			item := MenuItem labeled: (#ToCollaborator << #menus >> 'To <1s>'
								expandMacrosWith: each label).
			item value: [self diveIntoCollaborator: each].
			aMenu addItem: item]
]

{ #category : '*GbsTrippy-Extensions' }
InspectorShell >> refreshWindowLabel
[

	self gbxHasGemStoneTabs
		ifTrue: [builder window icon: GemStone.Gbs.GbxVisualLauncher gemIcon]
		ifFalse: [builder window icon: (Icon constantNamed: #default)].
	builder window label: self visit displayString
]

{ #category : '*GbsTrippy-Extensions' }
InspectorShell >> gbxCancelToken
[
	^self class gbxCancelToken
]

{ #category : '*GbsTrippy-Extensions' }
InspectorShell >> gbxDoItReceiver
[
	"grab the visit's object (through the installedNavigator), not the current inspector's object)"
	
	^(Inspector wrappedOrNot: self navigator object) gbxDoItReceiver
]

{ #category : '*GbsTrippy-Extensions' }
InspectorShell >> doItReceiver
[
	"the doItReceiver should be the object except for GbxInspectionWrappers which then return the localObject. The inspector can choose to have a different doItReceiver if need be.
	See Inspector>>doItReceiver which returns the object"

	^self inspector doItReceiver
]

{ #category : '*GbsTrippy-Extensions' }
InspectorShell >> noticeOfWindowClose: aWindow
[
	"make sure we disconnect from our session"

	GBSM sessions do: [:sess | sess removeDependent: self].
	super noticeOfWindowClose: aWindow
]

{ #category : '*GbsTrippy-Extensions' }
InspectorShell >> addDependencyToSession: aSession
[
	"This can be invoked multiple times, so make certain
	 we only add the dependency once."

	(aSession dependents includes: self) ifTrue: [^self].
	aSession addDependent: self.
]

{ #category : '*GbsTrippy-Extensions' }
InspectorShell >> receiveEventsFrom: anObject
[
	(GemStone.Gbs.GbxReflection isWrapped: anObject)
		ifTrue: 
			[
			[self addDependencyToSession: anObject session.
			anObject when: #objectChanged send: #inspectedObjectChanged to: self]
					on: GbsError errorSignal
					do: [:ex | self addDependencyToSession: GBSM currentSession]]
]

{ #category : '*GbsTrippy-Extensions' }
InspectorShell >> inspectedObjectChanged
[
	"if we get here a stub has faulted or a refresh is needed. "

	| inspectorClass wrapper obj |
	obj := installedNavigator object.
	wrapper := GemStone.Gbs.GbxInspectionWrapper on: obj delegate.
	wrapper inspectedObject: obj.
	self visit setObject: wrapper.
	self receiveEventsFrom: wrapper.
	inspectorClass := (Inspector gbxCautiousInspectorClassesFor: self visit object) at: 1.
	installedNavigator inspector: (inspectorClass on: (self visit object inspectableObjectFor: inspectorClass)).
	installedNavigator refreshInspectorClasses.
	self refresh
]

{ #category : '*GbsTrippy-Extensions' }
InspectorShell >> sessionTerminated: anObject
[
	"the session is going away. Make sure to chop off the gemstone tabs without trying to become a gemstone object again. "

	| inspectorClass |
	self visit resetObjectWhileSessionTerminating: anObject.
	self receiveEventsFrom: anObject.
	inspectorClass := (Inspector gbxCautiousInspectorClassesFor: anObject) at: 1.
	installedNavigator inspector: (inspectorClass on: (anObject inspectableObjectFor: inspectorClass)).
	installedNavigator refreshLocalInspectorClasses.
	installedNavigator nilInitialInspector.
	self refresh
]

{ #category : '*GbsTrippy-Extensions' }
InspectorShell >> update: aSymbol
[
	"If there are no GemStone object dives and it is a replicate inspector, 
	remove the GemStone tabs but leave the inspector open. Else shut it down."

	| localObj |
	self builder ifNil: [^self	"dead inspector"].
	aSymbol = #sessionTerminated
		ifTrue: 
			[self navigator isNil ifTrue: [^self closeAndUnschedule].
			(self gbxIsReplicateInspector and: [self gbxNoDives])
				ifTrue: 
					[localObj := self visit object localObject.
					(GemStone.Gbs.GbxReflection isProxy: localObj)
						ifTrue: [self closeAndUnschedule]
						ifFalse: [self sessionTerminated: localObj]]
				ifFalse: [self gbxDoveIntoGemStoneObject ifTrue: [self closeAndUnschedule]]]
]

{ #category : '*GbsTrippy-Extensions' }
InspectorShell class >> gbxCancelToken
[
	"Answer a unique token whose identity can be used
	 to indicate an operation has been canceled."

	^'canceled'
]

