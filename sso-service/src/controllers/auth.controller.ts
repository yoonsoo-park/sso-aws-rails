import { Router, Request, Response } from "express";
import { generateToken } from "../services/token.service";
import { encryptToken } from "../services/encryption.service";
import {
  getCognitoAuthUrl,
  exchangeCodeForTokens,
  getCognitoLogoutUrl,
} from "../services/cognito.service";
import { AuthenticationError } from "../utils/errors";
import logger from "../utils/logger";

const router = Router();

// Initiate SSO login by redirecting to Cognito
router.get("/login", (req: Request, res: Response) => {
  try {
    const authUrl = getCognitoAuthUrl();
    logger.info("Redirecting to Cognito login");
    res.redirect(authUrl);
  } catch (error) {
    logger.error("Failed to generate Cognito auth URL", { error });
    throw error;
  }
});

// Handle the callback from Cognito
router.get("/callback", async (req: Request, res: Response) => {
  const { code } = req.query;

  if (!code || typeof code !== "string") {
    throw new AuthenticationError("Authorization code is required");
  }

  try {
    // Exchange the authorization code for Cognito tokens and get user info
    const userInfo = await exchangeCodeForTokens(code);

    // Generate our own JWT token with the actual user information
    const token = await generateToken({
      sub: userInfo.sub,
      email: userInfo.email,
      name: userInfo.name,
    });

    // Encrypt token using AWS KMS
    const encryptedToken = await encryptToken(token);

    // Generate redirect URL with encrypted token
    const redirectUrl = `${
      process.env.RAILS_APP_URL
    }/auth/v1/control_plane_sso?token=${encodeURIComponent(
      encryptedToken
    )}&state=test`;

    logger.info("Login successful via Cognito, generated redirect URL");
    res.redirect(redirectUrl);
  } catch (error) {
    logger.error("Failed to process Cognito callback", { error });
    throw error;
  }
});

// Handle logout by redirecting to Cognito logout
router.get("/logout", (req: Request, res: Response) => {
  try {
    const logoutUrl = getCognitoLogoutUrl();
    logger.info("Redirecting to Cognito logout");
    res.redirect(logoutUrl);
  } catch (error) {
    logger.error("Failed to generate Cognito logout URL", { error });
    throw error;
  }
});

export const authRouter = router;
