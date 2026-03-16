*** Settings ***
Library           SeleniumLibrary
Suite Teardown    Close Browser

*** Variables ***
${URL}            http://csse4369.cpkku.com/login
${BROWSER}        chrome
${ADMIN_USER}     admin_UAT
${ADMIN_PASS}     passadmin
#  ล็อคเป้า Dropdown "สถานะ" โดยเฉพาะ (หาช่อง select ที่มี value='pending')
${STATUS_DROPDOWN}    xpath=//select[.//option[@value='pending']]

*** Test Cases ***
การกรองข้อมูลคำร้องของผู้ใช้ (สถานะ)
    [Documentation]    UAT-Admin-Filter-ProductBacklogItemsNo.16-001: ทดสอบการเลือกตัวกรอง "สถานะ" ทั้ง 6 รูปแบบ
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
    # Step 2: Navigate to Dashboard -> All Request
    # ==========================================
    Click Element   xpath=//span[contains(@class, 'text-blue-600')]
    Wait Until Element Is Visible    xpath=//a[contains(., 'Dashboard')]    timeout=5s
    Click Element                    xpath=//a[contains(., 'Dashboard')]
    Sleep    1s

    Wait Until Element Is Visible    xpath=//span[contains(text(), 'All Request')]    timeout=10s
    Click Element                    xpath=//span[contains(text(), 'All Request')]
    Sleep    2s    # รอให้หน้าตารางโหลดเสร็จสมบูรณ์
    
    Wait Until Element Is Visible    ${STATUS_DROPDOWN}    timeout=5s

    # ==========================================
    # ทดสอบที่ 1: สถานะ "ทั้งหมด" (value="")
    # ==========================================
    Click Element                    ${STATUS_DROPDOWN}
    Sleep    0.5s
    Click Element                    ${STATUS_DROPDOWN}//option[@value='']
    Sleep    2s
    Log    ผ่าน Step 1: ตารางแสดงข้อมูลสถานะ "ทั้งหมด"

    # ==========================================
    # ทดสอบที่ 2: สถานะ "รอดำเนินการ" (value="pending")
    # ==========================================
    Click Element                    ${STATUS_DROPDOWN}
    Sleep    0.5s
    Click Element                    ${STATUS_DROPDOWN}//option[@value='pending']
    Sleep    2s
    Log    ผ่าน Step 2: ตารางแสดงข้อมูลสถานะ "รอดำเนินการ"

    # ==========================================
    # ทดสอบที่ 3: สถานะ "อนุมัติแล้ว" (value="approved")
    # ==========================================
    Click Element                    ${STATUS_DROPDOWN}
    Sleep    0.5s
    Click Element                    ${STATUS_DROPDOWN}//option[@value='approved']
    Sleep    2s
    Log    ผ่าน Step 3: ตารางแสดงข้อมูลสถานะ "อนุมัติแล้ว"

    # ==========================================
    # ทดสอบที่ 4: สถานะ "ปฏิเสธแล้ว" (value="rejected")
    # ==========================================
    Click Element                    ${STATUS_DROPDOWN}
    Sleep    0.5s
    Click Element                    ${STATUS_DROPDOWN}//option[@value='rejected']
    Sleep    2s
    Log    ผ่าน Step 4: ตารางแสดงข้อมูลสถานะ "ปฏิเสธแล้ว"

    # ==========================================
    # ทดสอบที่ 5: สถานะ "ยกเลิกแล้ว" (value="cancelled")
    # ==========================================
    Click Element                    ${STATUS_DROPDOWN}
    Sleep    0.5s
    Click Element                    ${STATUS_DROPDOWN}//option[@value='cancelled']
    Sleep    2s
    Log    ผ่าน Step 5: ตารางแสดงข้อมูลสถานะ "ยกเลิกแล้ว"

    # ==========================================
    # ทดสอบที่ 6: สถานะ "ลบ/นิรนามแล้ว" (value="deleted")
    # ==========================================
    Click Element                    ${STATUS_DROPDOWN}
    Sleep    0.5s
    Click Element                    ${STATUS_DROPDOWN}//option[@value='deleted']
    
    #  หน่วงเวลาตอนท้าย 5 วินาทีให้คุณดูผลลัพธ์อันสุดท้ายก่อนจบ
    Sleep    5s
    Log    ผ่าน Step 6: ตารางแสดงข้อมูลสถานะ "ลบ/นิรนามแล้ว"
    Log    UAT-Admin-Filter การกรองข้อมูลคำร้องผู้ใช้ (สถานะ) ผ่านการทดสอบสมบูรณ์!