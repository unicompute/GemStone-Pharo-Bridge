Class {
	#name : #'GbxManyClientToOneKernelConnector',
	#superclass : #'GbsFastConnector',
	#instVars : [ #'secondaryClientObjs' ],
	#classVars : [  ],
	#category : #'GemStone-GBS-Converted'
}

{ #category : #'accessing' }
GbxManyClientToOneKernelConnector >> secondaryClientObjs: anObject
	secondaryClientObjs := anObject

{ #category : #'printing' }
GbxManyClientToOneKernelConnector >> printOn: stream

	super printOn: stream.
	stream nextPutAll: ', #('.
	secondaryClientObjs do: 
			[:each |
			each gbxDebugPrintOn: stream.
			stream space].
	stream nextPut: $)

{ #category : #'private connecting' }
GbxManyClientToOneKernelConnector >> postConnectClient: primaryClass server: delegate inSession: sess
	"Private to GBS.  Events to occur after connecting.
	Sender must hold session's sessionProtect"

	super postConnectClient: primaryClass server: delegate inSession: sess.
	(primaryClass isBehavior and: [primaryClass isMeta not])
		ifFalse: 
			[self gbsMessenger
				error: 'Many-to-one kernel connectors are intended for use only with classes.'].
	sess cacheCritical: 
			[| clientMap primaryMetaclass |
			clientMap := GBSM clientMap.
			primaryMetaclass := primaryClass class.
			secondaryClientObjs do: 
					[:secondaryClass |
					| secondaryMetaclass |
					(secondaryClass isBehavior and: [secondaryClass isMeta not])
						ifFalse: 
							[self gbsMessenger
								error: 'Many-to-one kernel connectors are intended for use only with classes.'].
					secondaryMetaclass := secondaryClass class.
					clientMap atClient: secondaryClass putDelegate: delegate.
					sess setReplicatorForClient: secondaryClass
						sameAsReplicatorForClient: primaryClass.
					clientMap atClient: secondaryMetaclass
						putDelegate: (primaryMetaclass asGSObjectInSession: sess).
					sess setReplicatorForClient: secondaryMetaclass
						sameAsReplicatorForClient: primaryMetaclass]]

{ #category : #'instance creation' }
GbxManyClientToOneKernelConnector class >> primaryClientObj: primaryClientObj secondaryClientObjs: secondaryClientObjs serverOop: serverOop

	| conn |
	conn := self stObj: primaryClientObj gsObj: serverOop.
	conn secondaryClientObjs: secondaryClientObjs.
	^conn

