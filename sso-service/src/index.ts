import dotenv from "dotenv";
// Configure dotenv before any other imports
dotenv.config();

import express from "express";
import cors from "cors";
import { authRouter } from "./controllers/auth.controller";
import { errorHandler } from "./middleware/error.middleware";
import logger from "./utils/logger";

const app = express();
const port = process.env.PORT || 3000;

// Middleware
app.use(express.json());
app.use(cors());

// Routes
app.use("/auth", authRouter);

// Health check endpoint
app.get("/health", (req, res) => {
  res.json({ status: "healthy" });
});

// Error handling middleware should be last
app.use(errorHandler);

app.listen(port, () => {
  logger.info(`SSO service listening at http://localhost:${port}`);
});
