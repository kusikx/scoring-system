CREATE TYPE "applicant_type" AS ENUM (
  'INDIVIDUAL',
  'LEGAL_ENTITY'
);

CREATE TYPE "request_status" AS ENUM (
  'created',
  'processing',
  'completed',
  'failed',
  'manual_review'
);

CREATE TYPE "decision_type" AS ENUM (
  'approve',
  'decline',
  'refer',
  'counter_offer'
);

CREATE TYPE "policy_status" AS ENUM (
  'draft',
  'active',
  'archived'
);


CREATE TYPE "rule_execution_result" AS ENUM (
  'passed',
  'failed'
);

CREATE TYPE "address_type" AS ENUM (
  'REGISTRATION',
  'RESIDENTIAL',
  'LEGAL',
  'ACTUAL'
);


CREATE TABLE "applicants" (
  "id" uuid PRIMARY KEY,
  "applicant_type" applicant_type NOT NULL,
  "phone" varchar,
  "email" varchar,
  "created_at" timestamp NOT NULL
);


CREATE TABLE "legal_entities" (
  "applicant_id" uuid PRIMARY KEY,
  "company_name" varchar NOT NULL,
  "inn" varchar NOT NULL,
  "ogrn" varchar,
  "registration_date" date
);


CREATE TABLE "individual_applicants" (
  "applicant_id" uuid PRIMARY KEY,
  "first_name" varchar NOT NULL,
  "last_name" varchar NOT NULL,
  "middle_name" varchar,
  "birth_date" date
);


CREATE TABLE "addresses" (
  "id" uuid PRIMARY KEY,
  "region" varchar,
  "city" varchar,
  "street" varchar,
  "house" varchar,
  "apartment" varchar,
  "postal_code" varchar,
  "latitude" decimal,
  "longitude" decimal,
  "created_at" timestamp
);


CREATE TABLE "applicant_addresses" (
  "id" uuid PRIMARY KEY,
  "applicant_id" uuid NOT NULL,
  "address_id" uuid NOT NULL,
  "address_type" address_type NOT NULL
);


CREATE TABLE "credit_policies" (
  "id" uuid PRIMARY KEY,
  "name" varchar NOT NULL,
  "version" varchar NOT NULL,
  "status" policy_status NOT NULL,
  "effective_from" timestamp NOT NULL,
  "effective_to" timestamp,
  "created_at" timestamp NOT NULL
);


CREATE TABLE "decision_requests" (
  "id" uuid PRIMARY KEY,
  "applicant_id" uuid NOT NULL,
  "credit_policy_id" uuid NOT NULL,

  "requested_amount" decimal NOT NULL,
  "requested_term" integer NOT NULL,

  "processing_started_at" timestamp,
  "completed_at" timestamp,

  "request_status" request_status NOT NULL,

  "score" decimal,
  "pd" decimal,
  "pti" decimal,

  "created_at" timestamp NOT NULL
);


CREATE TABLE "decisions" (
  "id" uuid PRIMARY KEY,

  "decision_request_id" uuid NOT NULL UNIQUE,

  "decision_type" decision_type NOT NULL,

  "approved_limit" decimal,
  "interest_rate" decimal,

  "explanation" text,

  "created_at" timestamp NOT NULL
);


CREATE TABLE "policy_rule_results" (
  "id" uuid PRIMARY KEY,

  "rule_name" varchar NOT NULL,
  "rule_version" integer NOT NULL,
  "rule_document_id" varchar NOT NULL,

  "decision_request_id" uuid NOT NULL,

  "result" rule_execution_result NOT NULL,

  "created_at" timestamp NOT NULL
);


CREATE TABLE "knockout_rule_results" (
  "id" uuid PRIMARY KEY,

  "decision_request_id" uuid NOT NULL,

  "rule_document_id" varchar NOT NULL,

  "result" rule_execution_result NOT NULL,

  "created_at" timestamp NOT NULL
);


CREATE TABLE "reason_codes" (
  "id" uuid PRIMARY KEY,

  "code" varchar NOT NULL,

  "description" text NOT NULL
);


CREATE TABLE "decision_reason_codes" (
  "decision_id" uuid NOT NULL,

  "reason_code_id" uuid NOT NULL,

  PRIMARY KEY ("decision_id", "reason_code_id")
);

ALTER TABLE "individual_applicants"
ADD FOREIGN KEY ("applicant_id")
REFERENCES "applicants" ("id");


ALTER TABLE "legal_entities"
ADD FOREIGN KEY ("applicant_id")
REFERENCES "applicants" ("id");


ALTER TABLE "applicant_addresses"
ADD FOREIGN KEY ("applicant_id")
REFERENCES "applicants" ("id");


ALTER TABLE "applicant_addresses"
ADD FOREIGN KEY ("address_id")
REFERENCES "addresses" ("id");


ALTER TABLE "decision_requests"
ADD FOREIGN KEY ("applicant_id")
REFERENCES "applicants" ("id");


ALTER TABLE "decision_requests"
ADD FOREIGN KEY ("credit_policy_id")
REFERENCES "credit_policies" ("id");


ALTER TABLE "decisions"
ADD CONSTRAINT "fk_decisions_request"
FOREIGN KEY ("decision_request_id")
REFERENCES "decision_requests" ("id");


ALTER TABLE "policy_rule_results"
ADD CONSTRAINT "fk_policy_rules_request"
FOREIGN KEY ("decision_request_id")
REFERENCES "decision_requests" ("id");


ALTER TABLE "knockout_rule_results"
ADD CONSTRAINT "fk_knockout_rules_request"
FOREIGN KEY ("decision_request_id")
REFERENCES "decision_requests" ("id");


ALTER TABLE "decision_reason_codes"
ADD FOREIGN KEY ("decision_id")
REFERENCES "decisions" ("id");


ALTER TABLE "decision_reason_codes"
ADD FOREIGN KEY ("reason_code_id")
REFERENCES "reason_codes" ("id");