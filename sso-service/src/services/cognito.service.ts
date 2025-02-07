import { ConfigurationError } from "../utils/errors";
import logger from "../utils/logger";
import axios from "axios";
import qs from "querystring";
import jwt from "jsonwebtoken";

interface CognitoTokens {
  id_token: string;
  access_token: string;
  refresh_token: string;
}

interface CognitoUserInfo {
  sub: string;
  email: string;
  name: string;
  [key: string]: any;
}

export const getCognitoAuthUrl = (): string => {
  const cognitoDomain = process.env.COGNITO_DOMAIN;
  const clientId = process.env.COGNITO_CLIENT_ID;
  const callbackUrl = process.env.COGNITO_CALLBACK_URL;

  if (!cognitoDomain || !clientId || !callbackUrl) {
    throw new ConfigurationError("Missing required Cognito configuration");
  }

  const queryParams = new URLSearchParams({
    client_id: clientId,
    response_type: "code",
    scope: "openid email profile",
    redirect_uri: callbackUrl,
  });

  return `${cognitoDomain}/oauth2/authorize?${queryParams.toString()}`;
};

export const exchangeCodeForTokens = async (
  code: string
): Promise<CognitoUserInfo> => {
  const cognitoDomain = process.env.COGNITO_DOMAIN;
  const clientId = process.env.COGNITO_CLIENT_ID;
  const clientSecret = process.env.COGNITO_CLIENT_SECRET;
  const callbackUrl = process.env.COGNITO_CALLBACK_URL;

  if (!cognitoDomain || !clientId || !clientSecret || !callbackUrl) {
    throw new ConfigurationError("Missing required Cognito configuration");
  }

  try {
    // Exchange the authorization code for tokens using Cognito's OAuth endpoint
    const tokenEndpoint = `${cognitoDomain}/oauth2/token`;

    // Create Basic Auth header
    const basicAuth = Buffer.from(`${clientId}:${clientSecret}`).toString(
      "base64"
    );

    const response = await axios.post(
      tokenEndpoint,
      qs.stringify({
        grant_type: "authorization_code",
        code: code,
        redirect_uri: callbackUrl,
      }),
      {
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
          Authorization: `Basic ${basicAuth}`,
        },
      }
    );

    const tokens: CognitoTokens = response.data;

    // Decode the ID token to get user information
    const decodedToken = jwt.decode(tokens.id_token);
    if (!decodedToken || typeof decodedToken === "string") {
      throw new Error("Invalid ID token format");
    }

    // Ensure required fields exist
    if (!decodedToken.sub || !decodedToken.email) {
      throw new Error("Required user information missing from ID token");
    }

    logger.info("Successfully exchanged code for tokens and decoded user info");

    return {
      sub: decodedToken.sub,
      email: decodedToken.email,
      name:
        decodedToken.name ||
        (decodedToken.given_name && decodedToken.family_name
          ? `${decodedToken.given_name} ${decodedToken.family_name}`.trim()
          : decodedToken.email.split("@")[0]), // fallback to email username if no name available
    };
  } catch (error) {
    logger.error("Failed to exchange code for tokens", { error });
    throw error;
  }
};

export const getCognitoLogoutUrl = (): string => {
  const cognitoDomain = process.env.COGNITO_DOMAIN;
  const clientId = process.env.COGNITO_CLIENT_ID;
  const logoutUrl =
    process.env.RAILS_APP_URL || process.env.COGNITO_CALLBACK_URL;

  if (!cognitoDomain || !clientId || !logoutUrl) {
    throw new ConfigurationError("Missing required Cognito configuration");
  }

  const queryParams = new URLSearchParams({
    client_id: clientId,
    logout_uri: logoutUrl,
  });

  return `${cognitoDomain}/logout?${queryParams.toString()}`;
};
