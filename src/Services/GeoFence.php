<?php

declare(strict_types=1);

namespace AgriPass\Services;

/** Great-circle distance used to keep QR check-in inside an event's venue radius. */
final class GeoFence
{
    private const EARTH_METERS = 6371000.0;

    public static function meters(float $lat1, float $lng1, float $lat2, float $lng2): float
    {
        $lat1r = deg2rad($lat1);
        $lat2r = deg2rad($lat2);
        $dLat = deg2rad($lat2 - $lat1);
        $dLng = deg2rad($lng2 - $lng1);
        $a = sin($dLat / 2) ** 2 + cos($lat1r) * cos($lat2r) * sin($dLng / 2) ** 2;

        return 2 * self::EARTH_METERS * asin(min(1.0, sqrt($a)));
    }
}
