
% command defines used in the PIC code
%  CMD_FLASH_LED     1
%  CMD_READ_SENSORS  2
%  CMD_STEP_X        3
%  CMD_STEP_Y        4
%  CMD_ENABLE_X      5  
%  CMD_ENABLE_Y      6


function XYMotorControlGUI
addpath('C:\BME4390\group 6, Ang, Tu\PICcode\XYScanner\XYScanner');
% load the dll-

if not(libisloaded('usbhidlib'))
    loadlibrary('usbhidlib');
end
%libfunctions('usbhidlib');  
% Create a figure and axes
f = figure('Visible','off');
f.MenuBar = 'none';
f.Name = 'XY Scanner';
f.NumberTitle = 'off';
axes('Units','pixels');

% get the screen size to resize the window
% this may need some further adjustment 
screensize = get(groot, 'Screensize');
width =  screensize(3)/3;  % set figure width to ~1/3 of the screen 
height = screensize(4)/2; % set figure height to 1/2 of the screen
x0 = (screensize(3)- width)/2; % center the window
y0 = (screensize(4) - height)/3; % center the window
% this is the image array
global image_array; 
global npixels; npixels = 128;
image_array = zeros(npixels, 'uint8');%by some weird Matlab logic this returns a n x n array
% make the background white
for y=1:npixels
    for x=1:npixels
    image_array(y,x) = 255;
    end
end
global hImage; 
hImage = image(image_array, 'CDataMapping','scaled');
caxis([0,255]) % change caxis
colormap(gray);
colorbar;
set(gcf,'units','pixels','position',[x0, y0, width, height])
set(gca,'units','pixels','position',[120, 40, 256, 256])

%define globals for number of motor steps, absolute x and y positions,etc
global nsteps; nsteps = 50;   % # motor steps to take in PIC for loop
global xpos; xpos = 0;        % cntr for number of steps in x
global ypos;  ypos = 0;       % cntr for number of steps in y
global Xmin; Xmin = 0;        % minimum xpos (these must be set to avoid jamming)
global Xmax;  Xmax = 0;       % maximum xpos 
global Ymin; Ymin = 0;        % minimum ypos
global Ymax;   Ymax = 0;      % maximum ypos
global mm_per_step; mm_per_step = 0.04;  %for displaying x and y in mm
global adc;   adc = 0;        % 255 - the ADC value
global numsteps; numsteps = 0;
global bStop; bStop = 0; 

% define the commands
global CMD_FLASH_LED; CMD_FLASH_LED = int8(1);
global CMD_READ_SENSORS; CMD_READ_SENSORS = int8(2);
global CMD_STEP_X; CMD_STEP_X = int8(3);
global CMD_STEP_Y; CMD_STEP_Y = int8(4);
global CMD_ENABLE_X; CMD_ENABLE_X = int8(5);  
global CMD_ENABLE_Y; CMD_ENABLE_Y= int8(6);

% Create push buttons and other controls

% Values for positioning the controls - may have to be customized 
% depending on your screen size
button_height = 20;  
yoffset = 5;
button_ypos_row1 = height - button_height;  % button position in Y
button_ypos_row2 = button_ypos_row1 - button_height - yoffset ; 
button_ypos_row3 = button_ypos_row2 - button_height - yoffset ;
button_ypos_row4 = button_ypos_row3 - button_height - yoffset ;
button_ypos_row5 = button_ypos_row4 - button_height - yoffset - 6 ;
button_xpos1 = 20;
button_xpos2 = 85;
button_xpos3 = 145;
button_xpos4 = 210;
button_xpos5 = 300;
button_xpos6 = 360;
button_xpos7 = 460;
button_xpos8 = 520;


% Top row - X controls 
global bEnableX;  bEnableX = 0;
uicontrol('Style','checkbox','String','Enable X', 'Position',...
         [button_xpos1-5 button_ypos_row1 70 button_height],...
          'Value', 0,'CallBack',@cbXBoxChanged);
      
uicontrol('Style', 'pushbutton', 'String', '<-X step',...
        'Position', [button_xpos2 button_ypos_row1 56 button_height],...
        'Callback', @BtnStepMotorXF);
    
