*** Settings ***
Library           SeleniumLibrary
Suite Teardown    Close Browser

*** Variables ***
${URL}            http://csse4369.cpkku.com/login
${BROWSER}        chrome
${ADMIN_USER}     admin_UAT
${ADMIN_PASS}     passadmin

*** Test Cases ***
Admin อนุมัติคำขอลบข้อมูลผู้ใช้
    [Documentation]    UAT-Admin-ProductBacklogItemsNo.16-001: Admin อนุมัติคำขอลบข้อมูลสำเร็จ
    Set Selenium Speed    0.3s

    # ==========================================
    # Step 1-2: Open Website and Login (เข้าสู่ระบบ Admin)
    # ==========================================
    Open Browser    ${URL}    ${BROWSER}
    Maximize Browser Window
    Wait Until Page Contains    เข้าสู่ระบบ    timeout=10s

    Input Text      id=identifier    ${ADMIN_USER}
    Input Text      id=password      ${ADMIN_PASS}
    Click Button    xpath=//button[contains(text(), 'เข้าสู่ระบบ')]
    
    # รอจนกว่าจะเข้าสู่ระบบสำเร็จ (สังเกตจากมุมขวาบนเปลี่ยนเป็นชื่อผู้ใช้)
    Wait Until Element Is Visible    xpath=//span[contains(@class, 'text-blue-600')]    timeout=10s

    # ==========================================
    # Step 3: Navigate to Dashboard (เปิดเมนูผู้ใช้ และไปที่ Dashboard)
    # ==========================================
    Click Element   xpath=//span[contains(@class, 'text-blue-600')]
    
    #  ใช้โค้ดจากที่คุณให้มา: คลิกเมนู Dashboard
    Wait Until Element Is Visible    xpath=//a[contains(., 'Dashboard')]    timeout=5s
    Click Element                    xpath=//a[contains(., 'Dashboard')]
    Sleep    1s

    # ==========================================
    # Step 4: View All Requests (ไปที่หน้า All Request)
    # ==========================================
    #  ใช้โค้ดจากที่คุณให้มา: คลิกเมนูด้านข้าง All Request
    Wait Until Element Is Visible    xpath=//span[contains(text(), 'All Request')]    timeout=10s
    Click Element                    xpath=//span[contains(text(), 'All Request')]
    Sleep    1s

    # ==========================================
    # Step 5: Open Approve Modal (กดปุ่มติ๊กถูกในตาราง)
    # ==========================================
    #  ใช้โค้ดจากที่คุณให้มา: หาไอคอน fa-check
    Wait Until Element Is Visible    xpath=//i[contains(@class, 'fa-check')]    timeout=10s
    Click Element                    xpath=//i[contains(@class, 'fa-check')]
    Sleep    1s

    # ==========================================
    # Step 6: Confirm Approval (กดอนุมัติในหน้าต่าง Modal)
    # ==========================================
    #  ใช้โค้ดจากที่คุณให้มา: กดปุ่ม อนุมัติ
    Wait Until Element Is Visible    xpath=//button[contains(text(), 'อนุมัติ')]    timeout=5s
    Click Button                     xpath=//button[contains(text(), 'อนุมัติ')]

    #  หน่วงเวลา 5 วินาที เพื่อให้คุณมองเห็น Alert แจ้งเตือนการอนุมัติสำเร็จ
    Sleep    5s
    Log    ทดสอบ Admin อนุมัติคำขอลบข้อมูลผู้ใช้สำเร็จ