/// Lista canónica de ubicaciones de En Copa de Balón.
/// NO inventar ubicaciones que no estén aquí.
/// Coordenadas aproximadas — Bosco debe ajustar con las reales.
class UbicacionSeed {
  final String nombre;
  final String tipo;
  final double latitud;
  final double longitud;
  final int radioPermitido;

  const UbicacionSeed({
    required this.nombre,
    required this.tipo,
    required this.latitud,
    required this.longitud,
    this.radioPermitido = 100,
  });
}

class UbicacionesECDB {
  UbicacionesECDB._();

  static const List<UbicacionSeed> todas = [
    // ── Tiendas ──
    UbicacionSeed(
      nombre: 'Zoco de Pozuelo',
      tipo: 'tienda',
      latitud: 40.4357,
      longitud: -3.8123,
    ),
    UbicacionSeed(
      nombre: 'Centro Oeste Majadahonda',
      tipo: 'tienda',
      latitud: 40.4500,
      longitud: -3.8700,
    ),
    UbicacionSeed(
      nombre: 'CC Arturo Soria Plaza',
      tipo: 'tienda',
      latitud: 40.4520,
      longitud: -3.6380,
    ),
    UbicacionSeed(
      nombre: 'Calle Granada',
      tipo: 'tienda',
      latitud: 40.4168,
      longitud: -3.7038,
    ),
    UbicacionSeed(
      nombre: 'Calle Núñez de Balboa',
      tipo: 'tienda',
      latitud: 40.4280,
      longitud: -3.6830,
    ),

    // ── Híbrido ──
    UbicacionSeed(
      nombre: 'La Casita (Claudio Coello 121)',
      tipo: 'híbrido',
      latitud: 40.4295,
      longitud: -3.6795,
    ),

    // ── Restaurantes ──
    UbicacionSeed(
      nombre: 'Restaurante Aravaca',
      tipo: 'restaurante',
      latitud: 40.4590,
      longitud: -3.7930,
    ),
    UbicacionSeed(
      nombre: 'Restaurante Moraleja',
      tipo: 'restaurante',
      latitud: 40.5200,
      longitud: -3.6350,
    ),
    UbicacionSeed(
      nombre: 'Restaurante Pozuelo',
      tipo: 'restaurante',
      latitud: 40.4370,
      longitud: -3.8100,
    ),

    // ── Gastronómicos ──
    UbicacionSeed(
      nombre: 'Ancestral',
      tipo: 'gastronómico',
      latitud: 40.4200,
      longitud: -3.7050,
    ),
    UbicacionSeed(
      nombre: 'Brassafina',
      tipo: 'gastronómico',
      latitud: 40.4250,
      longitud: -3.6900,
    ),
    UbicacionSeed(
      nombre: 'Las Margaritas',
      tipo: 'gastronómico',
      latitud: 40.4300,
      longitud: -3.7100,
    ),

    // ── Noche ──
    UbicacionSeed(
      nombre: 'Panthera',
      tipo: 'noche',
      latitud: 40.4230,
      longitud: -3.6920,
    ),
    UbicacionSeed(
      nombre: 'Rubicon',
      tipo: 'noche',
      latitud: 40.4220,
      longitud: -3.6950,
    ),

    // ── Distribución ──
    UbicacionSeed(
      nombre: 'CODEBA — Nave Leganés',
      tipo: 'distribución',
      latitud: 40.3270,
      longitud: -3.7640,
      radioPermitido: 200,
    ),
  ];
}
