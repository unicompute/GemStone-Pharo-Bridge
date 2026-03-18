| env stone user pass serviceName classes paramsClass launcherClass classicLauncherClass currentSessionClass params session launcher exClass |
[
	[ Metacello new
		baseline: 'GemStonePharo';
		repository: 'tonel:///Users/tariq/src/gemtools/GemStone-Pharo-Bridge/src';
		load: 'default' ] on: Error do: [ :ex |
			Transcript show: 'LOAD_ERROR: ', ex messageText; cr.
			ex signalerContext ifNotNil: [ :ctx | Transcript show: ctx shortDebugStack; cr ].
			Smalltalk snapshot: false andQuit: true ].

	classes := Dictionary new.
	#(
		GbsSessionParameters
		GbsLauncher
		GbsClassicLauncher
		GbsSession
	) do: [ :each |
		classes at: each put: (Smalltalk at: each ifAbsent: [ nil ]) ].

	paramsClass := classes at: #GbsSessionParameters.
	launcherClass := classes at: #GbsLauncher.
	classicLauncherClass := classes at: #GbsClassicLauncher.

	(paramsClass isNil or: [ launcherClass isNil or: [ classicLauncherClass isNil ] ]) ifTrue: [
		Transcript show: 'MISSING_CLASSES'; cr.
		Smalltalk snapshot: false andQuit: true ].

	env := [ Smalltalk os environment ] on: Error do: [ Dictionary new ].
	stone := env at: 'GS_STONE' ifAbsent: [ 'gs64stone' ].
	user := env at: 'GS_USER' ifAbsent: [ 'DataCurator' ].
	pass := env at: 'GS_PASS' ifAbsent: [ 'swordfish' ].
	serviceName := env at: 'GS_SERVICE' ifAbsent: [ 'gemnetobject' ].

	params := paramsClass new.
	params
		gemStoneName: stone;
		username: user;
		password: pass;
		gemService: serviceName.

	session := nil.
	[ session := params login ]
		on: Error
		do: [ :ex |
			Transcript show: 'LOGIN_ERROR: ', ex class name, ' ', ex messageText; cr.
			ex signalerContext ifNotNil: [ :ctx | Transcript show: ctx shortDebugStack; cr ].
			Smalltalk snapshot: false andQuit: true ].

	Transcript show: 'LOGIN_OK '; show: session printString; cr.

	[ paramsClass currentSession: session ]
		on: Error
		do: [ :ex |
			Transcript show: 'SET_CURRENT_ERROR: ', ex class name, ' ', ex messageText; cr.
			ex signalerContext ifNotNil: [ :ctx | Transcript show: ctx shortDebugStack; cr ].
			Smalltalk snapshot: false andQuit: true ].

	launcher := launcherClass new.
	[ launcher initializePresenters ]
		on: Error
		do: [ :ex |
			Transcript show: 'INIT_PRESENTERS_ERROR: ', ex class name, ' ', ex messageText; cr.
			ex signalerContext ifNotNil: [ :ctx | Transcript show: ctx shortDebugStack; cr ].
			Smalltalk snapshot: false andQuit: true ].

	[ launcher ensureCurrentSessionVisibleInAllSessions ]
		on: Error
		do: [ :ex |
			Transcript show: 'ENSURE_VISIBLE_ERROR: ', ex class name, ' ', ex messageText; cr.
			ex signalerContext ifNotNil: [ :ctx | Transcript show: ctx shortDebugStack; cr ].
			Smalltalk snapshot: false andQuit: true ].

	[ launcher refreshAllLaunchers ]
		on: Error
		do: [ :ex |
			Transcript show: 'REFRESH_ALL_LAUNCHERS_ERROR: ', ex class name, ' ', ex messageText; cr.
			ex signalerContext ifNotNil: [ :ctx | Transcript show: ctx shortDebugStack; cr ].
			Smalltalk snapshot: false andQuit: true ].

	[ classicLauncherClass refreshAllWindows ]
		on: Error
		do: [ :ex |
			Transcript show: 'CLASS_REFRESH_WINDOWS_ERROR: ', ex class name, ' ', ex messageText; cr.
			ex signalerContext ifNotNil: [ :ctx | Transcript show: ctx shortDebugStack; cr ].
			Smalltalk snapshot: false andQuit: true ].

	Transcript show: 'PROBE_OK'; cr.
] ensure: [
	[ (Smalltalk at: #GbsSessionParameters ifAbsent: [ nil ]) currentSession
		ifNotNil: [ :s | (s respondsTo: #logout) ifTrue: [ s logout ] ] ]
		on: Error
		do: [ ].
	Smalltalk snapshot: false andQuit: true
].
