import { encryptToken } from "@/services/encryption.service";
import { generateToken } from "@/services/token.service";
import { EncryptionError } from "@/utils/errors";

describe("Encryption Service Tests", () => {
  const sampleToken =
    "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJ0ZXN0LXVzZXIifQ.KxUQFnXBxkN_dwhxJqeKvZYWSyUt4GF69Sg5PaHvoYA";

  it("should successfully encrypt a JWT token", async () => {
    const token = await generateToken({
      sub: "test-user",
      email: "test@example.com",
      name: "Test User",
    });

    const encryptedToken = await encryptToken(token);

    expect(encryptedToken).toBeDefined();
    expect(typeof encryptedToken).toBe("string");
    expect(encryptedToken.length).toBeGreaterThan(0);
    // Base64 string should be properly formatted
    expect(encryptedToken).toMatch(/^[A-Za-z0-9+/]+=*$/);
  });

  it("should generate different ciphertexts for the same input", async () => {
    const firstEncryption = await encryptToken(sampleToken);
    const secondEncryption = await encryptToken(sampleToken);

    expect(firstEncryption).not.toBe(secondEncryption);
  });

  it("should handle concurrent encryption requests", async () => {
    const tokens = await Promise.all([
      generateToken({
        sub: "user1",
        email: "user1@example.com",
        name: "User 1",
      }),
      generateToken({
        sub: "user2",
        email: "user2@example.com",
        name: "User 2",
      }),
      generateToken({
        sub: "user3",
        email: "user3@example.com",
        name: "User 3",
      }),
    ]);

    const encryptionPromises = tokens.map((token) => encryptToken(token));
    const encryptedTokens = await Promise.all(encryptionPromises);

    encryptedTokens.forEach((encryptedToken) => {
      expect(encryptedToken).toBeDefined();
      expect(typeof encryptedToken).toBe("string");
      expect(encryptedToken.length).toBeGreaterThan(0);
      expect(encryptedToken).toMatch(/^[A-Za-z0-9+/]+=*$/);
    });

    // Ensure all encrypted tokens are unique
    const uniqueTokens = new Set(encryptedTokens);
    expect(uniqueTokens.size).toBe(tokens.length);
  });
});
