import dotenv from "dotenv";
import path from "path";
import { randomBytes } from "crypto";

// Load test environment variables
dotenv.config({
  path: path.join(__dirname, "../.env.test"),
});

// Set default test environment variables if not present
// Generate a 32-byte (256-bit) key and convert to hex string (64 characters)
process.env.ENCRYPTION_KEY =
  process.env.ENCRYPTION_KEY || randomBytes(32).toString("hex");

// Test RSA key pair for JWT signing
process.env.JWT_PRIVATE_KEY =
  "-----BEGIN PRIVATE KEY-----\nMIIEvAIBADANBgkqhkiG9w0BAQEFAASCBKYwggSiAgEAAoIBAQCod8qDyNwlDfrn\ni3eYz4vavOyWmzudKKlH2xHTq59LY01/iolNN3ZKmCXlXCIEtSoGkg26JPIb7man\nGCobMAjraMl8GsWJjVlYSOR9t0pfFEc5D1crdvkaKlTFmMChtW+iqKUcxb9fscbk\nFGXOion7TYanJ97suISDyclLMkQSLn3eQsJOtRIWqev/j6x0JubGf9Rt0ixcGZIZ\nModz68FjSUo2MchH9qofTa1Y/qCfYB8N8IWuzro+ym5dw9bI3yjXbMprAx4fYyhV\nNEbcmiH9IBEkhm2E0KdawEVbfTeZgeiUiP9+TdsULfeaKii4pZuNhe+q9yn6CnB+\njQQZMZ3ZAgMBAAECggEABW/sUimIQA099P18LCs9UnTOK/mG8zEN7vBD7dwi+ti8\ndmp/DkYaeW4vVuziJNsV/U/3GnQOeQFOQIQCo+L+frPgljKk/9CskAa2PSp5FNgq\nM6NqRvsC2inV7OoGWZG/WyAXSCDyZsEYRWHf0UqJCS/SMeXoXM/YaF/PBoVw9fyK\n93cw3bmWipUo9JJg6DYfR1seI3M2Jk8KSekX5zKW4dBpLCWDHy/vtKSlaNhq8uDR\ns/ez5rOmCX8fN2BU12DV7hzoelYiQsRMVPpJWzwZrbRR3VEKHsUI91fzf3rvMYNn\nsuOUaj/xFCgvrDQ9gNL1uy8NZSAoOpeLh28reSboewKBgQDriJYD9tf5JHFfbi4l\nb0Gi9wfsRUR0mie75K9n4izXCbBhYE4C/mrh9IgHsi25Tx2COR+nYJRjV6HrJhFN\nCdKkflFryTGJeH9PTP/6yagGp1pv2PNSNLyKNcjfbR1RoneoKyD5wQoKJQNwM2Y/\nDq6XgktpGnqHdDVSCFzy+d9pNwKBgQC3G1bP3M0b/dsWskLJxt0jCLAlfhmd/uvQ\nUiinwQyrAIs26duMZh9Uy4nz0XrlV1kx94XTOQBL6XVxLyiyuumVHfZxvto+Ja7D\njlo4UsEZkDrhWCISXAWKnHQuBfaudWeADvZ1eKM/2M3MuZS53oRP+SP79ngSzx+t\n7QQLCCh5bwKBgHeCDUQjqoASuqfGOwnpgq9SkqWSm+JiGYkfxtR6EXBmzSULfWnN\nd6QAtEjbYpHlD770hxghTAl//HtZDGw/cK7gHSYIpubuygINutCgI26E2cFonkV2\n1rd2BN9A+SBjxD0C7S9sgFCXaUA0BEw4geQES4kf004Ja8icz7TFjlNPAoGABikg\nUZwPNpri7S+QObO8KvqW2pwUhpFWI8sv3P0MzRAWnwFdRqsE8NhsSszIgsDemmTG\nluW7EdLIBcfdaa4KP98jNI6ET0T7TU8T0ANQxehpYr2RX+bCtPgwnH/M3e/LTK60\nMh2d+H715aZ0z5AiCYLLaCXRwmg/m5123lwm6HcCgYBjM3s2hXAQZspXr2Yy2e3g\nWSWclreaSNXp/ueDYYyqF5Rw5fBIYwFE2tjEy3Nzd6mzyIN51OMr62x9BOMfrZSm\nwwWcxdg4urzqMRae2vQypvFNxsfVpfSekfgiJiVjRzX3DbT9WZpRx9yQZIDPE111\n5GHyOkDcqaulCCklnqsw9Q==\n-----END PRIVATE KEY-----";
