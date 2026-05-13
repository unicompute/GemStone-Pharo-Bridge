Extension { #name : 'GbsRemoteMethodObject' }

{ #category : '*GemStone-GBS-MagLev' }
GbsRemoteMethodObject >> toProc [
	| targetProxy command rawProcOop procOop builder |
	targetProxy := self effectiveReceiverProxy.
	builder := GbsRemoteScriptBuilder new.
	command := (GbsRemoteCommand
		blockBody: '[
		| meth proc |
		receiver ifNil: [ ^ ''0'' ].
		meth := [ receiver method: selector ] on: Error do: [ nil ].
		meth ifNil: [ ^ ''0'' ].
		proc := [ (meth respondsTo: #to_proc)
			ifTrue: [ meth to_proc ]
			ifFalse: [ (meth respondsTo: #toProc)
				ifTrue: [ meth toProc ]
				ifFalse: [ nil ] ] ] on: Error do: [ nil ].
		proc ifNil: [ ^ ''0'' ].
		(Reflection oopOf: proc) asString
	] value'
		argumentNames: #('receiver' 'selector')
		argumentScripts: {
			builder objectForOop: targetProxy oop.
			builder literalFor: self selector asSymbol }).
	rawProcOop := self session fetchRemoteCommand: command.
	rawProcOop ifNil: [ ^ nil ].
	(rawProcOop respondsTo: #asLocalString) ifTrue: [ rawProcOop := rawProcOop asLocalString ].
	procOop := [ rawProcOop asString asInteger ]
		on: Error
		do: [ nil ].
	(procOop isInteger and: [ procOop > 20 ]) ifFalse: [ ^ nil ].
	^ self session procObjectForOop: procOop
]
