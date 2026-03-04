# -*- coding: utf-8 -*-
*** Settings ***
Documentation     UAT-TEST13: ยื่นลบบัญชี + อนุมัติแบบคลิกหน้าเว็บ แล้วทดสอบ cron 90 วันด้วย fast-forward
Library           SeleniumLibrary
Library           RequestsLibrary
Library           Collections
Suite Teardown    Close All Browsers

*** Variables ***
${WEB_URL}          http://csse4369.cpkku.com/login
${BASE_URL}         https://painamnaesoftenscrumteam-production.up.railway.app
${BROWSER}          chrome
${TEST_USERNAME}    Test12
${TEST_PASSWORD}    Isaac1234
${ADMIN_USERNAME}   admin_UAT
${ADMIN_PASS}       passadmin

*** Test Cases ***
Test Cronjob 90 Days By Click UI + API Trigger
    [Documentation]    User ยื่นคำขอผ่าน UI -> Admin อนุมัติผ่าน UI -> fast-forward + trigger cron ผ่าน API -> ตรวจ DELETED + audit
    Disable Insecure HTTPS Warning

    Log To Console    [STEP] User submits deletion request via UI
    User Submit Deletion Request Via UI

    Log To Console    [STEP] Admin approves deletion request via UI
    Admin Approve Deletion Request Via UI

    Log To Console    [STEP] Create API sessions and load latest approved request
    Create Api Sessions
    ${request_id}=    Get Latest Request Id By User    APPROVED
    Log To Console    [STEP] Request id: ${request_id}

    Log To Console    [STEP] Fast-forward request to >90 days
    ${ff_resp}=    PUT On Session    backend    /api/test/cron/fast-forward/${request_id}
    Should Be Equal As Integers    ${ff_resp.status_code}    200

    Log To Console    [STEP] Trigger cron and verify DELETED
    Wait Until Keyword Succeeds    45 sec    5 sec    Trigger Cron And Request Should Become Deleted    ${request_id}

    Log To Console    [STEP] Verify audit trail contains anonymization/deletion
    Wait Until Keyword Succeeds    20 sec    5 sec    Request Should Have Deletion Audit    ${request_id}
    Log To Console    [DONE] Cron 90-day UI+API test passed

*** Keywords ***
Disable Insecure HTTPS Warning
    Evaluate    __import__('urllib3').disable_warnings(__import__('urllib3').exceptions.InsecureRequestWarning)

User Submit Deletion Request Via UI
    Open Browser    ${WEB_URL}    ${BROWSER}
    Maximize Browser Window
    Wait Until Page Contains    เข้าสู่ระบบ    timeout=10s

    Input Text      id=identifier    ${TEST_USERNAME}
    Input Text      id=password      ${TEST_PASSWORD}
    Click Button    xpath=//button[contains(text(), 'เข้าสู่ระบบ')]
    Wait Until Element Is Visible    xpath=//span[contains(@class, 'text-blue-600')]    timeout=10s

    Click Element   xpath=//span[contains(@class, 'text-blue-600')]
    Wait Until Element Is Visible    xpath=//a[contains(text(), 'บัญชีของฉัน')]    timeout=5s
    Click Element   xpath=//a[contains(text(), 'บัญชีของฉัน')]
    Wait Until Element Is Visible    xpath=//button[contains(text(), 'ลบบัญชี')]    timeout=10s

    Scroll Element Into View    xpath=//button[contains(text(), 'ลบบัญชี')]
    Click Button    xpath=//button[contains(text(), 'ลบบัญชี')]
    Sleep    1s

    Wait Until Element Is Visible    xpath=//select    timeout=10s
    Click Element                    xpath=//select
    Sleep    0.5s
    Wait Until Element Is Visible    xpath=//option[@value='ไม่ต้องการใช้บริการอีกต่อไป']    timeout=5s
    Click Element                    xpath=//option[@value='ไม่ต้องการใช้บริการอีกต่อไป']
    Sleep    0.5s

    Wait Until Element Is Visible    xpath=//input[@placeholder='กรอกรหัสผ่านของคุณ']    timeout=5s
    Input Text                       xpath=//input[@placeholder='กรอกรหัสผ่านของคุณ']    ${TEST_PASSWORD}
    Press Keys                       xpath=//input[@placeholder='กรอกรหัสผ่านของคุณ']    TAB
    Sleep    0.5s

    Wait Until Element Is Visible    xpath=//input[@type='checkbox']    timeout=5s
    Click Element                    xpath=//input[@type='checkbox']
    Sleep    1s

    Wait Until Element Is Enabled    xpath=//button[contains(text(), 'ยืนยันการลบข้อมูล')]    timeout=10s
    Click Button                     xpath=//button[contains(text(), 'ยืนยันการลบข้อมูล')]

    Sleep    4s
    Wait Until Page Contains    เข้าสู่ระบบ    timeout=15s
    Close Browser

