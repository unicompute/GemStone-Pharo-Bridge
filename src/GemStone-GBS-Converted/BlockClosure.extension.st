Extension { #name : 'BlockClosure' }

{ #category : '*GemStone-GBS-Converted-block replication' }
BlockClosure >> asBlockCallback [
	GbsConfiguration current blockReplicationPolicy = #replicate
		ifTrue: [ GbxExecBlock addCallbackOverride: self ].
	^ self
]

{ #category : '*GemStone-GBS-Converted-block replication' }
BlockClosure >> asBlockReplicate [
	GbsConfiguration current blockReplicationPolicy = #callback
		ifTrue: [ GbxExecBlock addReplicateOverride: self ].
	^ self
]

{ #category : '*GemStone-GBS-Converted-block replication' }
BlockClosure >> asGSObjectCopyInSession: aSession [
	GbsConfiguration
		deprecated: 'Copy replication deprecated March, 2006. Use normal replication instead'.
	^ self gbxCopyToSession: aSession exporting: false
]

{ #category : '*GemStone-GBS-Converted-block replication' }
BlockClosure >> asGSObjectInSession: sess [
	| delegate |
	delegate := sess cacheAtST: self.
	delegate isNil ifFalse: [ ^ delegate forSession: sess ].
	self gbxBlockReplicationPolicy = #replicate
		ifTrue: [ delegate := self gbxCopyToSession: sess exporting: true ]
		ifFalse: [ delegate := sess unsynchronizedExecute: 'ClientForwarder new' ].
	sess connectClient: self toServer: delegate.
	^ delegate
]

{ #category : '*GemStone-GBS-Converted-assertions' }
BlockClosure >> gbxAssert [
	self gbxAssertEquals: true
]

{ #category : '*GemStone-GBS-Converted-assertions' }
BlockClosure >> gbxAssertEquals: expectedValue [
	self gbxAssertEquals: expectedValue message: ''
]

{ #category : '*GemStone-GBS-Converted-assertions' }
BlockClosure >> gbxAssertEquals: expectedValue message: failureString [
	self gbsMessenger
		runAssertion: self
		forResult: expectedValue
		message: failureString
]

{ #category : '*GemStone-GBS-Converted-block replication' }
BlockClosure >> gbxBlockReplicationPolicy [
	^ GbxExecBlock blockReplicationPolicyFor: self
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
BlockClosure >> gbxCanBeStubbed [
	^ false
]

{ #category : '*GemStone-GBS-Converted-block replication' }
BlockClosure >> gbxCopyToSession: aSession exporting: shouldExport [
	| source |
	source := WriteStream on: (String new: 100).
	shouldExport
		ifTrue: [
			source
				nextPutAll: '| gbxBlock |';
				nextPutAll: String cr;
				nextPutAll: 'gbxBlock := ';
				nextPutAll: self gbxDecompiledSource;
				nextPutAll: '.';
				nextPutAll: String cr;
				nextPutAll: 'System _add: gbxBlock toGciSet: 39.';
				nextPutAll: String cr;
				nextPutAll: '^gbxBlock' ]
		ifFalse: [ source nextPutAll: self gbxDecompiledSource ].
	^ [ aSession unsynchronizedExecute: source contents ]
		on: GbsCompilerError
		do: [ :ex | self gbsMessenger raise: GbsBlockReplicationError message: ex description ]
]

{ #category : '*GemStone-GBS-Converted-block replication' }
BlockClosure >> gbxDecompiledSource [
	| source |
	GbsConfiguration current blockReplicationEnabled
		ifFalse: [
			^ self gbsMessenger
				raise: GbsBlockReplicationError
				message: 'Block replication is disabled.' ].
	self numCopiedValues > 0
		ifTrue: [
			^ self gbsMessenger
				raise: GbsBlockReplicationError
				message: 'Attempt to replicate a dirty block. Dirty blocks can''t be replicated.' ].
	source := [ self sourceNode value sourceCode ]
		on: Error
		do: [
			:ex |
			^ self gbsMessenger
				raise: GbsBlockReplicationError
				message: 'Block could not be decompiled.' ].
	(source includes: $^)
		ifTrue: [
			^ self gbsMessenger
				raise: GbsBlockReplicationError
				message: 'Can''t replicate blocks containing returns.' ].
	^ source
]

{ #category : '*GemStone-GBS-Converted-guarantees' }
BlockClosure >> gbxGuarantee [
	self gbxGuaranteeEquals: true
]

{ #category : '*GemStone-GBS-Converted-guarantees' }
BlockClosure >> gbxGuaranteeEquals: expectedValue [
	self gbxGuaranteeEquals: expectedValue message: ''
]

{ #category : '*GemStone-GBS-Converted-guarantees' }
BlockClosure >> gbxGuaranteeEquals: expectedValue message: failureString [
	self gbsMessenger
		runGuarantee: self
		forResult: expectedValue
		message: failureString
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
BlockClosure >> gbxIsModifiable [
	^ false
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
BlockClosure >> gbxNewProcessNamed: aString [
	| process |
	process := self newProcess.
	process name: aString.
	^ process
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
BlockClosure >> gbxNumArguments [
	^ self numArgs
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
BlockClosure >> gbsValueAutonomous [
	| response sem |
	sem := Semaphore new.
	[
		[ response := self value ]
			ensure: [ sem signal ] ] fork.
	sem wait.
	^ response
]
