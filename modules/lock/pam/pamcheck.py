#!/usr/bin/env python3
# Runs pam_authenticate for the current user against /etc/pam.d/<service> and prints the raw PAM code.
# Uses only the system libpam through ctypes (nothing to install). The password is typed locally, never stored.
import ctypes, ctypes.util, getpass, sys
from ctypes import c_int, c_void_p, c_char_p, POINTER, Structure, CFUNCTYPE, byref, cast, sizeof

pam = ctypes.CDLL(ctypes.util.find_library("pam"))
libc = ctypes.CDLL(ctypes.util.find_library("c"))
libc.calloc.restype = c_void_p
libc.strdup.restype = c_void_p

class Msg(Structure): _fields_ = [("style", c_int), ("msg", c_char_p)]
class Resp(Structure): _fields_ = [("resp", c_void_p), ("retcode", c_int)]
CONV = CFUNCTYPE(c_int, c_int, POINTER(POINTER(Msg)), POINTER(POINTER(Resp)), c_void_p)
class Conv(Structure): _fields_ = [("conv", CONV), ("data", c_void_p)]

pam.pam_strerror.restype = c_char_p
pw = getpass.getpass("Password: ").encode()

def talk(n, msgs, resp, _):
    arr = libc.calloc(n, sizeof(Resp))
    resp[0] = cast(arr, POINTER(Resp))
    for i in range(n):
        style, text = msgs[i][0].style, msgs[i][0].msg
        print(f"   pam message style={style}: {text.decode(errors='replace') if text else ''}")
        if style in (1, 2):  # PAM_PROMPT_ECHO_OFF / ON: give the password
            resp[0][i].resp = libc.strdup(pw)
    return 0

keep = CONV(talk)  # must stay referenced
names = {0: "PAM_SUCCESS", 4: "PAM_SYSTEM_ERR", 6: "PAM_PERM_DENIED", 7: "PAM_AUTH_ERR",
         9: "PAM_AUTHINFO_UNAVAIL", 10: "PAM_USER_UNKNOWN", 11: "PAM_MAXTRIES", 13: "PAM_ACCT_EXPIRED"}
for service in sys.argv[1:] or ["login", "system-auth"]:
    h = c_void_p()
    conv = Conv(keep, None)
    rc = pam.pam_start(service.encode(), getpass.getuser().encode(), byref(conv), byref(h))
    if rc:
        print(f"{service}: pam_start failed {rc}"); continue
    rc = pam.pam_authenticate(h, 0)
    print(f"{service}: pam_authenticate = {rc} {names.get(rc, '')} ({pam.pam_strerror(h, rc).decode()})")
    pam.pam_end(h, rc)
