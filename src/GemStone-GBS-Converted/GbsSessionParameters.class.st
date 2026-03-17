Class {
	#name : 'GbsSessionParameters',
	#superclass : 'GbxSessionSpecification',
	#instVars : [
		'gemStoneName',
		'hostUsername',
		'hostPassword',
		'gemService',
		'rememberPassword',
		'rememberHostPassword'
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Converted'
}

{ #category : 'comparing' }
GbsSessionParameters >> = aGbsSessionParameters

	^(aGbsSessionParameters isKindOf: self class)
		and: [self gemStoneName = aGbsSessionParameters gemStoneName
		and: [self gemService = aGbsSessionParameters gemService
		and: [self username = aGbsSessionParameters username
		and: [self connectors = aGbsSessionParameters connectors]]]]

{ #category : 'comparing' }
GbsSessionParameters >> hash

	^self gemStoneName hash
	+ self gemService hash
	+ self username hash
	+ self connectors hash

{ #category : 'accessing' }
GbsSessionParameters >> hostUsername

	^hostUsername

{ #category : 'accessing' }
GbsSessionParameters >> hostUsername: aHostUsername

	hostUsername := aHostUsername

{ #category : 'accessing' }
GbsSessionParameters >> rememberHostPassword
	^rememberHostPassword

{ #category : 'accessing' }
GbsSessionParameters >> rememberHostPassword: aBoolean

	"If aBoolean is true, this instance will remember the host password from login to login.  If false, the password will not be stored, but will be prompted for at each login."

	rememberHostPassword := aBoolean

{ #category : 'accessing' }
GbsSessionParameters >> rememberPassword
	^rememberPassword

{ #category : 'accessing' }
GbsSessionParameters >> gemService

	^gemService

{ #category : 'accessing' }
GbsSessionParameters >> gemService: aGemService

	gemService := aGemService

{ #category : 'accessing' }
GbsSessionParameters >> rememberPassword: aBoolean

	"If aBoolean is true, this instance will remember the GemStone password from login to login.  If false, the password will not be stored, but will be prompted for at each login."

	rememberPassword := aBoolean

{ #category : 'accessing' }
GbsSessionParameters >> gemServiceHost
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

{ #category : 'accessing' }
GbsSessionParameters >> gemStoneName

	^gemStoneName

{ #category : 'accessing' }
GbsSessionParameters >> gemStoneName: aGemStoneName
	gemStoneName := aGemStoneName

{ #category : 'accessing' }
GbsSessionParameters >> hostPassword

	^hostPassword

{ #category : 'accessing' }
GbsSessionParameters >> hostPassword: aHostPassword

	hostPassword := aHostPassword

{ #category : 'printing' }
GbsSessionParameters >> printOn: aStream

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

{ #category : 'session management' }
GbsSessionParameters >> loginRpc

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

{ #category : 'session management' }
GbsSessionParameters >> login
	"If a linked session is possible, do a linked login.  Otherwise, do an rpc."

	"Must hold loginProtect throughout to prevent another thread from 'stealing' the linked session
	after we've determined it's available."

	^GBSM loginCritical: 
			[GBSM isLinkedLoginAvailable 
				ifTrue: [self loginLnk]
				ifFalse: [self loginRpc]]

{ #category : 'session management' }
GbsSessionParameters >> loginLinked: aBoolean onPasswordExpirationWarning: aOneArgBlock
	"Log in to GemStone with the receiver's login parameters.  Login linked if aBoolean
	 is true, rpc if aBoolean is false.  If rtPasswordExpirationWarning occurs, aOneArgBlock
	 is evaluated with the GbsError as the argument."
	"Must acquire loginProtect before logging in so we don't 'steal' the linked session 
	from another thread that's in the midst of running #login."

	^
	[GBSM
		loginCritical: [self sessionClass loginLinked: aBoolean withParameters: self]]
			on: (GbsError exceptionClassFor: #rtErrWarningPasswordExpire)
			do: 
				[:ex |
				aOneArgBlock value: ex originator.
				ex resume]

{ #category : 'session management' }
GbsSessionParameters >> loginLnk

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

{ #category : 'private' }
GbsSessionParameters >> checkPasswords
	"Private"

	rememberPassword ifFalse: [ password := '' ].
	rememberHostPassword ifFalse: [ hostPassword := '' ]

{ #category : 'private' }
GbsSessionParameters >> passwordsLinked: linked ifCancel: cancelBlock

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

{ #category : 'defaults' }
GbsSessionParameters class >> defaultGemServiceName
	^'gemnetobject'

{ #category : 'defaults' }
GbsSessionParameters class >> registerNewParameters: aBoolean

	"If set to true, new instances are automatically registered with the session manager,
	 via GBSM addParameters: theNewInstance"
	"GbsSessionParameters registerNewParameters: true"
	"GbsSessionParameters registerNewParameters: false"

	RegisterNewParameters := aBoolean

{ #category : 'defaults' }
GbsSessionParameters class >> defaultStoneName

	^'gs64stone'

{ #category : 'defaults' }
GbsSessionParameters class >> registerNewParameters

	"If set to true, new instances are automatically registered with the session manager,
	 via GBSM addParameters: theNewInstance"

	RegisterNewParameters isNil ifTrue: [ RegisterNewParameters := false ].
	^RegisterNewParameters

{ #category : 'instance creation' }
GbsSessionParameters class >> newWithGemStoneName: aGemStoneName
username: aUsername
password: aPassword
hostUsername: aHostUsername
hostPassword: aHostPassword
gemService: aGemServiceName

	^ self
		newWithGemStoneName: aGemStoneName
		username: aUsername
		password: aPassword
		rememberPassword: false
		hostUsername: aHostUsername
		hostPassword: aHostPassword
		rememberHostPassword: false
		gemService: aGemServiceName

{ #category : 'instance creation' }
GbsSessionParameters class >> new

	"Returns an instance of this class with default login parameters"
	"GbsSessionParameters new"

	^self
		newWithGemStoneName: self defaultStoneName
		username: ''
		password: ''

{ #category : 'instance creation' }
GbsSessionParameters class >> newWithGemStoneName: aGemStoneName
username: aUsername
password: aPassword
rememberPassword: aRememberPasswordBoolean
hostUsername: aHostUsername
hostPassword: aHostPassword
rememberHostPassword: aRememberHostPasswordBoolean
gemService: aGemServiceName

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

{ #category : 'instance creation' }
GbsSessionParameters class >> newWithGemStoneName: aGemStoneName
username: aUsername
password: aPassword
rememberPassword: aRememberPasswordBoolean
hostUsername: aHostUsername
hostPassword: aHostPassword
rememberHostPassword: aRememberHostPasswordBoolean
gemService: aGemServiceName
addToKnownParameters: addToKnown

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
	addToKnown ifTrue: [ GBSM addParameters: inst ].
	^inst

{ #category : 'instance creation' }
GbsSessionParameters class >> newWithGemStoneName: aGemStoneName username: aUsername password: aPassword

	^self
		newWithGemStoneName: aGemStoneName
		username: aUsername
		password: aPassword
		hostUsername: ''
		hostPassword: ''
		gemService: self defaultGemServiceName

