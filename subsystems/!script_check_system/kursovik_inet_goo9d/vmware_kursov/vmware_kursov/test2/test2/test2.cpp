/* *********************************************************************
 * Copyright (c) 2006 VMware, Inc.
 * All rights not expressly granted to you by VMware, Inc. are reserved.
 * *********************************************************************/

/* This demonstrates how to open a virtual machine,
 * power it on, and power it off.
 *
 * This uses the VixJob_Wait function to block after starting each
 * asynchronous function. This effectively makes the asynchronous
 * functions synchronous, because VixJob_Wait will not return until the
 * asynchronous function has completed.
 */
#include <stdio.h>
#include <tchar.h>
//#include "stdafx.h"
#include "windows.h"




////////////////////////////////////////////////////////////////////////////////
int _tmain(int argc, _TCHAR* argv[])
{
	printf("Hello");getchar();
	return 1;
}

