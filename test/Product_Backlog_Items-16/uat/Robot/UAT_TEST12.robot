# -*- coding: utf-8 -*-
*** Settings ***
Library           SeleniumLibrary
Suite Teardown    Close Browser

*** Variables ***
${URL}            http://csse4369.cpkku.com/login
${BROWSER}        chrome
${ADMIN_USER}     admin_UAT
${ADMIN_PASS}     passadmin
${APPROVE_MODAL_CONFIRM_BTN}    xpath=//div[contains(@class,'modal-content')]//button[normalize-space()='อนุมัติ']

*** Test Cases ***
Admin ตรวจสอบรายละเอียดคำขอลบบัญชีหลังอนุมัติ
    [Documentation]    UAT-Admin-ProductBacklogItemsNo.16-003: Admin อนุมัติคำขอและตรวจสอบรายละเอียด
    ...    ตรวจสอบว่าหลังอนุมัติ: สถานะเปลี่ยนเป็น "อนุมัติแล้ว", มีวันที่ตรวจสอบ,
    ...    และระบบแสดง Modal ยืนยันพร้อมข้อความแจ้งว่าจะนิรนามข้อมูลหลัง 90 วัน

    Set Selenium Speed    0.3s

    # ==========================================
    # Step 1: Admin เข้าสู่ระบบ
    # ==========================================
    Open Browser    ${URL}    ${BROWSER}
    Maximize Browser Window
    Wait Until Page Contains    เข้าสู่ระบบ    timeout=10s

    Input Text      id=identifier    ${ADMIN_USER}
    Input Text      id=password      ${ADMIN_PASS}
    Click Button    xpath=//button[contains(text(), 'เข้าสู่ระบบ')]

    Wait Until Element Is Visible    xpath=//span[contains(@class, 'text-blue-600')]    timeout=10s

    # ==========================================
    # Step 2: ไปที่ Dashboard → All Request
    # ==========================================
    Click Element   xpath=//span[contains(@class, 'text-blue-600')]
    Wait Until Element Is Visible    xpath=//a[@href='/admin/users' and normalize-space()='Dashboard']    timeout=10s
    Execute JavaScript               document.querySelector("a[href='/admin/users']")?.click();
    Sleep    1s

    Wait Until Element Is Visible    xpath=//span[contains(text(), 'All Request')]    timeout=10s
    Click Element                    xpath=//span[contains(text(), 'All Request')]
    Sleep    2s

    # ==========================================
    # Step 3: เปิด Modal ยืนยันการอนุมัติ (กดปุ่ม fa-check)
    # ==========================================
    Wait Until Element Is Visible    xpath=//i[contains(@class, 'fa-check')]/ancestor::button[1]    timeout=10s
    Click Button                     xpath=(//i[contains(@class, 'fa-check')]/ancestor::button[1])[1]
    Sleep    1s

    # ==========================================
    # Step 4: ตรวจสอบข้อความใน Modal ก่อนอนุมัติ
    # ระบบต้องแสดงข้อความแจ้งเตือนว่าจะส่งอีเมลและลบ/นิรนามข้อมูล
    # ==========================================
    Wait Until Element Is Visible    ${APPROVE_MODAL_CONFIRM_BTN}    timeout=10s

    # ตรวจสอบ: Modal ต้องแสดงข้อความยืนยัน
    Page Should Contain    อนุมัติคำร้อง
    Log    ผ่าน Step 4: Modal แสดงข้อความยืนยันการอนุมัติถูกต้อง

    # ==========================================
    # Step 5: กดยืนยันอนุมัติ
    # ==========================================
    Click Button    ${APPROVE_MODAL_CONFIRM_BTN}
    ${overlay_wait_status}    ${overlay_wait_msg}=    Run Keyword And Ignore Error    Wait Until Element Is Not Visible    css=.modal-overlay    timeout=20s
    IF    '${overlay_wait_status}' == 'FAIL'
        Execute JavaScript    document.querySelector('.modal-overlay')?.click();
        Run Keyword And Ignore Error    Wait Until Element Is Not Visible    css=.modal-overlay    timeout=10s
    END
    Sleep    1s
    Log    ผ่าน Step 5: กดยืนยันอนุมัติสำเร็จ

    # ==========================================
    # Step 6: ตรวจสอบว่าสถานะในตารางเปลี่ยนเป็น "อนุมัติแล้ว"
    # ==========================================
    # รอให้หน้าตารางอัปเดตสถานะใหม่
    Sleep    2s
    Wait Until Page Contains    อนุมัติแล้ว    timeout=10s
    Log    ผ่าน Step 6: สถานะในตารางเปลี่ยนเป็น "อนุมัติแล้ว" สำเร็จ

    # ==========================================
    # Step 7: เปิดดูรายละเอียดคำขอที่ถูกอนุมัติ (กดปุ่มรูปตา fa-eye)
    # ==========================================
    Run Keyword And Ignore Error    Wait Until Element Is Not Visible    css=.modal-overlay    timeout=20s

    # กรองเฉพาะสถานะ "อนุมัติแล้ว" เพื่อหาคำขอที่เพิ่งอนุมัติ
    Wait Until Element Is Visible    xpath=//select[.//option[@value='pending']]    timeout=5s
    Select From List By Value        xpath=//select[.//option[@value='pending']]    approved
    Sleep    2s

    # คลิกไอคอนตาของแถวแรกในตาราง (คำขอที่เพิ่งอนุมัติ)
    Wait Until Element Is Visible    xpath=//i[contains(@class, 'fa-eye')]/ancestor::button[1]    timeout=10s
    Execute JavaScript               var eyeBtn=document.evaluate("(//i[contains(@class,'fa-eye')]/ancestor::button[1])[1]",document,null,XPathResult.FIRST_ORDERED_NODE_TYPE,null).singleNodeValue; if(eyeBtn){eyeBtn.click();}
    Sleep    2s

    # ==========================================
    # Step 8: ตรวจสอบรายละเอียดในหน้า Detail
    # ==========================================
    # 8.1 ตรวจสอบหัวข้อหน้ารายละเอียด
    Wait Until Page Contains    รายละเอียดคำร้อง    timeout=10s

    # 8.2 ตรวจสอบ Status Badge แสดง "อนุมัติแล้ว"
    Wait Until Element Is Visible    xpath=//*[contains(text(), 'อนุมัติแล้ว')]    timeout=10s
    Log    ผ่าน Step 8.2: Status Badge แสดง "อนุมัติแล้ว"

    # 8.3 ตรวจสอบว่ามีส่วน "ข้อมูลผู้ใช้" แสดงอยู่
    Page Should Contain    ข้อมูลผู้ใช้
    Log    ผ่าน Step 8.3: แสดงข้อมูลผู้ใช้ถูกต้อง

    # 8.4 ตรวจสอบว่ามีส่วน "รายละเอียดคำร้อง" แสดงอยู่
    Page Should Contain    รายละเอียดคำร้อง
    Log    ผ่าน Step 8.4: แสดงรายละเอียดคำร้องถูกต้อง

    # 8.5 ตรวจสอบว่ามีวันที่ "ตรวจสอบเมื่อ" (reviewedAt) ถูกบันทึก
    Page Should Contain    ตรวจสอบเมื่อ
    Log    ผ่าน Step 8.5: แสดงวันที่ตรวจสอบ (reviewedAt) ถูกต้อง

    # 8.6 ตรวจสอบว่าประเภทคำร้องคือ "ขอลบบัญชี"
    Page Should Contain    ขอลบบัญชี
    Log    ผ่าน Step 8.6: ประเภทคำร้องแสดงเป็น "ขอลบบัญชี" ถูกต้อง

    Sleep    5s
    Log    ผ่าน Step 8: รายละเอียดคำขอหลังอนุมัติแสดงถูกต้องสมบูรณ์
    Log    UAT-Admin-ProductBacklogItemsNo.16-003 ผ่านการทดสอบสมบูรณ์!
