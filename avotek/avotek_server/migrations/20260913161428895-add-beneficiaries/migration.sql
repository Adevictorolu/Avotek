BEGIN;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "beneficiaries" (
    "id" bigserial PRIMARY KEY,
    "userId" bigint NOT NULL,
    "serviceType" text NOT NULL,
    "networkProvider" text NOT NULL,
    "recipientIdentifier" text NOT NULL,
    "name" text NOT NULL,
    "createdAt" timestamp without time zone NOT NULL
);


--
-- MIGRATION VERSION FOR avotek
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('avotek', '20260913161428895-add-beneficiaries', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260913161428895-add-beneficiaries', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20260129180959368', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260129180959368', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod_auth_idp
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod_auth_idp', '20260213194423028', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260213194423028', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod_auth_core
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod_auth_core', '20260129181112269', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260129181112269', "timestamp" = now();


COMMIT;
