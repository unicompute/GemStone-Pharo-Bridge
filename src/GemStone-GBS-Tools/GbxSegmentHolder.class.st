Class {
	#name : #'GbxSegmentHolder',
	#superclass : #'Object',
	#instVars : [ #'segmentProxy' #'dictProxy' #'segmentName' ],
	#classVars : [  ],
	#category : #'GemStone-GBS-Tools'
}

{ #category : #'comparing' }
GbxSegmentHolder >> <= aHolder

   "Comparison operator used for sorting segment holder collections."

   ^(self segmentName <= aHolder segmentName)

{ #category : #'accessing' }
GbxSegmentHolder >> segmentProxy

   "Return the value of the 'segmentProxy' instance variable."

   ^segmentProxy

{ #category : #'accessing' }
GbxSegmentHolder >> dictProxy

   "Return the value of the 'dictProxy' instance variable."

   ^dictProxy

{ #category : #'accessing' }
GbxSegmentHolder >> segmentName

   "Return the value of the 'segmentName' instance variable."

   ^segmentName

{ #category : #'updating' }
GbxSegmentHolder >> dictProxy: dict

   "Set the value of the 'dictProxy' instance variable."

   dictProxy := dict

{ #category : #'updating' }
GbxSegmentHolder >> segmentProxy: sgmt

   "Set the value of the 'segmentProxy' instance variable."

   segmentProxy := sgmt

{ #category : #'updating' }
GbxSegmentHolder >> segmentName: nm

   "Set the value of the 'segmentName' instance variable."

   segmentName := nm

{ #category : #'private' }
GbxSegmentHolder >> getSegmentName: userProxy
	"Determine the name of the segment holder's segment relative to
	the given user. If no name is found and the segment is not the
	user's default segment, name the segment 'UnNamed#', where # is
	the number of the segment in the system repository."

	| anArrayProxy defSgmtProxy |
	anArrayProxy := segmentProxy session
				execute: '
					| array | 
					array := (System myUserProfile dictionariesAndSymbolsOf: self).
					array isEmpty
						ifTrue:[nil]
						ifFalse:[array first]'
				context: segmentProxy.
	(anArrayProxy performOnGsServer: #notNil)
		ifTrue: 
			[segmentName := anArrayProxy performOnGsServer: #at: withArguments: #(2).
			dictProxy := anArrayProxy remotePerform: #at: with: 1]
		ifFalse: 
			[defSgmtProxy := userProxy remotePerform: #defaultObjectSecurityPolicy.
			segmentName := (defSgmtProxy performOnGsServer: #==
						withArguments: (Array with: segmentProxy))
							ifTrue: [#DefaultSegment]
							ifFalse: 
								[('Unnamed' , (segmentProxy performOnGsServer: #number) printString)
									asSymbol].
			dictProxy := anArrayProxy]

{ #category : #'instance creation' }
GbxSegmentHolder class >> new

   "Disallow #new operator, use #newWithSgmt:name:dict: or
   #newWithSgmt:user: instead."

   self shouldNotImplement

{ #category : #'instance creation' }
GbxSegmentHolder class >> newWithSgmt: sgmtProxy name: nm dict: dictProxy

   "Create a segment holder from the new segment with the given name
	in the given dictionary."

   | inst |

   inst := super new.
   inst segmentProxy: sgmtProxy.
   inst segmentName: nm.
   inst dictProxy: dictProxy.
   ^inst

{ #category : #'instance creation' }
GbxSegmentHolder class >> newWithSgmt: sgmtProxy user: userProxy

   "Create a segment holder from an existing segment and determine its
	name relative to the given user."

   | inst |

   inst := super new.
   inst segmentProxy: sgmtProxy.
   inst getSegmentName: userProxy.
   ^inst

