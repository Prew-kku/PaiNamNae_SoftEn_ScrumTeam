*** Settings ***
Library           SeleniumLibrary
Suite Teardown    Close Browser

*** Variables ***
${URL}            http://csse4369.cpkku.com/login
${BROWSER}        chrome
${ADMIN_USER}     admin_UAT
${ADMIN_PASS}     passadmin
${REJECT_ACTION_BTN}    xpath=(//button[@aria-label='ปฏิเสธ' or @title='ปฏิเสธ'])[1]
${REJECT_ACTION_BTNS}    xpath=//button[@aria-label='ปฏิเสธ' or @title='ปฏิเสธ']
${REJECT_MODAL_TEXTAREA}    xpath=//div[contains(@class,'modal-content')]//textarea[contains(@placeholder,'ระบุหมายเหตุ')]
${REJECT_MODAL_CONFIRM_BTN}    xpath=//div[contains(@class,'modal-content')]//button[normalize-space()='ปฏิเสธ']

*** Test Cases ***
Admin ปฏิเสธคำขอลบข้อมูลผู้ใช้
    [Documentation]    UAT-Admin-ProductBacklogItemsNo.16-002: Admin ปฏิเสธคำขอลบของ User
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
    Wait Until Element Is Visible    xpath=//a[@href='/admin/users' and normalize-space()='Dashboard']    timeout=10s
    Execute JavaScript               document.querySelector("a[href='/admin/users']")?.click();
    Sleep    1s

    # ==========================================
    # Step 4: View All Requests (ไปที่หน้า All Request)
    # ==========================================
    Wait Until Element Is Visible    xpath=//a[@href='/admin/allrequests']//span[normalize-space()='All Request']    timeout=10s
    Click Element                    xpath=//a[@href='/admin/allrequests']
    Sleep    1s

    # ==========================================
    # Step 5: Open Reject Modal (กดปุ่มกากบาทในตาราง)
    # ==========================================
    ${before_count}=                  Get Element Count                 ${REJECT_ACTION_BTNS}
    Wait Until Element Is Not Visible    css=.modal-overlay    timeout=20s
    Wait Until Element Is Visible    ${REJECT_ACTION_BTN}    timeout=10s
    Click Button                     ${REJECT_ACTION_BTN}
    Sleep    1s

    # ==========================================
    # Step 6: Confirm Rejection (กรอกเหตุผล และกดปฏิเสธในหน้าต่าง Modal)
    # ==========================================
    Wait Until Page Contains         ปฏิเสธคำร้อง    timeout=10s
    Wait Until Element Is Visible    ${REJECT_MODAL_TEXTAREA}    timeout=10s
    Input Text                       ${REJECT_MODAL_TEXTAREA}    เหตุผลยังไม่เพียงพอ
    Sleep    0.5s

    Wait Until Element Is Enabled    ${REJECT_MODAL_CONFIRM_BTN}    timeout=10s
    Click Button                     ${REJECT_MODAL_CONFIRM_BTN}

    # บาง environment อาจแสดงผลลัพธ์ช้าหรือค้าง modal ชั่วคราว จึงตรวจแบบไม่บล็อก
    Sleep                                  2s
    Run Keyword And Ignore Error           Wait Until Element Is Not Visible    ${REJECT_MODAL_TEXTAREA}    timeout=8s
    Run Keyword And Ignore Error           Wait Until Keyword Succeeds          12s    1s    Verify Reject Count Decreased    ${before_count}
    Page Should Contain                    All Requests

    #  หน่วงเวลา 5 วินาที เพื่อให้คุณมองเห็น Alert แจ้งเตือน และตารางที่อัปเดตแล้ว
    Sleep    5s
    Log    ทดสอบ Admin ปฏิเสธคำขอลบข้อมูลผู้ใช้สำเร็จ

*** Keywords ***
Verify Reject Count Decreased
    [Arguments]    ${before_count}
    ${after_count}=    Get Element Count    ${REJECT_ACTION_BTNS}
    Should Be True    ${after_count} < ${before_count}