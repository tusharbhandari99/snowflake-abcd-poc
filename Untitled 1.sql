# 1. Generate an encrypted private key (you will be prompted to enter a passphrase)
openssl genrsa 2048 | openssl pkcs8 -topk8 -v2 des3 -inform PEM -out rsa_key.p8

# 2. Generate the matching public key from rsa_key.p8
openssl rsa -in rsa_key.p8 -pubout -out rsa_key.pub



-- 1. Create a dedicated POC user without a password
CREATE OR REPLACE USER keypair_poc_user
  DEFAULT_ROLE = PUBLIC
  TYPE = SERVICE;

-- Grant basic warehouse and role access
GRANT USAGE ON WAREHOUSE COMPUTE_WH TO USER keypair_poc_user;
ALTER USER keypair_poc_user SET DEFAULT_WAREHOUSE = 'COMPUTE_WH';


-- 2. Attach the public key
ALTER USER keypair_poc_user 
  SET RSA_PUBLIC_KEY = 'MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA4NF5VUmNU0A+B41rY/Ot
ql1GL5/85L4Uf8COWZJla6K1zaLytOLhuuSPWF2Ir3MKs8/JYUUaPw76Detbfpxc
p7k2vR4s0yjrrNPerOUU95XN/4iVznWuExXNg0nYzmSuFhjx2PgS5/8m+q1AMtnK
KcUx9kZSTAYmg2lg9u92N543t7Zi3AMwU/Bo/yYDwenDy580qgAJ7dxZqe6BKSWt
q6nMKgTz0D1ZSOjJj3P8skiPz3vPpQz4U9K5KH01refFpksaGadWcxGmdx+eiirN
kOEzPMndxew9rw6bwWXY5Ti9tT076ovDuwtHuH00zLE83OfmFV9MHoupt7OdX2Yg
UQIDAQAB';

-- 3. Verify key assignment
DESCRIBE USER keypair_poc_user;

-- compare the output to verify

DESC USER keypair_poc_user
  ->> SELECT SUBSTR(
     (SELECT "value" FROM $1
        WHERE "property" = 'RSA_PUBLIC_KEY_FP'),
     LEN('SHA256:') + 1) AS key;

openssl rsa -pubin -in rsa_key.pub -outform DER | openssl dgst -sha256 -binary | openssl enc -base64