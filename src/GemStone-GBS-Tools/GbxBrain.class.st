Class {
	#name : #'GbxBrain',
	#superclass : #'Object',
	#instVars : [ #'tool' #'allSegments' ],
	#classVars : [  ],
	#category : #'GemStone-GBS-Tools'
}

{ #category : #'accessing' }
GbxBrain >> tool
	" Answer the value of tool, which contains the window interface within which I am embedded. "

	^ tool

{ #category : #'accessing' }
GbxBrain >> session

	^ self windowInterface session

{ #category : #'accessing' }
GbxBrain >> userProfileProxy

	^ self windowInterface userProfileProxy

{ #category : #'accessing' }
GbxBrain >> windowInterface
	" Answer the window interface within which I am embedded. "

	^ self tool

{ #category : #'accessing' }
GbxBrain >> allSegments
	"Return a list of segment holders for all segments in our tool's session."
	
	| allSgmts sess user |
	allSegments == nil
		ifTrue:
			[sess := self session.
			user := self windowInterface userProfileProxy.
			allSgmts := sess evaluate:
					'| sr segments |
								sr := SystemRepository.
								segments := OrderedCollection new. 
								1 to: sr size do:  [:idx | | seg |
									seg := sr at: idx.
									 ((System canRead: seg) and: [seg ~~ nil]) ifTrue:[segments add: seg]]. 
								segments'.
			allSegments := (allSgmts
				collect:
					[:segFwd | 
					GbxSegmentHolder
						newWithSgmt: (segFwd asGSObjectInSession: sess)
						user: user]) asSortedCollection].
	^allSegments

{ #category : #'private' }
GbxBrain >> addSessionInfoTo: aStream
	" Add some info about the session for this tool to aStream. "

	aStream
		nextPutAll: 'The session for this window is:' ;
		cr ;
		nextPutAll: '    ' ;
		nextPutAll: (self session isNil
			ifTrue: ['None']
			ifFalse: [self session printString]) ;
		nextPut: $. ;
		cr ;
		cr ;
		nextPutAll: 'The current session is:' ;
		cr ;
		nextPutAll: '    ' ;
		nextPutAll: GBSM currentSession printString ;
		nextPut: $..

{ #category : #'private' }
GbxBrain >> showBusyWhile: aBlock
	" I show the Gem cursor while evaluating aBlock.
	  This lets the user know that something is happening. "

	^GBSM showBusyWhile: aBlock

{ #category : #'actions' }
GbxBrain >> showSessionInfo
	" Give the user some about the session for this tool. "

	| info |

	info := WriteStream on: (String new: 200).
	self addSessionInfoTo: info.
	self gbsMessenger warn: info contents.

{ #category : #'actions' }
GbxBrain >> commitTransaction
	" Allow the user to make permanent all changes in the current transaction.
	Answer true if the commit succeeds, false if the commit fails, and nil if
	the user cancels the commit."

	| commitResult |

	(self gbsMessenger confirm: 'Are you sure you want to commit this session?')
		ifFalse: [^ nil].
	self showBusyWhile: [
		[ commitResult := self session commitTransaction. ]
			on:  (GbsError signalFor: #rtErrMaxCommitRetry)
			do: [ :aContext |
				self gbsMessenger warn: 'Commit failed.  Please\abort before you retry.'.
				aContext return.
			].
	].
	commitResult == true
		ifTrue: [ self gbsMessenger warn: 'Committed.' ]
		ifFalse: [ self gbsMessenger warn: 'Not committed.' ].
	^commitResult.

{ #category : #'actions' }
GbxBrain >> abortTransaction
	" Allow the user to discard all changes made in the current transaction.
	  Answer true if the user aborted, or false if the abort was cancelled. "

	(self gbsMessenger confirm: 'Are you sure you want to abort your transaction?')
		ifFalse: [^ false ].
	self showBusyWhile: [
		self session abortTransaction isNil ifTrue: [
			self gbsMessenger warn: 'Not aborted.'.
			^ false
		].
	].
	self gbsMessenger warn: 'Aborted.'.
	^ true

{ #category : #'actions' }
GbxBrain >> showHelpInfo
	" Give the user some hints on how to use this tool. "

	self gbsMessenger warn: ' No help available.'.

{ #category : #'interface opening' }
GbxBrain >> postBuild
	" I take any additional action after the builder has completed work on my window.  Default to do nothing. "

{ #category : #'external changing' }
GbxBrain >> updateNotification: aSymbol
	" Some other DBA window has changed something.  I may have to update my information. "

	(self myNotificationSymbols includes: aSymbol) ifTrue:
		[self updateDataRequest.].

{ #category : #'external changing' }
GbxBrain >> myNotificationSymbols
	" Answer a list of symbols that mean I have to update my information. "

	^ self class myNotificationSymbols

{ #category : #'external changing' }
GbxBrain >> updateDataRequest
	" I allow external changes to refresh the data I am showing.  Default to do nothing. "

{ #category : #'external changing' }
GbxBrain >> changeNotification: aSymbol
	" I tell all other DBA windows that I have changed something which may require them to update their information. "

	self windowInterface changeNotification: aSymbol.

{ #category : #'updating' }
GbxBrain >> tool: aGSApplicationModel
	" Set the value of tool, which contains the window interface within which I am embedded. "

	tool := aGSApplicationModel.

{ #category : #'external changing' }
GbxBrain class >> myNotificationSymbols
	" Answer a list of symbols that mean I have to update my information.  Default to no symbols.
	  WARNING:  For VW / VS compatibility, do not user '#' before each symbol. "

	^ #( )

{ #category : #'instance creation' }
GbxBrain class >> new: tl
	" Answer an instance of the receiver on the window interface within which it is embedded. "

	| inst |
	inst := super new initialize.
	inst tool: tl.
	^inst

{ #category : #'instance creation' }
GbxBrain class >> within: aGSApplicationModel
	" Answer an instance of the receiver on the window interface within which it is embedded. "

	^ super new initialize
		tool: aGSApplicationModel

