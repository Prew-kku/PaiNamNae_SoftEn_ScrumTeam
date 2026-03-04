*** Settings ***
Library           SeleniumLibrary
Suite Teardown    Close Browser

*** Variables ***
${URL}            http://csse4369.cpkku.com/login
${BROWSER}        chrome
${USER}           driver2@gmail.com
${PASS}           jeng12345678

*** Test Cases ***
TC_06_Delete_Bank_Account
    [Documentation]    ทดสอบการลบบัญชีธนาคาร
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
    Wait Until Element Is Visible    xpath=//span[contains(@class, 'font-medium')]/..    timeout=10s
    Sleep    1s
    Click Element                    xpath=//span[contains(@class, 'font-medium')]/..

    # ==========================================
    # Step 4: Navigate to Profile Page
    # ==========================================
    Wait Until Element Is Visible    xpath=//a[contains(@href, '/profile')]    timeout=5s
    Sleep    1s
    Click Element                    xpath=//a[contains(@href, '/profile')]
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
    
    # ==========================================
    # Step 7: เปิดหน้าต่างยืนยันการลบ (คลิกไอคอนถังขยะ)
    # ==========================================
    # ใช้ local-name()='svg' จับรูปถังขยะตัวแรกในรายการบัญชี
    Wait Until Element Is Visible    xpath=(//*[local-name()='svg' and ./*[local-name()='path' and contains(@d, 'M19 7l')]])[1]/..    timeout=10s
    Sleep    1s    # เบรกให้หน้าเว็บนิ่งก่อนกด
    Click Element                    xpath=(//*[local-name()='svg' and ./*[local-name()='path' and contains(@d, 'M19 7l')]])[1]/..
    
    # รอให้ Pop-up ยืนยันแสดงขึ้นมา
    Wait Until Page Contains         คุณต้องการลบบัญชีนี้ใช่หรือไม่    timeout=5s

    # ==========================================
    # Step 8: ยืนยันการลบบัญชี (ใน Pop-up)
    # ==========================================
    # ล็อกเป้าหาปุ่มลบใน Pop-up (ใช้ text 'ลบ' หรือหา SVG ถังขยะตัวล่าสุด)
    Wait Until Element Is Visible    xpath=(//button[contains(., 'ลบ') or .//*[local-name()='svg' and ./*[local-name()='path' and contains(@d, 'M19 7l')]]])[last()]    timeout=5s
    Sleep    0.5s    # รอแอนิเมชัน Pop-up โหลดเสร็จ ป้องกันการชนเงาดำ modal-overlay
    Click Element                    xpath=(//button[contains(., 'ลบ') or .//*[local-name()='svg' and ./*[local-name()='path' and contains(@d, 'M19 7l')]]])[last()]

    # ตรวจสอบ Pop-up แจ้งเตือนสีเขียว
    Wait Until Element Is Visible    xpath=//div[contains(@class, 'toast-container')]    timeout=5s
    
    # ดักจับข้อความแจ้งเตือน (ปรับแก้ข้อความตาม Pop-up จริงของระบบได้เลยครับ)
    Element Should Contain           xpath=//div[contains(@class, 'toast-container')]    ลบสำเร็จ
    Element Should Contain           xpath=//div[contains(@class, 'toast-container')]    ลบบัญชีธนาคารแล้ว
    
    Log    การทดสอบสำเร็จ: ลบบัญชีธนาคารเรียบร้อยแล้ว