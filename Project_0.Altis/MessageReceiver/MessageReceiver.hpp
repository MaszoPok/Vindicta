// Include this after OOP_Light.h !

#define OWNER_CHANGE_ACK(_ID) "ownerChangeAck_"+(str _ID)

// Timeout in seconds, how long we want for an ACK from the remote machine when changing owner
#define OWNER_CHANGE_ACK_TIMEOUT 2

#define MESSAGE_ID_INVALID -66.6

// Macro to ensure it is being called in proper thread
#ifdef OOP_ASSERT
#define ASSERT_THREAD(objNameStr) 0 try \
{ \
private _properThread = GETV(CALLM0(objNameStr, "getMessageLoop"), "scriptHandle") isEqualTo _thisScript; \
private _msg = format ["method is called in wrong thread. File: %1, line: %2", __FILE__, __LINE__]; \
ASSERT_MSG(_properThread, _msg); } catch { \
terminate _thisScript; \
}
#else
#define ASSERT_THREAD(objNameStr)
#endif