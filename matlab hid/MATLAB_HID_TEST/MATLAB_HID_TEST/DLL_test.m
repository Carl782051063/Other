%addpath('C:\..etc..');

% Display functions in library.
if not(libisloaded('usbhidlib'))
    loadlibrary('usbhidlib');
end
libfunctions('usbhidlib');

% NOTE: you can ignore the warning:
% "Warning: The data type 'hid_device_infoPtr' used by structure 
% hid_device_info does not exist." -- this is not true or a problem.
% (MatLab is easily confused by C code.)

% create an array of BYTES (uint8 in MatLab)
bOut = zeros(1,65,'uint8');
bIn = zeros(1,65,'uint8');
BufferSize = 64;
% Get a pointer to a BYTE array which you will use to see the return values 
pBuffer = libpointer('uint8Ptr',zeros(BufferSize,1));

% HID command defines
% Send 1 to flash the LED
% Send 2 to file the array with 0-63 and return


bOut(2)= 1;     % cmd  - index is 2, because MatLab arrays start at 1
                 % and the 1st element must have a value of 0 ascii for 
                 % the CCS HID code.   Put whatever command you want to
                 % send here.  You can also send additional info such 
                 % as the delay time or channel number as sequential
                 % bytes -- i.e bOut(3) = 100   (a delay)
calllib('usbhidlib','hid_send_64bytes',1121, 4, bOut, pBuffer, 100, 10);

y = pBuffer.Value;
x = linspace(0,63,64);
plot(x,y);

%unloadlibrary('usbhidlib');  % This unloads the dll when the program exits
                              % For developing the MatLab program, REM this
                              % out so it doesn't have to load the dll each
                              % time the pregram runs (saves time). 
