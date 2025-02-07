import { Request, Response, NextFunction } from "express";
import { validationResult, ValidationChain, body } from "express-validator";
import { ValidationError } from "../utils/errors";
import logger from "../utils/logger";

export const validate = (validations: ValidationChain[]) => {
  return async (req: Request, res: Response, next: NextFunction) => {
    // Run all validations
    await Promise.all(validations.map((validation) => validation.run(req)));

    const errors = validationResult(req);
    if (errors.isEmpty()) {
      return next();
    }

    logger.warn("Validation failed", {
      path: req.path,
      errors: errors.array(),
    });

    throw new ValidationError(errors.array()[0].msg);
  };
};

// Common validation rules
export const loginValidation = [
  body("username").trim().notEmpty().withMessage("Username is required"),
  body("password").trim().notEmpty().withMessage("Password is required"),
];
