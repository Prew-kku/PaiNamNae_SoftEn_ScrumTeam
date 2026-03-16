# -*- coding: utf-8 -*-
*** Settings ***
Documentation     UAT_TEST14 (V1.1) - User Profile / Payment Information
...               Driver ตรวจสอบและยืนยันการรับเงิน (โอน/เงินสด) กรณีจ่ายแทนกัน
Library           SeleniumLibrary
Suite Teardown    Close All Browsers

*** Variables ***
${URL}                               http://csse4369.cpkku.com/login
${MY_ROUTE_URL}                      http://csse4369.cpkku.com/myRoute
${BROWSER}                           chrome
${DRIVER_USERNAME}                   driver2@gmail.com
${DRIVER_PASSWORD}                   jeng12345678
${PASSENGER_USERNAME}                Test_UAT
${PASSENGER_PASSWORD}                123456789
${BTN_LOGIN}                         xpath=//button[contains(normalize-space(),'เข้าสู่ระบบ')]
${BTN_CONFIRM_PAYMENT}               xpath=//button[contains(normalize-space(),'ยืนยันการชำระเงิน')]
${PAYMENT_MODAL_TITLE}               xpath=//h3[contains(normalize-space(),'ตรวจสอบการชำระเงิน')]
${BTN_CONFIRM_RECEIVE}               xpath=//button[contains(normalize-space(),'ยืนยันการรับเงิน')]
${CHECKBOX_SLIP_VALID}               xpath=//label[contains(normalize-space(.),'สลิปถูกต้อง')]//input[@type='checkbox']
${CHECKBOX_CASH_RECEIVED}            xpath=//label[contains(normalize-space(.),'รับเงินสดแล้ว')]//input[@type='checkbox']
${LABEL_SLIP_VALID}                  xpath=//label[contains(normalize-space(.),'สลิปถูกต้อง')]
${LABEL_CASH_RECEIVED}               xpath=//label[contains(normalize-space(.),'รับเงินสดแล้ว')]
${TOAST_CONFIRMED}                   xpath=//*[contains(normalize-space(),'ยืนยันแล้ว')]
${STATUS_PAID}                       xpath=//*[contains(normalize-space(),'ชำระแล้ว')]
${STATUS_FINISHED}                   xpath=//*[contains(normalize-space(),'เสร็จสิ้น')]
${BTN_PAYMENT_HISTORY}               xpath=//button[contains(normalize-space(),'ประวัติการชำระเงิน')]
${BTN_VIEW_SLIP}                     xpath=//button[contains(normalize-space(),'ดูสลิป')]
${BTN_RECEIPT}                       xpath=//button[contains(normalize-space(),'ใบเสร็จ') or contains(normalize-space(),'โหลดใบเสร็จ')]

*** Test Cases ***
UAT14-Cash-Driver Confirm Cash Payment
    [Documentation]    ใช้ Driver: driver1 / Isaac1234 และ Passenger(คนจอง): TestS2 / Isaac1234
    ...    ขั้นตอนนี้ยืนยันฝั่งคนขับสำหรับเคสเงินสดจ่ายแทนกัน
    Open Login Page
    Login As Driver
    Open My Route Booking Requests
    Verify Cash Modal And Confirm
    Verify Payment Success Result

UAT14-Transfer-Driver Confirm Payment Slip
    [Documentation]    ใช้ Driver: driver1 / Isaac1234 และ Passenger(คนจอง): TestS2 / Isaac1234
    ...    ขั้นตอนนี้ยืนยันฝั่งคนขับสำหรับเคสโอนเงินที่ผู้โดยสารส่งสลิปแล้ว
    Open Login Page
    Login As Driver
    Open My Route Booking Requests
    Verify Transfer Modal And Confirm
    Verify Payment Success Result

*** Keywords ***
Open Login Page
    Open Browser    ${URL}    ${BROWSER}
    Maximize Browser Window
    Wait Until Element Is Visible    id=identifier    timeout=15s
    Wait Until Element Is Visible    id=password      timeout=15s

Login As Driver
    Input Text      id=identifier    ${DRIVER_USERNAME}
    Input Text      id=password      ${DRIVER_PASSWORD}
    Click Button    ${BTN_LOGIN}
    Wait Until Page Does Not Contain Element    ${BTN_LOGIN}    timeout=15s

Open My Route Booking Requests
    Go To    ${MY_ROUTE_URL}
    Wait Until Page Contains    คำขอจองเส้นทางของฉัน    timeout=20s
    Wait Until Keyword Succeeds    15s    1s    Switch To My Routes Tab
    Wait Until Element Is Visible    ${BTN_CONFIRM_PAYMENT}    timeout=20s

