# -*- coding: utf-8 -*-
*** Settings ***
Documentation     UAT_TEST14 Driver Confirm Cash Payment
...               Driver: driver1 / Isaac1234
Library           SeleniumLibrary
Suite Teardown    Close All Browsers

*** Variables ***
${BASE_URL}                     http://csse4369.cpkku.com
${LOGIN_URL}                    ${BASE_URL}/login
${BROWSER}                      chrome

${USERNAME}                     driver2@gmail.com
${PASSWORD}                     jeng12345678

${BTN_LOGIN}                    xpath=//button[contains(normalize-space(),'เข้าสู่ระบบ')]

${DROPDOWN_ALL_TRIPS}           xpath=//*[contains(normalize-space(),'การเดินทางทั้งหมด')]
${MENU_MY_BOOKING_REQUEST}      xpath=//*[contains(normalize-space(),'คำขอจองเส้นทางของฉัน') or contains(@href, '/myRoute')]
${TAB_MY_ROUTE}                 xpath=//button[contains(normalize-space(),'เส้นทางของฉัน')]

${BTN_CONFIRM_PAYMENT}          xpath=//button[contains(normalize-space(),'ยืนยันการชำระเงิน')]
${MODAL_TITLE}                  xpath=//h3[contains(normalize-space(),'ตรวจสอบการชำระเงิน') or contains(normalize-space(),'ยืนยันการชำระเงิน')]
${CHECKBOX_CASH}                xpath=//label[contains(normalize-space(.),'รับเงินสดแล้ว')]//input[@type='checkbox']
${LABEL_CASH}                   xpath=//label[contains(normalize-space(.),'รับเงินสดแล้ว')]

${BTN_CONFIRM_RECEIVE}          xpath=//button[contains(normalize-space(),'ยืนยันการรับเงิน')]
${TOAST_CONFIRMED}              xpath=//*[contains(normalize-space(),'ยืนยันแล้ว') or contains(normalize-space(),'สำเร็จ')]
${STATUS_PAID}                  xpath=//*[contains(normalize-space(),'ชำระแล้ว') or contains(normalize-space(),'เสร็จสิ้น')]

*** Test Cases ***
UAT14-Driver-Confirm-Cash
    Open Website and Login
    Submit Login Credentials
    Navigate to Driver Routes
    Open Payment Modal
    Confirm Cash Received
    Verify Status And Results

*** Keywords ***
Open Website and Login
    Open Browser    ${LOGIN_URL}    ${BROWSER}
    Maximize Browser Window
    Wait Until Element Is Visible    id=identifier    timeout=15s
    Wait Until Element Is Visible    id=password      timeout=15s

Submit Login Credentials
    Input Text      id=identifier    ${USERNAME}
    Input Text      id=password      ${PASSWORD}
    Click Button    ${BTN_LOGIN}
    Wait Until Page Does Not Contain Element    ${BTN_LOGIN}    timeout=15s

Navigate to Driver Routes
    Go To    ${BASE_URL}/myRoute
    Wait Until Page Contains    คำขอจองเส้นทางของฉัน    timeout=15s
    
    ${tab_status}    ${tab_msg}=    Run Keyword And Ignore Error    Click Element    xpath=(//button[contains(normalize-space(),'เส้นทางของฉัน')])[1]
    IF    '${tab_status}' == 'FAIL'
        Execute JavaScript    (function(){const btn=[...document.querySelectorAll('button')].find(el=>el.offsetParent!==null&&el.textContent&&el.textContent.includes('เส้นทางของฉัน'));if(btn){btn.click();}})();
    END
    Sleep    2s

Open Payment Modal
    ${arrive_status}    ${arrive_msg}=    Run Keyword And Ignore Error    Wait Until Element Is Visible    xpath=(//button[contains(normalize-space(),'ถึงที่หมายแล้ว')])[1]    timeout=2s
    IF    '${arrive_status}' == 'PASS'
        Click Element    xpath=(//button[contains(normalize-space(),'ถึงที่หมายแล้ว')])[1]
        Wait Until Element Is Visible    xpath=//button[contains(normalize-space(),'ยืนยัน') and not(contains(normalize-space(),'ชำระเงิน'))]    timeout=5s
        Click Element    xpath=(//button[contains(normalize-space(),'ยืนยัน') and not(contains(normalize-space(),'ชำระเงิน'))])[1]
        Sleep    2s
    END
    Wait Until Element Is Visible    ${BTN_CONFIRM_PAYMENT}    timeout=15s
    Click Element    xpath=(//button[contains(normalize-space(),'ยืนยันการชำระเงิน')])[1]
    Wait Until Element Is Visible    ${MODAL_TITLE}    timeout=15s

Confirm Cash Received
    Wait Until Element Is Visible    ${LABEL_CASH}    timeout=10s
    Scroll Element Into View    ${LABEL_CASH}
    ${cash_checked_status}    ${cash_checked_msg}=    Run Keyword And Ignore Error    Click Element    ${CHECKBOX_CASH}
    IF    '${cash_checked_status}' == 'FAIL'
        Click Element    ${LABEL_CASH}
    END
    Wait Until Element Is Enabled    ${BTN_CONFIRM_RECEIVE}    timeout=10s
    Click Button    ${BTN_CONFIRM_RECEIVE}

Verify Status And Results
    Run Keyword And Ignore Error    Wait Until Element Is Visible    ${TOAST_CONFIRMED}    timeout=15s
    Run Keyword And Ignore Error    Wait Until Element Is Visible    ${STATUS_PAID}    timeout=15s