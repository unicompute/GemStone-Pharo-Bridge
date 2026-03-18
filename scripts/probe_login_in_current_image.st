| env stone user pass serviceName paramsClass launcherClass params session launcher |
[
	paramsClass := Smalltalk at: #GbsSessionParameters ifAbsent: [ nil ].
	launcherClass := Smalltalk at: #GbsLauncher ifAbsent: [ nil ].

	(paramsClass isNil or: [ launcherClass isNil ]) ifTrue: [
		Transcript show: 'MISSING_CLASSES_IN_IMAGE'; cr.
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

	[ session := params login.
		Transcript show: 'PARAMS_LOGIN_OK '; show: session printString; cr ]
		on: Error
		do: [ :ex |
			Transcript show: 'PARAMS_LOGIN_ERROR: ', ex class name, ' ', ex messageText; cr.
			ex signalerContext ifNotNil: [ :ctx | Transcript show: ctx shortDebugStack; cr ] ].

	launcher := launcherClass new.
	[ launcher initializePresenters.
		Transcript show: 'LAUNCHER_INIT_OK'; cr ]
		on: Error
		do: [ :ex |
			Transcript show: 'LAUNCHER_INIT_ERROR: ', ex class name, ' ', ex messageText; cr.
			ex signalerContext ifNotNil: [ :ctx | Transcript show: ctx shortDebugStack; cr ] ].

	[ launcher doLogin.
		Transcript show: 'DO_LOGIN_RETURNED'; cr ]
		on: Error
		do: [ :ex |
			Transcript show: 'DO_LOGIN_ERROR: ', ex class name, ' ', ex messageText; cr.
			ex signalerContext ifNotNil: [ :ctx | Transcript show: ctx shortDebugStack; cr ] ].
] ensure: [
	[ (Smalltalk at: #GbsSessionParameters ifAbsent: [ nil ]) ifNotNil: [ :klass |
		klass currentSession ifNotNil: [ :s | (s respondsTo: #logout) ifTrue: [ s logout ] ] ] ]
		on: Error
		do: [ ].
	Smalltalk snapshot: false andQuit: true
].
