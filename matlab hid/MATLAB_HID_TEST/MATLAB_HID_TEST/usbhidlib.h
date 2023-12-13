/*******************************************************
 USBHIDLIB.h - header file for usbhidlib.cpp 
 
 This is an API wrapper for the SetupAPI.dll functions
 that talk to HID devices through the Windows supplied
 Hid.dll library (part of Windows).

 This C/C++ code is based on the code provided 
 by Alan Ott @ Signal 11 Software.  This version has changes 
 to make it Windows only (Alan's was cross-platfrom compatible) 
 and to modify things to remove warnings when compilied as 64 bit code.
 I've also added several function to more easily send data and 
 query the HID bus.
  
 Requires SetupAPI.lib (either or both 32 bit and 64 bit versions, depending 
 on the desired compile configuration).  These are located in 
 C:\Program Files (x86)\Microsoft SDKs\Windows\v7.0A\Lib  (32 bit)
 and
 C:\Program Files (x86)\Microsoft SDKs\Windows\v7.0A\Lib\x64 (64 bit)

 If complied as a DLL you can call the DLL from MatLab - here's some example m code:
  
	addpath('C:\MatLab_code');
	%Display functions in library.
	if not(libisloaded('usbhidlib'))
	 loadlibrary('usbhidlib');
	end
	libfunctions('usbhidlib');

	%create 2 empty arrays of BYTES (uint8 in MatLab)
	bOut = zeros(1,65,'uint8');
	bIn = zeros(1,65,'uint8');
	BufferSize = 64;
	pBuffer = libpointer('uint8Ptr',zeros(BufferSize,1));
	bOut(2)= 11;     % cmd  - index is 2, because MatLab arrays start at 1
		             % and the 1st element must have a value of 0 ascii for 
		             % the CCS HID code
	calllib('usbhidlib','hid_send_64bytes',1121, 4, bOut, pBuffer, 100, 10);
	y = pBuffer.Value;
	x = linspace(0,63,64);
	plot(x,y);
	unloadlibrary('usbhidlib');   % This unloads the dll when the program exits
								  % For developing the MatLab program, REM this
								  % out so it doesn't have to load the dll each
		                          % time the pregram runs (saves time). 
 
 Warren Zipfel 2014, 2015 Cornell University
********************************************************/
#pragma once
#include <Windows.h>
#include <wchar.h>
#include <SetupAPI.h>
      
// For MatLab use: put Hidclass.h and winapifamily.h in the directory that MatLab works 
// out of (use addpath('dir') to set it. The include for Hidclass.h is ""'d rather then 
// <>'d to allow the user to put it in the Matlab working directory along with winapifamily.h  
// confused.  Move a copy of Hidclass.h into the directory you're working out of in MatLab 
// and modify the line #include <winapifamily.h> in Hidclass.h to #include "winapifamily.h"
// so MatLab can find it.
// Alternatively, you can add the path (addpath()) that Hidclass and winapifamily live.
#include "Hidclass.h"                          

// Including SDKDDKVer.h defines the highest available Windows platform.
// If you wish to build your application for a previous Windows platform, include WinSDKVer.h and
// set the _WIN32_WINNT macro to the platform you wish to support before including SDKDDKVer.h.
#include <SDKDDKVer.h>

#define HID_API_EXPORT __declspec(dllexport)
#define HID_API_CALL
#define HID_API_EXPORT_CALL  HID_API_EXPORT HID_API_CALL  // API export and call macro

