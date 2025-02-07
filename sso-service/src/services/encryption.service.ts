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
    const iv = randomBytes(12);
    const cipher = createCipheriv(ALGORITHM, keyBuffer, iv);

    const encryptedBuffer = Buffer.concat([
      cipher.update(token, "utf8"),
      cipher.final(),
    ]);

    const authTag = cipher.getAuthTag();

    // Combine IV, encrypted data, and auth tag
    const result = Buffer.concat([iv, encryptedBuffer, authTag]);

    logger.debug("Token encrypted successfully");
    return result.toString("base64");
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
    // Convert base64 to buffer
    const encryptedBuffer = Buffer.from(encryptedToken, "base64");

    // Extract IV (12 bytes), auth tag (16 bytes), and encrypted data
    const iv = encryptedBuffer.subarray(0, 12);
    const authTag = encryptedBuffer.subarray(encryptedBuffer.length - 16);
    const encrypted = encryptedBuffer.subarray(12, encryptedBuffer.length - 16);

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
