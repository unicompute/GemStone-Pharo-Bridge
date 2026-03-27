Extension { #name : 'Inspector' }

{ #category : '*GbsTrippy-Extensions' }
Inspector >> gbxDoItAgent
[
	
	^self session
		ifNil: [super gbxDoItAgent]
		ifNotNil: [:obj | obj]
]

{ #category : '*GbsTrippy-Extensions' }
Inspector >> doItReceiver
[
	"Answer the object that should be 'self' in client doits in this inspector.
	Avoid answering an inspection wrapper, while not sending GBS messages to objects (which might not inherit from Object)
	that they don't understand."
	
	^(object respondsTo: #gbxClientDoItReceiver)
		ifTrue: [object gbxClientDoItReceiver]
		ifFalse: [object]
]

{ #category : '*GbsTrippy-Extensions' }
Inspector >> session: anObject
[
	"Note: this instance variable appears undefined when the overrides have been removed in preparation for publishing."

	session := anObject
]

{ #category : '*GbsTrippy-Extensions' }
Inspector >> session
[
	"Note: this instance variable appears undefined when the overrides have been removed in preparation for publishing."

	^session
]

{ #category : '*GbsTrippy-Extensions' }
Inspector >> gbxCanRefresh
[
	"some inspectors can't refresh their objects from the server
	such as the PoolDictionaryInspector which is on a workspace"

	^true
]

{ #category : '*GbsTrippy-Extensions' }
Inspector >> gbxTrimLongString: aString
[
	"Martin wants VW 9.x to preserve the long string truncation that was present in 8.x."

	aString size <= 128000 ifTrue: [^aString].
	^((#InspectorTruncatedContents << #dialogs >> '(Contents truncated from <1p> to <2p>)')
		expandMacrosWith: aString size with: 128000), '
', (aString copyFrom: 1 to: 128000), ' ...'
]

{ #category : '*GbsTrippy-Extensions' }
Inspector class >> gbxCautiousInspectorClassesFor: anObject
[
	"GBS variant for when the object could be a server object and shouldn't have a plain BehaviorInspector"

	| inspectors |
	inspectors := self
				cautiousSend: #inspectorClasses
				to: anObject
				else: [Array with: BasicInspector].
	^self possiblyAddBehaviorInspector: inspectors
]

{ #category : '*GbsTrippy-Extensions' }
Inspector class >> possiblyAddBehaviorInspector: inspectors
[
	"do nothing in VW 8.0"

	^inspectors
]

{ #category : '*GbsTrippy-Extensions' }
Inspector class >> gbxTabLabel: aString
[
	| text color |
	color := ColorValue scaledRed: 4818 scaledGreen: 0 scaledBlue: 4818.
	text := Text fromString: aString.
	text emphasizeAllWith: #color -> color.
	^text
]

{ #category : '*GbsTrippy-Extensions' }
Inspector class >> gbxIsGbsInspector
[

	^false
]

{ #category : '*GbsTrippy-Extensions' }
Inspector class >> wrappedOrNot: anObject
[
	| shouldWrap |
	shouldWrap := GemStone.Gbs.GbxReflection shouldBeWrapped: anObject.
	^shouldWrap
		ifTrue: [GemStone.Gbs.GbxInspectionWrapper on: anObject]
		ifFalse: [anObject]
]

