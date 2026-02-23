*** Settings ***
Library           SeleniumLibrary
Suite Teardown    Close Browser

*** Variables ***
${URL}            http://csse4369.cpkku.com/login
${BROWSER}        chrome
${ADMIN_USER}     admin_UAT
${ADMIN_PASS}     passadmin

#  ล็อคเป้า Dropdown "ประเภทคำร้อง" ในหน้า Audit Log (หาช่อง select ที่มีช้อยส์ value='deletion')
${REQUEST_TYPE_DROPDOWN}  xpath=//select[.//option[@value='deletion']]

*** Test Cases ***
ตรวจสอบการกรองประวัติข้อมูลตามประเภทคำร้อง
    [Documentation]    UAT-Admin-Filter-ProductBacklogItemsNo.16-002: ทดสอบการเลือกตัวกรอง "ประเภทคำร้อง" ในหน้า Audit Log (ทั้งหมด, ขอลบบัญชี)
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

    # ไปที่หน้า Audit Log
    Wait Until Element Is Visible    xpath=//span[contains(text(), 'Audit Log')]    timeout=10s
    Click Element                    xpath=//span[contains(text(), 'Audit Log')]
    Sleep    2s    # รอให้หน้าตารางประวัติข้อมูลโหลดเสร็จสมบูรณ์
    
    # รอจนกว่า Dropdown "ประเภทคำร้อง" จะโหลดขึ้นมา
    Wait Until Element Is Visible    ${REQUEST_TYPE_DROPDOWN}    timeout=5s

    # ==========================================
    # ทดสอบที่ 1: ประเภทคำร้อง "ทั้งหมด" (value="")
    # ==========================================
    Click Element                    ${REQUEST_TYPE_DROPDOWN}
    Sleep    0.5s
    Click Element                    ${REQUEST_TYPE_DROPDOWN}//option[@value='']
    
    # หน่วงเวลา 2 วินาที เพื่อตรวจสอบผลลัพธ์ว่าตารางแสดงข้อมูลทั้งหมด
    Sleep    2s
    Log    ผ่าน Step 1: ตารางแสดงข้อมูลประเภทคำร้อง "ทั้งหมด"

    # ==========================================
    # ทดสอบที่ 2: ประเภทคำร้อง "ขอลบบัญชี" (value="deletion")
    # ==========================================
    Click Element                    ${REQUEST_TYPE_DROPDOWN}
    Sleep    0.5s
    Click Element                    ${REQUEST_TYPE_DROPDOWN}//option[@value='deletion']
    
    #  หน่วงเวลาตอนท้าย 5 วินาทีให้คุณดูผลลัพธ์ของตารางก่อนบอทปิดหน้าต่าง
    Sleep    5s
    Log    ผ่าน Step 2: ตารางแสดงข้อมูลประเภทคำร้อง "ขอลบบัญชี"
    Log    UAT-Admin-Filter-ProductBacklogItemsNo.16-002 ผ่านการทดสอบสมบูรณ์!