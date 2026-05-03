| env stone user pass serviceName netldiHost netldiNameOrPort probeScript params session result |
[
	[ Metacello new
		baseline: 'GemStonePharo';
		repository: 'tonel:///Users/tariq/src/gemtools/GemStone-Pharo-Bridge/src';
		load: 'default' ] on: Error do: [ :ex |
			Transcript show: 'LOAD_ERROR: ', ex messageText; cr.
			Smalltalk snapshot: false andQuit: true ].

	env := [ Smalltalk os environment ] on: Error do: [ Dictionary new ].
	stone := env at: 'GS_STONE' ifAbsent: [ 'gs64stone' ].
	user := env at: 'GS_USER' ifAbsent: [ '' ].
	pass := env at: 'GS_PASS' ifAbsent: [ '' ].
	serviceName := env at: 'GS_SERVICE' ifAbsent: [ 'gemnetobject' ].
	netldiHost := env at: 'GS_NETLDI_HOST' ifAbsent: [ '' ].
	netldiNameOrPort := env at: 'GS_NETLDI_NAME_OR_PORT' ifAbsent: [ '' ].
	probeScript := env at: 'GS_PROBE_SCRIPT' ifAbsent: [ '1 + 1' ].

	(user isEmpty or: [ pass isEmpty ]) ifTrue: [
		Transcript show: 'PROBE_ERROR: set GS_USER and GS_PASS'; cr.
		Smalltalk snapshot: false andQuit: true ].

	Transcript show: 'PROBE_GEMSTONE_HOME: ', (GbsLibrary gemstoneHome ifNil: [ '(nil)' ]); cr.
	Transcript show: 'PROBE_GCI_LIBRARY: ', GbsServerInterface uniqueInstance libraryPath; cr.
	Transcript
		show: 'PROBE_CONFIG stone=' , stone
			, ' service=' , serviceName
			, ' host=' , (netldiHost ifEmpty: [ '(implicit)' ])
			, ' net=' , (netldiNameOrPort ifEmpty: [ '(implicit)' ]);
		cr.

	params := GbsSessionParameters new.
	params
		gemStoneName: stone;
		username: user;
		password: pass;
		gemService: serviceName.
	netldiHost isEmpty ifFalse: [ params netldiHostOrIp: netldiHost ].
	netldiNameOrPort isEmpty ifFalse: [ params netldiNameOrPort: netldiNameOrPort ].

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
	[ GbsSessionParameters currentSession ifNotNil: [ :s | s logout ] ] on: Error do: [ ].
	Smalltalk snapshot: false andQuit: true
].
