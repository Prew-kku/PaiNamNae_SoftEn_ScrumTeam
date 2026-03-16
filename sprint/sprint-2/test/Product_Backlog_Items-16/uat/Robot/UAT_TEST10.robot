# -*- coding: utf-8 -*-
*** Settings ***
Library           SeleniumLibrary
Suite Teardown    Close Browser

*** Variables ***
${URL}            http://csse4369.cpkku.com/login
${BROWSER}        chrome
${USERNAME}       Test12
${PASSWORD}       Isaac1234
${PROFILE_URL}    http://csse4369.cpkku.com/profile

*** Test Cases ***
ระบบป้องกันการส่งคำขอลบบัญชีซ้ำขณะมีคำขอค้างอยู่
    [Documentation]    UAT-User-ProductBacklogItemsNo.16-003: ทดสอบว่าระบบบล็อกการเข้าถึงหน้า Profile
    ...    เมื่อผู้ใช้มีคำขอลบบัญชีที่ยังค้างอยู่ (deletionPending = true)
    ...    ระบบต้องพา redirect ไปหน้า /deletion/cancel ทันที จึงไม่สามารถส่งคำขอซ้ำได้

    Set Selenium Speed    0.3s

    # ==========================================
    # Step 1: เข้าสู่ระบบ
    # ==========================================
    Open Browser    ${URL}    ${BROWSER}
    Maximize Browser Window
    Wait Until Page Contains    เข้าสู่ระบบ    timeout=10s

    Input Text      id=identifier    ${USERNAME}
    Input Text      id=password      ${PASSWORD}
    Click Button    xpath=//button[contains(text(), 'เข้าสู่ระบบ')]

    Wait Until Element Is Visible    xpath=//span[contains(@class, 'text-blue-600')]    timeout=10s

    # ==========================================
    # Step 2: ส่งคำขอลบบัญชีครั้งแรก
    # ==========================================
    Click Element   xpath=//span[contains(@class, 'text-blue-600')]
    Wait Until Element Is Visible    xpath=//a[contains(text(), 'บัญชีของฉัน')]    timeout=5s
    Click Element   xpath=//a[contains(text(), 'บัญชีของฉัน')]
    Wait Until Element Is Visible    xpath=//button[contains(text(), 'ลบบัญชี')]    timeout=10s

    Scroll Element Into View    xpath=//button[contains(text(), 'ลบบัญชี')]
    Click Button    xpath=//button[contains(text(), 'ลบบัญชี')]
    Sleep    1s

    # กรอกเหตุผล
    Wait Until Element Is Visible    xpath=//select    timeout=10s
    Click Element                    xpath=//select
    Sleep    0.5s
    Wait Until Element Is Visible    xpath=//option[@value='ไม่ต้องการใช้บริการอีกต่อไป']    timeout=5s
    Click Element                    xpath=//option[@value='ไม่ต้องการใช้บริการอีกต่อไป']
    Sleep    0.5s

    # กรอกรหัสผ่าน
    Wait Until Element Is Visible    xpath=//input[@placeholder='กรอกรหัสผ่านของคุณ']    timeout=5s
    Input Text                       xpath=//input[@placeholder='กรอกรหัสผ่านของคุณ']    ${PASSWORD}
    Press Keys                       xpath=//input[@placeholder='กรอกรหัสผ่านของคุณ']    TAB
    Sleep    0.5s

    # ติ๊ก Checkbox
    Wait Until Element Is Visible    xpath=//input[@type='checkbox']    timeout=5s
    Click Element                    xpath=//input[@type='checkbox']
    Sleep    1s

    # ยืนยันการส่งคำขอ
    Wait Until Element Is Enabled    xpath=//button[contains(text(), 'ยืนยันการลบข้อมูล')]    timeout=10s
    Click Button                     xpath=//button[contains(text(), 'ยืนยันการลบข้อมูล')]

    Log    ผ่าน Step 2: ส่งคำขอลบบัญชีครั้งแรกสำเร็จ

    # ==========================================
    # Step 3: รอระบบ logout อัตโนมัติก่อน (2 วินาที) แล้วจึง Login ใหม่
    # deletionPending = true จะถูก set หลัง Login ใหม่
    # ==========================================
    Sleep    4s
    Wait Until Page Contains    เข้าสู่ระบบ    timeout=15s
    Log    ผ่าน Step 3: ระบบ logout อัตโนมัติหลังส่งคำขอ และพาไปหน้า Login

    # ==========================================
    # Step 4: Login ใหม่ → Middleware ตรวจ deletionPending=true
    # → redirect ไป /deletion/cancel ทันที (ไม่ได้ไปหน้าปกติ)
    # ==========================================
    Input Text      id=identifier    ${USERNAME}
    Input Text      id=password      ${PASSWORD}
    Click Button    xpath=//button[contains(text(), 'เข้าสู่ระบบ')]

    Wait Until Page Contains    บัญชีอยู่ระหว่างรอลบ    timeout=15s
    Page Should Contain    บัญชีอยู่ระหว่างรอลบ
    Log    ผ่าน Step 4: Login แล้ว Middleware redirect ไป /deletion/cancel สำเร็จ

    # ==========================================
    # Step 5: พยายามไปหน้า Profile โดยตรง
    # (ทดสอบว่า Middleware บล็อกการเข้าถึงหน้า Profile จริงหรือไม่)
    # ==========================================
    Go To    ${PROFILE_URL}
    Sleep    2s

    # ==========================================
    # Step 6: ตรวจสอบว่า Middleware redirect กลับมาที่ /deletion/cancel
    # (ผู้ใช้ไม่สามารถเข้าถึงหน้า Profile ซึ่งมีปุ่มลบบัญชีอยู่)
    # ==========================================
    Wait Until Page Contains    บัญชีอยู่ระหว่างรอลบ    timeout=10s
    Page Should Contain    บัญชีอยู่ระหว่างรอลบ
    Page Should Contain    ยกเลิกการลบบัญชี

    Sleep    2s
    Log    ผ่าน Step 6: ระบบบล็อกการเข้าถึงหน้า Profile สำเร็จ
    Log    ระบบป้องกันการส่งคำขอซ้ำโดย: ผู้ใช้ถูก redirect กลับมาที่หน้ายกเลิกเสมอ

    # ==========================================
    # Step 7: ทำความสะอาด — ยกเลิกคำขอเพื่อ restore สถานะ
    # ==========================================
    Wait Until Element Is Visible    xpath=//button[contains(text(), 'ยกเลิกการลบบัญชี')]    timeout=10s
    Click Button                     xpath=//button[contains(text(), 'ยกเลิกการลบบัญชี')]
    Sleep    3s

    Log    ผ่าน Step 7: ยกเลิกคำขอเพื่อ restore สถานะผู้ใช้
    Sleep    3s
    Log    UAT-User-ProductBacklogItemsNo.16-003 ระบบป้องกันการส่งคำขอลบบัญชีซ้ำ ผ่านการทดสอบสมบูรณ์!