Switch To My Routes Tab
    ${tab_status}    ${tab_msg}=    Run Keyword And Ignore Error    Click Element    xpath=(//button[contains(normalize-space(),'เส้นทางของฉัน')])[1]
    IF    '${tab_status}' == 'FAIL'
        Execute JavaScript    (function(){const btn=[...document.querySelectorAll('button')].find(el=>el.offsetParent!==null&&el.textContent&&el.textContent.includes('เส้นทางของฉัน'));if(btn){btn.click();}})();
    END
    Wait Until Page Contains Element    xpath=//h3[contains(normalize-space(),'เส้นทางของฉัน') or contains(normalize-space(),'รายการคำขอจอง')]    timeout=10s

Open Payment Verification Modal
    [Arguments]    ${target_locator}
    Wait Until Element Is Visible    ${BTN_CONFIRM_PAYMENT}    timeout=15s
    ${confirm_count}=    Get Element Count    ${BTN_CONFIRM_PAYMENT}
    Should Be True    ${confirm_count} > 0
    ${end_index}=    Evaluate    ${confirm_count} + 1

    FOR    ${index}    IN RANGE    1    ${end_index}
        Click Element    xpath=(//button[contains(normalize-space(),'ยืนยันการชำระเงิน')])[${index}]
        Wait Until Element Is Visible    ${PAYMENT_MODAL_TITLE}    timeout=15s
        ${is_match}=    Run Keyword And Return Status    Wait Until Element Is Visible    ${target_locator}    timeout=3s
        IF    ${is_match}
            RETURN
        END
        Close Payment Verification Modal
    END

    Fail    ไม่พบรายการชำระเงินที่ตรงกับเงื่อนไข ${target_locator}

Close Payment Verification Modal
    Run Keyword And Ignore Error    Click Button    xpath=//button[contains(normalize-space(),'ปิด')]
    Run Keyword And Ignore Error    Click Element    xpath=(//h3[contains(normalize-space(),'ตรวจสอบการชำระเงิน')]/ancestor::div[1]//button)[1]
    Run Keyword And Ignore Error    Press Keys    xpath=//body    ESCAPE
    Run Keyword And Ignore Error    Wait Until Element Is Not Visible    ${PAYMENT_MODAL_TITLE}    timeout=5s

Verify Transfer Modal And Confirm
    Open Payment Verification Modal    ${LABEL_SLIP_VALID}
    Page Should Contain    ตรวจสอบการชำระเงิน
    Run Keyword And Ignore Error    Click Button    ${BTN_VIEW_SLIP}
    Wait Until Element Is Visible    ${LABEL_SLIP_VALID}    timeout=10s
    Scroll Element Into View    ${LABEL_SLIP_VALID}
    ${checked_status}    ${checked_msg}=    Run Keyword And Ignore Error    Click Element    ${CHECKBOX_SLIP_VALID}
    IF    '${checked_status}' == 'FAIL'
        Click Element    ${LABEL_SLIP_VALID}
    END
    Wait Until Element Is Enabled    ${BTN_CONFIRM_RECEIVE}    timeout=10s
    Click Button    ${BTN_CONFIRM_RECEIVE}

Verify Cash Modal And Confirm
    Open Payment Verification Modal    ${LABEL_CASH_RECEIVED}
    Page Should Contain    ตรวจสอบการชำระเงิน
    Wait Until Element Is Visible    ${LABEL_CASH_RECEIVED}    timeout=10s
    Scroll Element Into View    ${LABEL_CASH_RECEIVED}
    ${cash_checked_status}    ${cash_checked_msg}=    Run Keyword And Ignore Error    Click Element    ${CHECKBOX_CASH_RECEIVED}
    IF    '${cash_checked_status}' == 'FAIL'
        Click Element    ${LABEL_CASH_RECEIVED}
    END
    Wait Until Element Is Enabled    ${BTN_CONFIRM_RECEIVE}    timeout=10s
    Click Button    ${BTN_CONFIRM_RECEIVE}

Verify Payment Success Result
    Wait Until Element Is Visible    ${TOAST_CONFIRMED}    timeout=15s
    Wait Until Element Is Visible    ${STATUS_PAID}       timeout=15s
    Wait Until Element Is Visible    ${STATUS_FINISHED}   timeout=20s
    Run Keyword And Ignore Error    Wait Until Element Is Visible    ${BTN_VIEW_SLIP}          timeout=10s
    Run Keyword And Ignore Error    Wait Until Element Is Visible    ${BTN_RECEIPT}            timeout=10s
    Wait Until Element Is Visible    ${BTN_PAYMENT_HISTORY}    timeout=20s