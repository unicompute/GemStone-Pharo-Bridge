Class {
	#name : 'CoreGbsMigrationDomainMappedOrder',
	#superclass : 'Object',
	#instVars : [
		'customer',
		'lineItems',
		'total',
		'transientCache',
		'auditTrail'
	],
	#category : 'GemStone-Pharo-Core-Tests',
	#package : 'GemStone-Pharo-Core-Tests'
}

{ #category : 'replication' }
CoreGbsMigrationDomainMappedOrder class >> instVarMap [
	^ CoreGbsMigrationDomainOrder migrationDomainInstVarMap
]

{ #category : 'replication' }
CoreGbsMigrationDomainMappedOrder class >> migrationDomainReplicationSpec [
	^ CoreGbsMigrationDomainOrder migrationDomainReplicationSpec
]

{ #category : 'replication' }
CoreGbsMigrationDomainMappedOrder class >> migrationDomainServerInstVarNames [
	^ CoreGbsMigrationDomainOrder migrationDomainServerInstVarNamesWithInstVarMap
]

{ #category : 'replication' }
CoreGbsMigrationDomainMappedOrder class >> replicationSpec [
	^ self migrationDomainReplicationSpec
]
