*** Settings ***
Documentation     Test Suite สำหรับทดสอบ Cronjob การลบข้อมูล 90 วัน
Library           RequestsLibrary
Library           Collections

*** Variables ***
${BASE_URL}       https://painamnaesoftenscrumteam-production.up.railway.app
${TEST_USERNAME}  Test_UAT
${TEST_PASSWORD}  123456789
${ADMIN_USERNAME}    admin_UAT
${ADMIN_PASS}     passadmin

*** Test Cases ***
Test Cronjob 90 Days Works With Deployed API
    [Documentation]    ทดสอบ Cronjob จริงโดยใช้เว็บที่ deploy: สร้างคำขอ -> อนุมัติ -> fast-forward 91 วัน -> trigger cron -> ตรวจสถานะเป็น DELETED
    Disable Insecure HTTPS Warning

    # 1) Login ฝั่ง user
    Log To Console    [STEP] Login user/admin and prepare sessions
    Create Session    backend    ${BASE_URL}    verify=${False}    timeout=10
    ${user_login_payload}=    Create Dictionary    username=${TEST_USERNAME}    password=${TEST_PASSWORD}
    ${user_login}=    POST On Session    backend    /api/auth/login    json=${user_login_payload}
    Should Be Equal As Integers    ${user_login.status_code}    200
    ${user_login_json}=    Evaluate    $user_login.json()
    ${user_token}=    Set Variable    ${user_login_json['data']['token']}

    # 2) Login ฝั่ง admin
    ${admin_login_payload}=    Create Dictionary    username=${ADMIN_USERNAME}    password=${ADMIN_PASS}
    ${admin_login}=    POST On Session    backend    /api/auth/login    json=${admin_login_payload}
    Should Be Equal As Integers    ${admin_login.status_code}    200
    ${admin_login_json}=    Evaluate    $admin_login.json()
    ${admin_token}=    Set Variable    ${admin_login_json['data']['token']}

    # 3) สร้าง session ที่มี Authorization header
    ${user_headers}=    Create Dictionary    Authorization=Bearer ${user_token}    Content-Type=application/json
    ${admin_headers}=    Create Dictionary    Authorization=Bearer ${admin_token}    Content-Type=application/json
    Create Session    user_api     ${BASE_URL}    headers=${user_headers}    verify=${False}    timeout=10
    Create Session    admin_api    ${BASE_URL}    headers=${admin_headers}    verify=${False}    timeout=10

    # 4) Cleanup คำขอเดิมที่ค้างอยู่ (ถ้ามี)
    POST On Session    user_api    /api/deletion/cancel    expected_status=any

    # 5) User ส่งคำขอลบบัญชีใหม่
    Log To Console    [STEP] User sends deletion request
    ${request_body}=    Create Dictionary    password=${TEST_PASSWORD}    reason=ทดสอบ cron 90 วัน
    ${create_req}=    POST On Session    user_api    /api/deletion/request    json=${request_body}
    Should Be Equal As Integers    ${create_req.status_code}    200

    # 6) Admin หา request ล่าสุดของ user และอนุมัติ
    ${query_params}=    Create Dictionary    status=PENDING    q=${TEST_USERNAME}
    ${list_resp}=    GET On Session    admin_api    /api/deletion/admin/requests    params=${query_params}
    Should Be Equal As Integers    ${list_resp.status_code}    200
    ${list_json}=    Evaluate    $list_resp.json()
    ${requests}=    Set Variable    ${list_json['data']}
    ${request_count}=    Get Length    ${requests}
    Should Be True    ${request_count} > 0
    ${request_id}=    Evaluate    $requests[0]['id']
    Log To Console    [STEP] Request id: ${request_id}

    Log To Console    [STEP] Admin approves request
    Wait Until Keyword Succeeds    45 sec    8 sec    Approve Request Should Succeed    ${request_id}

    # 7) จำลองเวลาผ่านไป 91 วันด้วย endpoint test
    Log To Console    [STEP] Fast-forward request to >90 days
    ${ff_resp}=    PUT On Session    backend    /api/test/cron/fast-forward/${request_id}
    Should Be Equal As Integers    ${ff_resp.status_code}    200
    Request Should Be Eligible For Deletion    ${request_id}

    # 9) ตรวจสอบผลว่าคำร้องถูกประมวลผลแล้ว
    Log To Console    [STEP] Trigger cron and verify DELETED
    Wait Until Keyword Succeeds    30 sec    5 sec    Trigger Cron And Request Should Become Deleted    ${request_id}
    Log To Console    [STEP] Verify audit trail contains anonymization/deletion
    Wait Until Keyword Succeeds    20 sec    5 sec    Request Should Have Deletion Audit    ${request_id}
    Log To Console    [DONE] Cron 90-day test passed

*** Keywords ***
Disable Insecure HTTPS Warning
    Evaluate    __import__('urllib3').disable_warnings(__import__('urllib3').exceptions.InsecureRequestWarning)

Request Should Be Eligible For Deletion
    [Arguments]    ${request_id}
    ${detail_resp}=    GET On Session    admin_api    /api/deletion/admin/requests/${request_id}
    Should Be Equal As Integers    ${detail_resp.status_code}    200
    ${detail_json}=    Evaluate    $detail_resp.json()
    ${status}=    Set Variable    ${detail_json['status']}
    ${scheduled_delete_at}=    Evaluate    $detail_json.get('scheduledDeleteAt')
    ${is_eligible}=    Evaluate    ($status == 'DELETED') or ($scheduled_delete_at is not None)
    Should Be True    ${is_eligible}    Request is not eligible after fast-forward. Backend test endpoint may not update scheduledDeleteAt.

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

Approve Request Should Succeed
    [Arguments]    ${request_id}
    ${approve_call_status}    ${approve_call_result}=    Run Keyword And Ignore Error    PATCH On Session    admin_api    /api/deletion/admin/requests/${request_id}/approve    expected_status=any
    ${detail_resp}=    GET On Session    admin_api    /api/deletion/admin/requests/${request_id}
    Should Be Equal As Integers    ${detail_resp.status_code}    200
    ${detail_json}=    Evaluate    $detail_resp.json()
    ${current_status}=    Set Variable    ${detail_json['status']}
    ${is_approved_or_deleted}=    Evaluate    $current_status in ['APPROVED', 'DELETED']
    Should Be True    ${is_approved_or_deleted}
