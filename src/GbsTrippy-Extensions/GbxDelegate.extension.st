Extension { #name : 'GbxDelegate' }

{ #category : '*GbsTrippy-Extensions' }
GbxDelegate >> inspect
[
	InputState default altDown 
		ifTrue: [self gbxOldInspect]
		ifFalse: [(GbxInspectionWrapper on: self) inspect]
]

{ #category : '*GbsTrippy-Extensions' }
GbxDelegate >> browseHierarchy
[
	"If I represent a server class, browse that class. Otherwise, browse the class of the object I represent."

	| className |
	className := self session evaluate: 'self thisClass name' context: self remoteClass. 
	GbxBrowser openHierarchyBrowserOnClassNamed: className session: self session.
]

{ #category : '*GbsTrippy-Extensions' }
GbxDelegate >> gbxInspectorClassDictionary
[
	"Resurrected from GbsObject>>inspectorClassForGSClass: (in 6.1.* and earlier) to let #shiftDown use the old gemstone inspectors."

	^(Dictionary new)
		at: ONil put: GbxInspector;
		at: OAbstractDictionary put: GbxDictionaryInspector;
		at: ORcKeyValueDictionary put: GbxDictionaryInspector;
		at: OBag put: GbxNSCInspector;
		at: OUnorderedCollection put: GbxNSCInspector;
		yourself
]

{ #category : '*GbsTrippy-Extensions' }
GbxDelegate >> inspectableObjectFor: aClass
[
	^aClass gbxIsGbsInspector
		ifTrue: [GbxInspectionWrapper on: self]
		ifFalse: 
			[| sess |
			sess := self session.
			sess sessionCritical: [sess clientObjForDelegate: self otherwise: NotCachedToken]]
]

{ #category : '*GbsTrippy-Extensions' }
GbxDelegate >> browse
[

	self browseHierarchy
]

{ #category : '*GbsTrippy-Extensions' }
GbxDelegate >> gbxOldInspect
[
	"this was the pre-Trippy inspector. pre-Trippy behavior was if shift was down, to open an inspector on just the GbsObject. This has been changed to alt-Shift because to get the old inspectors from the ParagraphEditor, one uses Shift"

	"If left shift is down, inspect the proxy locally.  Otherwise, open a GemStone inspector"

	InputState default altDown 
		ifTrue: [self basicInspect]
		ifFalse: 
			[| sess |
			sess := self session.
			sess sessionCritical: 
					[sess flushDirtyToGS.
					GBSM showBusyWhile: [self inspectorClass openOn: self]]
				unlessBlocked: [self basicInspect]]
]

{ #category : '*GbsTrippy-Extensions' }
GbxDelegate >> inspectorClass
[
	"Should only be used if the old inspectors are active."

	^self gbxInspectorClassFor: self remoteClass
]

{ #category : '*GbsTrippy-Extensions' }
GbxDelegate >> gbxShouldBeWrapped
[
	"when inspecting with trippy, we want to be able to wrap up delegates for inspection. "

	^true
]

{ #category : '*GbsTrippy-Extensions' }
GbxDelegate >> gbxInspectorClassFor: aRemoteClass
[
	"Analogous to gbxInspectorClassesFor: but for the non-Trippy case."

	^self gbxInspectorClassDictionary at: aRemoteClass
		ifAbsent: 
			[self gbxInspectorClassFor: (aRemoteClass session 
						unsynchronizedExecute: 'self superClass'
						context: aRemoteClass)]
]

{ #category : '*GbsTrippy-Extensions' }
GbxDelegate >> delegate
[
	"used in the inspector to wrap objects"

	^self
]

