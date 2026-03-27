Extension { #name : 'GbxAbstractProxy' }

{ #category : '*GbsTrippy-Extensions' }
GbxAbstractProxy >> gbxShouldBeWrapped
[
	"when inspecting with trippy, we want to be able to wrap up stubs and forwarders for inspection. "

	^true
]

{ #category : '*GbsTrippy-Extensions' }
GbxAbstractProxy >> inspectableObjectFor: aClass
[
	^Tools.Trippy.Inspector wrappedOrNot: self
]

{ #category : '*GbsTrippy-Extensions' }
GbxAbstractProxy >> inspect
[
	"shift down brings up the old inspectors"

	^InputState default altDown 
		ifTrue: [self gbxOldInspect]
		ifFalse: [(GbxInspectionWrapper on: self) inspect]
]

{ #category : '*GbsTrippy-Extensions' }
GbxAbstractProxy >> gbxIsWrapped
[
	^false
]

{ #category : '*GbsTrippy-Extensions' }
GbxAbstractProxy >> gbxOldInspect
[
	^InputState default altDown 
		ifTrue: [self basicInspect]
		ifFalse: [self inspectorClass openOn: self]
]

