Extension { #name : 'PartListAbstractInspector' }

{ #category : '*GbsTrippy-Extensions' }
PartListAbstractInspector >> textAccepted: aController
[
	| newValue |
	self class gbxIsGbsInspector ifTrue: [^self gbxTextAccepted: aController].
	newValue := self
				evaluateText: aController text
				from: aController
				ifFail: [^false].
	self replaceSelectionsWith: newValue.
	^true
]

{ #category : '*GbsTrippy-Extensions' }
PartListAbstractInspector >> gbxUpdateInspectorText
[

	documentHolder value: self computeText
]

{ #category : '*GbsTrippy-Extensions' }
PartListAbstractInspector >> gbxTextAccepted: aString
[
	| newValue |
	
	[newValue := object session
				unsynchronizedExecute: aString
				context: object delegate]
			on: GbsError errorSignal
			do: [:ex | ^false].
	self replaceSelectionsWith: newValue.
	self refresh. 
	^true
]

{ #category : '*GbsTrippy-Extensions' }
PartListAbstractInspector >> gbxDoItReceiver
[
	"GBS: get the gbxDoItReceiver if available"

	^(object respondsTo: #gbxDoItReceiver) 
		ifTrue: [object gbxDoItReceiver]
		ifFalse: [object doItReceiver]
]

{ #category : '*GbsTrippy-Extensions' }
PartListAbstractInspector >> gbxDriverPartAt: anIndex
[
	"GBS: default to the normal part unless we need to display something special "

	^self partAt: anIndex
]

{ #category : '*GbsTrippy-Extensions' }
PartListAbstractInspector >> gbxCachedRanges
[
	"return our collection of interval indices which were cached"

	^object cachedRanges
]

