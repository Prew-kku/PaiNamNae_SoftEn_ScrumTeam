# -*- coding: utf-8 -*-
*** Settings ***
Documentation     UAT_TEST14 4.2 Passenger Cash Payment Request
...               Passenger: Test_UAT / 123456789
Library           SeleniumLibrary
Suite Teardown    Close All Browsers

*** Variables ***
${BASE_URL}                     http://csse4369.cpkku.com
${LOGIN_URL}                    ${BASE_URL}/login
${BROWSER}                      chrome

${USERNAME}                     Test_UAT
${PASSWORD}                     123456789

${BTN_LOGIN}                    xpath=//button[contains(normalize-space(),'เข้าสู่ระบบ')]

${MENU_MY_TRIP}                 xpath=//*[contains(normalize-space(),'การเดินทางของฉัน') and not(contains(normalize-space(),'คำขอจอง'))]

${BTN_PAY}                      xpath=(//button[contains(normalize-space(),'ชำระเงิน')])[1]
${BTN_CASH}                     xpath=//button[contains(normalize-space(),'เงินสด')]
${BTN_CONTINUE}                 xpath=//button[contains(normalize-space(),'ดำเนินการต่อ')]
${BTN_SUBMIT_CASH}              xpath=//button[contains(normalize-space(),'แจ้งชำระเงินสด')]

*** Test Cases ***
UAT14-4.2-Passenger-Cash
    Open Website and Login
    Navigate to My Trips
    Select Cash Payment
    Continue And Confirm Cash

*** Keywords ***
Open Website and Login
    Open Browser    ${LOGIN_URL}    ${BROWSER}
    Maximize Browser Window
    Wait Until Element Is Visible    id=identifier    timeout=15s
    Wait Until Element Is Visible    id=password      timeout=15s
    Input Text      id=identifier    ${USERNAME}
    Input Text      id=password      ${PASSWORD}
    Click Button    ${BTN_LOGIN}
    Wait Until Page Does Not Contain Element    ${BTN_LOGIN}    timeout=15s

Navigate to My Trips
    Go To    ${BASE_URL}/myTrip
    Wait Until Page Contains    การเดินทางของฉัน    timeout=15s
    ${tab_status}    ${tab_msg}=    Run Keyword And Ignore Error    Click Element    xpath=(//button[contains(normalize-space(),'ทั้งหมด')])[1]
    IF    '${tab_status}' == 'FAIL'
        Execute JavaScript    (function(){const btn=[...document.querySelectorAll('button')].find(el=>el.offsetParent!==null&&el.textContent&&el.textContent.includes('ทั้งหมด'));if(btn){btn.click();}})();
    END
    Wait Until Page Contains    รายการการเดินทาง    timeout=10s

Select Cash Payment
    Wait Until Element Is Visible    ${BTN_PAY}    timeout=15s
    Scroll Element Into View    ${BTN_PAY}
    Click Element    ${BTN_PAY}
    Wait Until Element Is Visible    ${BTN_CASH}    timeout=10s
    Click Element    ${BTN_CASH}
    Wait Until Element Is Visible    ${BTN_CONTINUE}    timeout=10s

Continue And Confirm Cash
    Click Element    ${BTN_CONTINUE}
    Wait Until Element Is Visible    ${BTN_SUBMIT_CASH}    timeout=10s
    Click Element    ${BTN_SUBMIT_CASH}
    Run Keyword And Ignore Error    Wait Until Page Contains    รับทราบแล้ว    timeout=10s