INSERT INTO applicants (
    id,
    applicant_type,
    phone,
    email,
    created_at
)
VALUES (
    '11111111-1111-1111-1111-111111111111',
    'INDIVIDUAL',
    '+79991234567',
    'ivan@example.com',
    NOW()
);


INSERT INTO individual_applicants (
    applicant_id,
    first_name,
    last_name,
    middle_name,
    birth_date
)
VALUES (
    '11111111-1111-1111-1111-111111111111',
    'Иван',
    'Иванов',
    'Иванович',
    '1990-05-20'
);


INSERT INTO addresses (
    id,
    region,
    city,
    street,
    house,
    apartment,
    postal_code,
    latitude,
    longitude,
    created_at
)
VALUES (
    '22222222-2222-2222-2222-222222222222',
    'Москва',
    'Москва',
    'Ленина',
    '10',
    '25',
    '101000',
    55.7558,
    37.6176,
    NOW()
);


INSERT INTO applicant_addresses (
    id,
    applicant_id,
    address_id,
    address_type
)
VALUES (
    '33333333-3333-3333-3333-333333333333',
    '11111111-1111-1111-1111-111111111111',
    '22222222-2222-2222-2222-222222222222',
    'REGISTRATION'
);


INSERT INTO credit_policies (
    id,
    name,
    version,
    status,
    effective_from,
    effective_to,
    created_at
)
VALUES (
    '44444444-4444-4444-4444-444444444444',
    'Retail Policy',
    '1.0',
    'active',
    NOW(),
    NULL,
    NOW()
);


INSERT INTO decision_requests (
    id,
    applicant_id,
    credit_policy_id,
    requested_amount,
    requested_term,
    processing_started_at,
    completed_at,
    request_status,
    score,
    pd,
    pti,
    created_at
)
VALUES (
    '55555555-5555-5555-5555-555555555555',
    '11111111-1111-1111-1111-111111111111',
    '44444444-4444-4444-4444-444444444444',
    300000,
    36,
    NOW(),
    NOW(),
    'completed',
    742,
    0.04,
    0.21,
    NOW()
);


INSERT INTO policy_rule_results (
    id,
    rule_name,
    rule_version,
    rule_document_id,
    decision_request_id,
    result,
    created_at
)
VALUES (
    '88888888-8888-8888-8888-888888888888',
    'income_check',
    1,
    'policy-retail-v1',
    '55555555-5555-5555-5555-555555555555',
    'passed',
    NOW()
);


INSERT INTO knockout_rule_results (
    id,
    decision_request_id,
    rule_document_id,
    result,
    created_at
)
VALUES (
    '99999999-9999-9999-9999-999999999999',
    '55555555-5555-5555-5555-555555555555',
    'ko-income',
    'passed',
    NOW()
);


INSERT INTO decisions (
    id,
    decision_request_id,
    decision_type,
    approved_limit,
    interest_rate,
    explanation,
    created_at
)
VALUES (
    '66666666-6666-6666-6666-666666666666',
    '55555555-5555-5555-5555-555555555555',
    'approve',
    300000,
    13.5,
    'Кредит одобрен.',
    NOW()
);


INSERT INTO reason_codes (
    id,
    code,
    description
)
VALUES (
    '77777777-7777-7777-7777-777777777777',
    'RC001',
    'Высокий скоринговый балл'
);


INSERT INTO decision_reason_codes (
    decision_id,
    reason_code_id
)
VALUES (
    '66666666-6666-6666-6666-666666666666',
    '77777777-7777-7777-7777-777777777777'
);