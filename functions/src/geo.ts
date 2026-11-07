const earthRadiusMeters = 6_371_000;

export function distanceMeters(
  first: readonly [number, number],
  second: readonly [number, number],
): number {
  const radians = (degrees: number) => degrees * Math.PI / 180;
  const latitudeDelta = radians(second[0] - first[0]);
  const longitudeDelta = radians(second[1] - first[1]);
  const firstLatitude = radians(first[0]);
  const secondLatitude = radians(second[0]);
  const haversine =
    Math.sin(latitudeDelta / 2) ** 2 +
    Math.cos(firstLatitude) *
      Math.cos(secondLatitude) *
      Math.sin(longitudeDelta / 2) ** 2;
  return earthRadiusMeters * 2 * Math.atan2(
    Math.sqrt(haversine),
    Math.sqrt(1 - haversine),
  );
}

export function isWithinRadius(
  origin: readonly [number, number],
  target: readonly [number, number],
  radiusMeters: number,
): boolean {
  return distanceMeters(origin, target) <= radiusMeters;
}
