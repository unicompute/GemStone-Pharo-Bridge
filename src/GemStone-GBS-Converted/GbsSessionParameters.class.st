Class {
	#name : 'GbsSessionParameters',
	#superclass : 'GbxSessionSpecification',
	#instVars : [
		'name',
		'sessionId',
		'gemStoneName',
		'hostUsername',
		'hostPassword',
		'gemService',
		'netObject',
		'rememberPassword',
		'rememberHostPassword'
	],
	#classVars : [
		'AllParameters',
		'AllSessions',
		'CurrentSession',
		'PollingEnabled',
		'RegisterNewParameters'
	],
	#category : 'GemStone-GBS-Converted'
}

{ #category : 'accessing' }
GbsSessionParameters >> name
[

	^name ifNil: [self generatedName]
]

{ #category : 'accessing' }
GbsSessionParameters >> name: aString
[

	name := aString
]

{ #category : 'comparing' }
GbsSessionParameters >> = aGbsSessionParameters
[

	^(aGbsSessionParameters isKindOf: self class)
		and: [self gemStoneName = aGbsSessionParameters gemStoneName
		and: [self gemService = aGbsSessionParameters gemService
		and: [self username = aGbsSessionParameters username
		and: [self connectors = aGbsSessionParameters connectors]]]]
]

{ #category : 'comparing' }
GbsSessionParameters >> hash
[

	^self gemStoneName hash
	+ self gemService hash
	+ self username hash
	+ self connectors hash
]

{ #category : 'accessing' }
GbsSessionParameters >> hostUsername
[

	^hostUsername
]

{ #category : 'accessing' }
GbsSessionParameters >> hostUsername: aHostUsername
[

	hostUsername := aHostUsername
]

{ #category : 'accessing' }
GbsSessionParameters >> rememberHostPassword
[
	^rememberHostPassword
]

{ #category : 'accessing' }
GbsSessionParameters >> rememberHostPassword: aBoolean
[

	"If aBoolean is true, this instance will remember the host password from login to login.  If false, the password will not be stored, but will be prompted for at each login."

	rememberHostPassword := aBoolean
]

{ #category : 'accessing' }
GbsSessionParameters >> rememberPassword
[
	^rememberPassword
]

{ #category : 'accessing' }
GbsSessionParameters >> gemService
[

	^gemService
]

{ #category : 'accessing' }
GbsSessionParameters >> gemService: aGemService
[

	gemService := aGemService
]

{ #category : 'accessing' }
GbsSessionParameters >> rememberPassword: aBoolean
[

	"If aBoolean is true, this instance will remember the GemStone password from login to login.  If false, the password will not be stored, but will be prompted for at each login."

	rememberPassword := aBoolean
]

{ #category : 'accessing' }
GbsSessionParameters >> gemServiceHost
[
	"Exception handling included to protect against pathological
	 cases like creating the instance using #basicNew or assigning
	 something other than a String to the #gemService instance variable."

	| sourceStream resultStream |
	[(self gemService includes: $@) ifFalse: [^''].
	sourceStream := self gemService readStream.
	resultStream := String new writeStream.
	sourceStream through: $@.
	
	[sourceStream atEnd
		or: [(sourceStream peekFor: $.)
		or: [(sourceStream peekFor: $#)
		or: [sourceStream peekFor: $!]]]]
			whileFalse: [resultStream nextPut: sourceStream next].
	^resultStream contents]
		on: Error
		do: [:ex | ^''].
]

{ #category : 'accessing' }
GbsSessionParameters >> gemStoneName
[

	^gemStoneName
]

{ #category : 'accessing' }
GbsSessionParameters >> gemStoneName: aGemStoneName
[
	gemStoneName := aGemStoneName
]

{ #category : 'accessing' }
GbsSessionParameters >> hostPassword
[

	^hostPassword
]

{ #category : 'accessing' }
GbsSessionParameters >> hostPassword: aHostPassword
[

	hostPassword := aHostPassword
]

{ #category : 'accessing' }
GbsSessionParameters >> netObject
[

	^netObject ifNil: ['']
]

{ #category : 'accessing' }
GbsSessionParameters >> netObject: aString
[

	netObject := aString
]

{ #category : 'accessing' }
GbsSessionParameters >> gsRemember
[

	^self rememberPassword
]

{ #category : 'accessing' }
GbsSessionParameters >> gsRemember: aBoolean
[

	self rememberPassword: aBoolean
]

{ #category : 'accessing' }
GbsSessionParameters >> hostRemember
[

	^self rememberHostPassword
]

{ #category : 'accessing' }
GbsSessionParameters >> hostRemember: aBoolean
[

	self rememberHostPassword: aBoolean
]

{ #category : 'accessing' }
GbsSessionParameters >> sessionId
[

	sessionId ifNotNil: [^sessionId].
	^self liveSessionFromParameters
		ifNil: [nil]
		ifNotNil: [:session | [session sessionId] on: Error do: [nil]]
]

{ #category : 'accessing' }
GbsSessionParameters >> sessionId: anObject
[

	sessionId := anObject
]

{ #category : 'printing' }
GbsSessionParameters >> printOn: aStream
[

	| hostname |
	username isEmpty
		ifTrue: [ '(no username)' printOn: aStream ]
		ifFalse: [ username printOn: aStream ].
	aStream nextPutAll: ' on '.
	gemStoneName isEmpty
		ifTrue: [ '(no stonename)' printOn: aStream ]
		ifFalse: [ gemStoneName printOn: aStream ].
	(hostname := self gemServiceHost) isEmpty
		ifFalse: [aStream nextPutAll: ' @ '; print: hostname].
]

{ #category : 'session management' }
GbsSessionParameters >> loginRpc
[

	"Log into GemStone with the receiver parameters, spawning an rpc
	 gem session.  The parameters required for an rpc login (gemStoneName,
	 username, password, hostUsername, hostPassword, gemService) should
	 be valid for this method to succeed.  If password or hostPassword are not
	 'remebered', they will be prompted for.  For a fill-in-the-blank form, call
	 editLoginData."
	"Returns a new GbsSession on successful login, nil otherwise"

	^self
		loginLinked: false
		onPasswordExpirationWarning: [ :aGSError |
			self gbsMessenger warn: aGSError messageText ]
]

{ #category : 'session management' }
GbsSessionParameters >> login
[
	"If a linked session is possible, do a linked login.  Otherwise, do an rpc."

	"Must hold loginProtect throughout to prevent another thread from 'stealing' the linked session
	after we've determined it's available."

	| manager session |
	manager := GbsSessionManager current.
	session := manager loginCritical: 
			[manager isLinkedLoginAvailable 
				ifTrue: [self loginLnk]
				ifFalse: [self loginRpc]].
	session ifNotNil: [
		self sessionId: ([session sessionId] on: Error do: [nil]).
		self class registerSession: self].
	^session
]

{ #category : 'session management' }
GbsSessionParameters >> loginLinked: aBoolean onPasswordExpirationWarning: aOneArgBlock
[
	"Log in to GemStone with the receiver's login parameters.  Login linked if aBoolean
	 is true, rpc if aBoolean is false.  If rtPasswordExpirationWarning occurs, aOneArgBlock
	 is evaluated with the GbsError as the argument."
	"Must acquire loginProtect before logging in so we don't 'steal' the linked session 
	from another thread that's in the midst of running #login."

	| manager session |
	manager := GbsSessionManager current.
	session := ([manager
		loginCritical: [self sessionClass loginLinked: aBoolean withParameters: self]]
			on: (GbsError exceptionClassFor: #rtErrWarningPasswordExpire)
			do: 
				[:ex |
				aOneArgBlock value: ex originator.
				ex resume]).
	session ifNotNil: [
		self sessionId: ([ session sessionId ] on: Error do: [ nil ]).
		self class registerSession: self.
		self class currentSession: session ].
	^ session
]

{ #category : 'session management' }
GbsSessionParameters >> loginLnk
[

	"Log into GemStone with the receiver parameters, using a gem session
	 linked with this Smalltalk virtual machine (only possible if 'GBSM isLinkedLoginAvailable'
	 is true).  The parameters required for a linked login (gemStoneName, username,
	 password) should be valid for this method to succeed.  If password is not
	 'remebered', it will be prompted for.  For a fill-in-the-blank form, call
	 editLoginData."
	"Returns a new GbsSession on successful login, nil otherwise"

	^self
		loginLinked: true
		onPasswordExpirationWarning: [ :aGSError |
			self gbsMessenger warn: aGSError messageText ]
]

{ #category : 'private' }
GbsSessionParameters >> checkPasswords
[
	"Private"

	rememberPassword ifFalse: [ password := '' ].
	rememberHostPassword ifFalse: [ hostPassword := '' ]
]

{ #category : 'private' }
GbsSessionParameters >> passwordsLinked: linked ifCancel: cancelBlock
[

	"Private.  Return password and hostPassword in a two-element array.  If password or hostPassword are not remembered, this method will prompt for them.  If linked, hostPassword will not be prompted for.  If the user cancels during prompting, the value of cancelBlock will be returned"

	| promptPwd promptHostPwd result |
	promptPwd := rememberPassword not & password isEmpty.
	promptHostPwd :=
		linked not "Hostpassword only needed for rpc login"
		& rememberHostPassword not "Only need to prompt if they aren't remembered"
		& hostUsername isEmpty not "Only need hostpass if hostuser is set.  Might use kerberose or .netrc instead."
		& hostPassword isEmpty. "Maybe it was already supplied"
	(promptPwd | promptHostPwd) ifFalse: [
		^Array with: password with: hostPassword ].

	"Need to do some prompting"
	(self gbxResolve: #GbxSessionParametersDialog) notNil
		ifTrue: [(self openDialogForGSPassword: promptPwd forHostPassword: promptHostPwd) ifFalse: [^cancelBlock value]]
		ifFalse: [self gbsMessenger warn: 'No user interface tools exist to prompt for passwords'].
	result := Array with: self password with: self hostPassword.

	self checkPasswords.

	^result
]

{ #category : 'private' }
GbsSessionParameters >> generatedName
[

	| user stone |
	user := username ifNil: [''].
	stone := gemStoneName ifNil: [''].
	user isEmpty ifTrue: [^stone].
	stone isEmpty ifTrue: [^user].
	^user , '@' , stone
]

{ #category : 'private' }
GbsSessionParameters >> liveSession
[

	| current |
	(self liveSessionFromParameters) ifNotNil: [ :session | ^ session ].
	current := self class currentSession.
	(current isNil or: [ sessionId isNil ]) ifTrue: [ ^ nil ].
	(current respondsTo: #sessionId) ifFalse: [ ^ nil ].
	^(([ current sessionId ] on: Error do: [ nil ]) = sessionId)
		ifTrue: [ current ]
		ifFalse: [ nil ]
]

{ #category : 'private' }
GbsSessionParameters >> liveSessionFromParameters
[

	| sessions |
	sessions := [ GBSM sessionsWithParameters: self ] on: Error do: [ #() ].
	(sessions respondsTo: #detect:ifNone:) ifFalse: [ ^ nil ].
	^sessions
		detect: [ :each |
			(each respondsTo: #hasValidSessionId)
				ifTrue: [ [ each hasValidSessionId ] on: Error do: [ false ] ]
				ifFalse: [
					(each respondsTo: #isLoggedIn)
						and: [ [ each isLoggedIn ] on: Error do: [ false ] ] ] ]
		ifNone: [ nil ]
]

{ #category : 'private - initialization' }
GbsSessionParameters >> initialize
[
	"Private"

	super initialize.
	name ifNil: [name := ''].
	gemStoneName ifNil: [gemStoneName := self class defaultStoneName].
	hostUsername ifNil: [hostUsername := ''].
	hostPassword ifNil: [hostPassword := ''].
	gemService ifNil: [gemService := self class defaultGemServiceName].
	netObject ifNil: [netObject := ''].
	rememberPassword ifNil: [rememberPassword := false].
	rememberHostPassword ifNil: [rememberHostPassword := false].
	username ifNil: [username := ''].
	password ifNil: [password := '']
]

{ #category : 'testing' }
GbsSessionParameters >> isConnected
[

	self liveSession ifNotNil: [ ^ true ].
	^self sessionId notNil
]

{ #category : 'testing' }
GbsSessionParameters >> isLoggedIn
[

	^self isConnected
]

{ #category : 'session management' }
GbsSessionParameters >> logout
[

	| session didLogout |
	session := self liveSession.
	session ifNil: [
		self sessionId: nil.
		((self class currentSession == self)
			or: [ self class currentSession isNil not
			and: [ (self class currentSession respondsTo: #parameters)
			and: [ (self class currentSession parameters == self) ] ] ])
			ifTrue: [ self class currentSession: nil ].
		^false ].
	didLogout := [ session logout ] on: Error do: [ :ex | ex pass ].
	didLogout ifTrue: [
		self sessionId: nil.
		((self class currentSession == session)
			or: [ self class currentSession == self ])
			ifTrue: [ self class currentSession: nil ] ].
	^didLogout
]

{ #category : 'defaults' }
GbsSessionParameters class >> defaultGemServiceName
[
	^'gemnetobject'
]

{ #category : 'defaults' }
GbsSessionParameters class >> registerNewParameters: aBoolean
[

	"If set to true, new instances are automatically registered with the session manager,
	 via GBSM addParameters: theNewInstance"
	"GbsSessionParameters registerNewParameters: true"
	"GbsSessionParameters registerNewParameters: false"

	RegisterNewParameters := aBoolean
]

{ #category : 'defaults' }
GbsSessionParameters class >> defaultStoneName
[

	^'gs64stone'
]

{ #category : 'defaults' }
GbsSessionParameters class >> registerNewParameters
[

	"If set to true, new instances are automatically registered with the session manager,
	 via GBSM addParameters: theNewInstance"

	RegisterNewParameters isNil ifTrue: [ RegisterNewParameters := false ].
	^RegisterNewParameters
]

{ #category : 'accessing' }
GbsSessionParameters class >> allParameters
[

	^AllParameters ifNil: [AllParameters := OrderedCollection new]
]

{ #category : 'accessing' }
GbsSessionParameters class >> allSessions
[

	AllSessions ifNil: [AllSessions := OrderedCollection new].
	AllSessions removeAllSuchThat: [ :each | self isInvalidSessionRegistryCandidate: each ].
	^AllSessions
]

{ #category : 'accessing' }
GbsSessionParameters class >> currentSession
[

	(self isInvalidCurrentSessionCandidate: CurrentSession)
		ifTrue: [ CurrentSession := nil ].
	^CurrentSession
]

{ #category : 'accessing' }
GbsSessionParameters class >> currentSession: anObject
[

	| sessionParameters sessionId existing |
	(self isInvalidCurrentSessionCandidate: anObject)
		ifTrue: [
			CurrentSession := nil.
			^ nil ].
	CurrentSession := anObject.
	anObject ifNil: [ ^ anObject ].
	(anObject respondsTo: #parameters) ifFalse: [ ^ anObject ].
	sessionParameters := [ anObject parameters ] on: Error do: [ nil ].
	sessionParameters ifNil: [ ^ anObject ].
	sessionId := (anObject respondsTo: #sessionId)
		ifTrue: [ [ anObject sessionId ] on: Error do: [ nil ] ]
		ifFalse: [ nil ].
	existing := self allParameters
		detect: [ :each | each = sessionParameters ]
		ifNone: [ nil ].
	sessionParameters := existing ifNil: [ sessionParameters ] ifNotNil: [ existing ].
	(sessionParameters respondsTo: #sessionId:) ifTrue: [ sessionParameters sessionId: sessionId ].
	self registerSession: sessionParameters.
	^anObject
]

{ #category : 'accessing' }
GbsSessionParameters class >> isInvalidCurrentSessionCandidate: anObject
[

	anObject ifNil: [ ^ false ].
	^#(BlockClosure FullBlockClosure CleanBlockClosure) includes: anObject class name
]

{ #category : 'accessing' }
GbsSessionParameters class >> isInvalidSessionRegistryCandidate: anObject
[

	anObject ifNil: [ ^ true ].
	^self isInvalidCurrentSessionCandidate: anObject
]

{ #category : 'accessing' }
GbsSessionParameters class >> pollingEnabled
[

	PollingEnabled isNil ifTrue: [ PollingEnabled := false ].
	^PollingEnabled
]

{ #category : 'accessing' }
GbsSessionParameters class >> pollingEnabled: aBoolean
[

	PollingEnabled := aBoolean
]

{ #category : 'accessing' }
GbsSessionParameters class >> togglePolling
[

	self pollingEnabled: self pollingEnabled not.
	^self pollingEnabled
]

{ #category : 'session management' }
GbsSessionParameters class >> registerSession: anObject
[

	| sessionId |
	(self isInvalidSessionRegistryCandidate: anObject) ifTrue: [ ^ nil ].
	self allSessions remove: anObject ifAbsent: [ ].
	sessionId := (anObject respondsTo: #sessionId)
		ifTrue: [ [ anObject sessionId ] on: Error do: [ nil ] ]
		ifFalse: [ nil ].
	sessionId ifNotNil: [
		self allSessions
			removeAllSuchThat: [ :each |
				each == anObject ifTrue: [ false ] ifFalse: [
					(each respondsTo: #sessionId)
						and: [ ([ each sessionId ] on: Error do: [ nil ]) = sessionId ] ] ] ].
	self allSessions add: anObject.
	^anObject
]

{ #category : 'session management' }
GbsSessionParameters class >> unregisterSession: anObject
[

	| sessionId |
	(self isInvalidSessionRegistryCandidate: anObject) ifTrue: [ ^ nil ].
	sessionId := (anObject respondsTo: #sessionId)
		ifTrue: [ [ anObject sessionId ] on: Error do: [ nil ] ]
		ifFalse: [ nil ].
	self allSessions remove: anObject ifAbsent: [ ].
	sessionId ifNotNil: [
		self allSessions
			removeAllSuchThat: [ :each |
				(each respondsTo: #sessionId)
					and: [ ([ each sessionId ] on: Error do: [ nil ]) = sessionId ] ] ].
	^anObject
]

{ #category : 'instance creation' }
GbsSessionParameters class >> addParameter: aSessionParameters
[

	aSessionParameters ifNil: [ ^ nil ].
	self allParameters remove: aSessionParameters ifAbsent: [ ].
	self allParameters add: aSessionParameters.
	^aSessionParameters
]

{ #category : 'instance creation' }
GbsSessionParameters class >> removeParameter: aSessionParameters
[

	self unregisterSession: aSessionParameters.
	^self allParameters remove: aSessionParameters ifAbsent: [ nil ]
]

{ #category : 'instance creation' }
GbsSessionParameters class >> newWithGemStoneName: aGemStoneName username: aUsername password: aPassword hostUsername: aHostUsername hostPassword: aHostPassword gemService: aGemServiceName
[
	^ self
		newWithGemStoneName: aGemStoneName
		username: aUsername
		password: aPassword
		rememberPassword: false
		hostUsername: aHostUsername
		hostPassword: aHostPassword
		rememberHostPassword: false
		gemService: aGemServiceName
]

{ #category : 'instance creation' }
GbsSessionParameters class >> new
[

	"Returns an instance of this class with default login parameters"
	"GbsSessionParameters new"

	^self
		newWithGemStoneName: self defaultStoneName
		username: ''
		password: ''
]

{ #category : 'instance creation' }
GbsSessionParameters class >> newWithGemStoneName: aGemStoneName username: aUsername password: aPassword rememberPassword: aRememberPasswordBoolean hostUsername: aHostUsername hostPassword: aHostPassword rememberHostPassword: aRememberHostPasswordBoolean gemService: aGemServiceName
[
	^self
		newWithGemStoneName: aGemStoneName
		username: aUsername
		password: aPassword
		rememberPassword: aRememberPasswordBoolean
		hostUsername: aHostUsername
		hostPassword: aHostPassword
		rememberHostPassword: aRememberHostPasswordBoolean
		gemService: aGemServiceName
		addToKnownParameters: self registerNewParameters
]

{ #category : 'instance creation' }
GbsSessionParameters class >> newWithGemStoneName: aGemStoneName username: aUsername password: aPassword rememberPassword: aRememberPasswordBoolean hostUsername: aHostUsername hostPassword: aHostPassword rememberHostPassword: aRememberHostPasswordBoolean gemService: aGemServiceName addToKnownParameters: addToKnown
[
	| inst |

	inst := super new.
	inst
		gemStoneName: aGemStoneName;
		username: aUsername;
		password: aPassword;
		rememberPassword: aRememberPasswordBoolean;
		hostUsername: aHostUsername;
		hostPassword: aHostPassword;
		rememberHostPassword: aRememberHostPasswordBoolean;
		gemService: aGemServiceName;
		initialize.
	addToKnown ifTrue: [ self addParameter: inst ].
	^inst
]

{ #category : 'instance creation' }
GbsSessionParameters class >> newWithGemStoneName: aGemStoneName username: aUsername password: aPassword
[

	^self
		newWithGemStoneName: aGemStoneName
		username: aUsername
		password: aPassword
		hostUsername: ''
		hostPassword: ''
		gemService: self defaultGemServiceName
]
