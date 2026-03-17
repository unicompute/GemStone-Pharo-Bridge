Class {
	#name : #'GbxGroupHolder',
	#superclass : #'Object',
	#instVars : [ #'group' #'members' ],
	#classVars : [  ],
	#category : #'GemStone-GBS-Tools'
}

{ #category : #'comparing' }
GbxGroupHolder >> <= aHolder

   "Comparison operator used for sorting group holder collections."

   ^(self group <= aHolder group)

{ #category : #'accessing' }
GbxGroupHolder >> members

   "Return the value of the 'members' instance variable."

   (members isNil) ifTrue: [
	  members := SortedCollection new.
	  ].
   ^members

{ #category : #'accessing' }
GbxGroupHolder >> group

   "Return the value of the 'group' instance variable."

   ^group

{ #category : #'updating' }
GbxGroupHolder >> group: aGroupNameString

	"Set the value of the 'group' instance variable.
	NOTE:  Starting in 5.0, group names are strings, not symbols."

	group := aGroupNameString isNil
		ifTrue: [ aGroupNameString ]
		ifFalse: [ aGroupNameString asString ].

{ #category : #'updating' }
GbxGroupHolder >> members: mbrs

   "Set the value of the 'members' instance variable."

   members := mbrs.

{ #category : #'private' }
GbxGroupHolder >> getMembers: users
	"Gets the group holder's group members and assigns a list of them to
   members. The group members are taken from the given users list"

	members := (users select: [:userHldr | self shouldAddGroupFor: userHldr])
				asSortedCollection

{ #category : #'private' }
GbxGroupHolder >> shouldAddGroupFor: userHldr

	^group gbxDelegate session
		evaluateBlock: '[:user :group |user groups isNil 
	ifTrue:[false] 
	ifFalse:[(user groups detect:[:userProfileGroup | userProfileGroup groupName asString = group ] ifNone:[]) notNil]]'
		withArguments: (Array with: userHldr remoteUserProfile with: group)
		context: nil

{ #category : #'instance creation' }
GbxGroupHolder class >> newWithGrp: aGroupNameString

   "Create a group holder from a new group, i.e. a group which does not
	have any members yet. The group holder contains the group and the
	userProfile members belonging to the group."

   | inst |

   inst := super new.
   inst group: aGroupNameString.
   ^inst

{ #category : #'instance creation' }
GbxGroupHolder class >> new

   "Disallow #new operator, use #newWithGrp: or #newWithGrp:users:
   instead."

   self shouldNotImplement.

{ #category : #'instance creation' }
GbxGroupHolder class >> newWithGrp: aGroupNameString
users: users

   "Create a group holder from an existing group which could already have
	members. The group holder contains the group and the userProfile
	members belonging to the group."

   | inst |

   inst := super new.
   inst group: aGroupNameString.
   inst getMembers: users.
   ^inst

