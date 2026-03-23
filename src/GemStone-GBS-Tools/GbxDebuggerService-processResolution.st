{
  #category : 'private-process resolution',
  #package : 'GemStone-GBS-Tools'
}
GbxDebuggerService >> aboutToDebugServer
	"Answer true if the next bytecode implements a send to the GemStone server.
	This can depend on whether glue is hidden. If glue is shown, we wait until lower-level 
	code to answer true here. Can't wait until the bottom of shown glue, because the send 
	into GS must set the single-step flag, and the returned error must be detected and thrown, 
	all in a single debugger operation.
	Assumes top of stack is selected."

	| rcvr |
	currentContext ifNil: [ ^ false ].
	(currentContext respondsTo: #willSend) ifFalse: [ ^ false ].
	currentContext willSend ifFalse: [ ^ false ].
	(currentContext respondsTo: #gbxPeekForReceiver) ifFalse: [ ^ false ].
	rcvr := [ currentContext gbxPeekForReceiver ] on: Error do: [ nil ].
	rcvr ifNil: [ ^ false ].
	"If the receiver doesn't understand, it's not about to debug"
	^ GbsStackDumper
		ifUnderstoodSend: #gbxStepsIntoGemStone:showGlue:
		to: rcvr
		arguments: (Array with: currentContext peekForSelector with: self glueIsHidden not)
		else: [ false ]

{
  #category : 'private-process resolution',
  #package : 'GemStone-GBS-Tools'
}
GbxDebuggerService >> resolveDebugProcessOopFromCurrentProcessOop
	"Resolve the actual debug process OOP from the current process OOP using the same discipline as C tests.
	This follows the exact pattern from test_restart_pharo_style_extended.cpp resolve_process_oop function."
	
	| contextOop exceptionOop script result resolvedProcessOop |
	
	"Get current context and exception OOPs for resolution"
	contextOop := currentContext ifNotNil: [ 
		(currentContext respondsTo: #asOop) 
			ifTrue: [ currentContext asOop ]
			ifFalse: [ nil ] ].
	exceptionOop := nil. "Will be set if we have an exception context"
	
	"Build the resolution script following C test pattern exactly"
	script := '[
		| primary secondary resolveProc proc toOop |
		resolveProc := [ :obj |
			obj isNil ifTrue: [ ^ nil ].
			(obj isInteger or: [ obj class == SmallInteger ]) ifTrue: [ obj := Object _objectForOop: obj ].
			((obj respondsTo: #_gsiDebuggerDetailedReportAt:)
				or: [ obj respondsTo: #_gsiStackReportFromLevel:toLevel:
				or: [ obj respondsTo: #_trimStackToLevel: ] ]) ifTrue: [ ^ obj ].
			(obj respondsTo: #serverProcess) ifTrue: [
				| p |
				p := [ obj serverProcess ] on: Error do: [ nil ].
				(p notNil and: [ (p respondsTo: #_gsiDebuggerDetailedReportAt:)
					or: [ p respondsTo: #_gsiStackReportFromLevel:toLevel: ] ]) ifTrue: [ ^ p ]
			].
			(obj respondsTo: #process) ifTrue: [
				| p |
				p := [ obj process ] on: Error do: [ nil ].
				(p notNil and: [ (p respondsTo: #_gsiDebuggerDetailedReportAt:)
					or: [ p respondsTo: #_gsiStackReportFromLevel:toLevel: ] ]) ifTrue: [ ^ p ]
			].
			(obj respondsTo: #topContext) ifTrue: [
				| c p |
				c := [ obj topContext ] on: Error do: [ nil ].
				(c notNil and: [ c respondsTo: #process ]) ifTrue: [
					p := [ c process ] on: Error do: [ nil ].
					(p notNil and: [ (p respondsTo: #_gsiDebuggerDetailedReportAt:)
						or: [ p respondsTo: #_gsiStackReportFromLevel:toLevel: ] ]) ifTrue: [ ^ p ]
				]
			].
			^ nil
		].
		toOop := [ :o |
			(o isInteger or: [ o class == SmallInteger ]) ifTrue: [ ^ o ].
			[ o asOop ] on: Error do: [ [ Reflection oopOf: o ] on: Error do: [ 0 ] ]
		].
		primary := Object _objectForOop: ', (contextOop ifNil: ['0']), '.
		secondary := Object _objectForOop: ', (exceptionOop ifNil: ['0']), '.
		proc := resolveProc value: primary.
		proc isNil ifTrue: [ proc := resolveProc value: secondary ].
		proc isNil ifTrue: [ ^ ''0'' ].
		[ (toOop value: proc) printString ] on: Error do: [ ''0'' ]
	] value'.
	
	"Execute the resolution script"
	result := [ session evaluate: script ] on: Error do: [ '0' ].
	(result respondsTo: #asLocalString) ifTrue: [ result := result asLocalString ].
	resolvedProcessOop := [ result asString asInteger ] on: Error do: [ 0 ].
	
	"Fallback to original processOop if resolution failed or returned 0/nil"
	((resolvedProcessOop isNumber and: [ resolvedProcessOop > 20 ]) not) 
		ifTrue: [ resolvedProcessOop := processOop ].
	
	^ resolvedProcessOop

{
  #category : 'private-process resolution',
  #package : 'GemStone-GBS-Tools'
}
GbxDebuggerService >> resolveProcessOopFromContext: aContext exception: anException
	"Resolve process OOP from context and exception objects following C test discipline"
	
	| contextOop exceptionOop |
	contextOop := aContext ifNotNil: [ 
		(aContext respondsTo: #asOop) 
			ifTrue: [ aContext asOop ]
			ifFalse: [ nil ] ].
	exceptionOop := anException ifNotNil: [ 
		(anException respondsTo: #asOop) 
			ifTrue: [ anException asOop ]
			ifFalse: [ nil ] ].
	
	^ self resolveDebugProcessOopFromContextOop: contextOop exceptionOop: exceptionOop

{
  #category : 'private-process resolution',
  #package : 'GemStone-GBS-Tools'
}
GbxDebuggerService >> resolveDebugProcessOopFromContextOop: contextOop exceptionOop: exceptionOop
	"Core process resolution logic following C test discipline exactly"
	
	| script result resolvedProcessOop |
	
	"Build the resolution script following C test pattern exactly"
	script := '[
		| primary secondary resolveProc proc toOop |
		resolveProc := [ :obj |
			obj isNil ifTrue: [ ^ nil ].
			(obj isInteger or: [ obj class == SmallInteger ]) ifTrue: [ obj := Object _objectForOop: obj ].
			((obj respondsTo: #_gsiDebuggerDetailedReportAt:)
				or: [ obj respondsTo: #_gsiStackReportFromLevel:toLevel:
				or: [ obj respondsTo: #_trimStackToLevel: ] ]) ifTrue: [ ^ obj ].
			(obj respondsTo: #serverProcess) ifTrue: [
				| p |
				p := [ obj serverProcess ] on: Error do: [ nil ].
				(p notNil and: [ (p respondsTo: #_gsiDebuggerDetailedReportAt:)
					or: [ p respondsTo: #_gsiStackReportFromLevel:toLevel: ] ]) ifTrue: [ ^ p ]
			].
			(obj respondsTo: #process) ifTrue: [
				| p |
				p := [ obj process ] on: Error do: [ nil ].
				(p notNil and: [ (p respondsTo: #_gsiDebuggerDetailedReportAt:)
					or: [ p respondsTo: #_gsiStackReportFromLevel:toLevel: ] ]) ifTrue: [ ^ p ]
			].
			(obj respondsTo: #topContext) ifTrue: [
				| c p |
				c := [ obj topContext ] on: Error do: [ nil ].
				(c notNil and: [ c respondsTo: #process ]) ifTrue: [
					p := [ c process ] on: Error do: [ nil ].
					(p notNil and: [ (p respondsTo: #_gsiDebuggerDetailedReportAt:)
						or: [ p respondsTo: #_gsiStackReportFromLevel:toLevel: ] ]) ifTrue: [ ^ p ]
				]
			].
			^ nil
		].
		toOop := [ :o |
			(o isInteger or: [ o class == SmallInteger ]) ifTrue: [ ^ o ].
			[ o asOop ] on: Error do: [ [ Reflection oopOf: o ] on: Error do: [ 0 ] ]
		].
		primary := Object _objectForOop: ', (contextOop ifNil: ['0']), '.
		secondary := Object _objectForOop: ', (exceptionOop ifNil: ['0']), '.
		proc := resolveProc value: primary.
		proc isNil ifTrue: [ proc := resolveProc value: secondary ].
		proc isNil ifTrue: [ ^ ''0'' ].
		[ (toOop value: proc) printString ] on: Error do: [ ''0'' ]
	] value'.
	
	"Execute the resolution script"
	result := [ session evaluate: script ] on: Error do: [ '0' ].
	(result respondsTo: #asLocalString) ifTrue: [ result := result asLocalString ].
	resolvedProcessOop := [ result asString asInteger ] on: Error do: [ 0 ].
	
	^ resolvedProcessOop

{
  #category : 'private-process resolution',
  #package : 'GemStone-GBS-Tools'
}
GbxDebuggerService >> verifyDebuggerPrimitivesForProcess: processOop
	"Verify that the resolved process supports debugger primitives as per C test discipline"
	
	| script result |
	
	processOop ifNil: [ ^ false ].
	(processOop isNumber and: [ processOop > 20 ]) ifFalse: [ ^ false ].
	
	script := '[
		| obj |
		obj := Object _objectForOop: ', processOop asString, '.
		obj isNil ifTrue: [ ^ false ].
		((obj respondsTo: #_gsiDebuggerDetailedReportAt:)
			or: [ obj respondsTo: #_gsiStackReportFromLevel:toLevel: ])
	] value'.
	
	result := [ session evaluate: script ] on: Error do: [ false ].
	^ self asBooleanResult: result default: false

{
  #category : 'private-process resolution',
  #package : 'GemStone-GBS-Tools'
}
GbxDebuggerService >> reResolveProcessAfterRestartOrStep
	"Re-resolve process OOP after restart or step cycle to maintain consistency as per C test discipline"
	
	| newProcessOop |
	
	"Only re-resolve if we have a current context"
	currentContext ifNil: [ ^ processOop ].
	
	"Try to resolve from current context and any exception"
	newProcessOop := self resolveDebugProcessOopFromCurrentProcessOop.
	
	"Verify the new process supports debugger primitives"
	(self verifyDebuggerPrimitivesForProcess: newProcessOop) ifTrue: [
		"Update processOop if we got a valid resolution"
		processOop := newProcessOop.
		(debugger respondsTo: #processOop:) ifTrue: [ 
			[ debugger processOop: newProcessOop ] on: Error do: [ ] ].
	].
	
	^ processOop