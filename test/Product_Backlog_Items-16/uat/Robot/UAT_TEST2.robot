# -*- coding: utf-8 -*-
*** Settings ***
Library           SeleniumLibrary
Suite Teardown    Close Browser

*** Variables ***
${URL}            http://csse4369.cpkku.com/login
${BROWSER}        chrome
${USERNAME}       Test12
${PASSWORD}       Isaac1234
${REASON}         ไม่ต้องการใช้บริการอีกต่อไป
${DELETE_BTN}     xpath=//button[contains(text(), 'ยืนยันการลบข้อมูล')]
${TOAST}          xpath=//*[contains(@class,'toast') or contains(@class,'Toast') or contains(@class,'notification')]

*** Test Cases ***
ทดสอบระบบป้องกันฟอร์มลบบัญชี
    [Documentation]    UAT-User-ProductBacklogItemsNo.16-002: ทดสอบ Validation ของปุ่มยืนยันการลบข้อมูล
    ...    ปุ่มยืนยันต้องกดไม่ได้เมื่อยังไม่เลือกเหตุผล/ไม่ติ๊กยืนยัน และกรณียืนยันผิดต้องขึ้นเตือนข้อผิดพลาด

    Set Selenium Speed    0.3s

    # Step 1: Open Website and Login
    Open Browser    ${URL}    ${BROWSER}
    Maximize Browser Window
    Wait Until Page Contains    เข้าสู่ระบบ    timeout=10s

    Input Text      id=identifier    ${USERNAME}
    Input Text      id=password      ${PASSWORD}
    Click Button    xpath=//button[contains(text(), 'เข้าสู่ระบบ')]
    Wait Until Element Is Visible    xpath=//span[contains(@class, 'text-blue-600')]    timeout=10s
    Log    เข้าสู่ระบบสำเร็จและแสดงชื่อผู้ใช้มุมขวาบน

    # Step 2-4: Open User Dropdown -> Navigate to Profile -> Open Delete Modal
    Click Element   xpath=//span[contains(@class, 'text-blue-600')]
    Wait Until Element Is Visible    xpath=//a[contains(text(), 'บัญชีของฉัน')]    timeout=5s
    Click Element   xpath=//a[contains(text(), 'บัญชีของฉัน')]
    Wait Until Element Is Visible    xpath=//button[contains(text(), 'ลบบัญชี')]    timeout=10s
    Scroll Element Into View    xpath=//button[contains(text(), 'ลบบัญชี')]
    Click Button    xpath=//button[contains(text(), 'ลบบัญชี')]
    Sleep    1s

    Wait Until Element Is Visible    xpath=//select    timeout=10s
    Wait Until Element Is Visible    xpath=//input[@placeholder='กรอกรหัสผ่านของคุณ']    timeout=10s
    Wait Until Element Is Visible    xpath=//input[@type='checkbox']    timeout=10s

    # Check Missing Reason (ไม่เลือกเหตุผล)
    Input Text                       xpath=//input[@placeholder='กรอกรหัสผ่านของคุณ']    ${PASSWORD}
    Select Checkbox                  xpath=//input[@type='checkbox']
    Element Should Be Disabled       ${DELETE_BTN}

    # Check Button Click Action while disabled
    Click Element                     ${DELETE_BTN}
    Sleep                            1s
    Location Should Contain          /profile
    Page Should Not Contain          ลบข้อมูลสำเร็จ
    Page Should Not Contain          เกิดข้อผิดพลาด

    # Check Missing Checkbox (ไม่ติ๊กยืนยัน)
    Select From List By Value        xpath=//select    ${REASON}
    Unselect Checkbox                xpath=//input[@type='checkbox']
    Clear Element Text               xpath=//input[@placeholder='กรอกรหัสผ่านของคุณ']
    Input Text                       xpath=//input[@placeholder='กรอกรหัสผ่านของคุณ']    ${PASSWORD}
    Element Should Be Disabled       ${DELETE_BTN}

    Click Element                     ${DELETE_BTN}
    Sleep                            1s
    Location Should Contain          /profile
    Page Should Not Contain          ลบข้อมูลสำเร็จ
    Page Should Not Contain          เกิดข้อผิดพลาด

    # Check Wrong Confirmation Text (พิมพ์ผิด)
    Select From List By Value        xpath=//select    ${REASON}
    Select Checkbox                  xpath=//input[@type='checkbox']
    Clear Element Text               xpath=//input[@placeholder='กรอกรหัสผ่านของคุณ']
    Input Text                       xpath=//input[@placeholder='กรอกรหัสผ่านของคุณ']    12345678
    Element Should Be Enabled        ${DELETE_BTN}
    Click Button                     ${DELETE_BTN}

    Wait Until Page Contains         เกิดข้อผิดพลาด    timeout=10s
    Page Should Not Contain          ลบข้อมูลสำเร็จ
    Log    ผ่าน: Validation ของปุ่มยืนยันการลบข้อมูลทำงานถูกต้องตามเงื่อนไข