uicontrol('Style', 'pushbutton', 'String', 'X step->',...
        'Position', [button_xpos3 button_ypos_row1 56 button_height],...
        'Callback', @BtnStepMotorXB);
    
global txtXPos; 
txtXPos = uicontrol('Style','text','Position',...
         [button_xpos4 button_ypos_row1-2 90 20],'String','X: 0');

uicontrol('Style', 'pushbutton', 'String', 'Set Xmin','Position',...
[button_xpos5 button_ypos_row1 56 button_height],'Callback', @SetMotorXMin);

global txtXMin; 
txtXMin = uicontrol('Style','text', 'Position',...
       [button_xpos6 button_ypos_row1-2 90 20],'String','Xmin: 0');
    
uicontrol('Style', 'pushbutton', 'String', 'Set Xmax','Position',...
[button_xpos7 button_ypos_row1 56 button_height],'Callback', @SetMotorXMax);

global txtXMax;  
txtXMax = uicontrol('Style','text', 'Position',...
       [button_xpos8 button_ypos_row1-2 90 20], 'String','Xmax: 0');
    
% second row - Y controls
global bEnableY;  bEnableY = 0;
uicontrol('Style','checkbox','String','Enable Y',...
          'Position',[button_xpos1-5 button_ypos_row2 70 button_height],...
          'Value', 0,'CallBack',@cbYBoxChanged);
      
uicontrol('Style', 'pushbutton', 'String', '<-Y step',...
        'Position', [button_xpos2 button_ypos_row2 56 button_height],...
        'Callback', @BtnStepMotorYF);
    
uicontrol('Style', 'pushbutton', 'String', 'Y step->',...
        'Position', [button_xpos3 button_ypos_row2 56 button_height],...
        'Callback', @BtnStepMotorYB); 

global txtYPos;
txtYPos = uicontrol('Style','text','Position',...
          [button_xpos4 button_ypos_row2-2 90 20],  'String','Y: 0');
    
uicontrol('Style', 'pushbutton', 'String', 'Set Ymin','Position',...
         [button_xpos5 button_ypos_row2 56 button_height],'Callback', @SetMotorYMin); 
 
global txtYMin;
txtYMin = uicontrol('Style','text',...
        'Position',[button_xpos6 button_ypos_row2-2 90 20],...
        'String','Ymin: 0');

uicontrol('Style', 'pushbutton', 'String', 'Set Ymax','Position',...
[button_xpos7 button_ypos_row2 56 button_height],'Callback', @SetMotorYMax);

global txtYMax;
txtYMax = uicontrol('Style','text',...
        'Position',[button_xpos8 button_ypos_row2 90 20],...
        'String','Ymax: 0');
    
% row 3 - sensor reading and scan button
% text control for display the sensor reading 
uicontrol('Style', 'pushbutton', 'String', 'Sensors',...
        'Position', [button_xpos1 button_ypos_row3 60 button_height],...
        'Callback', @ReadSensors);
   
 % edit box for number of stepper steps in the "for loop"
uicontrol('Style','text',...
        'Position',[button_xpos2 button_ypos_row3-2 60 20],...
        'String','#steps:');
    
global editNsteps; 
editNsteps = uicontrol('Style','edit',...
        'Position',[button_xpos3 button_ypos_row3 60 20],...
        'String', nsteps, 'Callback', @NstepsCallback);
    
% scan the motors and return what the sensor sees
global txtMM_step;
strMM = sprintf('%2.1f mm', mm_per_step * nsteps);
txtMM_step = uicontrol('Style','text',...
        'Position',[button_xpos4 button_ypos_row3-2 70 20],...
        'String',strMM);
 % set xpos to 0
uicontrol('Style', 'pushbutton', 'String', 'Set x=0',...
       'Position', [button_xpos5 button_ypos_row3 56 button_height],...
        'Callback', @SetMotorXZero);
 % set ypos to 0
uicontrol('Style', 'pushbutton', 'String', 'Set y=0',...
       'Position', [button_xpos7 button_ypos_row3 56 button_height],...
        'Callback', @SetMotorYZero);

