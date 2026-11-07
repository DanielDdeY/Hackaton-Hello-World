"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.distanceMeters = distanceMeters;
exports.isWithinRadius = isWithinRadius;
const earthRadiusMeters = 6371000;
function distanceMeters(first, second) {
    const radians = (degrees) => degrees * Math.PI / 180;
    const latitudeDelta = radians(second[0] - first[0]);
    const longitudeDelta = radians(second[1] - first[1]);
    const firstLatitude = radians(first[0]);
    const secondLatitude = radians(second[0]);
    const haversine = Math.sin(latitudeDelta / 2) ** 2 +
        Math.cos(firstLatitude) *
            Math.cos(secondLatitude) *
            Math.sin(longitudeDelta / 2) ** 2;
    return earthRadiusMeters * 2 * Math.atan2(Math.sqrt(haversine), Math.sqrt(1 - haversine));
}
function isWithinRadius(origin, target, radiusMeters) {
    return distanceMeters(origin, target) <= radiusMeters;
}
//# sourceMappingURL=geo.js.map