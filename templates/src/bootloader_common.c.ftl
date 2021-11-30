/*******************************************************************************
  Bootloader Common Source File

  File Name:
    bootloader_common.c

  Summary:
    This file contains common definitions and functions.

  Description:
    This file contains common definitions and functions.
 *******************************************************************************/

// DOM-IGNORE-BEGIN
/*******************************************************************************
* Copyright (C) 2019 Microchip Technology Inc. and its subsidiaries.
*
* Subject to your compliance with these terms, you may use Microchip software
* and any derivatives exclusively with Microchip products. It is your
* responsibility to comply with third party license terms applicable to your
* use of third party software (including open source software) that may
* accompany Microchip software.
*
* THIS SOFTWARE IS SUPPLIED BY MICROCHIP "AS IS". NO WARRANTIES, WHETHER
* EXPRESS, IMPLIED OR STATUTORY, APPLY TO THIS SOFTWARE, INCLUDING ANY IMPLIED
* WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY, AND FITNESS FOR A
* PARTICULAR PURPOSE.
*
* IN NO EVENT WILL MICROCHIP BE LIABLE FOR ANY INDIRECT, SPECIAL, PUNITIVE,
* INCIDENTAL OR CONSEQUENTIAL LOSS, DAMAGE, COST OR EXPENSE OF ANY KIND
* WHATSOEVER RELATED TO THE SOFTWARE, HOWEVER CAUSED, EVEN IF MICROCHIP HAS
* BEEN ADVISED OF THE POSSIBILITY OR THE DAMAGES ARE FORESEEABLE. TO THE
* FULLEST EXTENT ALLOWED BY LAW, MICROCHIP'S TOTAL LIABILITY ON ALL CLAIMS IN
* ANY WAY RELATED TO THIS SOFTWARE WILL NOT EXCEED THE AMOUNT OF FEES, IF ANY,
* THAT YOU HAVE PAID DIRECTLY TO MICROCHIP FOR THIS SOFTWARE.
 *******************************************************************************/
// DOM-IGNORE-END

// *****************************************************************************
// *****************************************************************************
// Section: Include Files
// *****************************************************************************
// *****************************************************************************

#include "bootloader_common.h"

// *****************************************************************************
// *****************************************************************************
// Section: Type Definitions
// *****************************************************************************
// *****************************************************************************

// *****************************************************************************
// *****************************************************************************
// Section: Global objects
// *****************************************************************************
// *****************************************************************************


// *****************************************************************************
// *****************************************************************************
// Section: Bootloader Local Functions
// *****************************************************************************
// *****************************************************************************


// *****************************************************************************
// *****************************************************************************
// Section: Bootloader Global Functions
// *****************************************************************************
// *****************************************************************************


bool __WEAK bootloader_Trigger(void)
{
    /* Function can be overriden with custom implementation */
    return false;
}

void __WEAK SYS_DeInitialize( void *data )
{
    /* Function can be overriden with custom implementation */
}

<#if BTL_WDOG_ENABLE?? &&  BTL_WDOG_ENABLE == true>
void kickdog(void)
{
    if (WDT_IsEnabled())
    {
        WDT_Clear();
    }
}
</#if>


<#if BTL_HW_CRC_GEN?? && BTL_HW_CRC_GEN == true>
    <#lt>/* Function to Generate CRC using the device service unit peripheral on programmed data */
    <#lt>uint32_t bootloader_CRCGenerate(uint32_t start_addr, uint32_t size)
    <#lt>{
    <#lt>    uint32_t crc  = 0xffffffff;

    <#lt>    PAC_PeripheralProtectSetup (PAC_PERIPHERAL_DSU, PAC_PROTECTION_CLEAR);

    <#if BTL_WDOG_ENABLE?? &&  BTL_WDOG_ENABLE == true>
        <#lt>    uint32_t i;

        <#lt>    for (i = 0; i < size; i += ERASE_BLOCK_SIZE)
        <#lt>    {
        <#lt>       DSU_CRCCalculate (
        <#lt>           start_addr + i,
        <#lt>           ERASE_BLOCK_SIZE,
        <#lt>           crc,
        <#lt>           &crc
        <#lt>       );

        <#lt>       kickdog();
        <#lt>    }
    <#else>
        <#lt>    DSU_CRCCalculate (start_addr, size, crc, &crc);
    </#if>

    <#lt>    PAC_PeripheralProtectSetup (PAC_PERIPHERAL_DSU, PAC_PROTECTION_SET);

    <#lt>    return crc;
    <#lt>}