% break
uicontrol('Style', 'pushbutton', 'String', 'break',...
       'Position', [button_xpos6 button_ypos_row4 56 button_height],...
        'Callback', @BtnBreak);

%flash LED
uicontrol('Style', 'pushbutton', 'String', 'Flash LED',...
       'Position', [(button_xpos8+5) button_ypos_row3 56 button_height],...
        'Callback', @FlashLED);
    
%save image
uicontrol('Style', 'pushbutton', 'String', 'Save Image',...
       'Position', [(button_xpos7) button_ypos_row4 63 button_height],...
        'Callback', @SaveImage);
    
% row 4 - position sensor reading 
% text control for display the sensor reading 
 
global txtSensorVal;
txtSensorVal = uicontrol('Style','text',...
        'Position',[button_xpos1 button_ypos_row4-2 60 20],...
        'String','QTR:0');    
global txtXStart;
txtXStart = uicontrol('Style','text',...
        'Position',[button_xpos2 button_ypos_row4-2 50 20],...
        'String','--');
    
global txtXEnd;
txtXEnd = uicontrol('Style','text',...
        'Position',[button_xpos3 button_ypos_row4-2 50 20],...
        'String','--');
    
global txtYStart;
txtYStart = uicontrol('Style','text',...
        'Position',[button_xpos4 button_ypos_row4-2 50 20],...
        'String','--');
    
global txtYEnd;
txtYEnd = uicontrol('Style','text',...
        'Position',[button_xpos5 button_ypos_row4-2 50 20],...
        'String','--');
   
uicontrol('Style', 'pushbutton', 'String', 'Show Limits',...
       'Position', [button_xpos1 button_ypos_row5 70 button_height/0.8],...
        'Callback', @ShowScanPrm);

global txtScanPrm; 
txtScanPrm = uicontrol('Style','text', 'HorizontalAlignment', 'left',...
        'Position',[button_xpos2+30 button_ypos_row5 300 20],...
        'String','');
  
uicontrol('Style', 'pushbutton', 'String', 'Scan',...
       'Position', [button_xpos7 button_ypos_row5 60 button_height/0.8],...
        'Callback', @Scan);
    
uicontrol('Style','text','Position',...
         [button_xpos8 button_ypos_row5-2 50 20],'String','#pixels');

global editNumPixels; 
editNumPixels =  uicontrol('Style','edit',...
        'Position',[button_xpos8+50 button_ypos_row5 40 20],...
        'String', npixels, 'Callback', @GetNumPixels);
     
f.Visible = 'on'; % Make figure visible after adding all components


% have the stage cover a bunch of x,y positions and
% read the QTR sensor value and build an image 
function Scan (~, ~)
    % check the user has set xmin, xmax etc
    if (Xmin >= Xmax || Ymin >= Ymax) 
       msgbox('Min-max values not properly set.');
       return; 
    end
    
    bStop = 0; 
    % move to the starting position
    MovetoXY(Xmin, Ymin); 
    ShowScanPrm;    % this calculates numsteps
   % loop over Y
   for yval = 1:npixels
     if bStop < 1 
       for xval = 1:npixels
         if(mod(yval,2))
             StepMotorX(numsteps, 1);
             image_array(yval, xval) = adc;
         else
             StepMotorX(numsteps, 0);
             image_array(yval, npixels +  1-xval) = adc;
         end
         set(hImage, 'CData', image_array);
      end
      StepMotorY(numsteps, 1);
    end
   end 
   MovetoXY(Xmin, Ymin);  % move back to the start point
end
  
% moves
 function MovetoXY(x,y)
 
   % move in X
   n = x - xpos;
   if n < 0 
       direction = 0;
   else
       direction = 1;
   end
   n = abs(n);
   if n < 255
      StepMotorX(n, direction);
   else
      nLoops = floor(n/255);
      nRemainder = mod(n, 255); 
      if nLoops > 0 
          for i = 1 : nLoops 
             StepMotorX(255, direction);
          end
          StepMotorX(nRemainder, direction);
      end
   end
   
  % move in Y
   n = y - ypos;
   if n < 0 
       direction = 0;
   else
       direction = 1;
   end
   n = abs(n);
   if n < 255
      StepMotorY(n, direction);
   else
      nLoops = floor(n/255);
      nRemainder = mod(n, 255); 
      if nLoops > 0 
          for i = 1 : nLoops 
             StepMotorY(255, direction);
          end
          StepMotorY(nRemainder, direction);
      end
   end
