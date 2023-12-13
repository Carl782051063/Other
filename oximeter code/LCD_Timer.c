// LCD_Timer.c
// Tests 2 x 26 char LCD code
#include <18F2455.h>
#include <stdlib.h>
#include <math.h>
#fuses HSPLL,NOWDT,NOPROTECT,NOLVP,NODEBUG,USBDIV,PLL5,CPUDIV1,VREGEN, MCLR
#use delay(clock=48000000)

#define LCD_E         PIN_A1                                    ////
#define LCD_RS        PIN_A2                                    ////
#define LCD_DB4       PIN_B0                                    ////
#define LCD_DB5       PIN_B1                                    ////
#define LCD_DB6       PIN_B2                                    ////
#define LCD_DB7       PIN_B3 

#include <Flex_lcd.c>

/////////////////////////////////////////////////////////////////////////////
//In usb.c/h - tells the CCS PIC USB firmware to include HID handling code.
//#DEFINE USB_HID_DEVICE  TRUE

//the following defines needed for the CCS USB PIC driver to enable the TX endpoint 1
// and allocate buffer space on the peripheral
//#define USB_EP1_TX_ENABLE  USB_ENABLE_INTERRUPT   //turn on EP1 for IN bulk/interrupt transfers
//#define USB_EP1_TX_SIZE    54  //allocate 50 bytes in the hardware for transmission   

//the following defines needed for the CCS USB PIC driver to enable the RX endpoint 1
// and allocate buffer space on the peripheral
//#define USB_EP1_RX_ENABLE  USB_ENABLE_INTERRUPT   //turn on EP1 for OUT bulk/interrupt transfers
//#define USB_EP1_RX_SIZE    54  //allocate 50 bytes in the hardware for reception   

//#include <pic18_usb.h>      //Microchip 18Fxx5x hardware layer for usb.c
//#include <4ChannelController_desc_54.h>   //USB Configuration and Device descriptors for this USB device
//#include <usb.c>            //handles usb setup tokens and get descriptor reports


void main(void) {
      
      lcd_init();          // Always call this first to set up the LCD. 
      lcd_putc("\fHello World");  // since this is a static string lcd_putc works with having to loop over the chars
      delay_ms(1000);
      
      // init variables here
      
      while (TRUE) {
      // loop over time writing to the LCD...   
          
          }
}

