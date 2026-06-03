Class {
	#name : 'CoreGbsMigrationDomainOrder',
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
CoreGbsMigrationDomainOrder class >> migrationDomainCallbackReplicationSpec [
	^ #callback
]

{ #category : 'replication' }
CoreGbsMigrationDomainOrder class >> migrationDomainInstVarMap [
	^ #(
		#(#customer #buyer)
		#(#lineItems #items)
		#(#total #amount)
		#(#auditTrail #audit)
		#(#transientCache nil))
]

{ #category : 'replication' }
CoreGbsMigrationDomainOrder class >> migrationDomainReplicationSpec [
	^ #(
		#(#customer #forwarder)
		#(#lineItems #min 2)
		#(#total #max 1)
		#(#auditTrail #stub)
		#(#indexable_part #replicate))
]

{ #category : 'replication' }
CoreGbsMigrationDomainOrder class >> migrationDomainServerInstVarNames [
	^ #('customer' 'lineItems' 'total' 'transientCache' 'auditTrail')
]

{ #category : 'replication' }
CoreGbsMigrationDomainOrder class >> migrationDomainServerInstVarNamesWithInstVarMap [
	^ #('buyer' 'items' 'transientCache' 'amount' 'audit')
]

{ #category : 'replication' }
CoreGbsMigrationDomainOrder class >> replicationSpec [
	^ self migrationDomainReplicationSpec
]
