"Reproduce the okzulu prod 'Could not activate GemStone GCI session N' bug:
 log in TWO GBS sessions via the production path (GbsSessionParameters>>login),
 inspect each session's sessionId and sessionOop, then evaluate on each and on
 the FIRST again (to mimic the pool switching between sessions per request).

 Hypothesis (candidate c): login sets sessionOop := sessionId (an int id, not an
 execution-context OOP). GciExecuteStr's context arg should be OOP_NIL (0). With
 one session (~id 1) this is benign; with two sessions the second's eval errors
 or returns nil, and re-activating the first fails -> 'Could not activate'."
| env envAtAny stone user pass serviceName netldiHost netldiNameOrPort hostUser hostPassword paramsClass mk loginOne loginTwo |
[
	[ Metacello new
		baseline: 'GemStonePharo';
		repository: 'tonel:///Users/tariq/src/gemtools/GemStone-Pharo-Bridge/src';
		load: 'default' ] on: Error do: [ :ex |
			Transcript show: 'LOAD_ERROR: ', ex messageText; cr.
			Smalltalk snapshot: false andQuit: true ].

	env := [ OSEnvironment current ] on: Error do: [ Dictionary new ].
	envAtAny := [ :keys :default | | value |
		value := default.
		keys do: [ :key | | raw |
			value = default ifTrue: [
				raw := [ env at: key ifAbsent: [ nil ] ] on: Error do: [ nil ].
				raw ifNotNil: [
					raw := [ raw asString trimBoth ] on: Error do: [ '' ].
					raw isEmpty ifFalse: [ value := raw ] ] ] ].
		value ].
	stone := envAtAny value: #('GS_STONE') value: 'gs64stone'.
	user := envAtAny value: #('GS_USER' 'GS_USERNAME') value: ''.
	pass := envAtAny value: #('GS_PASS' 'GS_PASSWORD') value: ''.
	serviceName := envAtAny value: #('GS_SERVICE') value: 'gemnetobject'.
	netldiHost := envAtAny value: #('GS_NETLDI_HOST' 'GS_HOST') value: ''.
	netldiNameOrPort := envAtAny value: #('GS_NETLDI_NAME_OR_PORT' 'GS_NETLDI') value: ''.
	hostUser := envAtAny value: #('OKZ_GEMSTONE_HOST_USERNAME' 'GS_HOST_USERNAME') value: ''.
	hostPassword := envAtAny value: #('OKZ_GEMSTONE_HOST_PASSWORD' 'GS_HOST_PASSWORD') value: ''.

	paramsClass := Smalltalk at: #GbsSessionParameters ifAbsent: [ nil ].
	paramsClass ifNil: [ Transcript show: 'PROBE_ERROR: classes not loaded'; cr. Smalltalk snapshot: false andQuit: true ].

	"Build a fresh GbsSessionParameters and log in, returning the GbsSession."
	mk := [ | params |
		params := paramsClass new.
		params gemStoneName: stone; username: user; password: pass; gemService: serviceName.
		netldiHost isEmpty ifFalse: [ params netldiHostOrIp: netldiHost ].
		netldiNameOrPort isEmpty ifFalse: [ params netldiNameOrPort: netldiNameOrPort ].
		hostUser isEmpty ifFalse: [ params hostUsername: hostUser ].
		hostPassword isEmpty ifFalse: [ params hostPassword: hostPassword ].
		[ params login ] on: Error do: [ :ex |
			Transcript show: 'LOGIN_ERROR: ', ex messageText; cr. nil ] ].

	"--- Session A ---"
	loginOne := mk value.
	loginOne ifNil: [ Transcript show: 'A_LOGIN_FAILED'; cr. Smalltalk snapshot: false andQuit: true ].
	Transcript show: 'A sessionId=', loginOne sessionId printString,
		' sessionOop=', loginOne sessionOop printString; cr.
	[ Transcript show: 'A eval(1+1)=', (loginOne evaluate: '1 + 1') printString; cr ]
		on: Error do: [ :ex | Transcript show: 'A_EVAL_ERROR: ', ex messageText; cr ].

	"--- Session B (second concurrent session, as the pool would create) ---"
	loginTwo := mk value.
	loginTwo ifNil: [ Transcript show: 'B_LOGIN_FAILED'; cr ]
	ifNotNil: [
		Transcript show: 'B sessionId=', loginTwo sessionId printString,
			' sessionOop=', loginTwo sessionOop printString; cr.
		[ Transcript show: 'B eval(2+2)=', (loginTwo evaluate: '2 + 2') printString; cr ]
			on: Error do: [ :ex | Transcript show: 'B_EVAL_ERROR: ', ex messageText; cr ].

		"--- Re-use A AFTER B was activated (the pool switching back). This is the
		 exact prod scenario: activate A again, execute. If sessionOop/sessionId is
		 the bug, this errors with 'Could not activate' or returns the wrong/nil. ---"
		[ Transcript show: 'A-again eval(3+3)=', (loginOne evaluate: '3 + 3') printString; cr ]
			on: Error do: [ :ex | Transcript show: 'A_AGAIN_EVAL_ERROR: ', ex messageText; cr ].
		[ loginTwo logout ] on: Error do: [ ] ].

	[ loginOne logout ] on: Error do: [ ].
	Transcript show: 'PROBE_DONE'; cr.
] ensure: [ Smalltalk snapshot: false andQuit: true ].
