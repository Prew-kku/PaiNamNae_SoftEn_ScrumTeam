# -*- coding: utf-8 -*-
*** Settings ***
Library           SeleniumLibrary
Suite Teardown    Close All Browsers

*** Variables ***
${URL}            http://csse4369.cpkku.com/login
${BROWSER}        chrome
${USERNAME}       Test_UAT
${PASSWORD}       123456789
${ADMIN_USER}     admin_UAT
${ADMIN_PASS}     passadmin

*** Test Cases ***
ผู้ใช้ส่งคำขอลบบัญชีใหม่หลังถูกปฏิเสธ
    [Documentation]    UAT-User-ProductBacklogItemsNo.16-004: ทดสอบว่าผู้ใช้สามารถส่งคำขอลบบัญชีใหม่ได้
    ...    หลังจากที่ Admin ปฏิเสธคำขอเดิม (status = rejected)
    ...    ขั้นตอน: User ส่งคำขอ → Admin ปฏิเสธ → User ส่งคำขอใหม่ (ต้องสำเร็จ)

    Set Selenium Speed    0.3s

    # ==========================================
    # ส่วนที่ 1: User ส่งคำขอลบบัญชีครั้งแรก
    # ==========================================
    Open Browser    ${URL}    ${BROWSER}
    Maximize Browser Window
    Wait Until Page Contains    เข้าสู่ระบบ    timeout=10s

    Input Text      id=identifier    ${USERNAME}
    Input Text      id=password      ${PASSWORD}
    Click Button    xpath=//button[contains(text(), 'เข้าสู่ระบบ')]
    Wait Until Element Is Visible    xpath=//span[contains(@class, 'text-blue-600')]    timeout=10s

    Click Element   xpath=//span[contains(@class, 'text-blue-600')]
    Wait Until Element Is Visible    xpath=//a[contains(text(), 'บัญชีของฉัน')]    timeout=5s
    Click Element   xpath=//a[contains(text(), 'บัญชีของฉัน')]
    Wait Until Element Is Visible    xpath=//button[contains(text(), 'ลบบัญชี')]    timeout=10s

    Scroll Element Into View    xpath=//button[contains(text(), 'ลบบัญชี')]
    Click Button    xpath=//button[contains(text(), 'ลบบัญชี')]
    Sleep    1s

    Wait Until Element Is Visible    xpath=//select    timeout=10s
    Click Element                    xpath=//select
    Sleep    0.5s
    Wait Until Element Is Visible    xpath=//option[@value='ไม่ต้องการใช้บริการอีกต่อไป']    timeout=5s
    Click Element                    xpath=//option[@value='ไม่ต้องการใช้บริการอีกต่อไป']
    Sleep    0.5s

    Wait Until Element Is Visible    xpath=//input[@placeholder='กรอกรหัสผ่านของคุณ']    timeout=5s
    Input Text                       xpath=//input[@placeholder='กรอกรหัสผ่านของคุณ']    ${PASSWORD}
    Press Keys                       xpath=//input[@placeholder='กรอกรหัสผ่านของคุณ']    TAB
    Sleep    0.5s

    Wait Until Element Is Visible    xpath=//input[@type='checkbox']    timeout=5s
    Click Element                    xpath=//input[@type='checkbox']
    Sleep    1s

    Wait Until Element Is Enabled    xpath=//button[contains(text(), 'ยืนยันการลบข้อมูล')]    timeout=10s
    Click Button                     xpath=//button[contains(text(), 'ยืนยันการลบข้อมูล')]

    # รอระบบส่ง API และ logout อัตโนมัติ (handleDeleteRequest เรียก logout() หลัง 2 วินาที)
    Sleep    4s
    Wait Until Page Contains    เข้าสู่ระบบ    timeout=15s

    Log    ผ่าน: User ส่งคำขอลบบัญชีครั้งแรกสำเร็จ และระบบ logout อัตโนมัติ
    Close Browser

    # ==========================================
    # ส่วนที่ 2: Admin เข้าสู่ระบบและปฏิเสธคำขอ
    # ==========================================
    Open Browser    ${URL}    ${BROWSER}
    Maximize Browser Window
    Wait Until Page Contains    เข้าสู่ระบบ    timeout=10s

    Input Text      id=identifier    ${ADMIN_USER}
    Input Text      id=password      ${ADMIN_PASS}
    Click Button    xpath=//button[contains(text(), 'เข้าสู่ระบบ')]
    Wait Until Element Is Visible    xpath=//span[contains(@class, 'text-blue-600')]    timeout=10s

    # ไป Dashboard → All Request
    Click Element   xpath=//span[contains(@class, 'text-blue-600')]
    Wait Until Element Is Visible    xpath=//a[contains(., 'Dashboard')]    timeout=5s
    Click Element                    xpath=//a[contains(., 'Dashboard')]
    Sleep    1s

    Wait Until Element Is Visible    xpath=//span[contains(text(), 'All Request')]    timeout=10s
    Click Element                    xpath=//span[contains(text(), 'All Request')]
    Sleep    2s

    # กดปุ่ม fa-xmark เพื่อปฏิเสธคำขอ
    Wait Until Element Is Visible    xpath=//i[contains(@class, 'fa-xmark')]    timeout=10s
    Click Element                    xpath=//i[contains(@class, 'fa-xmark')]
    Sleep    1s

    # กรอกหมายเหตุและกดปฏิเสธ
    # ใช้ xpath=//textarea เพื่อรองรับทั้ง placeholder "ไม่บังคับ" และ "บังคับสำหรับการปฏิเสธ"
    Wait Until Element Is Visible    xpath=//textarea    timeout=5s
    Input Text                       xpath=//textarea    ทดสอบการส่งคำขอใหม่หลังถูกปฏิเสธ
    Sleep    0.5s

    Wait Until Element Is Enabled    xpath=//button[contains(text(), 'ปฏิเสธ')]    timeout=5s
    Click Button                     xpath=//button[contains(text(), 'ปฏิเสธ')]
    Sleep    3s

    Log    ผ่าน: Admin ปฏิเสธคำขอลบบัญชีของ User สำเร็จ
    Close Browser

    # ==========================================
    # ส่วนที่ 3: User ส่งคำขอลบบัญชีใหม่หลังถูกปฏิเสธ
    # ==========================================
    Open Browser    ${URL}    ${BROWSER}
    Maximize Browser Window
    Wait Until Page Contains    เข้าสู่ระบบ    timeout=10s

    Input Text      id=identifier    ${USERNAME}
    Input Text      id=password      ${PASSWORD}
    Click Button    xpath=//button[contains(text(), 'เข้าสู่ระบบ')]
    Wait Until Element Is Visible    xpath=//span[contains(@class, 'text-blue-600')]    timeout=10s

    # ตรวจสอบว่า User ไม่ได้ถูก redirect ไปหน้า /deletion/cancel
    # (เพราะคำขอถูกปฏิเสธแล้ว deletionPending = false)
    Location Should Contain    csse4369.cpkku.com
    Page Should Not Contain    บัญชีอยู่ระหว่างรอลบ
    Log    ผ่าน: User ไม่ถูก redirect ไปหน้า /deletion/cancel หลังคำขอถูกปฏิเสธ

    # เข้าไปที่บัญชีของฉัน
    Click Element   xpath=//span[contains(@class, 'text-blue-600')]
    Wait Until Element Is Visible    xpath=//a[contains(text(), 'บัญชีของฉัน')]    timeout=5s
    Click Element   xpath=//a[contains(text(), 'บัญชีของฉัน')]
    Wait Until Element Is Visible    xpath=//button[contains(text(), 'ลบบัญชี')]    timeout=10s

    Log    ผ่าน: หน้า Profile โหลดสำเร็จ ปุ่ม "ลบบัญชี" แสดงอยู่ (User สามารถส่งคำขอใหม่ได้)

    # ส่งคำขอลบบัญชีใหม่
    Scroll Element Into View    xpath=//button[contains(text(), 'ลบบัญชี')]
    Click Button    xpath=//button[contains(text(), 'ลบบัญชี')]
    Sleep    1s

    Wait Until Element Is Visible    xpath=//select    timeout=10s
    Click Element                    xpath=//select
    Sleep    0.5s
    Wait Until Element Is Visible    xpath=//option[@value='กังวลเรื่องความเป็นส่วนตัว']    timeout=5s
    Click Element                    xpath=//option[@value='กังวลเรื่องความเป็นส่วนตัว']
    Sleep    0.5s

    Wait Until Element Is Visible    xpath=//input[@placeholder='กรอกรหัสผ่านของคุณ']    timeout=5s
    Input Text                       xpath=//input[@placeholder='กรอกรหัสผ่านของคุณ']    ${PASSWORD}
    Press Keys                       xpath=//input[@placeholder='กรอกรหัสผ่านของคุณ']    TAB
    Sleep    0.5s

    Wait Until Element Is Visible    xpath=//input[@type='checkbox']    timeout=5s
    Click Element                    xpath=//input[@type='checkbox']
    Sleep    1s

    Wait Until Element Is Enabled    xpath=//button[contains(text(), 'ยืนยันการลบข้อมูล')]    timeout=10s
    Click Button                     xpath=//button[contains(text(), 'ยืนยันการลบข้อมูล')]

    # รอระบบส่ง API และ logout อัตโนมัติ (หลัง 2 วินาที)
    Sleep    4s
    Wait Until Page Contains    เข้าสู่ระบบ    timeout=15s

    Log    ผ่าน: User ส่งคำขอลบบัญชีใหม่สำเร็จ ระบบ logout อัตโนมัติ (API call สำเร็จ)

    # Login ใหม่อีกครั้ง → Middleware ตรวจ deletionPending = true
    # → redirect ไปหน้า /deletion/cancel โดยอัตโนมัติ
    Input Text      id=identifier    ${USERNAME}
    Input Text      id=password      ${PASSWORD}
    Click Button    xpath=//button[contains(text(), 'เข้าสู่ระบบ')]

    # ตรวจสอบผล: ระบบต้องพา redirect ไปหน้า /deletion/cancel (คำขอใหม่สำเร็จ)
    Wait Until Page Contains    บัญชีอยู่ระหว่างรอลบ    timeout=15s

    Sleep    5s
    Log    ผ่าน: User ส่งคำขอลบบัญชีใหม่หลังถูกปฏิเสธสำเร็จ (Login ใหม่ → Middleware redirect → /deletion/cancel)
    Log    UAT-User-ProductBacklogItemsNo.16-004 ผ่านการทดสอบสมบูรณ์!
