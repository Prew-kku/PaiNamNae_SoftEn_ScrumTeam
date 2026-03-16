*** Settings ***
Library           SeleniumLibrary
Suite Teardown    Close Browser

*** Variables ***
${URL}            http://csse4369.cpkku.com/login
${BROWSER}        chrome
${USER}           driver2@gmail.com
${PASS}           jeng12345678
${ACC_NUM}        1234567890
${ACC_NAME}       สมชาย สุดหล่อ

*** Test Cases ***
TC_04_Add_Bank_Account_Kasikorn
    [Documentation]    ทดสอบการเพิ่มบัญชีธนาคารกสิกรไทย ในหน้าข้อมูลการรับเงิน
    Set Selenium Speed    0.5s

    # ==========================================
    # Step 1 & 2: Open Website and Login
    # ==========================================
    Open Browser    ${URL}    ${BROWSER}
    Maximize Browser Window
    Wait Until Page Contains    เข้าสู่ระบบ    timeout=10s

    Input Text      id=identifier    ${USER}
    Input Text      id=password      ${PASS}
    Click Element   xpath=//button[@type='submit' and contains(text(), 'เข้าสู่ระบบ')]
    
    # ==========================================
    # Step 3: Open User Dropdown
    # ==========================================
    Wait Until Element Is Visible    xpath=//span[contains(@class, 'font-medium') and contains(@class, 'text-blue-600')]    timeout=10s
    Sleep    1s
    Click Element                    xpath=//span[contains(@class, 'font-medium') and contains(@class, 'text-blue-600')]/..

    # ==========================================
    # Step 4: Navigate to Profile Page
    # ==========================================
    Wait Until Element Is Visible    xpath=//a[@href='/profile' and contains(., 'บัญชีของฉัน')]    timeout=5s
    Sleep    1s
    Click Element                    xpath=//a[@href='/profile' and contains(., 'บัญชีของฉัน')]
    Wait Until Page Contains         ข้อมูลการรับเงิน    timeout=10s
    Sleep    1s

    # ==========================================
    # Step 5: เลือกเมนู "ข้อมูลการรับเงิน"
    # ==========================================
    Wait Until Element Is Visible    xpath=//a[contains(., 'ข้อมูลการรับเงิน')]    timeout=10s
    Click Element                    xpath=//a[contains(., 'ข้อมูลการรับเงิน')]

    # ==========================================
    # Step 6: ตรวจสอบการแสดงผลข้อมูลการรับเงิน
    # ==========================================
    Wait Until Element Is Visible    xpath=//button[contains(., 'เพิ่มบัญชี')]    timeout=10s
    Page Should Contain Element      xpath=//input[@placeholder='เบอร์โทรศัพท์ หรือ เลขบัตรประชาชน']
    Page Should Contain Element      xpath=//button[contains(text(), 'บันทึก')]
    
    # ==========================================
    # Step 7: เปิดหน้าต่างเพิ่มบัญชี
    # ==========================================
    # คลิกปุ่ม "+ เพิ่มบัญชี" (ที่มีเครื่องหมายบวก)
    Click Element                    xpath=//button[contains(., '+ เพิ่มบัญชี') or contains(., 'เพิ่มบัญชี')]
    # รอให้ Pop-up โชว์
    Wait Until Element Is Visible    xpath=//button[.//span[text()='เลือกธนาคาร']]    timeout=5s

    # ==========================================
    # Step 8: เลือกธนาคาร (กสิกรไทย)
    # ==========================================
    # คลิกช่อง "เลือกธนาคาร" ให้ Dropdown กางออก
    Click Element                    xpath=//button[.//span[text()='เลือกธนาคาร']]
    Sleep    0.5s    # รอให้รายชื่อธนาคารกาง
    
    # เลือก "ธนาคารกสิกรไทย"
    Wait Until Element Is Visible    xpath=//button[.//span[text()='ธนาคารกสิกรไทย']]    timeout=5s
    Click Element                    xpath=//button[.//span[text()='ธนาคารกสิกรไทย']]
    
    # ==========================================
    # Step 9: กรอกข้อมูลและบันทึก
    # ==========================================
    # กรอกเลขบัญชี
    Input Text                       xpath=//input[@placeholder='เช่น 123-4-56789-0']    ${ACC_NUM}
    
    # กรอกชื่อบัญชี
    Input Text                       xpath=//input[@placeholder='ชื่อ-นามสกุล ตามบัญชีธนาคาร']    ${ACC_NAME}
    
    # คลิกปุ่ม "เพิ่มบัญชี" (ปุ่มยืนยันใน Pop-up)
    Click Element                    xpath=//button[text()='เพิ่มบัญชี' and contains(@class, 'text-blue-600')]

    # ตรวจสอบ Pop-up แจ้งเตือนสีเขียว
    Wait Until Element Is Visible    xpath=//div[contains(@class, 'toast-container')]    timeout=5s
    
    # เปลี่ยนข้อความให้ตรงกับ Pop-up จริงของระบบ
    Element Should Contain           xpath=//div[contains(@class, 'toast-container')]    เพิ่มสำเร็จ
    Element Should Contain           xpath=//div[contains(@class, 'toast-container')]    เพิ่มบัญชีธนาคารแล้ว
    
    Log    การทดสอบสำเร็จ: เพิ่มบัญชีธนาคารกสิกรไทยเสร็จสมบูรณ์