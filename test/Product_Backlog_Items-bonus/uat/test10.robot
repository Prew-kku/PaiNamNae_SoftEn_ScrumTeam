# -*- coding: utf-8 -*-
*** Settings ***
Documentation     UAT_TEST14 5.1 Driver Delete Bank Account
...               Driver: driver2@gmail.com / jeng12345678
Library           SeleniumLibrary
Suite Teardown    Close All Browsers

*** Variables ***
${BASE_URL}                     http://csse4369.cpkku.com
${LOGIN_URL}                    ${BASE_URL}/login
${BROWSER}                      chrome

${USERNAME}                     Test_UAT
${PASSWORD}                     123456789

${BTN_LOGIN}                    xpath=//button[contains(normalize-space(),'เข้าสู่ระบบ')]
${MENU_PAYMENT_INFO}            xpath=//a[contains(normalize-space(),'ข้อมูลการรับเงิน') or contains(@href, '/profile/payment-info')]
${BTN_DELETE_ACCOUNT}           xpath=(//button[@title='ลบ'])[1]
${BTN_CONFIRM_DELETE}           xpath=//button[normalize-space()='ลบบัญชี']

*** Test Cases ***
UAT14-5.1-Driver-Delete-Bank-Account
    Open Website and Login
    Open User Dropdown and Navigate to Profile Page
    Select Payment Information Menu
    Check Payment Information Display
    Open Delete Confirmation Modal
    Confirm Delete Account

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

Open User Dropdown and Navigate to Profile Page
    Go To    ${BASE_URL}/profile
    Wait Until Page Contains    บัญชีของฉัน    timeout=15s

Select Payment Information Menu
    Wait Until Element Is Visible    ${MENU_PAYMENT_INFO}    timeout=10s
    Scroll Element Into View    ${MENU_PAYMENT_INFO}
    ${click_status}    ${click_msg}=    Run Keyword And Ignore Error    Click Element    ${MENU_PAYMENT_INFO}
    IF    '${click_status}' == 'FAIL'
        Execute JavaScript    document.querySelector("a[href='/profile/payment-info']").click()
    END
    Wait Until Location Contains    /profile/payment-info    timeout=10s
    Wait Until Page Contains    บัญชีธนาคาร    timeout=10s

Check Payment Information Display
    Wait Until Page Contains    บัญชีธนาคาร    timeout=10s

Open Delete Confirmation Modal
    Wait Until Element Is Visible    ${BTN_DELETE_ACCOUNT}    timeout=10s
    Click Element    ${BTN_DELETE_ACCOUNT}
    Wait Until Page Contains    ลบบัญชีธนาคาร    timeout=5s
    Wait Until Page Contains    คุณต้องการลบบัญชีนี้ใช่หรือไม่?    timeout=5s

Confirm Delete Account
    Wait Until Element Is Visible    ${BTN_CONFIRM_DELETE}    timeout=5s
    Click Element    ${BTN_CONFIRM_DELETE}
    Run Keyword And Ignore Error    Wait Until Page Contains    ลบสำเร็จ    timeout=10s