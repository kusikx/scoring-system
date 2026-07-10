db.createCollection("policy_rules")

db.policy_rules.insertOne({
  "_id": "policy-retail-v1",
  "policyId": "44444444-4444-4444-4444-444444444444",
  "version": 1,
  "rules": [
    {
      "id": "rule-approve-low-risk",
      "priority": 1,
      "conditions": [
        {
          "field": "score",
          "operator": ">=",
          "value": 700
        }
      ],
      "action": {
        "decision": "approve",
        "approvedLimit": 300000,
        "interestRate": 13.5
      }
    }
  ]
});