<#else>
    <#lt>/* Function to Generate CRC by reading the firmware programmed into internal flash */
    <#lt>uint32_t bootloader_CRCGenerate(uint32_t start_addr, uint32_t size)
    <#lt>{
    <#lt>    uint32_t   i, j, value;
    <#lt>    uint32_t   crc_tab[256];
    <#lt>    uint32_t   crc = 0xffffffff;
    <#lt>    uint8_t    data;

    <#lt>    for (i = 0; i < 256; i++)
    <#lt>    {
    <#lt>        value = i;

    <#lt>        for (j = 0; j < 8; j++)
    <#lt>        {
    <#lt>            if (value & 1)
    <#lt>            {
    <#lt>                value = (value >> 1) ^ 0xEDB88320;
    <#lt>            }
    <#lt>            else
    <#lt>            {
    <#lt>                value >>= 1;
    <#lt>            }
    <#lt>        }
    <#lt>        crc_tab[i] = value;
    <#lt>    }

    <#lt>    for (i = 0; i < size; i++)
    <#lt>    {
    <#if __PROCESSOR?matches("PIC32M.*") == false>
    <#lt>        data = *(uint8_t *)(start_addr + i);
    <#else>
    <#lt>        data = *(uint8_t *)KVA0_TO_KVA1((start_addr + i));
    </#if>
    <#lt>
    <#lt>        crc = crc_tab[(crc ^ data) & 0xff] ^ (crc >> 8);
    <#lt>    }
    <#lt>    return crc;
    <#lt>}
</#if>

<#if __PROCESSOR?matches("PIC32M.*") == false>
    <#lt>/* Trigger a reset */
    <#lt>void bootloader_TriggerReset(void)
    <#lt>{
    <#lt>    NVIC_SystemReset();
    <#lt>}

    <#lt>void run_Application(void)
    <#lt>{
    <#lt>    uint32_t msp            = *(uint32_t *)(APP_START_ADDRESS);
    <#lt>    uint32_t reset_vector   = *(uint32_t *)(APP_START_ADDRESS + 4);

    <#lt>    if (msp == 0xffffffff)
    <#lt>    {
    <#lt>        return;
    <#lt>    }

    <#lt>    /* Call Deinitialize routine to free any resources acquired by Bootloader */
    <#lt>    SYS_DeInitialize(NULL);

    <#lt>    __set_MSP(msp);

    <#lt>    asm("bx %0"::"r" (reset_vector));
    <#lt>}
<#else>
    <#lt>/* Trigger a reset */
    <#lt>void bootloader_TriggerReset(void)
    <#lt>{
    <#lt>    /* Perform system unlock sequence */
    <#lt>    SYSKEY = 0x00000000;
    <#lt>    SYSKEY = 0xAA996655;
    <#lt>    SYSKEY = 0x556699AA;

    <#lt>    RSWRSTSET = _RSWRST_SWRST_MASK;
    <#lt>    (void)RSWRST;
    <#lt>}

    <#lt>void run_Application(void)
    <#lt>{
    <#lt>    uint32_t msp            = *(uint32_t *)(APP_START_ADDRESS);

    <#lt>    void (*fptr)(void);

    <#lt>    /* Set default to APP_RESET_ADDRESS */
    <#lt>    fptr = (void (*)(void))APP_START_ADDRESS;

    <#lt>    if (msp == 0xffffffff)
    <#lt>    {
    <#lt>        return;
    <#lt>    }

    <#lt>    fptr();
    <#lt>}
</#if>

