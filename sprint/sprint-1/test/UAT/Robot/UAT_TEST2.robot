# -*- coding: utf-8 -*-
*** Settings ***
Library           SeleniumLibrary
Suite Teardown    Close Browser

*** Variables ***
${URL}            http://csse4369.cpkku.com/login
${BROWSER}        chrome
${USERNAME}       Test_UAT
${PASSWORD}       123456789

*** Test Cases ***
ผู้ใช้ยกเลิกคำขอลบบัญชีด้วยตัวเอง
    [Documentation]    UAT-User-ProductBacklogItemsNo.16-002: ทดสอบการยกเลิกคำขอลบบัญชีโดยผู้ใช้เอง
    ...    ขั้นตอน: ส่งคำขอลบบัญชี → ระบบพา redirect ไปหน้า /deletion/cancel → กดยกเลิก → ระบบพากลับสู่หน้าหลัก

    Set Selenium Speed    0.3s

    # ==========================================
    # Step 1: เปิดเว็บไซต์และเข้าสู่ระบบ
    # ==========================================
    Open Browser    ${URL}    ${BROWSER}
    Maximize Browser Window
    Wait Until Page Contains    เข้าสู่ระบบ    timeout=10s

    Input Text      id=identifier    ${USERNAME}
    Input Text      id=password      ${PASSWORD}
    Click Button    xpath=//button[contains(text(), 'เข้าสู่ระบบ')]

    Wait Until Element Is Visible    xpath=//span[contains(@class, 'text-blue-600')]    timeout=10s

    # ==========================================
    # Step 2: ไปที่บัญชีของฉัน (Profile)
    # ==========================================
    Click Element   xpath=//span[contains(@class, 'text-blue-600')]
    Wait Until Element Is Visible    xpath=//a[contains(text(), 'บัญชีของฉัน')]    timeout=5s
    Click Element   xpath=//a[contains(text(), 'บัญชีของฉัน')]
    Wait Until Element Is Visible    xpath=//button[contains(text(), 'ลบบัญชี')]    timeout=10s

    # ==========================================
    # Step 3: เปิดฟอร์มลบบัญชีและกรอกข้อมูล
    # ==========================================
    Scroll Element Into View    xpath=//button[contains(text(), 'ลบบัญชี')]
    Click Button    xpath=//button[contains(text(), 'ลบบัญชี')]
    Sleep    1s

    # 3.1 เลือกเหตุผล
    Wait Until Element Is Visible    xpath=//select    timeout=10s
    Click Element                    xpath=//select
    Sleep    0.5s
    Wait Until Element Is Visible    xpath=//option[@value='ไม่ต้องการใช้บริการอีกต่อไป']    timeout=5s
    Click Element                    xpath=//option[@value='ไม่ต้องการใช้บริการอีกต่อไป']
    Sleep    0.5s

    # 3.2 กรอกรหัสผ่าน
    Wait Until Element Is Visible    xpath=//input[@placeholder='กรอกรหัสผ่านของคุณ']    timeout=5s
    Input Text                       xpath=//input[@placeholder='กรอกรหัสผ่านของคุณ']    ${PASSWORD}
    Press Keys                       xpath=//input[@placeholder='กรอกรหัสผ่านของคุณ']    TAB
    Sleep    0.5s

    # 3.3 ติ๊ก Checkbox ยืนยัน
    Wait Until Element Is Visible    xpath=//input[@type='checkbox']    timeout=5s
    Click Element                    xpath=//input[@type='checkbox']
    Sleep    1s

    # ==========================================
    # Step 4: กดปุ่ม "ยืนยันการลบข้อมูล"
    # ==========================================
    Wait Until Element Is Enabled    xpath=//button[contains(text(), 'ยืนยันการลบข้อมูล')]    timeout=10s
    Click Button                     xpath=//button[contains(text(), 'ยืนยันการลบข้อมูล')]

    # ==========================================
    # Step 5: รอระบบ logout อัตโนมัติ (2 วินาทีหลังส่งคำขอสำเร็จ)
    # ==========================================
    # handleDeleteRequest ใน profile/index.vue เรียก logout() หลัง 2 วินาที
    # ระบบจะพา redirect ไปหน้า login
    Sleep    4s
    Wait Until Page Contains    เข้าสู่ระบบ    timeout=15s
    Log    ผ่าน Step 5: ระบบ logout อัตโนมัติหลังส่งคำขอ และพามาหน้า Login

    # ==========================================
    # Step 6: Login ใหม่ — Middleware จะตรวจ deletionPending = true
    # และ redirect ไปยัง /deletion/cancel อัตโนมัติ
    # ==========================================
    Input Text      id=identifier    ${USERNAME}
    Input Text      id=password      ${PASSWORD}
    Click Button    xpath=//button[contains(text(), 'เข้าสู่ระบบ')]

    # ==========================================
    # Step 7: ตรวจสอบว่า Middleware พา redirect ไปหน้า /deletion/cancel
    # ==========================================
    Wait Until Page Contains    บัญชีอยู่ระหว่างรอลบ    timeout=15s
    Log    ผ่าน Step 7: Login ใหม่แล้ว Middleware redirect ไปหน้า /deletion/cancel สำเร็จ

    # ==========================================
    # Step 8: กดปุ่ม "ยกเลิกการลบบัญชี"
    # ==========================================
    Wait Until Element Is Visible    xpath=//button[contains(text(), 'ยกเลิกการลบบัญชี')]    timeout=10s
    Click Button                     xpath=//button[contains(text(), 'ยกเลิกการลบบัญชี')]

    # รอระบบประมวลผลการยกเลิก
    Sleep    3s

    # ==========================================
    # Step 9: ตรวจสอบว่าระบบพากลับสู่หน้าหลักสำเร็จ
    # ==========================================
    # หลังยกเลิก deletionPending = false → middleware ไม่บล็อก → กลับไปหน้าหลักได้
    Wait Until Element Is Visible    xpath=//span[contains(@class, 'text-blue-600')]    timeout=10s
    Page Should Not Contain    บัญชีอยู่ระหว่างรอลบ

    Sleep    5s
    Log    ผ่าน Step 9: ผู้ใช้ยกเลิกคำขอลบบัญชีสำเร็จ ระบบกลับสู่หน้าปกติ
    Log    UAT-User-ProductBacklogItemsNo.16-002 ผ่านการทดสอบสมบูรณ์!
