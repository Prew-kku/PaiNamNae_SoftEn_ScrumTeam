*** Settings ***
Library           SeleniumLibrary
Suite Teardown    Close Browser

*** Variables ***
${URL}            http://csse4369.cpkku.com/login
${BROWSER}        chrome
${USER}           driver2@gmail.com
${PASS}           jeng12345678
${PROMPTPAY_NUM}  0895674356

*** Test Cases ***
TC_01_Check_And_Update_PromptPay
    [Documentation]    ทดสอบการเข้าสู่ระบบ ไปที่หน้าข้อมูลรับเงิน และอัปเดต PromptPay ด้วยเบอร์โทรศัพท์
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
    # Step 3: Open User Dropdown
    # ==========================================
    # 1. รอจนกว่า span ชื่อผู้ใช้จะแสดงขึ้นมา
    Wait Until Element Is Visible    xpath=//span[contains(@class, 'font-medium') and contains(@class, 'text-blue-600')]    timeout=10s
    
    # 2. เบรกให้บอทหายใจ 1 วินาที (เพื่อให้ Script ของหน้าเว็บพร้อมรับคำสั่งคลิก)
    Sleep    1s    
    
    # 3. สั่งคลิกไปที่ Element แม่ (Parent) ที่ครอบ span นี้อยู่ (ใส่ /.. ต่อท้าย)
    Click Element                    xpath=//span[contains(@class, 'font-medium') and contains(@class, 'text-blue-600')]/..

    # ==========================================
    # Step 4: Navigate to Profile Page
    # ==========================================
    # 1. รอจนกว่าเมนู "บัญชีของฉัน" จะกางลงมาและมองเห็นได้
    Wait Until Element Is Visible    xpath=//a[@href='/profile' and contains(., 'บัญชีของฉัน')]    timeout=5s
    Sleep    0.5s    # รอให้แอนิเมชัน Dropdown กางจนสุดก่อนกด
    Click Element                    xpath=//a[@href='/profile' and contains(., 'บัญชีของฉัน')]

    # ==========================================
    # Step 5: เลือกเมนู "ข้อมูลการรับเงิน"
    # ==========================================
    Wait Until Element Is Visible    xpath=//a[@href='/profile/payment-info']    timeout=10s
    Click Element                    xpath=//a[@href='/profile/payment-info']

    # ==========================================
    # Step 6: ตรวจสอบการแสดงผลข้อมูลการรับเงิน
    # ==========================================
    Wait Until Element Is Visible    xpath=//input[@placeholder='เบอร์โทรศัพท์ หรือ เลขบัตรประชาชน']    timeout=10s
    Page Should Contain Element      xpath=//input[@placeholder='เบอร์โทรศัพท์ หรือ เลขบัตรประชาชน']
    Page Should Contain Element      xpath=//button[contains(text(), 'บันทึก')]
    Page Should Contain Element      xpath=//button[contains(., 'เพิ่มบัญชี')]

    # ==========================================
    # Step 7: ทดสอบกรอกด้วยเบอร์โทรศัพท์
    # ==========================================
    # ล้างข้อมูลเดิมในช่องกรอก (ถ้ามี) แล้วกรอกเบอร์โทรศัพท์
    Clear Element Text               xpath=//input[@placeholder='เบอร์โทรศัพท์ หรือ เลขบัตรประชาชน']
    Input Text                       xpath=//input[@placeholder='เบอร์โทรศัพท์ หรือ เลขบัตรประชาชน']    ${PROMPTPAY_NUM}
    
    # คลิกปุ่ม "บันทึก"
    Click Element                    xpath=//button[contains(text(), 'บันทึก')]

    # รอจนกว่า Toast Notification (Pop-up แจ้งเตือน) จะแสดงขึ้นมา
    Wait Until Element Is Visible    xpath=//div[contains(@class, 'toast-container')]    timeout=5s
    
    # ตรวจสอบข้อความใน Pop-up ว่าถูกต้องตาม Expected Result
    Element Should Contain           xpath=//div[contains(@class, 'toast-container')]    บันทึกสำเร็จ
    Element Should Contain           xpath=//div[contains(@class, 'toast-container')]    อัปเดตหมายเลข PromptPay แล้ว
    
    Log    การทดสอบสำเร็จ: กรอกเบอร์โทรศัพท์และบันทึกข้อมูล Prompt Pay สำเร็จพร้อมแสดงแจ้งเตือนถูกต้อง