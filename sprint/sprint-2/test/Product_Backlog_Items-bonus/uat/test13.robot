# -*- coding: utf-8 -*-
*** Settings ***
Documentation     UAT_TEST14 Passenger Cash only (separated)
Library           SeleniumLibrary
Suite Teardown    Close All Browsers

*** Variables ***
${BASE_URL}                     http://csse4369.cpkku.com
${LOGIN_URL}                    ${BASE_URL}/login
${MY_TRIP_URL}                  ${BASE_URL}/myTrip
${BROWSER}                      chrome

${USERNAME}                     Test_UAT
${PASSWORD}                     123456789

${BTN_LOGIN}                    xpath=//button[contains(normalize-space(),'เข้าสู่ระบบ')]
${BTN_PAY}                      xpath=(//button[contains(normalize-space(),'ชำระเงิน') or contains(normalize-space(),'ส่งสลิปใหม่')])[1]
${PAY_MODAL_TITLE}              xpath=//h3[contains(normalize-space(),'ข้อมูลการชำระเงิน')]
${TAB_ALL}                      xpath=(//button[contains(normalize-space(),'ทั้งหมด')])[1]

${CHECKBOX_PAY_FOR_FRIEND}      xpath=(//p[contains(normalize-space(),'จ่ายแทนผู้ร่วมเดินทาง')]/following::input[@type='checkbox'])[1]
${BTN_METHOD_CASH}              xpath=//button[contains(normalize-space(),'เงินสด')]
${BTN_CONTINUE_CASH}            xpath=//button[contains(normalize-space(),'ดำเนินการต่อ')]
${BTN_SUBMIT_CASH}              xpath=//button[contains(normalize-space(),'แจ้งชำระเงินสด')]

${STATE_WAIT_DRIVER}            xpath=//button[contains(normalize-space(),'รอคนขับยืนยัน')]
${BTN_VIEW_SLIP}                xpath=//button[contains(normalize-space(),'ดูสลิป')]

*** Test Cases ***
UAT14-Passenger-Cash-Payment-Only
    Open Website And Login
    Open My Trip Page And Select All
    Open Payment Popup
    Verify Payment Popup Step1
    Choose Pay For Friend And Cash
    Continue And Submit Cash
    Verify Pending Driver Confirmation

*** Keywords ***
Open Website And Login
    Open Browser    ${LOGIN_URL}    ${BROWSER}
    Maximize Browser Window
    Wait Until Element Is Visible    id=identifier    timeout=20s
    Wait Until Element Is Visible    id=password      timeout=20s
    Input Text    id=identifier    ${USERNAME}
    Input Text    id=password      ${PASSWORD}
    Click Button    ${BTN_LOGIN}
    Wait Until Page Does Not Contain Element    ${BTN_LOGIN}    timeout=20s
    Wait Until Keyword Succeeds    20s    2s    Login Should Be Successful

Login Should Be Successful
    ${current_url}=    Get Location
    Should Not Contain    ${current_url}    /login
    Wait Until Element Is Visible    xpath=//span[contains(@class,'text-blue-600')]    timeout=10s

Open My Trip Page And Select All
    Go To    ${MY_TRIP_URL}
    Wait Until Page Contains    การเดินทางของฉัน    timeout=20s
    ${tab_status}    ${tab_msg}=    Run Keyword And Ignore Error    Click Element    ${TAB_ALL}
    IF    '${tab_status}' == 'FAIL'
        Execute JavaScript    (function(){const b=[...document.querySelectorAll('button')].find(el=>el.offsetParent!==null&&el.textContent&&el.textContent.includes('ทั้งหมด'));if(b){b.click();}})();
    END
    Wait Until Page Contains    รายการการเดินทาง    timeout=10s

Open Payment Popup
    Wait Until Keyword Succeeds    20s    2s    Pay Button Should Be Visible
    Scroll Element Into View    ${BTN_PAY}
    Click Element    ${BTN_PAY}
    Wait Until Element Is Visible    ${PAY_MODAL_TITLE}    timeout=15s

Pay Button Should Be Visible
    ${visible}=    Run Keyword And Return Status    Element Should Be Visible    ${BTN_PAY}
    IF    not ${visible}
        ${tab_done_status}    ${tab_done_msg}=    Run Keyword And Ignore Error    Click Element    xpath=(//button[contains(normalize-space(),'เสร็จสิ้น')])[1]
        IF    '${tab_done_status}' == 'FAIL'
            Run Keyword And Ignore Error    Click Element    ${TAB_ALL}
        END
    END
    Wait Until Element Is Visible    ${BTN_PAY}    timeout=10s

Verify Payment Popup Step1
    Page Should Contain    ข้อมูลการชำระเงิน
    Page Should Contain    เงินสด

Choose Pay For Friend And Cash
    ${friend_status}    ${friend_msg}=    Run Keyword And Ignore Error    Click Element    ${CHECKBOX_PAY_FOR_FRIEND}
    Click Element    ${BTN_METHOD_CASH}
    Wait Until Page Contains    ชำระด้วยเงินสดกับคนขับโดยตรง    timeout=10s
    Wait Until Element Is Visible    ${BTN_CONTINUE_CASH}    timeout=10s

Continue And Submit Cash
    Click Button    ${BTN_CONTINUE_CASH}
    Wait Until Page Contains    ยืนยันและส่ง    timeout=10s
    Wait Until Element Is Visible    ${BTN_SUBMIT_CASH}    timeout=10s
    Click Button    ${BTN_SUBMIT_CASH}
    Run Keyword And Ignore Error    Wait Until Page Contains    รับทราบแล้ว    timeout=8s
    Wait Until Element Is Not Visible    ${PAY_MODAL_TITLE}    timeout=20s

Verify Pending Driver Confirmation
    Wait Until Page Contains    การเดินทางของฉัน    timeout=20s
    Run Keyword And Ignore Error    Wait Until Element Is Visible    ${BTN_VIEW_SLIP}    timeout=10s
    Wait Until Element Is Visible    ${STATE_WAIT_DRIVER}    timeout=20s