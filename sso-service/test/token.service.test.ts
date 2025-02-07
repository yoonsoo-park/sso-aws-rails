import { generateToken } from "../src/services/token.service";
import fs from "fs";
import path from "path";

jest.mock("fs");
jest.mock("path");

describe("Token Service", () => {
  const mockPrivateKey = `-----BEGIN PRIVATE KEY-----
MIIEvAIBADANBgkqhkiG9w0BAQEFAASCBKYwggSiAgEAAoIBAQCod8qDyNwlDfrn
i3eYz4vavOyWmzudKKlH2xHTq59LY01/iolNN3ZKmCXlXCIEtSoGkg26JPIb7man
GCobMAjraMl8GsWJjVlYSOR9t0pfFEc5D1crdvkaKlTFmMChtW+iqKUcxb9fscbk
FGXOion7TYanJ97suISDyclLMkQSLn3eQsJOtRIWqev/j6x0JubGf9Rt0ixcGZIZ
Modz68FjSUo2MchH9qofTa1Y/qCfYB8N8IWuzro+ym5dw9bI3yjXbMprAx4fYyhV
NEbcmiH9IBEkhm2E0KdawEVbfTeZgeiUiP9+TdsULfeaKii4pZuNhe+q9yn6CnB+
jQQZMZ3ZAgMBAAECggEABW/sUimIQA099P18LCs9UnTOK/mG8zEN7vBD7dwi+ti8
dmp/DkYaeW4vVuziJNsV/U/3GnQOeQFOQIQCo+L+frPgljKk/9CskAa2PSp5FNgq
M6NqRvsC2inV7OoGWZG/WyAXSCDyZsEYRWHf0UqJCS/SMeXoXM/YaF/PBoVw9fyK
93cw3bmWipUo9JJg6DYfR1seI3M2Jk8KSekX5zKW4dBpLCWDHy/vtKSlaNhq8uDR
s/ez5rOmCX8fN2BU12DV7hzoelYiQsRMVPpJWzwZrbRR3VEKHsUI91fzf3rvMYNn
suOUaj/xFCgvrDQ9gNL1uy8NZSAoOpeLh28reSboewKBgQDriJYD9tf5JHFfbi4l
b0Gi9wfsRUR0mie75K9n4izXCbBhYE4C/mrh9IgHsi25Tx2COR+nYJRjV6HrJhFN
CdKkflFryTGJeH9PTP/6yagGp1pv2PNSNLyKNcjfbR1RoneoKyD5wQoKJQNwM2Y/
Dq6XgktpGnqHdDVSCFzy+d9pNwKBgQC3G1bP3M0b/dsWskLJxt0jCLAlfhmd/uvQ
UiinwQyrAIs26duMZh9Uy4nz0XrlV1kx94XTOQBL6XVxLyiyuumVHfZxvto+Ja7D
jlo4UsEZkDrhWCISXAWKnHQuBfaudWeADvZ1eKM/2M3MuZS53oRP+SP79ngSzx+t
7QQLCCh5bwKBgHeCDUQjqoASuqfGOwnpgq9SkqWSm+JiGYkfxtR6EXBmzSULfWnN
d6QAtEjbYpHlD770hxghTAl//HtZDGw/cK7gHSYIpubuygINutCgI26E2cFonkV2
1rd2BN9A+SBjxD0C7S9sgFCXaUA0BEw4geQES4kf004Ja8icz7TFjlNPAoGABikg
UZwPNpri7S+QObO8KvqW2pwUhpFWI8sv3P0MzRAWnwFdRqsE8NhsSszIgsDemmTG
luW7EdLIBcfdaa4KP98jNI6ET0T7TU8T0ANQxehpYr2RX+bCtPgwnH/M3e/LTK60
Mh2d+H715aZ0z5AiCYLLaCXRwmg/m5123lwm6HcCgYBjM3s2hXAQZspXr2Yy2e3g
WSWclreaSNXp/ueDYYyqF5Rw5fBIYwFE2tjEy3Nzd6mzyIN51OMr62x9BOMfrZSm
wwWcxdg4urzqMRae2vQypvFNxsfVpfSekfgiJiVjRzX3DbT9WZpRx9yQZIDPE111
5GHyOkDcqaulCCklnqsw9Q==
-----END PRIVATE KEY-----`;

  beforeEach(() => {
    // Mock the fs.readFileSync to return our test private key
    (fs.readFileSync as jest.Mock).mockReturnValue(mockPrivateKey);
    // Mock path.join to return a dummy path
    (path.join as jest.Mock).mockReturnValue("/dummy/path/private.pem");
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  it("should generate a valid JWT token", async () => {
    const claims = {
      sub: "test-user",
      email: "test@example.com",
      name: "Test User",
    };

    const token = await generateToken(claims);

    expect(token).toBeDefined();
    expect(typeof token).toBe("string");
    expect(token.split(".")).toHaveLength(3); // JWT has 3 parts
  });

  it("should throw error when private key file cannot be read", async () => {
    (fs.readFileSync as jest.Mock).mockImplementation(() => {
      throw new Error("File not found");
    });

    await expect(
      generateToken({
        sub: "test-user",
        email: "test@example.com",
        name: "Test User",
      })
    ).rejects.toThrow("Failed to read JWT private key file");
  });
});
