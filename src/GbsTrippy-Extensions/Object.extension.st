Extension { #name : 'Object' }

{ #category : '*GbsTrippy-Extensions' }
Object >> gbxShouldBeWrapped
[
	" Answer true if I am a replicate of a server object. 
	In some cases, especially during logout processing, I might answer true when the session has gone away."

	^self gbxDelegate ~~ nil
]

{ #category : '*GbsTrippy-Extensions' }
Object >> gbxIsWrapped
[
	^false
]

{ #category : '*GbsTrippy-Extensions' }
Object >> inspectorActions
[

	| navigator context |
	context := thisContext.
	
	[context isNil or: 
			[(context receiver isKindOf: Tools.Trippy.Inspector)
				and: [context receiver gbxCanRefresh]]]
			whileFalse: [context := context sender].
	context isNil ifTrue: [^#()].	"if we ever find a stack that did not come from an inspector"
	navigator := context receiver container.
	navigator gbxHasShell ifFalse: [^Array new].
	^(GemStone.Gbs.GbxReflection
		isWrapped: navigator gbxShell gbxInstalledNavigator object)
			ifTrue: 
				[Array with: (Tools.Trippy.Action
							label: #RefreshFromGSServer << #gbs >> 'Refresh From GS Server'
							block: [navigator gbxShell inspectedObjectChanged])]
			ifFalse: [Array new]
]

{ #category : '*GbsTrippy-Extensions' }
Object >> inspectableObjectFor: aClass
[
	^self
]

{ #category : '*GbsTrippy-Extensions' }
Object >> gbxDoItAgent
[
	"default to return our current session"

	^GBSM currentSession
]

{ #category : '*GbsTrippy-Extensions' }
Object >> gbxOldInspect
[
	"Private to GBS"

	^self inspect
]

{ #category : '*GbsTrippy-Extensions' }
Object >> doItReceiver
[
	^self
]

{ #category : '*GbsTrippy-Extensions' }
Object >> gbxDoItReceiver
[
	"the default context for any gs actions is Onil"

	^GBSM currentSession oopNil
]

