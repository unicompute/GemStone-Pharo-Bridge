Class {
	#name : 'CoreGbsMigrationDomainInheritedMappedOrder',
	#superclass : 'CoreGbsMigrationDomainMappedOrder',
	#instVars : [
		'priority',
		'clientMemo'
	],
	#category : 'GemStone-Pharo-Core-Tests',
	#package : 'GemStone-Pharo-Core-Tests'
}

{ #category : 'replication' }
CoreGbsMigrationDomainInheritedMappedOrder class >> instVarMap [
	^ super instVarMap , #(
		#(#priority #urgency)
		#(#clientMemo nil)
		#(nil #serverAudit))
]

{ #category : 'replication' }
CoreGbsMigrationDomainInheritedMappedOrder class >> migrationDomainReplicationSpec [
	^ super migrationDomainReplicationSpec , #(
		#(#priority #min 1)
		#(#clientMemo #stub))
]

{ #category : 'replication' }
CoreGbsMigrationDomainInheritedMappedOrder class >> migrationDomainServerInstVarNames [
	^ super migrationDomainServerInstVarNames , #('urgency' 'serverAudit')
]

{ #category : 'replication' }
CoreGbsMigrationDomainInheritedMappedOrder class >> replicationSpec [
	^ self migrationDomainReplicationSpec
]
