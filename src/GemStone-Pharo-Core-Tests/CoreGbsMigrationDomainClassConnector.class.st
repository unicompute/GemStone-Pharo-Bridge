Class {
	#name : 'CoreGbsMigrationDomainClassConnector',
	#superclass : 'GbsClassConnector',
	#category : 'GemStone-Pharo-Core-Tests',
	#package : 'GemStone-Pharo-Core-Tests'
}

{ #category : 'connecting' }
CoreGbsMigrationDomainClassConnector >> clientClassConnectorForSession: aSession [
	| connector |
	connector := super clientClassConnectorForSession: aSession.
	connector
		replicationSpec: CoreGbsMigrationDomainOrder migrationDomainReplicationSpec;
		serverInstVarNames: CoreGbsMigrationDomainOrder migrationDomainServerInstVarNames;
		replicatorClass: GbxPointerObjectReplicator.
	^ connector
]
