Class {
	#name : 'CoreGbsCustomStoreMappedOrder',
	#superclass : 'CoreGbsMigrationDomainMappedOrder',
	#category : 'GemStone-Pharo-Core-Tests',
	#package : 'GemStone-Pharo-Core-Tests'
}

{ #category : 'replication' }
CoreGbsCustomStoreMappedOrder >> gbsStoreIndexableValues [
	^ {
		customer + lineItems.
		auditTrail + 1 }
]

{ #category : 'replication' }
CoreGbsCustomStoreMappedOrder >> gbsStoreNamedValues [
	^ {
		customer.
		lineItems.
		nil.
		total + 100.
		auditTrail }
]