#ifdef __cplusplus
extern "C" {
#endif

	struct hid_device_;
	typedef struct hid_device_ hid_device; // opaque hidapi structure 
	struct hid_device_info {   	// hid info structure 
		char *path;  // device path
		unsigned short vendor_id;
		unsigned short product_id;
		char *serial_number;
		unsigned short release_number;  // Device Release or Version Number in binary-coded decimal 
		char *manufacturer_string;
		char *product_string;
		unsigned short usage_page;  // Usage Page for this Device/Interface
		unsigned short usage;  // The USB interface which this logical device represents if the device contains more than one interface. 
		int interface_number;
		struct hid_device_info *next;  	// Pointer to the next device 
	};

#ifndef HID_BUFFER_SIZE
  #define HID_BUFFER_SIZE        128
#endif

// Structure for getting info on the device passed 
//  Used by  int hid_get_device_info_all(int device_index, PHID_INFO phi);
#define INFO_STR_SIZE   64
typedef struct tagHID_INFO
{
	unsigned short vendor_id;
	unsigned short product_id;
	unsigned short version_num; 
	char szProductName[INFO_STR_SIZE];
	char szManufacturerName[INFO_STR_SIZE];
	char szSerialNum[INFO_STR_SIZE];
	int NumBytesInputToProcess;
	int NumBytesOutputToProcess;
} HID_INFO, *PHID_INFO;


/* I always work with a 64 bytes transfer and allocate
   128 bytes for the data transfer buffer to be safe.
   You do need at least 65 bytes since the first byte
   bOut[0] is the report id  -- usually just '\0' for me
   since I use the CCS PIC compiler and microchip processors
   which only allows 1 report (id = ascii 0).
*/
#define HID_BUFFER_SIZE   128

// some error codes
#define HID_NO_ERROR                   0 
#define HID_DEVICE_NOT_FOUND          -1
#define HID_READ_ERROR                -2
#define HID_WRITE_ERROR               -3
#define HID_RETURN_DATA_MISMATCH      -4
#define HID_ERROR_COLLECTING_HID_INFO -5

// Initializes the HIDAPI library. Calling it is not
// necessary, as it will be called automatically by hid_enumerate() 
// and any of the hid_open_*() functions if it is needed.  This function 
// should be called at the beginning of execution however, if there is a 
// chance that HID handles are being opened by different threads simultaneously.
int HID_API_EXPORT HID_API_CALL hid_init(void);

// Call at the end of execution to avoid memory leaks.
int HID_API_EXPORT HID_API_CALL hid_exit(void);

// Returns a linked list of all the HID devices	attached to the system which match vendor_id and product_id.
// If vendor_id and product_id are both set to 0, then all HID devices will be returned.
// Returns NULL in the case of failure. Free the  linked list by calling hid_free_enumeration().
struct hid_device_info HID_API_EXPORT * HID_API_CALL hid_enumerate(unsigned short vendor_id, unsigned short product_id);

// Frees a linked list created by hid_enumerate().
void  HID_API_EXPORT HID_API_CALL hid_free_enumeration(struct hid_device_info *devs);

// Opens a HID device using a Vendor ID (VID), Product ID (PID) and optionally a serial number.
// If serial_number is NULL, the first device with the specified VID and PID is opened.
HID_API_EXPORT hid_device * HID_API_CALL hid_open(unsigned short vendor_id, unsigned short product_id, char *serial_number);

// Opens a HID device by its pathname.	The pathname be determined by calling hid_enumerate(), or a
//	platform-specific path name can be used 
HID_API_EXPORT hid_device * HID_API_CALL hid_open_path(const char *path);

// Writes an Output report to a HID device. 	The first byte of the data[] must contain 
// the Report ID. For devices which only support a single report (e.g. CCS pic HID code)
// this must be set to 0x0.  The remaining bytes contain the report data. Since the Report ID is 
// mandatory, calls to hid_write() will alwayscontain one more byte than the report contains. 
// For example,	if a hid report is 16 bytes long, 17 bytes must be passed to hid_write(), 
// the Report ID (or 0x0, for devices with a single report), followed by the report data (16 bytes). 
// In this example, the length passed in would be 17. hid_write() will send the data on the first 
// OUT endpoint, if one exists. If it does not, it will send the data through the Control Endpoint (Endpoint 0).
// Returns the actual number of bytes written and -1 on error.
int  HID_API_EXPORT HID_API_CALL hid_write(hid_device *device, const unsigned char *data, size_t length);

// Reads an Input report from a HID device with timeout. Input reports are returned	to the host through the 
// INTERRUPT IN endpoint. The first byte will contain the Report number if the device uses numbered reports.
// device  = device handle returned from hid_open().
// data = buffer to put the read data into.
// length = number of bytes to read. For devices with multiple reports, make sure to read an extra byte for report number.
// milliseconds = timeout in milliseconds or -1 for blocking wait.
// Returns the actual number of bytes read and -1 on error.
int HID_API_EXPORT HID_API_CALL hid_read_timeout(hid_device *dev, unsigned char *data, size_t length, int milliseconds);

// Reads an Input report from a HID device.	Input reports are returned to the host through the INTERRUPT IN endpoint. 
// The first byte will contain the Report number if the device uses numbered reports.
// device = device handle returned from hid_open().
// data = buffer to put the read data into.
// length = number of bytes to read. For devices with multiple reports, make sure to read an extra byte for	the report number.
// Returns the actual number of bytes read and -1 on error.
int  HID_API_EXPORT HID_API_CALL hid_read(hid_device *device, unsigned char *data, size_t length);

//  Sets the device handle to be non-blocking.	In non-blocking mode calls to hid_read() will return
//	immediately with a value of 0 if there is no data to be	read. In blocking mode, hid_read() will 
//  wait (block) until there is data to read before returning.	Nonblocking can be turned on and off at any time.
// device = device handle returned from hid_open().
// nonblock = enable or not the nonblocking reads: - 1 to enable nonblocking,  0 to disable nonblocking.
// Returns 0 on success and -1 on error.
int  HID_API_EXPORT HID_API_CALL hid_set_nonblocking(hid_device *device, int nonblock);

// Sends a Feature report to the device. Feature reports are sent over the Control endpoint as a
// Set_Report transfer.  The first byte of @p data[] must contain the Report ID. For devices which only support a
// single report, this must be set to 0x0. The remaining bytes	contain the report data. Since the Report ID is mandatory,
// calls to hid_send_feature_report() will always contain one more byte than the report contains. For example, if a hid
// report is 16 bytes long, 17 bytes must be passed to hid_send_feature_report(): the Report ID (or 0x0, for
// devices which do not use numbered reports), followed by the report data (16 bytes) - i.e length passed is 17.
// device  = device handle returned from hid_open().
// data = buffer to put the read data into.
// length = number of bytes to read. For devices with multiple reports, make sure to read an extra byte for report number.
// Returns the actual number of bytes written and -1 on error.
int HID_API_EXPORT HID_API_CALL hid_send_feature_report(hid_device *device, const unsigned char *data, size_t length);

// Gets a feature report from a HID device.	Make sure to set the first byte of @p data[] to the Report
// ID of the report to be read.  Make sure to allow space for this extra byte in @p data[].
// device  = device handle returned from hid_open().
// data = buffer to put the read data into.
// length = number of bytes to read. For devices with multiple reports, make sure to read an extra byte for report number.
// Returns the number of bytes read and	-1 on error.
int HID_API_EXPORT HID_API_CALL hid_get_feature_report(hid_device *device, unsigned char *data, size_t length);

// Close a HID device.
// device = device handle returned from hid_open().
void HID_API_EXPORT HID_API_CALL hid_close(hid_device *device);

// Gets The Manufacturer String from a HID device.
// device = device handle returned from hid_open().
// string =  wide string buffer to put the data into.
// maxlen = length of the buffer in multiples of wchar_t.
// Returns 0 on success and -1 on error.
int HID_API_EXPORT_CALL hid_get_manufacturer_string(hid_device *device, char *string, size_t maxlen);

// Gets the Product String  from a HID device.
// device = device handle returned from hid_open().
// string =  wide string buffer to put the data into.
// maxlen = length of the buffer in multiples of wchar_t.
// Returns 0 on success and -1 on error. The from a HID device.
int HID_API_EXPORT_CALL hid_get_product_string(hid_device *device, char *string, size_t maxlen);

// Gets the Serial number string  from a HID device.
// device = device handle returned from hid_open().
// string =  wide string buffer to put the data into.
// maxlen = length of the buffer in multiples of wchar_t.
// Returns 0 on success and -1 on error. The from a HID device.
int HID_API_EXPORT_CALL hid_get_serial_number_string(hid_device *device, char *string, size_t maxlen);

// Gets a string from a HID device, based on its string index.
// device = device handle returned from hid_open().
// string_index = index of the string to get.
// string = wide string buffer to put the data into.
// maxlen = length of the buffer in multiples of wchar_t.
//Returns 0 on success and -1 on error.
int HID_API_EXPORT_CALL hid_get_indexed_string(hid_device *device, int string_index, char *string, size_t maxlen);

// Gets a string describing the last error which occurred.
// device = device handle returned from hid_open().
// Returns a string containing the last error which occurred or NULL if none has occurred.
HID_API_EXPORT const char* HID_API_CALL hid_error(hid_device *device);

//  The main function that need to be called from the outside - assumes a 64 byte transfer 
extern int __declspec(dllexport) __stdcall hid_send_64bytes(unsigned short vendor_id, unsigned short product_id, unsigned char *bOut, unsigned char *bIn, int time_out, int delay);

int HID_API_EXPORT HID_API_CALL hid_load_hid_info_struct(hid_device *dev, PHID_INFO phi);

int HID_API_EXPORT hid_num_devices(void); 

int HID_API_EXPORT  hid_get_device_info_all(int device_index, PHID_INFO phi);

#ifdef __cplusplus
}
#endif



