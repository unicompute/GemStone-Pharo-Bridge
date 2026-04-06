# Quick Reference: Netldi Error Handling

## What Changed

Two login methods were enhanced to provide better error messages when netldi is not running:

1. **GbsSessionParameters >> login** - Used by the simple launcher UI
2. **GbsSession >> loginStone:user:password:** - Used by programmatic login

## New Error Messages

### When Netldi Is NOT Running

**Before:**
```
Login Failed
```

**After:**
```
Cannot connect to GemStone netldi daemon. Please ensure netldi is running on the GemStone server.

Original error: connection refused
```

### When Stone Doesn't Exist

**Before:**
```
Login Failed
```

**After:**
```
Cannot find the GemStone stone 'my_stone'. Please check that the stone exists and netldi is running.

Original error: no such stn: my_stone
```

## How to Test

### Quick Test in Pharo Playground

```smalltalk
"Test error interpretation"
| params |
params := GbsSessionParameters new.

"Test with netldi error pattern"
params interpretErrorMessage: 'connection refused' errorNumber: 1234.
```

### Test Actual Login

```smalltalk
"Will show improved error message if netldi is not running"
| params |
params := GbsSessionParameters new
    gemStoneName: 'gs64stone';
    username: 'DataCurator';
    password: 'swordfish';
    yourself.

[ params login ] on: Error do: [ :ex |
    Transcript show: ex messageText; cr ].
```

## Files Modified

1. `/Users/tariq/src/gemtools/GemStone-Pharo-Bridge/src/GemStone-GBS-Converted/GbsSessionParameters.class.st`
   - Modified: `login` method
   - Added: `handleLoginError:` method
   - Added: `interpretErrorMessage:errorNumber:` method

2. `/Users/tariq/src/gemtools/GemStone-Pharo-Bridge/src/GemStone-GBS-Converted/GbsSession.class.st`
   - Modified: `loginStone:user:password:` method
   - Added: `interpretLoginError:` method
   - Added: `interpretErrorMessage:errorNumber:` method

## Netldi Commands

### Start netldi
```bash
startnetldi -a gs64stone
```

### Check netldi status
```bash
ps aux | grep netldi
```

### Start the stone
```bash
startstone gs64stone
```

### Check stone status
```bash
stone status gs64stone
```

## Error Patterns Detected

The code now detects and explains:
- ✅ `connection refused` - netldi not running
- ✅ `no such stn/stone` - stone doesn't exist
- ✅ `netldi` - netldi not accessible
- ✅ `gemnetobject` - service not running
- ✅ `login denied/disabled` - authentication issues
- ✅ `shutdown` - stone is shutting down
- ✅ `timeout` - network connectivity issues

## What to Tell Users

When users report connection errors, they should now see:
1. A clear explanation of what went wrong
2. Specific guidance on how to fix it
3. The original error message for debugging

No more generic "Login Failed" messages!

---

**See Also:** `NETLDI_ERROR_HANDLING.md` for complete documentation
