# Generate RSA private key
openssl genpkey -algorithm RSA -out private.pem -pkeyopt rsa_keygen_bits:2048

# Export public key (place it in the system /etc/upgrade directory)
openssl rsa -in private.pem -pubout -out public.pem

# Generate AES key (256-bit = 32 bytes) and place it in /etc/upgrade
openssl rand -hex 32 > aes.key
