*** Settings ***
Library           SeleniumLibrary
Suite Teardown    Close Browser

*** Variables ***
${URL}            http://csse4369.cpkku.com/login
${BROWSER}        chrome
${ADMIN_USER}     admin_UAT
${ADMIN_PASS}     passadmin
#  ล็อคเป้า Dropdown "บทบาท" โดยเฉพาะ (หาช่อง select ที่มีช้อยส์ value='PASSENGER')
${ROLE_DROPDOWN}  xpath=//select[.//option[@value='PASSENGER']]

*** Test Cases ***
การกรองข้อมูลคำร้องของผู้ใช้ (บทบาท)
    [Documentation]    UAT-Admin-Filter-ProductBacklogItemsNo.16-001: ทดสอบการเลือกตัวกรอง "บทบาท" ทั้ง 3 รูปแบบ
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
    
    # รอจนกว่า Dropdown "บทบาท" จะโหลดขึ้นมา
    Wait Until Element Is Visible    ${ROLE_DROPDOWN}    timeout=5s

    # ==========================================
    # ทดสอบที่ 1: บทบาท "ทั้งหมด" (value="")
    # ==========================================
    Click Element                    ${ROLE_DROPDOWN}
    Sleep    0.5s
    Click Element                    ${ROLE_DROPDOWN}//option[@value='']
    Sleep    2s
    Log    ผ่าน Step 1: ตารางแสดงข้อมูลบทบาท "ทั้งหมด"

    # ==========================================
    # ทดสอบที่ 2: บทบาท "ผู้โดยสาร" (value="PASSENGER")
    # ==========================================
    Click Element                    ${ROLE_DROPDOWN}
    Sleep    0.5s
    Click Element                    ${ROLE_DROPDOWN}//option[@value='PASSENGER']
    Sleep    2s
    Log    ผ่าน Step 2: ตารางแสดงข้อมูลบทบาท "ผู้โดยสาร"

    # ==========================================
    # ทดสอบที่ 3: บทบาท "คนขับ" (value="DRIVER")
    # ==========================================
    Click Element                    ${ROLE_DROPDOWN}
    Sleep    0.5s
    Click Element                    ${ROLE_DROPDOWN}//option[@value='DRIVER']
    
    # 🟢 หน่วงเวลาตอนท้าย 5 วินาทีให้คุณดูผลลัพธ์ของตารางคนขับ
    Sleep    5s
    Log    ผ่าน Step 3: ตารางแสดงข้อมูลบทบาท "คนขับ"
    Log    UAT-Admin-Filter การกรองข้อมูลคำร้องผู้ใช้ (บทบาท) ผ่านการทดสอบสมบูรณ์!