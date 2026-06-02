Class {
	#name : 'CoreFakeKeychainBackend',
	#superclass : 'Object',
	#instVars : [
		'store',
		'services'
	],
	#category : 'GemStone-Pharo-Core-Tests',
	#package : 'GemStone-Pharo-Core-Tests'
}

{ #category : 'accessing' }
CoreFakeKeychainBackend >> deleteSecretAt: accountName service: serviceName [
	self services add: serviceName.
	self store removeKey: (self keyFor: accountName service: serviceName) ifAbsent: [ ].
	^ self
]

{ #category : 'private' }
CoreFakeKeychainBackend >> keyFor: accountName service: serviceName [
	^ serviceName asString, '|', accountName asString
]

{ #category : 'accessing' }
CoreFakeKeychainBackend >> secretAt: accountName service: serviceName [
	self services add: serviceName.
	^ self store
		at: (self keyFor: accountName service: serviceName)
		ifAbsent: [ nil ]
]

{ #category : 'accessing' }
CoreFakeKeychainBackend >> secretAt: accountName put: secretString service: serviceName [
	self services add: serviceName.
	self store
		at: (self keyFor: accountName service: serviceName)
		put: secretString.
	^ secretString
]

{ #category : 'accessing' }
CoreFakeKeychainBackend >> services [
	^ services ifNil: [ services := OrderedCollection new ]
]

{ #category : 'accessing' }
CoreFakeKeychainBackend >> store [
	^ store ifNil: [ store := Dictionary new ]
]
