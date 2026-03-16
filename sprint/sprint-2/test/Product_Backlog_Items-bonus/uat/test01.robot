*** Settings ***
Library           SeleniumLibrary
Suite Teardown    Close Browser

*** Variables ***
${URL}            http://csse4369.cpkku.com/login
${BROWSER}        chrome
${USER}           driver2@gmail.com
${PASS}           jeng12345678

*** Test Cases ***
TC_01_Check_Payment_Information_Page
    [Documentation]    ทดสอบการเข้าสู่ระบบและนำทางไปตรวจสอบหน้าข้อมูลการรับเงิน
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
    # รอจนกว่าจะ Login สำเร็จและแสดงชื่อ User มุมขวาบน
    Wait Until Element Is Visible    xpath=//span[contains(@class, 'font-medium') and contains(@class, 'text-blue-600')]    timeout=10s
    Click Element                    xpath=//span[contains(@class, 'font-medium') and contains(@class, 'text-blue-600')]

    # ==========================================
    # Step 4: Navigate to Profile Page (บัญชีของฉัน)
    # ==========================================
    Wait Until Element Is Visible    xpath=//a[@href='/profile' and contains(., 'บัญชีของฉัน')]    timeout=5s
    Click Element                    xpath=//a[@href='/profile' and contains(., 'บัญชีของฉัน')]

    # ==========================================
    # Step 5: เลือกเมนู "ข้อมูลการรับเงิน"
    # ==========================================
    Wait Until Element Is Visible    xpath=//a[@href='/profile/payment-info']    timeout=10s
    Click Element                    xpath=//a[@href='/profile/payment-info']

    # ==========================================
    # Step 6: ตรวจสอบการแสดงผลข้อมูลการรับเงิน
    # ==========================================
    # 1. ตรวจสอบช่องกรอก PromptPay
    Wait Until Element Is Visible    xpath=//input[@placeholder='เบอร์โทรศัพท์ หรือ เลขบัตรประชาชน']    timeout=10s
    Page Should Contain Element      xpath=//input[@placeholder='เบอร์โทรศัพท์ หรือ เลขบัตรประชาชน']
    
    # 2. ตรวจสอบปุ่ม "บันทึก" ของ PromptPay
    Page Should Contain Element      xpath=//button[contains(text(), 'บันทึก')]
    
    # 3. ตรวจสอบปุ่ม "+ เพิ่มบัญชี"
    Page Should Contain Element      xpath=//button[contains(., 'เพิ่มบัญชี')]

    Log    ตรวจสอบหน้าข้อมูลการรับเงินสำเร็จ: แสดงช่อง PromptPay และปุ่มเพิ่มบัญชีครบถ้วน