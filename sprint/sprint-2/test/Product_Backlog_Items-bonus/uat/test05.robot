*** Settings ***
Library           SeleniumLibrary
Suite Teardown    Close Browser

*** Variables ***
${URL}            http://csse4369.cpkku.com/login
${BROWSER}        chrome
${USER}           driver2@gmail.com
${PASS}           jeng12345678
${NEW_ACC_NUM}    1234098765
${NEW_ACC_NAME}   สมศรี ใจร้าย

*** Test Cases ***
TC_05_Edit_Bank_Account
    [Documentation]    ทดสอบการแก้ไขข้อมูลบัญชีธนาคาร
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
    # ตัดเงื่อนไขสี text-blue-600 ออก ให้หาแค่ span ที่มี class font-medium
    Wait Until Element Is Visible    xpath=//span[contains(@class, 'font-medium')]/..    timeout=10s
    Sleep    1s
    Click Element                    xpath=//span[contains(@class, 'font-medium')]/..

    # ==========================================
    # Step 4: Navigate to Profile Page
    # ==========================================
    # ค้นหาจากลิงก์ href ที่ไปหน้า /profile อย่างเดียว เผื่อคำว่า 'บัญชีของฉัน' พิมพ์ไม่ตรง
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
    # Step 7: เปิดหน้าต่างแก้ไขบัญชี (คลิกไอคอนดินสอ)
    # ==========================================
    # ใช้คำสั่ง local-name()='svg' เพื่อเจาะจงหาไอคอน และ /.. เพื่อกดตัวที่ครอบมันอยู่
    Wait Until Element Is Visible    xpath=//*[local-name()='svg' and ./*[local-name()='path' and contains(@d, 'M11 5H6')]]    timeout=10s
    Sleep    1s    # เบรกให้หน้าเว็บนิ่งก่อนกด
    Click Element                    xpath=//*[local-name()='svg' and ./*[local-name()='path' and contains(@d, 'M11 5H6')]]/..
    
    # รอให้ Pop-up โชว์ (ช่องกรอกข้อมูลต้องปรากฏขึ้นมา)
    Wait Until Element Is Visible    xpath=//input[@placeholder='เช่น 123-4-56789-0']    timeout=5s
    # ==========================================
    # Step 8: แก้ไขข้อมูล
    # ==========================================
    # 1. แก้ไขเลขบัญชี
    Clear Element Text               xpath=//input[@placeholder='เช่น 123-4-56789-0']
    Input Text                       xpath=//input[@placeholder='เช่น 123-4-56789-0']    ${NEW_ACC_NUM}
    
    # 2. แก้ไขชื่อบัญชี
    Clear Element Text               xpath=//input[@placeholder='ชื่อ-นามสกุล ตามบัญชีธนาคาร']
    Input Text                       xpath=//input[@placeholder='ชื่อ-นามสกุล ตามบัญชีธนาคาร']    ${NEW_ACC_NAME}

    # ==========================================
    # Step 9: บันทึกการแก้ไข
    # ==========================================
    # ล็อกเป้าหาปุ่มที่มีคำว่า "บันทึกการแก้ไข" เป๊ะๆ 
    Wait Until Element Is Visible    xpath=//button[text()='บันทึกการแก้ไข']    timeout=5s
    Sleep    0.5s    # เบรกให้แอนิเมชันของ Pop-up โหลดเสร็จ 100% ป้องกันการชนเงาดำ
    Click Element                    xpath=//button[text()='บันทึกการแก้ไข']

    # ตรวจสอบ Pop-up แจ้งเตือนสีเขียว
    Wait Until Element Is Visible    xpath=//div[contains(@class, 'toast-container')]    timeout=5s
    Element Should Contain           xpath=//div[contains(@class, 'toast-container')]    บันทึกสำเร็จ
    
    Log    การทดสอบสำเร็จ: แก้ไขบัญชีธนาคารเรียบร้อยแล้ว