Admin Approve Deletion Request Via UI
    Open Browser    ${WEB_URL}    ${BROWSER}
    Maximize Browser Window
    Wait Until Page Contains    เข้าสู่ระบบ    timeout=10s

    Input Text      id=identifier    ${ADMIN_USERNAME}
    Input Text      id=password      ${ADMIN_PASS}
    Click Button    xpath=//button[contains(text(), 'เข้าสู่ระบบ')]
    Wait Until Element Is Visible    xpath=//span[contains(@class, 'text-blue-600')]    timeout=10s

    Click Element   xpath=//span[contains(@class, 'text-blue-600')]
    Wait Until Element Is Visible    xpath=//a[@href='/admin/users' and normalize-space()='Dashboard']    timeout=10s
    Execute JavaScript               document.querySelector("a[href='/admin/users']")?.click();
    Sleep    1s

    Wait Until Element Is Visible    xpath=//a[@href='/admin/allrequests']//span[normalize-space()='All Request']    timeout=10s
    Click Element                    xpath=//a[@href='/admin/allrequests']
    Sleep    2s

    Wait Until Element Is Not Visible    css=.modal-overlay    timeout=10s
    Wait Until Element Is Visible    xpath=//i[contains(@class, 'fa-check')]/ancestor::button[1]    timeout=10s
    Click Button                     xpath=(//i[contains(@class, 'fa-check')]/ancestor::button[1])[1]
    Sleep    1s

    Wait Until Element Is Visible    xpath=//div[contains(@class,'modal-content')]//button[normalize-space()='อนุมัติ']    timeout=10s
    Click Button                     xpath=//div[contains(@class,'modal-content')]//button[normalize-space()='อนุมัติ']
    Run Keyword And Ignore Error     Wait Until Element Is Not Visible    css=.modal-overlay    timeout=20s
    Sleep    1s

    Wait Until Page Contains    อนุมัติแล้ว    timeout=10s
    Close Browser

Create Api Sessions
    Create Session    backend    ${BASE_URL}    verify=${False}    timeout=10

    ${user_login_payload}=    Create Dictionary    username=${TEST_USERNAME}    password=${TEST_PASSWORD}
    ${user_login}=    POST On Session    backend    /api/auth/login    json=${user_login_payload}
    Should Be Equal As Integers    ${user_login.status_code}    200
    ${user_login_json}=    Evaluate    $user_login.json()
    ${user_token}=    Set Variable    ${user_login_json['data']['token']}

    ${admin_login_payload}=    Create Dictionary    username=${ADMIN_USERNAME}    password=${ADMIN_PASS}
    ${admin_login}=    POST On Session    backend    /api/auth/login    json=${admin_login_payload}
    Should Be Equal As Integers    ${admin_login.status_code}    200
    ${admin_login_json}=    Evaluate    $admin_login.json()
    ${admin_token}=    Set Variable    ${admin_login_json['data']['token']}

    ${user_headers}=    Create Dictionary    Authorization=Bearer ${user_token}    Content-Type=application/json
    ${admin_headers}=    Create Dictionary    Authorization=Bearer ${admin_token}    Content-Type=application/json
    Create Session    user_api     ${BASE_URL}    headers=${user_headers}    verify=${False}    timeout=10
    Create Session    admin_api    ${BASE_URL}    headers=${admin_headers}    verify=${False}    timeout=10

Get Latest Request Id By User
    [Arguments]    ${status}=APPROVED
    ${query_params}=    Create Dictionary    status=${status}    q=${TEST_USERNAME}
    ${list_resp}=    GET On Session    admin_api    /api/deletion/admin/requests    params=${query_params}
    Should Be Equal As Integers    ${list_resp.status_code}    200
    ${list_json}=    Evaluate    $list_resp.json()
    ${requests}=    Set Variable    ${list_json['data']}
    ${request_count}=    Get Length    ${requests}
    Should Be True    ${request_count} > 0
    ${request_id}=    Evaluate    $requests[0]['id']
    RETURN    ${request_id}

Trigger Cron And Request Should Become Deleted
    [Arguments]    ${request_id}
    ${cron_call_status}    ${cron_call_result}=    Run Keyword And Ignore Error    POST On Session    backend    /api/test/cron/deletion    expected_status=any
    Log    Cron trigger result: ${cron_call_status}
    ${detail_resp}=    GET On Session    admin_api    /api/deletion/admin/requests/${request_id}
    Should Be Equal As Integers    ${detail_resp.status_code}    200
    ${detail_json}=    Evaluate    $detail_resp.json()
    Should Be Equal As Strings    ${detail_json['status']}    DELETED

Request Should Have Deletion Audit
    [Arguments]    ${request_id}
    ${detail_resp}=    GET On Session    admin_api    /api/deletion/admin/requests/${request_id}
    Should Be Equal As Integers    ${detail_resp.status_code}    200
    ${detail_json}=    Evaluate    $detail_resp.json()
    ${audits}=    Set Variable    ${detail_json['audits']}
    ${audit_count}=    Get Length    ${audits}
    Should Be True    ${audit_count} > 0
    ${has_deleted_or_anonymized}=    Evaluate    any(a.get('status') in ['ANONYMIZED', 'DELETED'] for a in $audits)
    Should Be True    ${has_deleted_or_anonymized}
