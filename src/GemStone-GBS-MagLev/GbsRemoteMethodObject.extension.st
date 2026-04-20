Extension { #name : 'GbsRemoteMethodObject' }

{ #category : '*GemStone-GBS-MagLev' }
GbsRemoteMethodObject >> toProc [
	| targetProxy rawProcOop procOop |
	targetProxy := self effectiveReceiverProxy.
	rawProcOop := self session executeScriptAndFetchObject: (String streamContents: [ :stream |
		stream nextPutAll: '[
		| receiver meth proc |
		receiver := Object _objectForOop: '.
		stream nextPutAll: targetProxy oop asString.
		stream nextPutAll: '.
		receiver ifNil: [ ^ ''0'' ].
		meth := [ receiver method: '.
		stream nextPutAll: (self session marshalArgumentToScript: self selector asSymbol).
		stream nextPutAll: ' ] on: Error do: [ nil ].
		meth ifNil: [ ^ ''0'' ].
		proc := [ (meth respondsTo: #to_proc)
			ifTrue: [ meth to_proc ]
			ifFalse: [ (meth respondsTo: #toProc)
				ifTrue: [ meth toProc ]
				ifFalse: [ nil ] ] ] on: Error do: [ nil ].
		proc ifNil: [ ^ ''0'' ].
		(Reflection oopOf: proc) asString
	] value' ]).
	rawProcOop ifNil: [ ^ nil ].
	(rawProcOop respondsTo: #asLocalString) ifTrue: [ rawProcOop := rawProcOop asLocalString ].
	procOop := [ rawProcOop asString asInteger ]
		on: Error
		do: [ nil ].
	(procOop isInteger and: [ procOop > 20 ]) ifFalse: [ ^ nil ].
	^ self session procObjectForOop: procOop
]
