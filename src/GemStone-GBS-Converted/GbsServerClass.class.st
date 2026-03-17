Class {
	#name : 'GbsServerClass',
	#superclass : 'Object',
	#instVars : [
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Converted'
}

{ #category : 'accessing' }
GbsServerClass class >> firstPublicInstVar

	"Returns the index of the first publicly available instance variable storage location, whether or not a public instance variable has actually been defined."

	^1

{ #category : 'accessing' }
GbsServerClass class >> remoteClass
	"Answer the GemStone class associated with the receiver."

	^GBSM currentSession gemStoneClassFor: self

{ #category : 'testing' }
GbsServerClass class >> instancesAreForwarders
	"Never create client-side instances of the subclasses of myself."

	^true

{ #category : 'instance creation' }
GbsServerClass class >> new: initialNumberOfUsersOrSize inSession: aSession
	"Return a forwarder to an instance."

	^((self asGSObjectInSession: aSession)
		remotePerform: #new: with: initialNumberOfUsersOrSize) asForwarder

{ #category : 'instance creation' }
GbsServerClass class >> newInSession: aSession
	"Return a forwarder to an instance."

	^((self asGSObjectInSession: aSession)
		remotePerform: #new) asForwarder

{ #category : 'instance creation' }
GbsServerClass class >> new

	^self newInSession: GBSM currentSession

{ #category : 'instance creation' }
GbsServerClass class >> new: initialNumberOfUsersOrSize

	^self new: initialNumberOfUsersOrSize inSession: GBSM currentSession

{ #category : 'message forwarding' }
GbsServerClass class >> doesNotUnderstand: aMessage
	"Server classes in the client act as forwarders to their GemStone counterpart,
	 so messages that aren't understood in the client are automatically forwarded
	 to the GemStone class"

	^self gbsAsUncachedForwarder
		perform: aMessage selector
		withArguments: aMessage arguments