end
 
 
    
function ShowScanPrm(~,~)
  
    GetNumPixels;
    xsteps = ceil((Xmax - Xmin) / npixels);  % number of motor steps per pixel needed
    ysteps = ceil((Ymax - Ymin) / npixels);  % number of motor steps per pixel needed
    if(xsteps > ysteps) 
        numsteps = xsteps;
    else
        numsteps = ysteps;
    end
    
    if(numsteps > 255) 
       msgbox('> 255 steps for PIC loop: Too large of an area - reduce field of view');
       return
    end
    
    mm_per_pixel = numsteps * mm_per_step; 
    str = sprintf('%2.2f x %2.2f mm at %2.2f mm/pixel', mm_per_pixel * 64, mm_per_pixel * 64, mm_per_pixel);
    set(txtScanPrm, 'string', str);
end

function  GetNumPixels
        num = str2double(get(editNumPixels,'String'));
        if(num < 0)
            num = 64;
        elseif (num > 256)
            num = 256;
        end
        
        npixels = num;
end

function BtnStepMotorXF (~,~)
    NstepsCallback;
    StepMotorX(nsteps, 1);
end


function BtnStepMotorXB (~,~)
    NstepsCallback;
    StepMotorX(nsteps, 0);
end

function BtnStepMotorYF (~,~)
    NstepsCallback;
    StepMotorY(nsteps, 1);
end


function BtnStepMotorYB (~,~)
    NstepsCallback;
    StepMotorY(nsteps, 0);
end

function BtnBreak (~,~)
   bStop = 1;
    msgbox('Break Hit.');
end

function FlashLED (~,~)
    bOut = zeros(1,65,'uint8');
    pBuffer = libpointer('uint8Ptr',zeros(64,1));
    bOut(2) = CMD_FLASH_LED; 
    calllib('usbhidlib','hid_send_64bytes',1121, 4, bOut, pBuffer, 100, 10);
end

% steps forward (away from the motor body)
function StepMotorX (numsteps, direction)
    bOut = zeros(1,65,'uint8');
    pBuffer = libpointer('uint8Ptr',zeros(64,1));
    bOut(2) = CMD_STEP_X;     
    bOut(3) = direction;     % 1 sets direction to away from motor or forward
    bOut(4) = numsteps;  % number of 1.8 degree motor steps your firmware will carry out
    calllib('usbhidlib','hid_send_64bytes',1121, 4, bOut, pBuffer, 100, 10);
    y = pBuffer.Value;
    DisplaySensorValues (y(2), y(3), y(4), y(5), y(6));
    if direction == 1
        xpos = xpos + numsteps;
    else
        xpos = xpos - numsteps;
    end
    str = sprintf('X = %2.1f mm', mm_per_step * xpos); 
    set(txtXPos,'String',str);
    drawnow;
 end


% steps forward (away from the motor body)
function StepMotorY (numsteps, direction)
    bOut = zeros(1,65,'uint8');
    pBuffer = libpointer('uint8Ptr',zeros(64,1));
    bOut(2) = CMD_STEP_Y;     
    bOut(3) = direction;  % direction byte 
    bOut(4) = numsteps;
    calllib('usbhidlib','hid_send_64bytes',1121, 4, bOut, pBuffer, 100, 10);
    y = pBuffer.Value;
    DisplaySensorValues (y(2), y(3), y(4), y(5), y(6));
    if direction == 1
        ypos = ypos + numsteps;
    else
        ypos = ypos - numsteps;
    end
    str = sprintf('Y = %2.1f mm', mm_per_step * ypos); 
    set(txtYPos,'String',str);
    drawnow;
end

