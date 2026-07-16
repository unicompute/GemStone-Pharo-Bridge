| env envAtAny stone user pass serviceName netldiHost netldiNameOrPort hostUser hostPassword probeScript libraryClass interfaceClass paramsClass params session result |
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
	hostUser := envAtAny value: #('OKZ_GEMSTONE_HOST_USERNAME' 'GS_HOST_USERNAME' 'GS_NETLDI_HOST_USERNAME') value: ''.
	hostPassword := envAtAny value: #('OKZ_GEMSTONE_HOST_PASSWORD' 'GS_HOST_PASSWORD' 'GS_NETLDI_HOST_PASSWORD') value: ''.
	probeScript := env at: 'GS_PROBE_SCRIPT' ifAbsent: [ '1 + 1' ].

	(user isEmpty or: [ pass isEmpty ]) ifTrue: [
		Transcript show: 'PROBE_ERROR: set GS_USER and GS_PASS'; cr.
		Smalltalk snapshot: false andQuit: true ].

	libraryClass := Smalltalk at: #GbsLibrary ifAbsent: [ nil ].
	interfaceClass := Smalltalk at: #GbsServerInterface ifAbsent: [ nil ].
	paramsClass := Smalltalk at: #GbsSessionParameters ifAbsent: [ nil ].
	(interfaceClass isNil or: [ paramsClass isNil ]) ifTrue: [
		Transcript show: 'PROBE_ERROR: GemStone classes were not loaded'; cr.
		Smalltalk snapshot: false andQuit: true ].

	Transcript show: 'PROBE_GEMSTONE_HOME: ', (libraryClass ifNil: [ '(nil)' ] ifNotNil: [ libraryClass gemstoneHome ifNil: [ '(nil)' ] ]); cr.
	Transcript show: 'PROBE_GCI_LIBRARY: ', interfaceClass uniqueInstance libraryPath; cr.
	Transcript
		show: 'PROBE_CONFIG stone=' , stone
			, ' service=' , serviceName
			, ' host=' , (netldiHost ifEmpty: [ '(implicit)' ])
			, ' net=' , (netldiNameOrPort ifEmpty: [ '(implicit)' ])
			, ' hostUser=' , (hostUser isEmpty ifTrue: [ 'unset' ] ifFalse: [ 'set' ])
			, ' hostPassword=' , (hostPassword isEmpty ifTrue: [ 'unset' ] ifFalse: [ 'set' ]);
		cr.

	params := paramsClass new.
	params
		gemStoneName: stone;
		username: user;
		password: pass;
		gemService: serviceName.
	netldiHost isEmpty ifFalse: [ params netldiHostOrIp: netldiHost ].
	netldiNameOrPort isEmpty ifFalse: [ params netldiNameOrPort: netldiNameOrPort ].
	hostUser isEmpty ifFalse: [ params hostUsername: hostUser ].
	hostPassword isEmpty ifFalse: [ params hostPassword: hostPassword ].

	session := [ params login ] on: Error do: [ :ex |
		Transcript show: 'PROBE_LOGIN_ERROR: ', ex messageText; cr.
		nil ].
	session ifNil: [
		Transcript show: 'PROBE_LOGIN_FAILED'; cr.
		Smalltalk snapshot: false andQuit: true ].

	Transcript
		show: 'PROBE_LOGIN_OK sessionId=';
		show: ((session respondsTo: #sessionId) ifTrue: [ session sessionId printString ] ifFalse: [ 'unknown' ]);
		cr.

	result := [ session evaluate: probeScript ] on: Error do: [ :ex |
		Transcript show: 'PROBE_EVAL_ERROR: ', ex messageText; cr.
		nil ].
	result isNil
		ifTrue: [ Transcript show: 'PROBE_EVAL_RESULT: nil'; cr ]
		ifFalse: [ Transcript show: 'PROBE_EVAL_RESULT: ', result printString; cr ].
] ensure: [
	[ (Smalltalk at: #GbsSessionParameters ifAbsent: [ nil ]) ifNotNil: [ :class |
		class currentSession ifNotNil: [ :s | s logout ] ] ] on: Error do: [ ].
	Smalltalk snapshot: false andQuit: true
].
