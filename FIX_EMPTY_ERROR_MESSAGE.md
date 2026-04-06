# Fix: Empty Error Message When Netldi Not Running

## Problem

When netldi is not running, the login error showed:
```
[GemStone Login Error]
  Stone: gs64stone
  User: DataCurator
  Error Number: 0
  Error Message: 
  Interpreted: 
```

The error message was empty because:
1. GCI's error buffer wasn't being populated when netldi is completely down
2. The `readString` method on ExternalAddress wasn't working correctly
3. Empty errors weren't being handled, resulting in blank messages

## Solution

### 1. Multiple Read Strategies

Created `readErrorMessageFrom:` method that tries 4 different approaches to read the error:

```smalltalk
"Strategy 1: Read bytes directly (most reliable)"
bytes := ByteArray new: 1024.
1 to: 1024 do: [ :i |
    bytes at: i put: (aBuffer + 112) byteAt: i - 1 ].
strEnd := bytes indexOf: 0.
strEnd > 1 ifTrue: [
    msg := (bytes copyFrom: 1 to: strEnd - 1) asString.
    msg trimBoth isEmpty ifFalse: [ ^ msg ] ]

"Strategy 2-4: Try readString at offsets 112, 113, 114"
```

### 2. Empty Error Handling

When error message is empty or nil, now shows helpful netldi message:

```smalltalk
"Handle nil or empty messages - likely netldi not running"
(aString isNil or: [ aString = '' or: [ aString = 'Unknown error' ] ]) ifTrue: [
    ^ self netldiErrorMessage ].
```

### 3. ByteArray Conversion

Properly handle ByteArray errors:

```smalltalk
(aString isKindOf: ByteArray) ifTrue: [
    "Convert ByteArray to String, stopping at null terminator"
    | nullPos |
    nullPos := aString indexOf: 0.
    nullPos > 0 
        ifTrue: [ (aString copyFrom: 1 to: nullPos - 1) asString ]
        ifFalse: [ aString asString ] ]
```

### 4. Dedicated Netldi Error Message

Created `netldiErrorMessage` method that provides clear instructions:

```smalltalk
GbsSessionParameters >> netldiErrorMessage
    ^ 'GemStone netldi daemon is not running or not accessible.

To fix this, start netldi on the GemStone server:

  startnetldi -a ', self gemStoneName, '

If netldi is already running, check:
• Stone name is correct: ', self gemStoneName, '
• Network connectivity to the GemStone server
• Firewall settings are not blocking the connection'
```

## What Users See Now

### In the Error Dialog

**Before:**
```
Connection Failed: Login failed: Message not understood
```

**After:**
```
Connection Failed: GemStone netldi daemon is not running or not accessible.

To fix this, start netldi on the GemStone server:

  startnetldi -a gs64stone

If netldi is already running, check:
• Stone name is correct: gs64stone
• Network connectivity to the GemStone server
• Firewall settings are not blocking the connection
```

### In the Transcript

**Before:**
```
[GemStone Login Error]
  Stone: gs64stone
  User: DataCurator
  Error Number: 0
  Error Message: 
  Interpreted: 
```

**After:**
```
[GemStone Login Error]
  Stone: gs64stone
  User: DataCurator
  Error Number: 0
  Error Message: (empty)
  Interpreted: GemStone netldi daemon is not running or not accessible.

To fix this, start netldi on the GemStone server:

  startnetldi -a gs64stone

If netldi is already running, check:
• Stone name is correct: gs64stone
• Network connectivity to the GemStone server
• Firewall settings are not blocking the connection
```

## Files Modified

**GbsSessionParameters.class.st**
- Modified `handleLoginError:` to use new reading strategy
- Added `readErrorMessageFrom:` - tries 4 strategies to read error
- Added `netldiErrorMessage` - dedicated helpful message
- Modified `interpretErrorMessage:errorNumber:` to handle empty/nil
- Modified ByteArray conversion to handle null terminators

## Testing

1. **Stop netldi** (or don't start it)
2. **Try to login** in GbsLauncher
3. **Expected:** Clear message with `startnetldi -a gs64stone` command
4. **Check Transcript:** Should show detailed diagnostic

## Benefits

- ✅ No more empty error messages
- ✅ Clear instructions on how to start netldi
- ✅ Multiple strategies to read error messages (more reliable)
- ✅ Proper ByteArray to String conversion
- ✅ Helpful fallback when GCI provides no error details
- ✅ Shows stone name in the startnetldi command

---

**Date:** April 5, 2026
**Bug Fixed:** Empty error messages when netldi is not running
**Feature Added:** Dedicated netldi error message with startnetldi command
