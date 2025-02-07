import { Request, Response, NextFunction } from "express";
import { BaseError } from "../utils/errors";
import logger from "../utils/logger";

export const errorHandler = (
  error: Error,
  req: Request,
  res: Response,
  next: NextFunction
) => {
  logger.error("Error occurred", {
    error: {
      message: error.message,
      stack: error.stack,
      name: error.name,
    },
    path: req.path,
    method: req.method,
  });

  if (error instanceof BaseError) {
    return res.status(error.statusCode).json({
      error: {
        message: error.message,
        type: error.name,
      },
    });
  }

  // Default error response for unknown errors
  return res.status(500).json({
    error: {
      message: "Internal server error",
      type: "InternalServerError",
    },
  });
};
