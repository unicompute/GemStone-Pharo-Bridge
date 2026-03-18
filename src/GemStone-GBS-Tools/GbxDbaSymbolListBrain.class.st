Class {
	#name : 'GbxDbaSymbolListBrain',
	#superclass : 'GbxDbaBrain',
	#instVars : [
		'mode',
		'user'
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Tools'
}

{ #category : 'accessing' }
GbxDbaSymbolListBrain >> dictionaryPasteIndex
[
	" Answer the index + 1 of the current selection in the list of names of symbol dictionaries available to my user.  Answer 1 if nothing is currently selected. "

	^ self currentDictsSelectionIndex + 1
]

{ #category : 'accessing' }
GbxDbaSymbolListBrain >> dictionaryCutIndex
[
	" Answer the index of the current selection in the list of names of symbol dictionaries available to my user.  Abort if nothing is currently selected. "

	self hasDictionarySelected ifFalse:
		[^ self error: 'no dict selected' ].
	^ self currentDictsSelectionIndex
]

{ #category : 'accessing' }
GbxDbaSymbolListBrain >> dictionaries
[
	" Answer a list of symbol dictionaries available to my user. "

	^ self user dictionaries
]

{ #category : 'accessing' }
GbxDbaSymbolListBrain >> user
[
	" Answer the value of user, the GSUserProfileHolder whose Symbol List shows in my window. "

	^ user
]

{ #category : 'accessing' }
GbxDbaSymbolListBrain >> currentGsForwarder
[
	" Answer a forwarder on the current selection. "

	^ self inDictionaryMode
		ifTrue: [self currentDictsSelection remoteSymbolListDictionary]
		ifFalse: [self userForwarderFor: self currentItemsSelection]
]

{ #category : 'accessing' }
GbxDbaSymbolListBrain >> itemNames
[
	" Answer a list of symbols in the current symbol dictionary. "

	^ self hasDictionarySelected
		ifTrue:
			[self currentDictsSelection keyNames]
		ifFalse:
			[ #() ]
]

{ #category : 'accessing' }
GbxDbaSymbolListBrain >> userForwarderFor: aSymbol
[
	" Answer an UNCACHED forwarder for the object whose name is aSymbol in the current user. "

	| assn aGbxUserProfileHolder |
	aGbxUserProfileHolder := self user.
	aGbxUserProfileHolder isNewUser
		ifTrue: [^aGbxUserProfileHolder internalForwarderFor: aSymbol].
	assn := aGbxUserProfileHolder remoteUserProfile ucfwresolveSymbol: aSymbol.
	assn isNil
		ifTrue: 
			[self tool changed: #symbolRemoved.	"The symbol was removed behind the tool's back. Update & inform the user"
			^self gbsMessenger
				warn: '#%1 has been removed. View updated'
				with: aSymbol].
	^assn ucfwvalue
]

{ #category : 'accessing' }
GbxDbaSymbolListBrain >> currDictionaryName
[
	" Answer the name of the currently selected GemStone SymbolListDictionary. "

	^ self currentDictsSelection displayString
]

{ #category : 'accessing' }
GbxDbaSymbolListBrain >> itemInformation
[
	" Answer a string that shows more information about the selected item in either the dictionary list or the name list. "

	self currentItemsSelection isNil ifTrue: [^String new].
	^self session
		unsynchronizedEvaluateBlock: '[:symDict :itemName :dictionaryMode |
			| object ws | 
			ws := WriteStream on: String new. 
			object := dictionaryMode
						ifTrue: [symDict]
						ifFalse: [symDict at: itemName].
			object _class == ClientForwarder ifTrue: [^''a ClientForwarder''].
			object isBehavior
				ifTrue: [ws nextPutAll: object printString, '' class '']
				ifFalse: [ws nextPutAll: object printString].
			ws cr; cr;
				nextPutAll: ''Security Policy: '';
				nextPutAll: object objectSecurityPolicy asString. 
			ws contents]'
		with: self currentDictsSelection remoteSymbolListDictionary
		with: self currentItemsSelection
		with: self inDictionaryMode
]

{ #category : 'accessing' }
GbxDbaSymbolListBrain >> currDictionaryForwarder
[
	" Answer a forwarder to the currently selected GemStone SymbolListDictionary. "

	^ self currentDictsSelection remoteSymbolListDictionary
]

{ #category : 'accessing' }
GbxDbaSymbolListBrain >> initialNote
[
	" I take advantage of the selected item status line by presenting the user some notes on this window. "

	^	'NOTE:  Changes take place ' ,
		(self user isNewUser
			ifTrue: ['when the new user is saved']
			ifFalse: ['immediately']) ,
		'.'
]

{ #category : 'accessing' }
GbxDbaSymbolListBrain >> mode
[
	" Answer the value of mode, a Symbol describing what the buttons affect. "

	mode isNil ifTrue:
		[mode := #dict.].
	^ mode
]

{ #category : 'testing' }
GbxDbaSymbolListBrain >> hasEntryCompatiblePasteBuffer
[
	" Answer true if the current contents of GbxClipboardObj is usable for pasting into the entry list. "

	^ GbxClipboardObj isEmpty not
]

{ #category : 'testing' }
GbxDbaSymbolListBrain >> hasDictionarySelected
[
	" Answer true if a dictionary is currently selected. "

	^ self currentDictsSelection notNil
]

{ #category : 'testing' }
GbxDbaSymbolListBrain >> hasDictCompatiblePasteBuffer
[
	" Answer true if the current contents of GbxClipboardObj is usable for pasting into the dictionary list. "

	| assn |
	assn := GbxClipboardObj
				getObjectForSession: self session
				context: #SymbolListStuff
				quietly: true.
	assn isNil ifTrue: [^false].
	^assn value gbxDelegate remoteClassName = 'SymbolDictionary'
]

{ #category : 'testing' }
GbxDbaSymbolListBrain >> hasCompatiblePasteBuffer
[
	" Answer true if the current contents of GSClipboardObj is usable for pasting in my current mode. "

	^ self inDictionaryMode
		ifTrue: [self hasDictCompatiblePasteBuffer]
		ifFalse: [self hasEntryCompatiblePasteBuffer & self hasDictionarySelected]
]

{ #category : 'testing' }
GbxDbaSymbolListBrain >> inEntryMode
[
	" Answer true if the buttons affect entries in the current dictionary. "

	^ self inDictionaryMode not
]

{ #category : 'testing' }
GbxDbaSymbolListBrain >> hasClassEntryItemSelected
[
	" Answer true if the current entry selection is a GemStone class. "

	^self hasItemSelected and: 
			[| item |
			(item := self userForwarderFor: self currentItemsSelection) notNil 
				and: [item performOnGsServer: #isBehavior]]
]

{ #category : 'testing' }
GbxDbaSymbolListBrain >> inDictionaryMode
[
	" Answer true if the buttons affect dictionaries. "

	^ #dict == self mode
]

{ #category : 'testing' }
GbxDbaSymbolListBrain >> hasItemSelected
[
	" Answer true if an entry item is currently selected. "

	^ self currentItemsSelection notNil
]

{ #category : 'changing' }
GbxDbaSymbolListBrain >> selectedItemNameChangeQuietly
[
	" The user has typed into the dictionary/entry name field. "

	self inDictionaryMode
		ifTrue:
			[self selectedDictionaryNameChange.]
		ifFalse:
			[self selectedEntryNameChangeQuietly.].
	self ableContextButtons.
]

{ #category : 'changing' }
GbxDbaSymbolListBrain >> selectedItemNameChange
[
	" The user has typed into the dictionary/entry name field. "

	self inDictionaryMode
		ifTrue:
			[self selectedDictionaryNameChange.]
		ifFalse:
			[self selectedEntryNameChange.].
	self ableContextButtons.
]

{ #category : 'changing' }
GbxDbaSymbolListBrain >> checkWildcardFor: aList
ifNoMatch: anExitBlock
[
		" If the user has typed a wildcard selection, I present a menu of matching items. "

	| chosenName |

	chosenName := self
		checkWildcardIn: self currentItemName
		for: aList
		ifNoMatch: [^ anExitBlock value ].
	self newItemName: chosenName.
]

{ #category : 'changing' }
GbxDbaSymbolListBrain >> selectedEntryNameChangeQuietly
[
	" Either the user or my code has changed the entry name field. "

	self newItemsSelection: self currentItemName asSymbol.
	self hasItemSelected ifFalse:
		[self gbsMessenger warn: 'There is no entry named %1.' with: self currentItemName.
		^ self ].
	self itemNameListSelected.
]

{ #category : 'changing' }
GbxDbaSymbolListBrain >> selectedEntryNameChange
[
	" The user has typed into the entry name field. "

	| noMatchBlock |

	noMatchBlock :=
		[self gbsMessenger warn: 'No match for %1.' with: self currentItemName.
		^ self showSelectedItemName ].
	(self gbsMessenger confirm: 'Search for ''%1'' in all dictionaries?' with: self currentItemName)
		ifTrue:
			[self	checkWildcardIfNoMatch: noMatchBlock.]
		ifFalse:
			[self	checkWildcardFor: self currentItemsList
				ifNoMatch: noMatchBlock.].
	self selectedEntryNameChangeQuietly.
]

{ #category : 'changing' }
GbxDbaSymbolListBrain >> selectedDictionaryNameChange
[
	" The user has typed into the dictionary name field. "

	self	checkWildcardFor: self currentDictsList
		ifNoMatch:
			[self gbsMessenger warn: 'No match for %1.' with: self currentItemName.
			^ self showSelectedItemName ].
	self currentDictsList do:
		[: aGSSymbolListDictionaryHolder |
		aGSSymbolListDictionaryHolder displayString = self currentItemName ifTrue:
			[self newDictsSelection: aGSSymbolListDictionaryHolder.
			^ self dictionaryListSelected ].].
	self gbsMessenger warn:  'There is no SymbolDictionary named %1.' with: self currentItemName.
]

{ #category : 'changing' }
GbxDbaSymbolListBrain >> checkWildcardIfNoMatch: anExitBlock
[
	" If the user has typed a wildcard selection, I present a menu of matching items. "

	| chosenName list header |

	chosenName := nil.
	self dictionaries do:
		[: aGSSymbolListDictionaryHolder |
		header := '-- Dictionary:  ' , aGSSymbolListDictionaryHolder dictName asString , ' --'.
		list := aGSSymbolListDictionaryHolder keyNames.
		chosenName := self
			checkWildcardIn: self currentItemName
			for: list
			title: header
			ifNoMatch: [ nil ].
		chosenName = header ifTrue:
			[chosenName := nil.].
		chosenName notNil ifTrue:
			[self newDictsSelection: aGSSymbolListDictionaryHolder.
			self newItemsList: list.
			^ self newItemName: chosenName ].].
	anExitBlock value.
]

{ #category : 'window accessing' }
GbxDbaSymbolListBrain >> currentItemsSelection
[
	" Answer the selection in my window's items list. "

	^ self windowInterface currentItemsSelection
]

{ #category : 'window accessing' }
GbxDbaSymbolListBrain >> currentUserId
[
	" Answer the value in my window's userId field. "

	^ self windowInterface currentUserId
]

{ #category : 'window accessing' }
GbxDbaSymbolListBrain >> setMenuLabelsTo: aSuffixString
[
	" I revise the items in my menu bar to reflect the current mode. "

	self windowInterface setMenuLabelsTo: aSuffixString.
]

{ #category : 'window accessing' }
GbxDbaSymbolListBrain >> newDictsList: aList
[
	" Set the list in my window's dicts list. "

	self windowInterface newDictsList: aList.
]

{ #category : 'window accessing' }
GbxDbaSymbolListBrain >> currentItemsSelectionIndex
[
	" Answer the index of the selection in my window's items list. "

	^ self windowInterface currentItemsSelectionIndex
]

{ #category : 'window accessing' }
GbxDbaSymbolListBrain >> newItemsSelection: aSymbol
[
	" Set the selection in my window's items list. "

	self windowInterface newItemsSelection: aSymbol.
]

{ #category : 'window accessing' }
GbxDbaSymbolListBrain >> newDictsSelection: aSymbol
[
	" Set the selection in my window's dicts list. "

	self windowInterface newDictsSelection: aSymbol.
]

{ #category : 'window accessing' }
GbxDbaSymbolListBrain >> currentDictsList
[
	" Answer the list in my window's dicts list. "

	^ self windowInterface currentDictsList
]

{ #category : 'window accessing' }
GbxDbaSymbolListBrain >> newItemInfo: aString
[
	" Set the value of my window's itemInfo field. "

	self windowInterface newItemInfo: aString.
]

{ #category : 'window accessing' }
GbxDbaSymbolListBrain >> newEntriesLabel: aString
[
	" Set the value of my window's entriesLabel field. "

	self windowInterface newEntriesLabel: aString.
]

{ #category : 'window accessing' }
GbxDbaSymbolListBrain >> newUserId: aString
[
	" Set the value in my window's userId field. "

	self windowInterface newUserId: aString.
]

{ #category : 'window accessing' }
GbxDbaSymbolListBrain >> selectedItemNameLabel
[
	" Answer the label for the selected item's name. "

	^ self windowInterface selectedItemNameLabel
]

{ #category : 'window accessing' }
GbxDbaSymbolListBrain >> currentDictsSelection
[
	" Answer the selection in my window's dicts list. "

	^ self windowInterface currentDictsSelection
]

{ #category : 'window accessing' }
GbxDbaSymbolListBrain >> newItemName: aString
[
	" Set the value in my window's itemName field. "

	self windowInterface newItemName: aString.
]

{ #category : 'window accessing' }
GbxDbaSymbolListBrain >> newItemsList: aList
[
	" Set the list in my window's items list. "

	self windowInterface newItemsList: aList.
]

{ #category : 'window accessing' }
GbxDbaSymbolListBrain >> currentDictsSelectionIndex
[
	" Answer the index of the selection in my window's dicts list. "

	^ self windowInterface currentDictsSelectionIndex
]

{ #category : 'window accessing' }
GbxDbaSymbolListBrain >> currentItemName
[
	" Answer the value in my window's itemName field. "

	^ self windowInterface currentItemName
]

{ #category : 'window accessing' }
GbxDbaSymbolListBrain >> setSelectedItemNameLabel: aString
[
	" Set the label for the selected item's name. "

	self windowInterface setSelectedItemNameLabel: aString.
]

{ #category : 'window accessing' }
GbxDbaSymbolListBrain >> currentItemsList
[
	" Answer the list in my window's items list. "

	^ self windowInterface currentItemsList
]

{ #category : 'actions' }
GbxDbaSymbolListBrain >> pasteItem
[
	" Place the paste buffer into the current selection. "

	self inDictionaryMode
		ifTrue: [self pasteDictItem]
		ifFalse: [self pasteEntryItem].
]

{ #category : 'actions' }
GbxDbaSymbolListBrain >> copy: anObject
named: aString
mode: aSymbol
[
		" Place the current selection into the paste buffer. "

	| label objClassName |

	objClassName := anObject gbxDelegate remoteClassName.
	label := WriteStream on: (String new: 100).
	label nextPutAll: 'The '.
	label nextPutAll: (#dict == aSymbol
		ifTrue: ['dictionary']
		ifFalse: ['entry']).
	label nextPutAll: ' named '''.
	label nextPutAll: aString.
	label nextPutAll: ''' (a'.
	objClassName first isVowel ifTrue:
		[label nextPut: $n.].
	label nextPut: $ .
	label nextPutAll: objClassName.
	label nextPut: $).
	GbxClipboardObj
		newForObj: (Association key: aString value: anObject)
		session: self session
		context: #SymbolListStuff
		descr: label contents.
	self ableContextButtons.
]

{ #category : 'actions' }
GbxDbaSymbolListBrain >> inspectDictItem
[
	" Inspect the current dictionary selection. "

	self currentDictsSelection remoteSymbolListDictionary inspect.
]

{ #category : 'actions' }
GbxDbaSymbolListBrain >> switchMode
[
	" Change mode and repaint the affected widgets. "

	self mode: (self inDictionaryMode
		ifTrue: [#entry]
		ifFalse: [#dict]).
	self updateInCurrentMode.
]

{ #category : 'actions' }
GbxDbaSymbolListBrain >> copyItem
[
	" Place the current selection into the paste buffer. "

	self inDictionaryMode
		ifTrue: [self copyDictItem]
		ifFalse: [self copyEntryItem].
]

{ #category : 'actions' }
GbxDbaSymbolListBrain >> pasteDictItem
[
	" Place the paste buffer into the user's list of symbol dictionaries. "

	self pasteMode: #dict.
]

{ #category : 'actions' }
GbxDbaSymbolListBrain >> userNameChange
[
	" The user has chosen a new user, either by typing or from the menu of users. "

	| newUser oldUser revertBlock |

	self newUserId: self currentUserId gbxTrimBlanks.
	oldUser := self user.
	revertBlock :=
		[self newUserId: oldUser userId asString.
		^ self userNameChange ].
	self currentUserId = ''
		ifTrue: [ ^revertBlock value ].
	self checkWildcardInUserId: self currentUserId
		ifMatch:
			[: aUserId | self newUserId: aUserId.]
		ifNoMatch:
			[(self currentUserId includes: $*) ifTrue:
				[self gbsMessenger warn: 'No match for %1.' with: self currentUserId.
				^ revertBlock value ].].
	newUser := self userNamed: self currentUserId.
	newUser isNil ifTrue:
		[self gbsMessenger warn: 'No user with ID: %1.' with: self currentUserId.
		^ revertBlock value ].
	^[
		self user: (GbxUserProfileHolder on: newUser).
		self newDictsSelection: nil.
		self newItemsSelection: nil.
		self newDictsList: self dictionaries.
		self dictionaryListSelected.
	 ]
		on: GbsError errorSignal
		do: [:ex |
			self gbsMessenger
				warn: 'You (as User ID %1) do not have\authority to view %2.\\%3'
				with: self session parameters username
				with: newUser userId asString
				with: ex originator messageText.
			ex return: revertBlock value
		].
]

{ #category : 'actions' }
GbxDbaSymbolListBrain >> cutDictionary: aNameString
[
	" I remove the SymbolDictionary object named aNameString from the current user.
	  Answer true if the cut is successful. "

	self newItemsSelection: nil.
	^[self user removeDictionaryAt: self dictionaryCutIndex. true]
		on: GbsError errorSignal
		do: [:ex |
			self gbsMessenger
				warn: 'You (as User ID %1) do not have\authority to remove from the SymbolList of %2.\\%3'
				with: self session parameters username
				with: self user userId asString
				with: ex originator messageText.
			ex return: false
		].
]

{ #category : 'actions' }
GbxDbaSymbolListBrain >> pasteEntryItem
[
	" Place the paste buffer into the currently selected symbol dictionary. "

	self pasteMode: #entry.
]

{ #category : 'actions' }
GbxDbaSymbolListBrain >> addDictItem
[
	" Allow the user to add a new dictionary to the current UserProfile. "

	| name symbDict |

	name := self gbsMessenger request: 'Name of new SymbolDictionary?'.
	(name size = 0) ifTrue: [^ self ].
	name := name asSymbol.
	symbDict := (self sessionForwarderFor: #SymbolDictionary) ucfwnew.
	symbDict ucfwat: name put: symbDict.
	self	pasteOrAdd: (Association key: name value: symbDict)
		mode: #dict
		with: #( 'Add' 'Added' ).
]

{ #category : 'actions' }
GbxDbaSymbolListBrain >> pasteOrAdd: anAssociation
mode: aSymbol
with: aLabelArray
[
		" Place the value of anAssociation into the current selection, using the key as its name. "

	| successful |

	successful := #dict == aSymbol
		ifTrue: [self pasteDictionary: anAssociation]
		ifFalse: [self pasteEntry: anAssociation].
	successful ifFalse:
		[^ self gbsMessenger warn: '%1 failed.' with: aLabelArray first].
	self gbsMessenger warn: '%1.' with: aLabelArray last.
	aSymbol == self mode
		ifTrue:
			[self clearModeSelection.
			self newItemName: anAssociation key asString.
			self selectedItemNameChangeQuietly.]
		ifFalse:
			[self updateNonModeList.].
]

{ #category : 'actions' }
GbxDbaSymbolListBrain >> checkSpecialDict: aDictNameSymbol
ifMistake: anExitBlock
[
		" Private - Warn the user if the symbol list dictionary named
	  aDictNameSymbol is one of the special symbol list dictionaries
	  whose removal may cause problems. "

	(#( Globals Published UserClasses UserGlobals ) includes: aDictNameSymbol)
		ifFalse: [^ self ].
	(self gbsMessenger
		confirm: '%1 is one of the standard GemStone dictionaries.Removing it may cause subsequent undefined symbols which could \adversely affect your image.\\Do you still want to remove it?'
		with: aDictNameSymbol
	) ifFalse: [ ^anExitBlock value ].
]

{ #category : 'actions' }
GbxDbaSymbolListBrain >> cutItem
[
	" Place the current selection into the paste buffer and remove it from its dictionary. "

	self inDictionaryMode
		ifTrue: [self cutDictItem]
		ifFalse: [self cutEntryItem].
]

{ #category : 'actions' }
GbxDbaSymbolListBrain >> updateSymbolListsRequest
[
	" I repaint the current information, as it may be obsolete. Deselect item before
	update, as it may no longer exist."

	| selectedItem |
	self showBusyWhile:
		["Deselect"
		selectedItem := self currentItemsSelection.
		self newItemsSelection: nil.
 		"Update"
		self windowInterface newUserId: self user userId.
		self showDictionaries.
		self showItems.
		"Reselect, if the item is still there"
		(selectedItem notNil and: [self itemNames includes: selectedItem])
			 ifTrue: [self newItemsSelection: selectedItem].
		].
]

{ #category : 'actions' }
GbxDbaSymbolListBrain >> copyEntryItem
[
	" Place the current selection into the paste buffer. "

	self	copy: (self userForwarderFor: self currentItemsSelection)
		named: self currentItemsSelection
		mode: #entry.
]

{ #category : 'actions' }
GbxDbaSymbolListBrain >> inspectItem
[
	" Inspect the current selection. "

	self inDictionaryMode
		ifTrue: [self inspectDictItem]
		ifFalse: [self inspectEntryItem].
]

{ #category : 'actions' }
GbxDbaSymbolListBrain >> cutDictItem
[
	" Place the current dictionary selection into the paste buffer and remove it from the user. "

	| name |

	name := self currentDictsSelection dictName.
	(self gbsMessenger confirm: 'Really remove %1?' with: name) ifFalse:
		[^ self ].
	self
		checkSpecialDict: name
		ifMistake: [^ self ].
	self mode: #dict.
	self copyDictItem.
	self updateInCurrentMode.
	self	cut: self currentDictsSelection remoteSymbolListDictionary
		named: name
		mode: #dict.
]

{ #category : 'actions' }
GbxDbaSymbolListBrain >> pasteEntry: anAssociation 
[
	" I place the contents of anAssociation into the current SymbolDictionary.
	  Answer true if the paste is successful. "

	| name symbDict |
	name := anAssociation key.
	symbDict := self currDictionaryForwarder.
	(symbDict includesKey: name) 
		ifTrue: 
			[(self gbsMessenger 
				confirm: '%1 is already in %2.\Do you want to paste over it?'
				with: name
				with: self currDictionaryName) ifFalse: [^false]].
	^
	[symbDict ucfwat: name asSymbol put: anAssociation value.
	self showItems.
	true] 
			on: GbsError errorSignal
			do: 
				[:ex | 
				self gbsMessenger 
					warn: 'You (as User ID %1) do not have\authority to change %2''s symbol list.\\%3'
					with: self session parameters username
					with: self user userId asString
					with: ex originator messageText.
				ex return: false]
]

{ #category : 'actions' }
GbxDbaSymbolListBrain >> browseClassEntryItem
[
	" Browse the current dictionary entry selection, which is a GemStone class.
	NOTE:  Fixed by Chuck Schmidt to resolve the class with respect to the selected user and his/her symbol list. "

	| classDictCreateString className |

	className := (self userForwarderFor: self currentItemsSelection) ucfwname asGSObject asLocalObject asString.
	  classDictCreateString :=
		('| dict profile class |\' ,
		'profile := AllUsers userWithId: #' , self user remoteUserProfile userId , '.\' ,
		'class := (profile resolveSymbol: #' , className , ') value.\' ,
		'dict := SymbolDictionary new.\' ,
		'dict at: #' , className , ' put: class.\' ,
		'dict') gbxAddLineDelimiters.
	GbxBrowser
		openBrowseClasses: (self session execute: classDictCreateString)
		sorted: true
		label: 'GemStone Class Browser for  ', className, ' on ', self session printString
		selecting: className asSymbol.
]

{ #category : 'actions' }
GbxDbaSymbolListBrain >> cutEntryItem
[
	" Place the current entry selection into the paste buffer and remove it from the dictionary. "

	self copyEntryItem.
	self	cut: (self userForwarderFor: self currentItemsSelection)
		named: self currentItemsSelection
		mode: #entry.
]

{ #category : 'actions' }
GbxDbaSymbolListBrain >> addItem
[
	" Allow the user to add a new item to the current environment. "

	self inDictionaryMode
		ifTrue: [self addDictItem]
		ifFalse: [self addEntryItem].
]

{ #category : 'actions' }
GbxDbaSymbolListBrain >> pasteMode: aSymbol
[
	" Place the paste buffer into the current selection. "

	| clipAssn newName  |

	GbxClipboardObj isEmpty
		ifTrue: [^self gbsMessenger warn: 'Nothing has been copied.'].
	clipAssn := GbxClipboardObj getObjectForSession: self session.
	clipAssn isNil ifTrue:
		[^ self gbsMessenger warn: 'Not pasted.' ].
	(clipAssn respondsTo: #key) ifFalse: [
		newName := self gbsMessenger request: 'Name for this object?'.
		(newName size = 0) ifTrue: [^ self ].
		clipAssn := Association
			key: newName
			value: clipAssn.
	].
	self pasteOrAdd: clipAssn
		mode: aSymbol
		with:  #( 'Paste' 'Pasted' ).
]

{ #category : 'actions' }
GbxDbaSymbolListBrain >> copyDictItem
[
	" Place the current selection into the paste buffer. "

	self	copy: self currentDictsSelection remoteSymbolListDictionary
		named: (self currentDictsSelection dictName ifNil: [''])
		mode: #dict.
]

{ #category : 'actions' }
GbxDbaSymbolListBrain >> inspectEntryItem
[
	" Inspect the current dictionary entry selection. "

	(self currentDictsSelection remoteSymbolListDictionary ucfwat: self currentItemsSelection) inspect.
]

{ #category : 'actions' }
GbxDbaSymbolListBrain >> updateNonModeList
[
	" I update the contents of the list in the non-selected mode. "

	self inDictionaryMode
		ifTrue:
			[self showItems.]
		ifFalse:
			[self showDictionaries.].
]

{ #category : 'actions' }
GbxDbaSymbolListBrain >> pasteDictionary: anAssociation
[
	" I add the SymbolList in anAssociation to the user's list.
	  Answer true if the paste is successful. "

	^[
		self user
			insertDictionary: anAssociation value
			at: self dictionaryPasteIndex. true
	 ]
		on: GbsError errorSignal
		do: [: ex |
			self gbsMessenger
				warn: 'You (as User ID %1) do not have\authority to add to the SymbolList of %2.\\%3'
				with: self session parameters username
				with: self user userId asString
				with: ex originator messageText.
			ex return: false
		].
]

{ #category : 'actions' }
GbxDbaSymbolListBrain >> cut: anObject
named: aString
mode: aSymbol
[
		" Place the current selection into the paste buffer and remove it from its dictionary. "

	| cutSuccessful |

	cutSuccessful := #dict == aSymbol
		ifTrue: [self cutDictionary: aString.]
		ifFalse: [self cutEntry: aString.].
	cutSuccessful ifFalse:
		[self gbsMessenger warn: 'Cut failed.'.
		^ self ].
	self gbsMessenger warn: 'Cut.'.
	self clearModeSelection.
	self showItems.
]

{ #category : 'actions' }
GbxDbaSymbolListBrain >> addEntryItem
[
	" Allow the user to add a new entry to the current dictionary. "

	| name |

	name := self gbsMessenger request: 'Name of new entry?'.
	(name size = 0) ifTrue: [^ self ].
	name := name asSymbol.
	self	pasteOrAdd: (Association key: name value: nil)
		mode: #entry
		with: #( 'Add' 'Added' ).
]

{ #category : 'actions' }
GbxDbaSymbolListBrain >> cutEntry: aNameString
[
	" I remove the object named aNameString from the currently selected SymbolDictionary.
	  Answer true if the cut is successful. "

	| symbDict |

	self currentDictsSelection dictName = aNameString ifTrue:
		[self gbsMessenger warn: 'You cannot remove this dictionary''s self-referencing entry.'.
		^ false ].
	symbDict := self currDictionaryForwarder.
	^ (symbDict includesKey: aNameString)
		ifTrue:
			[symbDict ucfwremoveKey: aNameString.
			true ]
		ifFalse:
			[ false ]
]

{ #category : 'window changing' }
GbxDbaSymbolListBrain >> clearModeSelection
[
	" The current selection has been cut. "

	self showBusyWhile:
		[ self newItemName: nil.
		self inDictionaryMode
			ifTrue:
				[self newDictsSelection: nil.
				self newDictsList: self dictionaries.
				self dictionaryListSelected.]
			ifFalse:
				[self newItemsSelection: nil.
				self newItemsList: self itemNames.
				self setEntryMode.].
		self enableButtons.].
]

{ #category : 'window changing' }
GbxDbaSymbolListBrain >> dictionaryListSelected
[
	" When no dictionary is selected, certain buttons must be disabled. "

	self showBusyWhile: 
			[self newItemsSelection: nil.
			self showSelectedItemName.
			self hasDictionarySelected
				ifTrue: 
					[self setEntryMode.
					self setSelectedItemNameLabel: 'Selected Dictionary'.
					self enableButtons.
					self showItems]
				ifFalse: 
					[self setDictMode.
					self disableButtons.
					self hideItems.
					self setSelectedItemNameLabel: String new]]
]

{ #category : 'window changing' }
GbxDbaSymbolListBrain >> disableButtons
[
	" Deactivate certain buttons until a dictionary is selected.
	  NOTE:  To be VW / VS compatible, button names must start with an uppercase letter.
	  WARNING:  Do not use # within array declarations. "

	self disableGroup: #( ModeButton ).
	self ableContextButtons.
]

{ #category : 'window changing' }
GbxDbaSymbolListBrain >> enableButtons
[
	" Activate certain buttons while a dictionary is selected.
	  NOTE:  To be VW / VS compatible, button names must start with an uppercase letter.
	  WARNING:  Do not use # within array declarations. "

	self enableGroup: #( ModeButton  AddItemButton ).
	self ableContextButtons.
]

{ #category : 'window changing' }
GbxDbaSymbolListBrain >> hideItems
[
	" When a dictionary is deselected, I must hide the names in it. "

	self newItemsList: #().
	self newEntriesLabel: ''.
]

{ #category : 'window changing' }
GbxDbaSymbolListBrain >> itemNameListSelected
[
	" When no entry is selected, certain buttons must be disabled. "

	self showBusyWhile: 
			[self hasItemSelected
				ifTrue: 
					[self setEntryMode.
					self setSelectedItemNameLabel: 'Selected Entry']
				ifFalse: 
					[self ableContextButtons.
					self showSelectedItemName.
					self setSelectedItemNameLabel: 'Selected Dictionary']]
]

{ #category : 'window changing' }
GbxDbaSymbolListBrain >> setDictMode
[
	" I configure the buttons to act on dictionaries. "

	self mode: #dict.
	self setMenuLabelsTo: 'Dict'.
	self setSelectedItemNameLabel: 'Selected Dictionary'.
	self enableButtons.
	self showSelectedItemName.
]

{ #category : 'window changing' }
GbxDbaSymbolListBrain >> setEntryMode
[
	" I configure the buttons to act on entries in the current dictionary. "

	self mode: #entry.
	self setMenuLabelsTo: 'Entry'.
	self hasItemSelected ifTrue: [self setSelectedItemNameLabel: 'Selected Entry'].
	self enableButtons.
	self showSelectedItemName
]

{ #category : 'window changing' }
GbxDbaSymbolListBrain >> showDictionaries
[
	" When a dictionary list is changed, I must update it. "

	| selection |

	self showBusyWhile:
		[ selection := self currentDictsSelection.
		self newDictsList: self dictionaries.
		self newDictsSelection: selection.
		self updateInCurrentMode.].
]

{ #category : 'window changing' }
GbxDbaSymbolListBrain >> showItems
[
	" When a dictionary is selected, I must show the names in it. "

	| list |

	self showBusyWhile:
		[ list := self itemNames.
		self newItemsList: list.
		self newEntriesLabel: (self hasDictionarySelected
			ifTrue:
				[(list isEmpty ifTrue: ['No'] ifFalse: [list size printString]) ,
					' Entr' ,
					(list size = 1ifTrue: ['y'] ifFalse: ['ies'])]
			ifFalse:
				['']).
		self updateInCurrentMode.	].
]

{ #category : 'window changing' }
GbxDbaSymbolListBrain >> showSelectedItemName
[
	" Update the selected item's name. "

	| label |
	self showBusyWhile: 
			[self newItemName: (self inDictionaryMode
						ifTrue: [self hasDictionarySelected ifTrue: [self currentDictsSelection displayString] ifFalse: ['']]
						ifFalse: 
							[self hasItemSelected
								ifTrue: [self currentItemsSelection asString]
								ifFalse: [self hasDictionarySelected ifTrue: [self currentDictsSelection displayString] ifFalse: []]]).
			label := self selectedItemNameLabel.
			(self currentItemName isNil or: [self currentItemName isEmpty])
				ifTrue: 
					[label disable.
					self newItemInfo: '']
				ifFalse: 
					[label enable.
					self newItemInfo: self itemInformation]]
]

{ #category : 'window changing' }
GbxDbaSymbolListBrain >> ableContextButtons
[
	" Activate or deactivate certain buttons, depending on the current context.
	  NOTE:  To be VW / VS compatible, button names must start with an uppercase letter.
	  WARNING:  Do not use # within array declarations. "

	self hasCompatiblePasteBuffer
		ifTrue:
			[self enableGroup: #( PasteItemButton ).]
		ifFalse:
			[self disableGroup: #( PasteItemButton ).].
	(self inDictionaryMode & self hasDictionarySelected
			or: [self inEntryMode & self hasItemSelected])
		ifTrue:
			[self enableGroup: #( CopyItemButton  CutItemButton  InspectItemButton ).]
		ifFalse:
			[self disableGroup: #( CopyItemButton  CutItemButton  InspectItemButton ).].
	self hasClassEntryItemSelected
		ifTrue:
			[self enableGroup: #( BrowseClassEntryItemButton ).]
		ifFalse:
			[self disableGroup: #( BrowseClassEntryItemButton ).].
]

{ #category : 'window changing' }
GbxDbaSymbolListBrain >> updateInCurrentMode
[
	" Repaint the affected widgets. "

	self inDictionaryMode
		ifTrue: [self setDictMode]
		ifFalse: [self setEntryMode].
]

{ #category : 'external changing' }
GbxDbaSymbolListBrain >> updateNotification: aSymbol
[
	" Some other DBA window has changed something.  I may have to update my user ID menu or my information. "

	(self class myUserIDMenuNotificationSymbols includes: aSymbol) ifTrue:
		[self windowInterface updateUserIDMenuRequest.].
	#clipboardChange == aSymbol ifTrue:
		[self ableContextButtons.].
	super updateNotification: aSymbol.
]

{ #category : 'external changing' }
GbxDbaSymbolListBrain >> updateDataRequest
[
	" I allow external changes to refresh the list of current dictionaries, etc. "

	(self user gbxIsGSDefunct
			or: [self user isNewUser not
				and: [(self userNamed: self user userId asString) isNil ]]) ifTrue:
		[^ self windowInterface closeRequest ].
	self updateSymbolListsRequest.
]

{ #category : 'updating' }
GbxDbaSymbolListBrain >> user: aGSUserProfileHolder
[
	" Set the value of user, the GSUserProfileHolder whose Symbol List shows in my window. "

	(aGSUserProfileHolder remoteUserProfile notNil
			and: [aGSUserProfileHolder remoteUserProfile zzzisForwarder not]) ifTrue:
		[^ self error: 'not a forwarder'].
	user := aGSUserProfileHolder.
]

{ #category : 'updating' }
GbxDbaSymbolListBrain >> mode: aSymbol
[
	" Set the value of mode, a Symbol describing what the buttons affect. "

	mode := aSymbol.
]

{ #category : 'external changing' }
GbxDbaSymbolListBrain class >> myNotificationSymbols
[
	" Answer a list of symbols that mean I have to update my information.  Default to no symbols.
	  WARNING:  For VW / VS compatibility, do not user '#' before each symbol. "

	^ super myNotificationSymbols , #(committed aborted symbolRemoved).
]

{ #category : 'interface opening' }
GbxDbaSymbolListBrain class >> fileAndEditMenuText
[
	" Answer an array of text for the variable parts of my window's menu bar.
	  WARNING:  Do not use embedded '#'s for VW/VS compatibility. "

	^ 	#(
			(
				'Edit'
				(
					'Cut '
					'Copy '
					'Paste '
				)
			)
			(
				'Object'
				(
					'Add '
					'Inspect '
					'Browse Class'
				)
			)
		)
]
