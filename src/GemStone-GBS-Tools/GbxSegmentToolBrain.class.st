Class {
	#name : 'GbxSegmentToolBrain',
	#superclass : 'GbxAdminToolsBrain',
	#instVars : [
		'allGroups',
		'allUsers'
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Tools'
}

{ #category : 'accessing' }
GbxSegmentToolBrain >> allGroups
[
	"Return a list of group holders for all groups in our tool's session."

	| allGrps numGrps grp |
	allGroups isNil
		ifTrue: 
			[allGrps := (self session resolveSymbol: #AllGroups) remotePerform: #asArray.
			numGrps := allGrps performOnGsServer: #size.
			allGroups := SortedCollection new: numGrps.
			1 to: numGrps
				do: 
					[:i |
					grp := allGrps performOnGsServer: #at: withArguments: (Array with: i).
					allGroups add: (GbxGroupHolder newWithGrp: grp users: self allUsers)]].
	^allGroups
]

{ #category : 'accessing' }
GbxSegmentToolBrain >> membersForGrp: selGrpRec
[
   " Answer a list of user profile holders representing the members for the selected group record. "

	^ self showBusyWhile:
		[ selGrpRec notNil
			ifTrue: [ selGrpRec groupHldr members ]
			ifFalse: [ SortedCollection new ]]
]

{ #category : 'accessing' }
GbxSegmentToolBrain >> segments
[
	" Answer a list of segment records for all object security policies readable by the tool session's user. "

	^self showBusyWhile: 
			[| isSU isDC userId sgmts sgmtProxy |
			userId := self userProfileProxy performOnGsServer: #userId.
			isSU := userId = 'SystemUser'.
			isDC := userId = 'DataCurator'.
			sgmts := SortedCollection new: self allSegments size.
			self allSegments do: 
					[:sgmtHldr |
					sgmtProxy := sgmtHldr segmentProxy.
					"Note that the follwoing check is not really necessary."
					((sgmtProxy performOnGsServer: #currentUserCanRead) or: [isSU or: [isDC]])
						ifTrue: 
							[(sgmtHldr segmentName == #GsIndexingSegment) not
								ifTrue: [sgmts add: (self windowInterface sgmtRecClass newWithSgmt: sgmtHldr tool: self windowInterface)]]].
			sgmts]
]

{ #category : 'accessing' }
GbxSegmentToolBrain >> allUsers
[
	"Return a list of user profile holders for all users in our tool's session."

	| allUsrs userFrwdr numUsers |
	allUsers isNil
		ifTrue: 
			[allUsrs := (self session resolveSymbol: #AllUsers) remotePerform: #asArray.
			numUsers := allUsrs performOnGsServer: #size.
			allUsers := SortedCollection new: numUsers.
			1 to: numUsers
				do: 
					[:i |
					userFrwdr := (allUsrs remotePerform: #at: with: i) asForwarder.
					allUsers add: (GbxUserProfileHolder on: userFrwdr)]].
	^allUsers
]

{ #category : 'accessing' }
GbxSegmentToolBrain >> groupsForSgmt: selSgmtRec
[
	" Answer a list of group records for the selected segment record. "

	| groups sgmtProxy sgmtHldr grp grps numGrps isMyGroup |
	selSgmtRec isNil ifTrue: [^SortedCollection new].
	self showBusyWhile: 
			[groups := selSgmtRec groups.
			groups isEmpty
				ifTrue: 
					[sgmtHldr := selSgmtRec segmentHldr.
					sgmtProxy := sgmtHldr segmentProxy.
					grps := sgmtProxy remotePerform: #groups.
					numGrps := grps performOnGsServer: #size.
					1 to: numGrps
						do: 
							[:index |
							grp := grps performOnGsServer: #at: withArguments: (Array with: index).
							self allGroups do: 
									[:grpHldr |
									isMyGroup := grpHldr group = grp groupName asString.
									isMyGroup
										ifTrue: 
											[groups add: (self windowInterface grpRecClass
														newWithGrp: grpHldr
														segment: sgmtHldr
														tool: self windowInterface)]]]]].
	^groups
]

{ #category : 'private' }
GbxSegmentToolBrain >> changeNameTo: sgmtName holder: sgmtHldr dictionary: dictProxy
[

	| dictSgmtProxy dictName result |
	dictSgmtProxy := dictProxy remotePerform: #objectSecurityPolicy.
	(dictSgmtProxy performOnGsServer: #currentUserCanWrite)
		ifTrue: 
			[sgmtName isEmpty
				ifTrue: 
					[self gbsMessenger warn: 'The object security policy must have a name!']
				ifFalse: 
					[dictName := dictProxy performOnGsServer: #name.
					result := self validateName: sgmtName inDict: dictProxy withName: dictName.
					result notNil
						ifTrue: 
							[result isEmpty ifTrue: [result := 'Object Security Policy name not changed!'].
							self gbsMessenger warn: result]
						ifFalse: 
							[dictProxy remotePerform: #removeKey:ifAbsent: with: sgmtHldr segmentName with: [].
							dictProxy
								remotePerform: #at:put:
								with: sgmtName
								with: sgmtHldr segmentProxy.
							sgmtHldr segmentName: sgmtName]]]
		ifFalse: 
			[self gbsMessenger
				warn: 'You do not have write authorization for the dictionary containing object security policy ''%1''!'
				with: sgmtHldr segmentName]
]

{ #category : 'private' }
GbxSegmentToolBrain >> collectGroupNamesFor: segmentOrUserProxy
[

	| grps |
	grps := self session
				evaluate: '(self groups collect:[:group | group groupName]) asSortedCollection'
				context: segmentOrUserProxy.
	^grps
]

{ #category : 'actions-group' }
GbxSegmentToolBrain >> removeGroup: selGrpRec fromSgmt: selSgmtRec updateList: grps
[
	"Remove given group from given Object Security Policy."

	| sgmtProxy sgmtHldr grpHldr result |
	(selSgmtRec notNil and: [selGrpRec notNil])
		ifTrue: 
			[sgmtHldr := selSgmtRec segmentHldr.
			grpHldr := selGrpRec groupHldr.
			sgmtProxy := sgmtHldr segmentProxy.
			(((self userProfileProxy performOnGsServer: #privileges)
				includes: #ObjectSecurityPolicyProtection) or: 
						[(sgmtProxy remotePerform: #owner) performOnGsServer: #==
							withArguments: (Array with: self userProfileProxy)])
				ifTrue: 
					[result := self gbsMessenger
								confirm: 'Really remove group ''%1''\from object security policy ''%2''?'
								with: grpHldr group asString
								with: sgmtHldr segmentName.
					result
						ifTrue: 
							[sgmtProxy
								remotePerform: #group:authorization:
								with: grpHldr group
								with: #none.
							selSgmtRec groups remove: selGrpRec.
							^selGrpRec]]
				ifFalse: 
					[self gbsMessenger warn: 'You do not have Object Security Policy Protection privilege!']].
	^nil
]

{ #category : 'actions-group' }
GbxSegmentToolBrain >> addGroupToSgmt: selSgmtRec updateList: grps
[
	"Prompt for the name of the group to be added."

	| sgmtHldr grpHldr sgmtProxy grpRec privs |
	selSgmtRec notNil
		ifTrue: 
			[sgmtHldr := selSgmtRec segmentHldr.
			sgmtProxy := sgmtHldr segmentProxy.
			privs := self session evaluate: 'self privileges'
						context: self userProfileProxy.
			((privs includes: #ObjectSecurityPolicyProtection)
				or: [(sgmtProxy remotePerform: #owner) performOnGsServer: #==
							withArguments: (Array with: self userProfileProxy)])
				ifTrue: 
					[grpHldr := self windowInterface addGroupDialog: self addGroupSuggestion
								with: selSgmtRec.
					grpHldr notNil
						ifTrue: 
							[grpRec := self windowInterface grpRecClass
										newWithGrp: grpHldr
										segment: sgmtHldr
										tool: self windowInterface.
							selSgmtRec groups add: grpRec.
							^grpRec]]
				ifFalse: 
					[self gbsMessenger warn: 'You do not have Object Security Policy Protection privilege!']].
	^nil
]

{ #category : 'actions-group' }
GbxSegmentToolBrain >> changeGroupAuthTo: grpAuth forGroup: selGrpRec inSgmt: selSgmtRec
[
	"Change the auhtorization for the given group in the given Object Security Policy to the given authorization."

	| grp sgmtProxy privs |
	(selSgmtRec notNil and: [selGrpRec notNil])
		ifTrue: 
			[sgmtProxy := selSgmtRec segmentHldr segmentProxy.
			privs := self session evaluate: 'self privileges' context: self userProfileProxy.
			((privs includes: #ObjectSecurityPolicyProtection)
				or: [(sgmtProxy remotePerform: #owner) performOnGsServer: #== withArguments: (Array with: self userProfileProxy)])
					ifTrue: 
						[(#(#read #write) includes: grpAuth)
							ifTrue: 
								[grp := selGrpRec groupHldr group.
								sgmtProxy remotePerform: #group:authorization: with: grp with: grpAuth.
								^grpAuth]
							ifFalse: 
								[grpAuth = #none
									ifTrue: [self gbsMessenger warn: 'Select the ''Remove...'' menu item in the ''Group'' menu to remove group authorization!']
									ifFalse: [self gbsMessenger warn: '''%1'' is not a valid authorization. Expected ''read'', or ''write''!' with: grpAuth]]]
					ifFalse: [self gbsMessenger warn: 'You do not have Object Security Policy Protection privilege!']].
	^nil
]

{ #category : 'actions-group' }
GbxSegmentToolBrain >> replaceGroup: selGrpRec inSgmt: selSgmtRec withGroup: grpName andAuth: grpAuth
[
	"Replace the given group in the given object security policy with the given new group."

	| grpHldr sgmtProxy oldGrp |
	(selSgmtRec notNil and: [selGrpRec notNil])
		ifTrue: 
			[| privs |
			sgmtProxy := selSgmtRec segmentHldr segmentProxy.
			privs := self userProfileProxy performOnGsServer: #privileges.
			((privs includes: #ObjectSecurityPolicyProtection)
				or: [(sgmtProxy remotePerform: #owner) performOnGsServer: #== withArguments: (Array with: self userProfileProxy)])
					ifTrue: 
						[oldGrp := selGrpRec groupHldr group.
						grpHldr := self
									addGroup: grpName
									toSgmt: selSgmtRec
									withAuth: grpAuth
									replace: oldGrp.
						grpHldr isString
							ifTrue: [self gbsMessenger warn: grpHldr]
							ifFalse: 
								[selGrpRec groupHldr: grpHldr.
								^selGrpRec]]
					ifFalse: [self gbsMessenger warn: 'You do not have Object Security Policy Protection privilege!']].
	^nil
]

{ #category : 'actions-group' }
GbxSegmentToolBrain >> addGroup: grpName toSgmt: selSgmtRec withAuth: grpAuth replace: oldGrp
[
	" Add the given group to the given Object Security Policy, replacing the old group if given. "

	| grps grpHldr grpNm sgmtHldr sgmtProxy allGrps allGrpsSgmtProxy includesGroup |
	(grpName isNil or: [grpName isEmpty])
		ifTrue: [^'The group must have a name!'].
	grpNm := grpName asString.	" group names are strings "
	sgmtHldr := selSgmtRec segmentHldr.
	sgmtProxy := sgmtHldr segmentProxy.
	grps := sgmtProxy remotePerform: #groups.
	(grps performOnGsServer: #includesValue: withArguments: (Array with: grpNm))
		ifTrue: 
			[^'Object Security Policy ''' , sgmtHldr segmentName
				, ''' already includes group ''' , grpNm
				, '''!'].
	allGrps := self session resolveSymbol: #AllGroups.
	includesGroup := allGrps performOnGsServer: #includesKey:
				withArguments: (Array with: grpNm asSymbol).
	includesGroup
		ifTrue: 
			[" It is possible that this group has been added to AllGroups while the Segment Tool has been up,
					so we need to create a GbxGroupHolder for it and update our allGroups snap shot. "
			self allGroups do: [:hldr | hldr group = grpNm ifTrue: [grpHldr := hldr]].
			grpHldr isNil
				ifTrue: 
					[grpHldr := GbxGroupHolder newWithGrp: grpNm.
					self allGroups add: grpHldr]]
		ifFalse: 
			[" We need to create a new group. "
			allGrpsSgmtProxy := allGrps remotePerform: #objectSecurityPolicy.
			allGrpsSgmtProxy = Onil
				ifTrue: 
					[^self gbsMessenger
						warn: 'AllGroups is not associated with an object security policy, and thus groups cannot be added'].
			(allGrpsSgmtProxy performOnGsServer: #currentUserCanWrite)
				ifFalse: 
					[^'There is no group named ''' , grpNm
						, ''' in this GemStone\' gbxAddLineDelimiters
							, 'session, and you do not have authorization to create it!'].
			(self gbsMessenger
				confirm: 'There is no group named ''%1'' in this GemStone session - create it?'
				with: grpNm) ifFalse: [^'Group ''' , grpNm , ''' not created!'].
			self session
				execute: 'AllGroups at: self put: (UserProfileGroup groupWithName: self ifAbsent:[UserProfileGroup newGroupWithName: self])'
				context: grpNm asSymbol.
			grpHldr := GbxGroupHolder newWithGrp: grpNm.
			self allGroups add: grpHldr].
	oldGrp notNil
		ifTrue: 
			[(self gbsMessenger
				confirm: 'Replace group ''%1'' with group ''%2''?'
				with: oldGrp asString
				with: grpNm)
					ifFalse: 
						[^'Group ''' , oldGrp asString , ''' not replaced with group ''' , grpNm
							, '''!'].
			sgmtProxy remotePerform: #group:authorization: with: grpNm with: grpAuth.
			sgmtProxy remotePerform: #group:authorization: with: oldGrp with: #none]
		ifFalse: 
			[sgmtProxy remotePerform: #group:authorization: with: grpNm with: grpAuth].
	^grpHldr
]

{ #category : 'reports' }
GbxSegmentToolBrain >> userReport
[
	"Generate a report on all the users in the tool's session."

	| report grps formatList tempSize userProxy userId |
	report := WriteStream on: String new.
	formatList := OrderedCollection new.
	report
		nextPutAll: 'User Report';
		cr;
		cr.
	GBSM showBusyWhile: 
			[self allUsers do: 
					[:userHldr |
					userProxy := userHldr remoteUserProfile asGSObject.
					userId := userProxy performOnGsServer: #userId.
					report nextPutAll: userId.
					tempSize := report contents size.
					formatList add: (Array with: tempSize - userId size with: tempSize).
					grps := self collectGroupNamesFor: userProxy.
					grps isEmpty
						ifFalse: 
							[report
								cr;
								nextPutAll: 'groups: ';
								cr.
							grps do: 
									[:grp |
									report
										tab;
										nextPutAll: grp;
										cr]]
						ifTrue: [report cr].
					report cr]].
	self windowInterface
		printText: report contents
		withTitle: 'User Report'
		formatList: formatList
]

{ #category : 'reports' }
GbxSegmentToolBrain >> groupReport
[
	"Generate a report on all the groups in the tool's session."

	| report mbrs formatList tempSize |
	report := WriteStream on: String new.
	formatList := OrderedCollection new.
	report
		nextPutAll: 'Group Report';
		cr;
		cr.
	GBSM showBusyWhile: 
			[self allGroups do: 
					[:grpHldr |
					report nextPutAll: grpHldr group.
					tempSize := report contents size.
					formatList add: (Array with: tempSize - grpHldr group size with: tempSize).
					mbrs := grpHldr members.
					mbrs isEmpty
						ifFalse: 
							[report
								cr;
								nextPutAll: 'members: ';
								cr.
							mbrs do: 
									[:mbrHldr |
									report
										tab;
										nextPutAll: (mbrHldr remoteUserProfile asGSObject
													performOnGsServer: #userId);
										cr]]
						ifTrue: [report cr].
					report cr]].
	self windowInterface
		printText: report contents
		withTitle: 'Group Report'
		formatList: formatList
]

{ #category : 'reports' }
GbxSegmentToolBrain >> segmentReport
[
	"Generate a report on all the object security policies a the user can read in the tool's session, including the
	GsIndexingSegment which is not displayed in the Security Policy table of the tool."

	| report sgmtProxy grps formatList tempSize dictProxy dictName |
	report := WriteStream on: String new.
	formatList := OrderedCollection new.
	report
		nextPutAll: 'Security Policy Report';
		cr;
		cr.
	GBSM showBusyWhile: 
			[self allSegments do: 
					[:sgmtHldr |
					sgmtProxy := sgmtHldr segmentProxy.
					report nextPutAll: sgmtHldr segmentName.
					tempSize := report contents size.
					formatList
						add: (Array with: tempSize - sgmtHldr segmentName size with: tempSize).
					dictProxy := sgmtHldr dictProxy.
					(dictProxy performOnGsServer: #notNil)
						ifTrue: [dictName := dictProxy performOnGsServer: #name]
						ifFalse: [dictName := '<none>'].
					report
						cr;
						nextPutAll: 'dictionary: ';
						nextPutAll: dictName.
					report
						cr;
						nextPutAll: 'owner: ';
						nextPutAll: ((sgmtProxy remotePerform: #owner) performOnGsServer: #userId);
						nextPutAll: ' (#';
						nextPutAll: (sgmtProxy performOnGsServer: #ownerAuthorization);
						nextPutAll: ')'.
					report
						cr;
						nextPutAll: 'world: (#';
						nextPutAll: (sgmtProxy performOnGsServer: #worldAuthorization);
						nextPutAll: ')'.
					grps := self collectGroupNamesFor: sgmtProxy.
					grps isEmpty
						ifFalse: 
							[report
								cr;
								nextPutAll: 'groups:';
								cr.
							grps do: 
									[:grp |
									report
										tab;
										nextPutAll: grp;
										nextPutAll: ' (#';
										nextPutAll: (sgmtProxy performOnGsServer: #authorizationForGroup:
													withArguments: (Array with: grp));
										nextPutAll: ')';
										cr]]
						ifTrue: [report cr].
					report cr]].
	self windowInterface
		printText: report contents
		withTitle: 'Security Policy Report'
		formatList: formatList
]

{ #category : 'actions-member' }
GbxSegmentToolBrain >> removeMember: selMbr fromGrp: selGrpRec updateList: mbrs
[
	"Remove given member from given group."

	| mbrProxy mbrName grp mbrSgmtProxy |
	(selGrpRec notNil and: [selMbr notNil])
		ifTrue: 
			[grp := selGrpRec groupHldr group.
			mbrProxy := selMbr remoteUserProfile asGSObject.
			mbrName := mbrProxy performOnGsServer: #userId.
			mbrSgmtProxy := mbrProxy remotePerform: #objectSecurityPolicy.
			(mbrSgmtProxy performOnGsServer: #currentUserCanWrite)
				ifTrue: 
					[(self gbsMessenger
						confirm: 'Really remove member ''%1''\from group ''%2''?'
						with: mbrName
						with: grp asString)
							ifTrue: 
								[mbrProxy remotePerform: #removeGroup: with: grp.
								selGrpRec groupHldr members remove: selMbr.
								^selMbr]]
				ifFalse: [self gbsMessenger warn: 'You do not have write authorization for user ''' , mbrName , '''!']].
	^nil
]

{ #category : 'actions-member' }
GbxSegmentToolBrain >> addMember: mbrName toGrp: selGrpRec
[
	"Add a member to the given group."

	| mbrProxy mbrHldr allUsrs grp grps mbrSgmtProxy userProxy |
	mbrName isEmpty ifTrue: [^'The member must have a user name!'].
	allUsrs := (self session resolveSymbol: #AllUsers) remotePerform: #asArray.
	1 to: (allUsrs performOnGsServer: #size)
		do: 
			[:i |
			userProxy := allUsrs remotePerform: #at: with: i.
			(userProxy performOnGsServer: #userId) = mbrName ifTrue: [mbrProxy := userProxy]].
	(mbrProxy asGSObject performOnGsServer: #isNil) ifTrue: [^'There is no user named ''' , mbrName , ''' in this GemStone session!'].
	grp := selGrpRec groupHldr group.
	grps := mbrProxy remotePerform: #groups.
	(grps performOnGsServer: #includesValue: withArguments: (Array with: grp))
		ifTrue: [^'User ''' , mbrName , ''' is already in group ''' , grp asString , '''!'].
	self allUsers
		do: [:userHldr | (userHldr remoteUserProfile asGSObject performOnGsServer: #== withArguments: (Array with: mbrProxy)) ifTrue: [mbrHldr := userHldr]].

	"It is possible that this user profile has been created and added to AllUsers while the Segment Tool
	has been up, so we need to create a GbxUserProfileHolder for it and update our allUsers snap shot."
	mbrHldr isNil
		ifTrue: 
			[mbrHldr := GbxUserProfileHolder on: mbrProxy asForwarder.
			self allUsers add: mbrHldr].
	mbrSgmtProxy := mbrProxy remotePerform: #objectSecurityPolicy.
	(mbrSgmtProxy performOnGsServer: #currentUserCanWrite) ifFalse: [^'You do not have write authorization for user ''' , mbrName , '''!'].
	mbrProxy remotePerform: #addGroup: with: grp.
	^mbrHldr
]

{ #category : 'actions-member' }
GbxSegmentToolBrain >> addMemberToGrp: selGrpRec updateList: mbrs
[

   "Prompt for the name of the member to be added."

   |  mbrHldr |

   (selGrpRec notNil) ifTrue: [
	  mbrHldr := self windowInterface addMemberDialog: 'AUser' with: selGrpRec.
	  (mbrHldr notNil) ifTrue: [
		 selGrpRec groupHldr members add: mbrHldr.
		 ^mbrHldr
		 ].
	  ].
   ^nil
]

{ #category : 'actions-segment' }
GbxSegmentToolBrain >> changeWorldAuthTo: worldAuth forSgmt: selSgmtRec
[
	"Change the world authorization for the given Object Security Policy to the given authorization."

	| sgmtProxy |
	selSgmtRec notNil
		ifTrue: 
			[| privs |
			sgmtProxy := selSgmtRec segmentHldr segmentProxy.
			privs := self userProfileProxy performOnGsServer: #privileges.
			((privs includes: #ObjectSecurityPolicyProtection)
				or: [(sgmtProxy remotePerform: #owner) performOnGsServer: #== withArguments: (Array with: self userProfileProxy)])
					ifTrue: 
						[(#(#read #write #none) includes: worldAuth)
							ifTrue: 
								[sgmtProxy remotePerform: #worldAuthorization: with: worldAuth.
								^worldAuth]
							ifFalse: 
								[self gbsMessenger warn: '''%1'' is not a valid authorization. Expected ''read'', ''write'', or ''none''!'
									with: worldAuth]]
					ifFalse: 
						[self gbsMessenger warn: 'You do not have Object Security Policy Protection privilege!']].
	^nil
]

{ #category : 'actions-segment' }
GbxSegmentToolBrain >> createSegment: sgmtName inDict: dictName
[
	"Create a new Object Security Policy with the given name in the given dictionary."

	| dictProxy sgmtProxy sgmtHldr symDictClassProxy dictSgmtProxy result |
	(sgmtName isEmpty or: [dictName isEmpty]) ifTrue: [^'The object security policy and dictionary must be named!'].
	dictProxy := self userProfileProxy remotePerform: #objectNamed: with: dictName asSymbol.
	symDictClassProxy := self session resolveSymbol: #SymbolDictionary.
	((dictProxy performOnGsServer: #isNil) or: [(dictProxy performOnGsServer: #isKindOf: withArguments: (Array with: symDictClassProxy)) not])
		ifTrue: [^'There is no dictionary named ''' , dictName , ''' in this GemStone session!'].
	dictSgmtProxy := dictProxy remotePerform: #objectSecurityPolicy.
	(dictSgmtProxy performOnGsServer: #currentUserCanWrite)
		ifFalse: [^'You do not have write authorization for dictionary ''' , dictName , '''!'].
	result := self validateName: sgmtName inDict: dictProxy withName: dictName.
	result notNil
		ifTrue: 
			[result isEmpty ifTrue: [result := 'Object Security Policy not created!'].
			^result].
	sgmtProxy := (self session resolveSymbol: #GsObjectSecurityPolicy) remotePerform: #new.
	sgmtProxy remotePerform: #worldAuthorization: with: #read.
	dictProxy
		remotePerform: #at:put:
		with: sgmtName asSymbol
		with: sgmtProxy.
	sgmtHldr := GbxSegmentHolder
				newWithSgmt: sgmtProxy
				name: sgmtName asSymbol
				dict: dictProxy.
	self allSegments add: sgmtHldr.
	^sgmtHldr
]

{ #category : 'actions-segment' }
GbxSegmentToolBrain >> createSegmentUpdateList: sgmtRecs
[
	"Prompt for the name and dictionary of the object security policy to be created."

	| sgmtHldr sgmtRec |
	((self userProfileProxy performOnGsServer: #privileges) includes: #ObjectSecurityPolicyCreation)
		ifTrue: 
			[sgmtHldr := self windowInterface createSegmentDialog: 'NewObjectSecurityPolicy'
						with: 'UserGlobals'.
			sgmtHldr notNil
				ifTrue: 
					[sgmtRec := self windowInterface sgmtRecClass newWithSgmt: sgmtHldr
								tool: self windowInterface.
					sgmtRecs add: sgmtRec.
					^sgmtRec]]
		ifFalse: 
			[self gbsMessenger warn: 'You do not have Object Security Policy Creation privilege!'].
	^nil
]

{ #category : 'actions-segment' }
GbxSegmentToolBrain >> grabSegment: selSgmtRec
[

   "Place the given Object Security Policy in the GBS clipboard."

   |  sgmtProxy  |

   (selSgmtRec notNil) ifTrue: [
	   sgmtProxy := selSgmtRec segmentHldr segmentProxy.
	   GbxClipboardObj newForObj: sgmtProxy session: (self session) context: #Segment.
	   ^selSgmtRec
	   ].
   ^nil
]

{ #category : 'actions-segment' }
GbxSegmentToolBrain >> setCurrentForDisplayUsingRecord: record 
[
	| currSgmtProxy |
	currSgmtProxy := self session systemProxy remotePerform: #currentObjectSecurityPolicy.
	self assignCurrentIndicatorForProxy: currSgmtProxy and: record
]

{ #category : 'actions-segment' }
GbxSegmentToolBrain >> setCurrentSegment: selSgmtRec updateList: sgmtRecs
[
	" Set the tool session's current Object Security Policy to the given Object Security Policy.
	  Answer selSgmtRec if successful; otherwise answer nil. "

	| isSameSeg sgmtProxy prevSgmtProxy systemProxy userCanWrite |
	selSgmtRec isNil ifTrue: [^nil].
	systemProxy := self session systemProxy.
	sgmtProxy := selSgmtRec segmentHldr segmentProxy.
	self showBusyWhile: 
			[" do remote stuff together "
			prevSgmtProxy := systemProxy remotePerform: #currentObjectSecurityPolicy.
			isSameSeg := prevSgmtProxy performOnGsServer: #== withArguments: (Array with: sgmtProxy).
			userCanWrite := sgmtProxy performOnGsServer: #currentUserCanWrite].
	isSameSeg
		ifTrue: 
			[" the specified Object Security Policy is already the current one, so
			  answer nil to avoid updating the unchanged Security Policy table "
			^nil].
	userCanWrite
		ifFalse: 
			[self gbsMessenger
				warn: 'You do not have write authorization for object security policy ''%1''!'
				with: selSgmtRec segmentHldr segmentName.
			^nil].
	self showBusyWhile: [systemProxy remotePerform: #currentObjectSecurityPolicy: with: sgmtProxy].
	^selSgmtRec
]

{ #category : 'actions-segment' }
GbxSegmentToolBrain >> assignCurrentIndicatorForProxy: currSgmtProxy and: record
[

	| sgmtProxy |
	sgmtProxy := record segmentHldr segmentProxy.
	(currSgmtProxy performOnGsServer: #== withArguments: (Array with: sgmtProxy))
		ifTrue: [record isCurrentHolder value: true]
		ifFalse: [record isCurrentHolder value: false]
]

{ #category : 'actions-segment' }
GbxSegmentToolBrain >> setDefaultForDisplayUsingRecord: record 
[
	| defSgmtProxy |
	defSgmtProxy := self userProfileProxy remotePerform: #defaultObjectSecurityPolicy.
	self assignDefaultIndicatorForProxy: defSgmtProxy and: record
]

{ #category : 'actions-segment' }
GbxSegmentToolBrain >> setDefaultSegment: selSgmtRec updateList: sgmtRecs
[
	" Set the tool session user's default Object Security Policy to the given Object Security Policy.
	  Answer selSgmtRec if successful; otherwise answer nil. "

	| isSameSeg sgmtProxy prevSgmtProxy userCanChange userCanWrite |
	selSgmtRec isNil ifTrue: [^nil].
	sgmtProxy := selSgmtRec segmentHldr segmentProxy.
	self showBusyWhile: 
			[" do remote stuff together "
			prevSgmtProxy := self userProfileProxy remotePerform: #defaultObjectSecurityPolicy.
			isSameSeg := prevSgmtProxy performOnGsServer: #==
						withArguments: (Array with: sgmtProxy).
			userCanChange := (self userProfileProxy performOnGsServer: #privileges)
						includes: #DefaultObjectSecurityPolicy.
			userCanWrite := sgmtProxy performOnGsServer: #currentUserCanWrite].
	isSameSeg
		ifTrue: 
			[" the specified Object Security Policy is already the default one, so
			  answer nil to avoid updating the unchanged Security Policy table "
			^nil].
	userCanChange
		ifFalse: 
			[self gbsMessenger
				warn: 'You do not have default object security policy setting privileges!'.
			^nil].
	userCanWrite
		ifFalse: 
			[self gbsMessenger
				warn: 'You do not have write authorization for object security policy ''%1''!'
				with: selSgmtRec segmentHldr segmentName.
			^nil].
	self showBusyWhile: 
			[self userProfileProxy remotePerform: #defaultObjectSecurityPolicy: with: sgmtProxy].
	^selSgmtRec
]

{ #category : 'actions-segment' }
GbxSegmentToolBrain >> assignDefaultIndicatorForProxy: defSgmtProxy and: record
[

	| sgmtProxy |
	sgmtProxy := record segmentHldr segmentProxy.
	(defSgmtProxy performOnGsServer: #== withArguments: (Array with: sgmtProxy))
		ifTrue: [record isDefaultHolder value: true]
		ifFalse: [record isDefaultHolder value: false]
]

{ #category : 'actions-segment' }
GbxSegmentToolBrain >> changeNameTo: sgmtName forSgmt: selSgmtRec
[
	"Change the name for the given Object Security Policy to the given name."

	| sgmtHldr dictProxy dictName |
	selSgmtRec isNil ifTrue: [^self].
	sgmtHldr := selSgmtRec segmentHldr.
	dictProxy := sgmtHldr dictProxy.
	(dictProxy performOnGsServer: #notNil)
		ifFalse: 
			[dictName := self gbsMessenger
						request: 'Enter a dictionary in which to put the object security policy ''%1'''
						with: sgmtHldr segmentName
						default: 'UserGlobals'.
			dictName isEmpty
				ifTrue: [^self gbsMessenger warn: 'Rename not performed.'].
			dictProxy := self userProfileProxy remotePerform: #objectNamed:
						with: dictName asSymbol].
	self changeNameTo: sgmtName holder: sgmtHldr dictionary: dictProxy
]

{ #category : 'actions-segment' }
GbxSegmentToolBrain >> validateName: sgmtName inDict: dictProxy withName: dictName
[
	"Verify that the given Object Security Policy name is a valid key for an Object Security Policy in the given dictionary."

	| sgmtSymbolProxy |
	sgmtName = 'DefaultSegment'
		ifTrue: [^'The Object Security Policy name ''DefaultSegment'' is reserved in the event of an unnamed default object security policy!'].
	(sgmtName beginsWith: 'Unnamed')
		ifTrue: [^'Object Security Policy names which start with ''Unnamed'' are reserved for unnamed ones!'].
	(dictProxy performOnGsServer: #includesKey: withArguments: (Array with: sgmtName asSymbol))
		ifTrue: [^'Dictionary ''' , dictName , ''' already includes an object named ''' , sgmtName , '''!'].
	sgmtSymbolProxy := self userProfileProxy remotePerform: #objectNamed: with: sgmtName asSymbol.
	(sgmtSymbolProxy performOnGsServer: #notNil)
		ifTrue: 
			[(self gbsMessenger
				confirm: 'The name ''%1'' is not unique within this session!\Do you still wish to use this name?'
				with: sgmtName)
					ifFalse: [^'']].
	^nil
]

{ #category : 'actions-segment' }
GbxSegmentToolBrain >> changeOwnerAuthTo: ownerAuth forSgmt: selSgmtRec
[
	"Change the owner authorization for the given Object Security Policy to the given authorization."

	| sgmtProxy privs |
	selSgmtRec notNil
		ifTrue: 
			[sgmtProxy := selSgmtRec segmentHldr segmentProxy.
			privs := self userProfileProxy performOnGsServer: #privileges.
			((privs includes: #ObjectSecurityPolicyProtection)
				or: [(sgmtProxy remotePerform: #owner) performOnGsServer: #== withArguments: (Array with: self userProfileProxy)])
					ifTrue: 
						[(#(#read #write #none) includes: ownerAuth)
							ifTrue: 
								[sgmtProxy remotePerform: #ownerAuthorization: with: ownerAuth.
								^ownerAuth]
							ifFalse: 
								[self gbsMessenger warn: '''%1'' is not a valid authorization. Expected ''read'', ''write'', or ''none''!'
									with: ownerAuth]]
					ifFalse: 
						[self gbsMessenger warn: 'You do not have Object Security Policy Protection privilege!']].
	^nil
]

{ #category : 'actions-segment' }
GbxSegmentToolBrain >> changeOwnerTo: ownerName forSgmt: selSgmtRec
[
	"Change the owner for the given Object Security Policy to the user with the given name."

	| myOwnerName newOwnerProxy sgmtSgmtProxy sgmtProxy userProxy allUsrs usrProfHldr |
	myOwnerName := ownerName asString.	" may be a symbol from some widgets "
	selSgmtRec notNil
		ifTrue: 
			[sgmtProxy := selSgmtRec segmentHldr segmentProxy.
			sgmtSgmtProxy := sgmtProxy remotePerform: #objectSecurityPolicy.
			(sgmtSgmtProxy performOnGsServer: #currentUserCanWrite)
				ifTrue: 
					[allUsrs := (self session resolveSymbol: #AllUsers) remotePerform: #asArray.
					1 to: (allUsrs performOnGsServer: #size)
						do: 
							[:i |
							userProxy := allUsrs remotePerform: #at: with: i.
							(userProxy performOnGsServer: #userId) = myOwnerName ifTrue: [newOwnerProxy := userProxy]].
					(newOwnerProxy asGSObject performOnGsServer: #isNil)
						ifTrue: [self gbsMessenger warn: 'There is no user named ''%1'' in this GemStone session!' with: myOwnerName]
						ifFalse: 
							[self allUsers do: 
									[:hldr |
									(hldr remoteUserProfile asGSObject performOnGsServer: #== withArguments: (Array with: newOwnerProxy))
										ifTrue: [usrProfHldr := hldr]].

							"It is possible that this user profile has been added to AllUsers while the Segment Tool has been
			 up, so we need to create a GbxUserProfileHolder for it and update our allUsers snap shot."
							usrProfHldr isNil
								ifTrue: 
									[usrProfHldr := GbxUserProfileHolder on: newOwnerProxy asForwarder.
									self allUsers add: usrProfHldr].
							sgmtProxy remotePerform: #owner: with: newOwnerProxy.
							^myOwnerName]]
				ifFalse: 
					[self gbsMessenger
						warn: 'You do not have authorization to change the owner of object security policy ''%1''!'
						with: selSgmtRec segmentHldr segmentName]].
	^nil
]

{ #category : 'constants' }
GbxSegmentToolBrain >> addGroupSuggestion
[
	"workaround for bug #47128  P2  NoModificationError thrown while adding new group."

	^'NewGroup' copy
]

