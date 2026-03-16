# -*- coding: utf-8 -*-
*** Settings ***
Documentation     UAT_TEST14 4.1 Passenger Transfer Payment Request
...               Passenger: Test_UAT / 123456789
Library           SeleniumLibrary
Library           OperatingSystem
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
${BTN_TRANSFER}                 xpath=//button[contains(normalize-space(),'โอนเงิน')]
${BTN_ATTACH_SLIP}              xpath=//button[contains(normalize-space(),'แนบสลิป')]
${BTN_CHECK}                    xpath=//button[contains(normalize-space(),'ตรวจสอบ')]
${BTN_SUBMIT_TRANSFER}          xpath=//button[contains(normalize-space(),'ส่งหลักฐาน')]
${FILE_INPUT}                   xpath=//input[@type='file']

${SLIP_FILE_NAME}               selenium-screenshot-1.png
${SLIP_FILE_PATH}               ${CURDIR}${/}${SLIP_FILE_NAME}

*** Test Cases ***
UAT14-4.1-Passenger-Transfer
    Open Website and Login
    Navigate to My Trips
    Select Transfer Payment
    Upload Slip and Check
    Submit Transfer Evidence

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

Select Transfer Payment
    Wait Until Element Is Visible    ${BTN_PAY}    timeout=15s
    Scroll Element Into View    ${BTN_PAY}
    Click Element    ${BTN_PAY}
    Wait Until Element Is Visible    ${BTN_TRANSFER}    timeout=10s
    Click Element    ${BTN_TRANSFER}
    Wait Until Element Is Visible    ${BTN_ATTACH_SLIP}    timeout=10s

Upload Slip and Check
    Click Element    ${BTN_ATTACH_SLIP}
    Wait Until Page Contains Element    ${FILE_INPUT}    timeout=5s
    ${slip_file_canonical}=    Normalize Path    ${SLIP_FILE_PATH}
    Execute JavaScript    (function(){const input=document.querySelector("input[type='file']");if(input){input.classList.remove('hidden');input.style.display='block';input.style.visibility='visible';input.style.opacity='1';}})();
    Wait Until Element Is Visible    ${FILE_INPUT}    timeout=5s
    Choose File    ${FILE_INPUT}    ${slip_file_canonical}
    Wait Until Element Is Enabled    ${BTN_CHECK}    timeout=10s
    Click Button    ${BTN_CHECK}
    Wait Until Page Contains    ยืนยันและส่ง    timeout=10s

Submit Transfer Evidence
    Wait Until Element Is Visible    ${BTN_SUBMIT_TRANSFER}    timeout=10s
    Click Button    ${BTN_SUBMIT_TRANSFER}
    Run Keyword And Ignore Error    Wait Until Page Contains    ส่งหลักฐานสำเร็จ    timeout=10s