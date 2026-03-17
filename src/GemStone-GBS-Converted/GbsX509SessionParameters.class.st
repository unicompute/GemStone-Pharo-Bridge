Class {
	#name : 'GbsX509SessionParameters',
	#superclass : 'GbxSessionSpecification',
	#instVars : [
		'netldiHostOrIp',
		'netldiNameOrPort',
		'privateKey',
		'cert',
		'caCert',
		'extraGemArgs',
		'dirArg',
		'logArg',
		'argsArePemStrings'
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Converted'
}

{ #category : 'comparing' }
GbsX509SessionParameters >> = aGbsX509SessionParameters

	^(aGbsX509SessionParameters isKindOf: self class)
		and: [self cert = aGbsX509SessionParameters cert
		and: [self extraGemArgs = aGbsX509SessionParameters extraGemArgs
		and: [self netldiHostOrIp = aGbsX509SessionParameters netldiHostOrIp
		and: [self netldiNameOrPort = aGbsX509SessionParameters netldiNameOrPort
		and: [self dirArg = aGbsX509SessionParameters dirArg
		and: [self logArg = aGbsX509SessionParameters logArg
		and: [self connectors = aGbsX509SessionParameters connectors]]]]]]]

{ #category : 'comparing' }
GbsX509SessionParameters >> hash

	^self cert hash
	+ self extraGemArgs hash
	+ self netldiHostOrIp hash
	+ self netldiNameOrPort hash
	+ self dirArg hash
	+ self logArg hash
	+ self connectors

{ #category : 'accessing' }
GbsX509SessionParameters >> privateKey

	^privateKey

{ #category : 'accessing' }
GbsX509SessionParameters >> privateKey: anObject

	privateKey := anObject

{ #category : 'accessing' }
GbsX509SessionParameters >> extraGemArgs

	^extraGemArgs

{ #category : 'accessing' }
GbsX509SessionParameters >> extraGemArgs: anObject

	extraGemArgs := anObject

{ #category : 'accessing' }
GbsX509SessionParameters >> logArg

	^logArg

{ #category : 'accessing' }
GbsX509SessionParameters >> argsArePemStrings

	^argsArePemStrings

{ #category : 'accessing' }
GbsX509SessionParameters >> argsArePemStrings: anObject

	argsArePemStrings := anObject

{ #category : 'accessing' }
GbsX509SessionParameters >> logArg: anObject

	logArg := anObject

{ #category : 'accessing' }
GbsX509SessionParameters >> caCert

	^caCert

{ #category : 'accessing' }
GbsX509SessionParameters >> caCert: anObject

	caCert := anObject

{ #category : 'accessing' }
GbsX509SessionParameters >> netldiHostOrIp

	^netldiHostOrIp

{ #category : 'accessing' }
GbsX509SessionParameters >> cert

	^cert

{ #category : 'accessing' }
GbsX509SessionParameters >> netldiHostOrIp: anObject

	netldiHostOrIp := anObject

{ #category : 'accessing' }
GbsX509SessionParameters >> netldiNameOrPort

	^netldiNameOrPort

{ #category : 'accessing' }
GbsX509SessionParameters >> cert: anObject

	cert := anObject

{ #category : 'accessing' }
GbsX509SessionParameters >> dirArg

	^dirArg

{ #category : 'accessing' }
GbsX509SessionParameters >> netldiNameOrPort: anObject

	netldiNameOrPort := anObject

{ #category : 'accessing' }
GbsX509SessionParameters >> dirArg: anObject

	dirArg := anObject

{ #category : 'GBS private' }
GbsX509SessionParameters >> isX509

	^true

{ #category : 'session management' }
GbsX509SessionParameters >> loginOnPasswordExpirationWarning: aOneArgBlock
	"Log in to GemStone with the receiver's login parameters. "

	self gbxFixMe.	"It may not be possible to get an rtErrWarningPasswordExpire on x509 login"
	^[self sessionClass loginWithX509Parameters: self]
		on: (GbsError exceptionClassFor: #rtErrWarningPasswordExpire)
		do: 
			[:ex |
			aOneArgBlock value: ex originator.
			ex resume]

{ #category : 'session management' }
GbsX509SessionParameters >> loginRpc
	"just login. Linked logins not supported with x509 logins"

	^self login

{ #category : 'session management' }
GbsX509SessionParameters >> login
	"Log into GemStone with the receiver parameters, spawning an rpc
	 gem session.  The parameters required for an x509 rpc login 
	(certificate, private key, etc.) must be valid for this method to succeed. "
	"Returns a new GbsSession on successful login, nil otherwise"

	^self
		loginOnPasswordExpirationWarning: [:aGSError | self gbsMessenger warn: aGSError messageText]

{ #category : 'initialize-release' }
GbsX509SessionParameters >> initialize

	super initialize.
	argsArePemStrings := false.
	extraGemArgs := dirArg := logArg := ''

{ #category : 'printing' }
GbsX509SessionParameters >> printOn: aStream

	aStream
		nextPutAll: 'x509';
		space;
		nextPutAll: (username ifNil: [String new]);
		space;
		nextPutAll: (caCert ifNil: [String new]);
		space;
		nextPutAll: (netldiHostOrIp ifNil: [String new])

{ #category : 'instance creation' }
GbsX509SessionParameters class >> new

	^(super new)
		initialize;
		yourself

