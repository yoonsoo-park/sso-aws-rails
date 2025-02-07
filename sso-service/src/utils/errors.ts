export class BaseError extends Error {
  constructor(message: string, public statusCode: number = 500) {
    super(message);
    this.name = this.constructor.name;
    Error.captureStackTrace(this, this.constructor);
  }
}

export class AuthenticationError extends BaseError {
  constructor(message: string) {
    super(message, 401);
  }
}

export class ValidationError extends BaseError {
  constructor(message: string) {
    super(message, 400);
  }
}

export class ConfigurationError extends BaseError {
  constructor(message: string) {
    super(message, 500);
  }
}

export class EncryptionError extends BaseError {
  constructor(message: string) {
    super(message, 500);
  }
}
