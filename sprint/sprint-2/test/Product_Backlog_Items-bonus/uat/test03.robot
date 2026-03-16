*** Settings ***
Library           SeleniumLibrary
Suite Teardown    Close Browser

*** Variables ***
${URL}            http://csse4369.cpkku.com/login    
${BROWSER}        chrome
${USER}           driver2@gmail.com
${PASS}           jeng12345678
${PROMPTPAY_ID}   1399933475839                      # ตัวแปรเลขบัตรประชาชน 13 หลัก

*** Test Cases ***
TC_02_Update_PromptPay_With_National_ID
    [Documentation]    ทดสอบการอัปเดต PromptPay ด้วยเลขบัตรประชาชน 13 หลัก
    Set Selenium Speed    0.5s

    # ==========================================
    # Step 1 & 2: Open Website and Submit Login Credentials
    # ==========================================
    Open Browser    ${URL}    ${BROWSER}
    Maximize Browser Window
    Wait Until Page Contains    เข้าสู่ระบบ    timeout=10s

    Input Text      id=identifier    ${USER}
    Input Text      id=password      ${PASS}
    Click Element   xpath=//button[@type='submit' and contains(text(), 'เข้าสู่ระบบ')]
    
    # ==========================================
    # Step 3: Open User Dropdown (ใส่เทคนิคแก้ปัญหากดไม่ลง)
    # ==========================================
    Wait Until Element Is Visible    xpath=//span[contains(@class, 'font-medium') and contains(@class, 'text-blue-600')]    timeout=10s
    Sleep    1s    # เบรกให้สคริปต์หน้าเว็บพร้อมทำงาน
    Click Element                    xpath=//span[contains(@class, 'font-medium') and contains(@class, 'text-blue-600')]/..

    # ==========================================
    # Step 4: Navigate to Profile Page
    # ==========================================
    Wait Until Element Is Visible    xpath=//a[@href='/profile' and contains(., 'บัญชีของฉัน')]    timeout=5s
    Sleep    1s  # รอให้ Dropdown กางลงมาสุดก่อน
    Click Element                    xpath=//a[@href='/profile' and contains(., 'บัญชีของฉัน')]

    
    # โดยรอจนกว่าจะมีคำว่า "โหมดผู้ขับขี่" หรือ "ข้อมูลการรับเงิน" โผล่มาบนหน้าเว็บ
    Wait Until Page Contains         ข้อมูลการรับเงิน    timeout=10s
    Sleep    1s  # เบรกหายใจอีกนิดให้ปุ่มพร้อมกด

    # ==========================================
    # Step 5: เลือกเมนู "ข้อมูลการรับเงิน"
    # ==========================================
    
    Wait Until Element Is Visible    xpath=//a[contains(., 'ข้อมูลการรับเงิน')]    timeout=10s
    Click Element                    xpath=//a[contains(., 'ข้อมูลการรับเงิน')]

    # ==========================================
    # Step 6: ตรวจสอบการแสดงผลข้อมูลการรับเงิน
    # ==========================================
    Wait Until Element Is Visible    xpath=//input[@placeholder='เบอร์โทรศัพท์ หรือ เลขบัตรประชาชน']    timeout=10s
    Page Should Contain Element      xpath=//input[@placeholder='เบอร์โทรศัพท์ หรือ เลขบัตรประชาชน']
    Page Should Contain Element      xpath=//button[contains(text(), 'บันทึก')]
    Page Should Contain Element      xpath=//button[contains(., 'เพิ่มบัญชี')]

    # ==========================================
    # Step 7: ทดสอบกรอกด้วยเลขบัตรประชาชน 13 หลัก
    # ==========================================
    # ล้างข้อมูลเดิมในช่องกรอก (ถ้ามี) แล้วกรอกเลขบัตรประชาชน
    Clear Element Text               xpath=//input[@placeholder='เบอร์โทรศัพท์ หรือ เลขบัตรประชาชน']
    Input Text                       xpath=//input[@placeholder='เบอร์โทรศัพท์ หรือ เลขบัตรประชาชน']    ${PROMPTPAY_ID}
    
    # คลิกปุ่ม "บันทึก"
    Click Element                    xpath=//button[contains(text(), 'บันทึก')]

    # รอจนกว่า Toast Notification (Pop-up แจ้งเตือนสีเขียว) จะแสดงขึ้นมา
    Wait Until Element Is Visible    xpath=//div[contains(@class, 'toast-container')]    timeout=5s
    
    # ตรวจสอบข้อความใน Pop-up ว่าถูกต้องตาม Expected Result
    Element Should Contain           xpath=//div[contains(@class, 'toast-container')]    บันทึกสำเร็จ
    Element Should Contain           xpath=//div[contains(@class, 'toast-container')]    อัปเดตหมายเลข PromptPay แล้ว
    
    Log    การทดสอบสำเร็จ: กรอกเลขบัตรประชาชนและบันทึกข้อมูล Prompt Pay สำเร็จพร้อมแสดงแจ้งเตือนถูกต้อง