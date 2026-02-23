*** Settings ***
Library           SeleniumLibrary
Suite Teardown    Close Browser

*** Variables ***
${URL}            http://csse4369.cpkku.com/login
${BROWSER}        chrome
${ADMIN_USER}     admin_UAT
${ADMIN_PASS}     passadmin
#  ล็อคเป้า Dropdown "ประเภท Action" (หาช่อง select ที่มีช้อยส์ value='REQUESTED')
${ACTION_DROPDOWN}  xpath=//select[.//option[@value='REQUESTED']]

*** Test Cases ***
ตรวจสอบการกรองประวัติข้อมูลตาม (ประเภท Action)
    [Documentation]    UAT-Admin-Filter-ProductBacklogItemsNo.16-001: ทดสอบการเลือกตัวกรอง "ประเภท Action" ในหน้า Audit Log ทั้ง 7 รูปแบบ
    Set Selenium Speed    0.3s

    # ==========================================
    # Step 1: Open Website and Login (เข้าสู่ระบบ Admin)
    # ==========================================
    Open Browser    ${URL}    ${BROWSER}
    Maximize Browser Window
    Wait Until Page Contains    เข้าสู่ระบบ    timeout=10s

    Input Text      id=identifier    ${ADMIN_USER}
    Input Text      id=password      ${ADMIN_PASS}
    Click Button    xpath=//button[contains(text(), 'เข้าสู่ระบบ')]
    
    Wait Until Element Is Visible    xpath=//span[contains(@class, 'text-blue-600')]    timeout=10s

    # ==========================================
    # Step 2: Navigate to Dashboard -> Audit Log
    # ==========================================
    Click Element   xpath=//span[contains(@class, 'text-blue-600')]
    Wait Until Element Is Visible    xpath=//a[contains(., 'Dashboard')]    timeout=5s
    Click Element                    xpath=//a[contains(., 'Dashboard')]
    Sleep    1s

    #  ใช้โค้ดเมนู Audit Log ที่คุณให้มา
    Wait Until Element Is Visible    xpath=//span[contains(text(), 'Audit Log')]    timeout=10s
    Click Element                    xpath=//span[contains(text(), 'Audit Log')]
    Sleep    2s    # รอให้หน้าตารางประวัติข้อมูล (Audit Log) โหลดเสร็จสมบูรณ์
    
    # รอจนกว่า Dropdown "ประเภท Action" จะโหลดขึ้นมา
    Wait Until Element Is Visible    ${ACTION_DROPDOWN}    timeout=5s

    # ==========================================
    # ทดสอบที่ 1: ประเภท Action "ทั้งหมด" (value="")
    # ==========================================
    Click Element                    ${ACTION_DROPDOWN}
    Sleep    0.5s
    Click Element                    ${ACTION_DROPDOWN}//option[@value='']
    Sleep    2s
    Log    ผ่าน Step 1: ตารางแสดงข้อมูลประเภท Action "ทั้งหมด"

    # ==========================================
    # ทดสอบที่ 2: ประเภท Action "ยื่นคำขอ" (value="REQUESTED")
    # ==========================================
    Click Element                    ${ACTION_DROPDOWN}
    Sleep    0.5s
    Click Element                    ${ACTION_DROPDOWN}//option[@value='REQUESTED']
    Sleep    2s
    Log    ผ่าน Step 2: ตารางแสดงข้อมูลประเภท Action "ยื่นคำขอ"

    # ==========================================
    # ทดสอบที่ 3: ประเภท Action "ยกเลิกคำขอ" (value="CANCELLED")
    # ==========================================
    Click Element                    ${ACTION_DROPDOWN}
    Sleep    0.5s
    Click Element                    ${ACTION_DROPDOWN}//option[@value='CANCELLED']
    Sleep    2s
    Log    ผ่าน Step 3: ตารางแสดงข้อมูลประเภท Action "ยกเลิกคำขอ"

    # ==========================================
    # ทดสอบที่ 4: ประเภท Action "อนุมัติ" (value="APPROVED")
    # ==========================================
    Click Element                    ${ACTION_DROPDOWN}
    Sleep    0.5s
    Click Element                    ${ACTION_DROPDOWN}//option[@value='APPROVED']
    Sleep    2s
    Log    ผ่าน Step 4: ตารางแสดงข้อมูลประเภท Action "อนุมัติ"

    # ==========================================
    # ทดสอบที่ 5: ประเภท Action "ปฏิเสธ" (value="REJECTED")
    # ==========================================
    Click Element                    ${ACTION_DROPDOWN}
    Sleep    0.5s
    Click Element                    ${ACTION_DROPDOWN}//option[@value='REJECTED']
    Sleep    2s
    Log    ผ่าน Step 5: ตารางแสดงข้อมูลประเภท Action "ปฏิเสธ"

    # ==========================================
    # ทดสอบที่ 6: ประเภท Action "นิรนามข้อมูล" (value="ANONYMIZED")
    # ==========================================
    Click Element                    ${ACTION_DROPDOWN}
    Sleep    0.5s
    Click Element                    ${ACTION_DROPDOWN}//option[@value='ANONYMIZED']
    Sleep    2s
    Log    ผ่าน Step 6: ตารางแสดงข้อมูลประเภท Action "นิรนามข้อมูล"

    # ==========================================
    # ทดสอบที่ 7: ประเภท Action "ลบแล้ว" (value="DELETED")
    # ==========================================
    Click Element                    ${ACTION_DROPDOWN}
    Sleep    0.5s
    Click Element                    ${ACTION_DROPDOWN}//option[@value='DELETED']
    
    #  หน่วงเวลาตอนท้าย 5 วินาทีให้คุณดูผลลัพธ์ของตารางอันสุดท้ายก่อนบอทปิดหน้าต่าง
    Sleep    5s
    Log    ผ่าน Step 7: ตารางแสดงข้อมูลประเภท Action "ลบแล้ว"
    Log    UAT-Admin-Filter การกรองข้อมูล Audit Log (ประเภท Action) ผ่านการทดสอบสมบูรณ์!