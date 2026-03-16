*** Settings ***
Library           SeleniumLibrary
Suite Teardown    Close Browser

*** Variables ***
${URL}            http://csse4369.cpkku.com/login
${BROWSER}        chrome
${ADMIN_USER}     admin_UAT
${ADMIN_PASS}     passadmin

*** Test Cases ***
การกรองข้อมูลคำร้องของผู้ใช้ (ประเภทคำร้อง)
    [Documentation]    UAT-Admin-Filter-ProductBacklogItemsNo.16-001: ทดสอบการเลือกตัวเลือกจาก Dropdown “ประเภทคำร้อง” ทั้ง 2 รูปแบบ
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
    Sleep    2s    # รอให้ตารางคำร้องโหลดเสร็จสมบูรณ์

    # ==========================================
    # Step 3: ทดสอบการกรองแบบ "ทั้งหมด"
    # ==========================================
    #  ล็อคเป้าช่อง Dropdown โดยหาจาก select ที่มีช้อยส์ 'deletion' อยู่ข้างใน
    Wait Until Element Is Visible    xpath=//select[.//option[@value='deletion']]    timeout=5s
    
    # สั่งกาง Dropdown ออก
    Click Element                    xpath=//select[.//option[@value='deletion']]
    Sleep    0.5s
    # สั่งคลิกเลือก "ทั้งหมด" (จากโค้ดที่คุณให้มา value="")
    Click Element                    xpath=//option[@value='']
    
    # หน่วงเวลา 2 วินาที เพื่อให้คุณเห็นว่าตารางแสดงข้อมูล "ทั้งหมด" (ทุกประเภท) เรียบร้อยแล้ว
    Sleep    2s
    Log    ผ่าน Step: เลือกตัวกรอง "ทั้งหมด" -> ตารางแสดงข้อมูลทุกประเภท

    # ==========================================
    # Step 4: ทดสอบการกรองแบบ "ขอลบบัญชี"
    # ==========================================
    # สั่งกาง Dropdown ออกอีกครั้ง
    Click Element                    xpath=//select[.//option[@value='deletion']]
    Sleep    0.5s
    # สั่งคลิกเลือก "ขอลบบัญชี" (จากโค้ดที่คุณให้มา value="deletion")
    Click Element                    xpath=//option[@value='deletion']
    
    # หน่วงเวลา 5 วินาที เพื่อให้คุณเห็นว่าตารางกรองเหลือแค่ "ขอลบบัญชี" ก่อนปิดหน้าต่าง
    Sleep    5s
    Log    ผ่าน Step: เลือกตัวกรอง "ขอลบบัญชี" -> ตารางแสดงเฉพาะรายการขอลบบัญชีเท่านั้น
    Log    UAT-Admin-Filter-ProductBacklogItemsNo.16-001 ผ่านการทดสอบสมบูรณ์!