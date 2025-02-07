import jwt from "jsonwebtoken";
import fs from "fs";
import path from "path";

interface TokenClaims {
  sub: string;
  email: string;
  name: string;
}

const getPrivateKey = (): string => {
  try {
    // Read from private.pem in the project root
    return fs.readFileSync(
      path.join(process.cwd(), "..", "private.pem"),
      "utf8"
    );
  } catch (error) {
    throw new Error("Failed to read JWT private key file");
  }
};

export const generateToken = async (claims: TokenClaims): Promise<string> => {
  const privateKey = getPrivateKey();

  const token = jwt.sign(
    {
      ...claims,
      iss: process.env.JWT_ISSUER || "sso-service",
      aud: process.env.JWT_AUDIENCE || "rails-app",
      exp: Math.floor(Date.now() / 1000) + 60 * 60, // 1 hour expiration
    },
    privateKey,
    { algorithm: "RS256" }
  );

  return token;
};
