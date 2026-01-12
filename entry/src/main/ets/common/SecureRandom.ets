import cryptoFramework from '@ohos.security.cryptoFramework';

const random = cryptoFramework.createRandom();

export async function secureRandomInt(min: number, max: number): Promise<number> {
  const bytes = await random.generateRandom(4);
  const v =
    (bytes.data[0] << 24) |
      (bytes.data[1] << 16) |
      (bytes.data[2] << 8) |
    bytes.data[3];

  const unsigned = v >>> 0;
  return min + (unsigned % (max - min + 1));
}
