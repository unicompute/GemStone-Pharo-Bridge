Class {
	#name : 'GbxClipboardObj',
	#superclass : 'Object',
	#instVars : [
		'obj',
		'context',
		'type',
		'session',
		'descr'
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Tools'
}

{ #category : 'updating' }
GbxClipboardObj >> obj: anObj session: aSession context: aContext
[

   "Set the instance variables for the clipboard object."

   obj := anObj.
   session := aSession.
   context := aContext.
   self setObjType.
   self setObjDescr.
   self pasteToClipboard.
]

{ #category : 'updating' }
GbxClipboardObj >> obj: anObj session: aSession context: aContext descr: aDescr
[

   "Set the instance variables for the clipboard object."

   obj := anObj.
   session := aSession.
   context := aContext.
   descr := aDescr.
   self setObjType.
   self pasteToClipboard.
]

{ #category : 'accessing' }
GbxClipboardObj >> getForSession: aSession context: aContext
[

   "This function is used for the less intelligent version of the clipboard. If the context and session for
	which the object is requested is the same as the object's session and context then the object is
	returned otherwise nil is returned."

	^ self
		getForSession: aSession
		context: aContext
		quietly: false
]

{ #category : 'accessing' }
GbxClipboardObj >> descr
[

   "Return the value of the 'descr' instance variable."

   ^descr
]

{ #category : 'accessing' }
GbxClipboardObj >> session
[

   "Return the value of the 'session' instance variable."

   ^session
]

{ #category : 'accessing' }
GbxClipboardObj >> obj
[

   "Return the value of the 'obj' instance variable."

   ^obj
]

{ #category : 'accessing' }
GbxClipboardObj >> context
[

   "Return the value of the 'context' instance variable."

   ^context
]

{ #category : 'accessing' }
GbxClipboardObj >> type
[

   "Return the value of the 'type' instance variable."

   ^type
]

{ #category : 'accessing' }
GbxClipboardObj >> getForSession: aSession
[
context: aContext
quietly: aQuietlyBoolean

   "This function is used for the less intelligent version of the clipboard. If the context and session for
	which the object is requested is the same as the object's session and context then the object is
	returned otherwise nil is returned.  If the requested context is nil, then only the session is checked."

   (context = aContext | aContext isNil) ifTrue: [
	   (session = aSession) ifTrue: [
		   ^obj
		   ]
	   ifFalse: [
	     aQuietlyBoolean ifFalse: [
		   	    self gbsMessenger warn: 'The clipboard object is not from the proper session: \''%1''!' with: aSession.
				 ].
		   ].
	   ]
   ifFalse: [
	   aQuietlyBoolean ifFalse: [
		   self gbsMessenger warn: 'The clipboard object does not have the proper context: \''%1''!' with: aContext.
		   ].
	   ].
   ^nil
]

{ #category : 'testing' }
GbxClipboardObj >> isValidType: aType
[

  "Return true if the clipboard object can be converted to type aType and if aType
   is a valid type."

  ((type = #smalltalk) and: [(type = aType) not]) ifTrue: [
	  self gbsMessenger warn: 'The clipboard object is of type #smalltalk which \cannot be converted to type ''%1''!' with: aType.
	  ^false
	  ].

  ((aType = #smalltalk) and: [(type = aType) not]) ifTrue: [
	  self gbsMessenger warn: 'The clipboard object is of type %1 which \cannot be converted to type #smalltalk!' with: type.
	  ^false
	  ].

  ((aType = #smalltalk) or: [(aType = #replicate) or: [(aType = #proxy) or: [aType = #forwarder]]]) ifFalse: [
	 self gbsMessenger warn: 'The given type, %1, is not a valid clipboard type!' with: aType.
	 ^false
	 ].

  ^true
]

{ #category : 'testing' }
GbxClipboardObj >> verifyObjInSession: aSession 
[
	"Verify that the session in which the clipboard object resides is on the same repository
	as aSession and if so return the identical GemStone object it corresponds to in session
	aSession if it exists. The assumption here is that the clipboard object is not of type
	#smalltalk."

	| objOop tempGSObj |
	session parameters gemStoneName = aSession parameters gemStoneName 
		ifFalse: 
			[self gbsMessenger 
				warn: 'The clipboard object''s session is not on the same repository as the given session!'.
			^nil].
	objOop := obj asGSObject oopValue.
	tempGSObj := GbxDelegate oopValue: objOop session: aSession.
	tempGSObj exists 
		ifFalse: 
			[self gbsMessenger 
				warn: 'The clipboard object in session ''%1''\ does not exist in session ''%1''!'
				with: session
				with: aSession.
			^nil].
	self gbsMessenger 
		warn: 'NOTE:  The clipboard object may not be identical in the two sessions!'.
	^tempGSObj
]

{ #category : 'clipboard' }
GbxClipboardObj >> removeFromClipboard
[

   "Remove the object from the clipboard."

   (GSClipboard notNil) ifTrue: [
	   GSClipboard remove: self ifAbsent: [^self gbsMessenger warn: 'There is no object ''%1'' in the GemBuilder clipboard!' with: self descr].
	   self clear.
	   ]
   ifFalse: [
	   self gbsMessenger warn: 'The GemBuilder clipboard has not been created yet!'.
	  ].
   self notifySessions.
  ^GSClipboard
]

{ #category : 'clipboard' }
GbxClipboardObj >> pasteToClipboard
[

   "Add the object to the top of our clipboard while removing any excess (>5) objects from
	the clipboard."

   | size lastObj |
   (GSClipboard isNil) ifTrue: [
	   GSClipboard := OrderedCollection new.
	   ]
   ifFalse: [
	  size := GSClipboard size.
	  (size = 5) ifTrue: [
		   lastObj := GSClipboard removeLast.
		   lastObj clear.
		   ].
	   ].
   GSClipboard addFirst: self.
   self gbsMessenger warn: '%1\ has been pasted to the GBS clipboard.' with: descr.
   self notifySessions.
   ^GSClipboard
]

{ #category : 'private' }
GbxClipboardObj >> notifySessions
[
	" I warn all of the current sessions that the clipboard has changed in some way. "

	GBSM loggedInSessions do:
		[: aGSSession |
		aGSSession changed: #clipboardChange.].
]

{ #category : 'private' }
GbxClipboardObj >> setObjType
[
	"Determine the clipboard object's type."

	obj zzzisForwarder ifTrue: [^type := #forwarder].
	obj isGSObject ifTrue: [^type := #proxy].
	(obj gbxDelegate forSession: session) notNil ifTrue: [^type := #replicate].
	^type := #smalltalk
]

{ #category : 'private' }
GbxClipboardObj >> setObjDescr
[

   "Determine the clipboard object's description from the object's context and type."

   descr := 'The object ''', context, ' (#',type,')'''.
]

{ #category : 'private' }
GbxClipboardObj >> clear
[

  "Clear all instance variables."

  obj := nil.
  type := nil.
  session := nil.
  descr := nil.
  context := nil.
]

{ #category : 'accessing' }
GbxClipboardObj class >> getObjectForSession: aSession
[

	" This method is used for the least intelligent version of the clipboard.
	   It returns the clipboard object if the requested session is correct. "

	^ self
		getObjectForSession: aSession
		context: nil
]

{ #category : 'accessing' }
GbxClipboardObj class >> getObjectForSession: aSession context: aContext
[

  "This method is used for the less intelligent version of the clipboard. It returns the clipboard object
   only if the requested session and context are correct."

	^ self
		getObjectForSession: aSession
		context: aContext
		quietly: false
]

{ #category : 'accessing' }
GbxClipboardObj class >> firstClipboardSession
[
	" Answer the session of the first clipboard object.  Answer nil if none exists. "

	^ self isEmpty
		ifTrue: [ nil ]
		ifFalse: [ GSClipboard first session ]
]

{ #category : 'accessing' }
GbxClipboardObj class >> getClipboardForSession: aSession context: aContext
[

  "This method is used for the less intelligent version of the clipboard. It returns the clipboard object
   only if the requested session and context are correct."

	| selClipObj |
	self isEmpty ifFalse: [
		selClipObj := self gbsMessenger
				choose: 'Pick an object'
				fromList: (GSClipboard collect: [:clipObj | clipObj descr ])
				values: GSClipboard lines: 5 cancel: [^nil].
		selClipObj notNil
			ifTrue: [ ^selClipObj getForSession: aSession context: aContext ].
	].
	^nil
]

{ #category : 'accessing' }
GbxClipboardObj class >> getObjectForSession: aSession
[
context: aContext
quietly: aQuietlyBoolean

  "This method is used for the less intelligent version of the clipboard. It returns the clipboard object
   only if the requested session and context are correct."

   | firstClipObj |

   self isEmpty ifFalse: [
	   firstClipObj := GSClipboard first.
	   (firstClipObj notNil) ifTrue: [
		   ^firstClipObj getForSession: aSession context: aContext quietly: aQuietlyBoolean.
		   ].
	   ].
   ^nil
]

{ #category : 'testing' }
GbxClipboardObj class >> notEmpty
[

	" Answer true if I have at least one clipboard object in my clipboard. "

	^self isEmpty not
]

{ #category : 'testing' }
GbxClipboardObj class >> isEmpty
[

	" Answer true if I have at least one clipboard object in my clipboard. "

	^ GSClipboard isNil or: [GSClipboard isEmpty]
]

{ #category : 'instance creation' }
GbxClipboardObj class >> new
[

   "Disallow #new operator, use #newForObj:session:context: or #newForObj:session:context:type:
   instead."

   self shouldNotImplement.
]

{ #category : 'instance creation' }
GbxClipboardObj class >> newForObj: anObj session: aSession context: aContext
[

   "Add the given object to the clipboard indicating its given session and context."

   | inst |

   inst := super new clear.
   inst obj: anObj session: aSession context: aContext.
   ^inst
]

{ #category : 'instance creation' }
GbxClipboardObj class >> newForObj: anObj session: aSession context: aContext descr: aDescr
[

   "Add the given object to the clipboard indicating its given session, context, and type."

   | inst |

   inst := super new clear.
   inst obj: anObj session: aSession context: aContext descr: aDescr.
   ^inst
]

{ #category : 'clipboard' }
GbxClipboardObj class >> clear
[

   "Clear the clipboard."

   GSClipboard := nil.
]

