Class {
	#name : 'GbsProxyLifecycle',
	#superclass : 'Object',
	#category : 'GemStone-GBS-Core',
	#package : 'GemStone-GBS-Core'
}

{ #category : 'tracking' }
GbsProxyLifecycle class >> currentGenerationForSession: aSession [
	^ (aSession class weakRegistryNamed: #GbsSessionProxyLifecycleGenerations)
		at: aSession
		ifAbsentPut: [ 0 ]
]

{ #category : 'tracking' }
GbsProxyLifecycle class >> generationForProxy: aProxy inSession: aSession [
	| registry |
	registry := self proxyGenerationRegistryForSessionIfPresent: aSession.
	registry ifNil: [ ^ nil ].
	^ registry at: aProxy ifAbsent: [ nil ]
]

{ #category : 'tracking' }
GbsProxyLifecycle class >> invalidateSession: aSession [
	| registry generation |
	registry := aSession class weakRegistryNamed: #GbsSessionProxyLifecycleGenerations.
	generation := (registry at: aSession ifAbsent: [ 0 ]) + 1.
	registry at: aSession put: generation.
	^ generation
]

{ #category : 'tracking' }
GbsProxyLifecycle class >> isProxyCurrent: aProxy forSession: aSession [
	| generation |
	generation := self generationForProxy: aProxy inSession: aSession.
	generation ifNil: [ ^ true ].
	^ generation = (self currentGenerationForSession: aSession)
]

{ #category : 'registries' }
GbsProxyLifecycle class >> newIdentityRegistry [
	| registryClass |
	registryClass := Smalltalk globals at: #WeakIdentityKeyDictionary ifAbsent: [ nil ].
	registryClass ifNotNil: [ ^ registryClass new ].
	^ IdentityDictionary new
]

{ #category : 'registries' }
GbsProxyLifecycle class >> proxyGenerationRegistryForSession: aSession [
	^ (aSession class weakRegistryNamed: #GbsSessionProxyLifecycleProxyGenerations)
		at: aSession
		ifAbsentPut: [ self newIdentityRegistry ]
]

{ #category : 'registries' }
GbsProxyLifecycle class >> proxyGenerationRegistryForSessionIfPresent: aSession [
	^ (aSession class weakRegistryNamed: #GbsSessionProxyLifecycleProxyGenerations)
		at: aSession
		ifAbsent: [ nil ]
]

{ #category : 'tracking' }
GbsProxyLifecycle class >> registerProxy: aProxy forSession: aSession [
	aSession ifNil: [ ^ aProxy ].
	(self proxyGenerationRegistryForSession: aSession)
		at: aProxy
		put: (self currentGenerationForSession: aSession).
	^ aProxy
]