% edit control for setting the number of stepper
% steps to take in the PIC for loop code
function NstepsCallback (~, ~)
    num = str2double(get(editNsteps,'String'));
    if isnan(num)
         set(editNsteps,'String','20')
         nsteps = 20;
    else
        if num > 255
            num = 255;
            set(editNsteps,'String',num)
        end
        nsteps = num;
    end
end 

% Read the QTR and other sensors and post the values
% Command array returns all 5 values
function ReadSensors (~, ~)
    bOut(2)= 2;  % CMD_SENSORS = 2;  
    pBuffer = libpointer('uint8Ptr',zeros(64,1));
    calllib('usbhidlib','hid_send_64bytes',1121, 4, bOut, pBuffer, 100, 10);
    y = pBuffer.Value;
    DisplaySensorValues (y(2), y(3), y(4), y(5), y(6));
end

% Displays sensor data
function DisplaySensorValues (QTR_value, x1, x2, y1, y2)
    adc = 255 - QTR_value;
    str = sprintf('QTR:%d', adc); 
    set(txtSensorVal,'String',str);
    if x1 == 1 
      str = sprintf('XStart:1'); 
    else 
      str = sprintf('XStart:0');
    end
    set(txtXStart,'String',str);
   
    if x2 == 1 
      str = sprintf('XEnd:1'); 
    else 
      str = sprintf('XEnd:0');
    end
    set(txtXEnd,'String',str);
 
    if y1 == 1 
      str = sprintf('YStart:1'); 
    else 
      str = sprintf('YStart:0');
    end
    set(txtYStart,'String',str);
 
    if y2 == 1 
      str = sprintf('YEnd:1'); 
    else 
      str = sprintf('YEnd:0');
    end
    set(txtYEnd,'String',str);
 
end


% set the x zero
function SetMotorXZero (~,~)
  xpos = 0;
  str = sprintf('Xpos = %2.1f mm', ypos); 
  set(txtXPos,'String',str);
  drawnow;
end

% set the y zero
function SetMotorYZero (~,~)
  ypos = 0;
  str = sprintf('Ypos = %2.1f mm', ypos); 
  set(txtYPos,'String',str);
  drawnow;
end

% set the x min
function SetMotorXMin (~,~)
  Xmin = xpos;
  str = sprintf('%2.1f mm (%d)', mm_per_step * xpos, xpos);
  set(txtXMin, 'String', str);
end

% set the x max
function SetMotorXMax (~,~)
  Xmax = xpos;
  str = sprintf('%2.1f mm (%d)', mm_per_step * xpos, xpos);
  set(txtXMax, 'String', str);
end

% set the y min
function SetMotorYMin (~,~)
  Ymin = ypos;
  str = sprintf('%2.1f mm (%d)', mm_per_step * ypos, ypos);
  set(txtYMin, 'String', str);
end

% set the y max
function SetMotorYMax (~,~)
  Ymax = ypos;
  str = sprintf('%2.1f mm (%d)', mm_per_step * ypos, ypos);
  set(txtYMax, 'String', str);
end

% Turns the X motor on and off
function  cbXBoxChanged(~,~)
  bOut = zeros(1,65,'uint8');
  pBuffer = libpointer('uint8Ptr',zeros(64,1));
  bOut(2) = CMD_ENABLE_X;
  if bEnableX == 1
      bOut(3) = 0;
      bEnableX = 0;
  else
      bOut(3) = 1;
      bEnableX = 1;
  end
  calllib('usbhidlib','hid_send_64bytes',1121, 4, bOut, pBuffer, 100, 10);
end

% Turns the Y motor on and off
function  cbYBoxChanged(~,~)
  bOut = zeros(1,65,'uint8');
  pBuffer = libpointer('uint8Ptr',zeros(64,1));
  bOut(2) = CMD_ENABLE_Y;
  if bEnableY == 1
      bOut(3) = 0;
      bEnableY = 0;
  else
      bOut(3) = 1;
      bEnableY = 1;
  end
  calllib('usbhidlib','hid_send_64bytes',1121, 4, bOut, pBuffer, 100, 10);
end

function SaveImage(~,~)
    imwrite(image_array,'XYscan.png');      
    msgbox('Image saved.');
end


% main program end
end


