// This demonstrates how to open a VM, power it on and power it off.
//
// This uses the VixJob_Wait function to block after starting each
// asynchronous function. This effectively makes the asynchronous
// functions synchronous, because VixJob_Wait will not return until the
// asynchronous function has completed.
//

#include "stdafx.h"
#include "windows.h"
#include <iostream>

#include "vix.h"
using namespace std;

VixHandle hostHandle = VIX_INVALID_HANDLE;


////////////////////////////////////////////////////////////////////////////////
int _tmain(int argc, _TCHAR* argv[])
{
    VixError err = VIX_OK;
    VixHandle jobHandle = VIX_INVALID_HANDLE;
    VixHandle vmHandle = VIX_INVALID_HANDLE;
cout << "0" << endl;
    jobHandle = VixHost_Connect(1,
                                VIX_SERVICEPROVIDER_VMWARE_SERVER,
								NULL, // *hostName,
                                NULL, // hostPort,
                                NULL, // *userName,
                                NULL, // *password,
                                0, // options,
                                VIX_INVALID_HANDLE, // propertyListHandle,
                                NULL, // *callbackProc,
                                NULL); // *clientData);
	cout << "1" << endl;
    err = VixJob_Wait(jobHandle, 
                      VIX_PROPERTY_JOB_RESULT_HANDLE, 
                      &hostHandle,
                      VIX_PROPERTY_NONE);
	cout << "2" << endl;
    if (VIX_OK != err) {
		cout << "err: " << (int)err << endl;
        goto abort;
    }
cout << "3" << endl;
    Vix_ReleaseHandle(jobHandle);
    jobHandle = VixVM_Open(hostHandle,
                           "D:\\virtual_machine\\new_win_xp\\winXPPro.vmx",
                           NULL, // VixEventProc *callbackProc,
                           NULL); // void *clientData);
	cout << "4" << endl;
    err = VixJob_Wait(jobHandle, 
                      VIX_PROPERTY_JOB_RESULT_HANDLE, 
                      &vmHandle,
                      VIX_PROPERTY_NONE);
	cout << "5" << endl;
    if (VIX_OK != err) {
        goto abort;
    }
cout << "6" << endl;
    Vix_ReleaseHandle(jobHandle);
    jobHandle = VixVM_PowerOn(vmHandle,
                              VIX_VMPOWEROP_NORMAL,
                              VIX_INVALID_HANDLE,
                              NULL, // *callbackProc,
                              NULL); // *clientData);
	cout << "7" << endl;
    err = VixJob_Wait(jobHandle, VIX_PROPERTY_NONE);
	cout << "8" << endl;
    if (VIX_OK != err) {
        goto abort;
    }
cout << "9" << endl;
    Vix_ReleaseHandle(jobHandle);



/**********************************************************************************************************************/

// Wait until guest is completely booted.
	jobHandle = VixVM_WaitForToolsInGuest(vmHandle,
								300, // timeoutInSeconds
								NULL, // callbackProc,
								NULL); // clientData
	err = VixJob_Wait(jobHandle, VIX_PROPERTY_NONE);
	if (VIX_OK != err) {
		// Handle the error...
		goto abort;
	}
	// Release the job handle because we no longer need it.
	Vix_ReleaseHandle(jobHandle);
	// Authenticate for guest operations.
	jobHandle = VixVM_LoginInGuest(vmHandle,
							"vixuser", // userName
							"secret", // password
							0, // options
							NULL, // callbackProc
							NULL); // clientData
	err = VixJob_Wait(jobHandle, VIX_PROPERTY_NONE);
	if (VIX_OK != err) {
	// Handle the error...
	goto abort;
	}
	// Release the job handle because we no longer need it.
	Vix_ReleaseHandle(jobHandle);
	// Copy a file.
	jobHandle = VixVM_CopyFileFromHostToGuest(vmHandle,
								"c:\\hostDir\\helloworld.c", // src name
								"c:\\guestDir\\helloworld.c", // dest name
								0, // options
								VIX_INVALID_HANDLE, // propertyList
								NULL, // callbackProc
								NULL); // clientData
	err = VixJob_Wait(jobHandle, VIX_PROPERTY_NONE);
	if (VIX_OK != err) {
	// Handle the error...
	goto abort;
	}
	Vix_ReleaseHandle(jobHandle);

/**********************************************************************************************************************/

    jobHandle = VixVM_PowerOff(vmHandle,
                               VIX_VMPOWEROP_NORMAL,
                               NULL, // *callbackProc,
                               NULL); // *clientData);
	cout << "10" << endl;
    err = VixJob_Wait(jobHandle, VIX_PROPERTY_NONE);
	cout << "11" << endl;
    if (VIX_OK != err) {
        goto abort;
    }
cout << "12" << endl;
    VixHost_Disconnect(hostHandle);
    goto done;

	int y;
	cin >> y; 

abort:
	return 0;

done:
    Vix_ReleaseHandle(jobHandle);
    Vix_ReleaseHandle(vmHandle);
}