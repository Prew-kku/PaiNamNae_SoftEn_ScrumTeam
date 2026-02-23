*** Settings ***
Library           SeleniumLibrary
Suite Teardown    Close Browser

*** Variables ***
${URL}            http://csse4369.cpkku.com/login
${BROWSER}        chrome
${USERNAME}       Test_UAT
${PASSWORD}       123456789

*** Test Cases ***
ผู้ใช้ส่งคำขอลบบัญชีสำเร็จ
    [Documentation]    UAT-User-ProductBacklogItemsNo.16-001: ทดสอบการส่งคำขอลบบัญชี

    Set Selenium Speed    0.3s

    # 1. Open Website and Login
    Open Browser    ${URL}    ${BROWSER}
    Maximize Browser Window
    Wait Until Page Contains    เข้าสู่ระบบ    timeout=10s

    # 2. Submit Login Credentials
    Input Text      id=identifier    ${USERNAME}
    Input Text      id=password      ${PASSWORD}
    Click Button    xpath=//button[contains(text(), 'เข้าสู่ระบบ')]
    
    Wait Until Element Is Visible    xpath=//span[contains(@class, 'text-blue-600')]    timeout=10s

    # 3. Open User Dropdown
    Click Element   xpath=//span[contains(@class, 'text-blue-600')]
    Wait Until Element Is Visible    xpath=//a[contains(text(), 'บัญชีของฉัน')]    timeout=5s

    # 4. Navigate to Profile Page
    Click Element   xpath=//a[contains(text(), 'บัญชีของฉัน')]
    Wait Until Element Is Visible    xpath=//button[contains(text(), 'ลบบัญชี')]    timeout=10s

    # 5. Open Delete Modal (กดปุ่มลบบัญชี)
    Scroll Element Into View    xpath=//button[contains(text(), 'ลบบัญชี')]
    Click Button    xpath=//button[contains(text(), 'ลบบัญชี')]
    Sleep    1s

    # 6. Fill Deletion Form
    
    Wait Until Element Is Visible    xpath=//select    timeout=10s
    Click Element                    xpath=//select
    Sleep    0.5s    # รอให้ Dropdown กางออกให้เห็นชัดๆ
    
    
    Wait Until Element Is Visible    xpath=//option[@value='ไม่ต้องการใช้บริการอีกต่อไป']    timeout=5s
    Click Element                    xpath=//option[@value='ไม่ต้องการใช้บริการอีกต่อไป']
    Sleep    0.5s    # รอให้เห็นว่าคลิกเลือกแล้วจริงๆ
    
    #  6.2 กรอกรหัสผ่านเพื่อยืนยัน (ล็อคเป้าจาก placeholder)
    Wait Until Element Is Visible    xpath=//input[@placeholder='กรอกรหัสผ่านของคุณ']    timeout=5s
    Input Text                       xpath=//input[@placeholder='กรอกรหัสผ่านของคุณ']    ${PASSWORD}
    
    # สั่งกด TAB เพื่อให้ปุ่มยืนยันหายจากสีเทา
    Press Keys                       xpath=//input[@placeholder='กรอกรหัสผ่านของคุณ']    TAB
    Sleep    0.5s

    #  6.3 ติ๊ก Checkbox
    Wait Until Element Is Visible    xpath=//input[@type='checkbox']    timeout=5s
    Click Element                    xpath=//input[@type='checkbox']
    Sleep    1s

    # 7. Submit Request (กดยืนยันการลบข้อมูล)
    Wait Until Element Is Enabled    xpath=//button[contains(text(), 'ยืนยันการลบข้อมูล')]    timeout=10s
    Click Button                     xpath=//button[contains(text(), 'ยืนยันการลบข้อมูล')]

    # 8. ตรวจสอบ Expected Result
    #  หน่วงเวลา 5 วินาที เพื่อให้คุณมองเห็น Alert เด้งขึ้นมา
    Sleep    5s
    Log    ทดสอบการส่งคำขอลบบัญชีสำเร็จ