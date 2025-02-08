import { randomBytes, createCipheriv, createDecipheriv } from "crypto";
import { ConfigurationError, EncryptionError } from "../utils/errors";
import logger from "../utils/logger";

// If ENCRYPTION_KEY is not provided, generate a random 32-byte key and convert to hex
const DEFAULT_KEY = randomBytes(32).toString("hex");
const ENCRYPTION_KEY = process.env.ENCRYPTION_KEY || DEFAULT_KEY;

// Convert hex string back to Buffer for encryption
const keyBuffer = Buffer.from(ENCRYPTION_KEY, "hex");
const ALGORITHM = "aes-256-gcm";

export async function encryptToken(token: string): Promise<string> {
  if (keyBuffer.length !== 32) {
    logger.error("Invalid encryption key length");
    throw new ConfigurationError(
      "Encryption key must be 32 bytes (64 hex characters)"
    );
  }

  try {
    logger.debug("Starting token encryption");
    logger.debug(`Key (hex): ${ENCRYPTION_KEY}`);
    logger.debug(`Key length: ${keyBuffer.length} bytes`);

    const iv = randomBytes(12);
    logger.debug(`Generated IV (hex): ${iv.toString("hex")}`);

    const cipher = createCipheriv(ALGORITHM, keyBuffer, iv);
    cipher.setAAD(Buffer.from("")); // Set empty auth data to match Ruby

    const encryptedBuffer = Buffer.concat([
      cipher.update(token, "utf8"),
      cipher.final(),
    ]);

    const authTag = cipher.getAuthTag();
    logger.debug(`Auth Tag (hex): ${authTag.toString("hex")}`);
    logger.debug(`Encrypted data length: ${encryptedBuffer.length} bytes`);

    // Format: base64(iv).base64(authTag).base64(encrypted)
    const encryptedToken = [
      iv.toString("base64"),
      authTag.toString("base64"),
      encryptedBuffer.toString("base64"),
    ].join(".");

    logger.debug("Token components:");
    logger.debug(
      ` - IV (base64): ${iv.toString("base64")} (${iv.length} bytes)`
    );
    logger.debug(
      ` - Auth Tag (base64): ${authTag.toString("base64")} (${
        authTag.length
      } bytes)`
    );
    logger.debug(
      ` - Encrypted (base64): ${encryptedBuffer
        .toString("base64")
        .substring(0, 64)}... (${encryptedBuffer.length} bytes)`
    );

    return encryptedToken;
  } catch (error) {
    logger.error("Encryption error:", { error });
    throw new EncryptionError("Failed to encrypt token");
  }
}

export async function decryptToken(encryptedToken: string): Promise<string> {
  if (keyBuffer.length !== 32) {
    logger.error("Invalid encryption key length");
    throw new ConfigurationError(
      "Encryption key must be 32 bytes (64 hex characters)"
    );
  }

  try {
    // Split the token into its components
    const [ivBase64, authTagBase64, encryptedBase64] =
      encryptedToken.split(".");
    if (!ivBase64 || !authTagBase64 || !encryptedBase64) {
      throw new Error("Invalid token format");
    }

    // Convert base64 components to buffers
    const iv = Buffer.from(ivBase64, "base64");
    const authTag = Buffer.from(authTagBase64, "base64");
    const encrypted = Buffer.from(encryptedBase64, "base64");

    // Create decipher
    const decipher = createDecipheriv(ALGORITHM, keyBuffer, iv);
    decipher.setAuthTag(authTag);

    // Decrypt
    const decrypted = Buffer.concat([
      decipher.update(encrypted),
      decipher.final(),
    ]);

    logger.debug("Token decrypted successfully");
    return decrypted.toString("utf8");
  } catch (error) {
    logger.error("Decryption error:", { error });
    throw new EncryptionError("Failed to decrypt token");
  }
}
