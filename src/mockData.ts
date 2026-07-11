import {
  Vehicle,
  VehicleStatus,
  TrackerStatus,
  Driver,
  DriverStatus,
  Trip,
  TripStatus,
  Exception,
  ExceptionSeverity,
  FuelRequest,
  MaintenanceRequest,
  MaintenanceStatus,
  SparePart,
  Tyre,
  PolicyRule,
  Incident,
  AuditLog
} from "./types";

export const defaultPolicyRules: PolicyRule[] = [
  {
    id: "p1",
    name: "Fuel Limit Alert",
    category: "Fuel",
    value: "200 Liters",
    description: "Maximum allowable fuel per vehicle per month without senior manager override."
  },
  {
    id: "p2",
    name: "Fuel Variance Tolerance",
    category: "Fuel",
    value: "10%",
    description: "Maximum deviation between GPS distance expected consumption and actual fuel volume."
  },
  {
    id: "p3",
    name: "Allowed Operations Window",
    category: "Trip",
    value: "06:00 - 22:00",
    description: "Operating hours window. Movement outside this window flags an After-Hours unauthorized movement alert."
  },
  {
    id: "p4",
    name: "Standard Maintenance Interval",
    category: "Maintenance",
    value: "5000 KM",
    description: "Routine maintenance cycle trigger based on odometer reading."
  },
  {
    id: "p5",
    name: "Quotation Comparison Threshold",
    category: "Maintenance",
    value: "$500",
    description: "Repairs exceeding this cost require 3 competitive vendor quotations."
  }
];

export const defaultVehicles: Vehicle[] = [
  {
    id: "v1",
    registrationNumber: "SL-423-AB",
    make: "Toyota",
    model: "Prado SUV",
    year: 2022,
    type: "SUV",
    fuelType: "Diesel",
    tankCapacity: 80,
    expectedFuelConsumption: 8.5, // 8.5 km per liter
    currentOdometer: 45200,
    status: VehicleStatus.Active,
    assignedDriverId: "d1",
    assignedDepartment: "Executive Transport",
    insuranceExpiry: "2026-11-20",
    roadworthinessExpiry: "2026-12-15",
    gpsTrackerId: "GPS-TRK-900",
    trackerStatus: TrackerStatus.Active,
    lastGpsLocation: { lat: 8.484, lng: -13.235, address: "Central Admin Block, Freetown" },
    lastGpsUpdateTime: "2026-07-11T03:45:00-07:00",
    monthlyFuelLimit: 300,
    currentMonthFuelUsed: 140
  },
  {
    id: "v2",
    registrationNumber: "SL-891-CD",
    make: "Nissan",
    model: "NV350 Urban Bus",
    year: 2021,
    type: "Bus",
    fuelType: "Petrol",
    tankCapacity: 65,
    expectedFuelConsumption: 10.0, // 10 km per liter
    currentOdometer: 68150,
    status: VehicleStatus.Parked,
    assignedDriverId: "d2",
    assignedDepartment: "Staff Shuttle",
    insuranceExpiry: "2026-08-05",
    roadworthinessExpiry: "2026-09-01",
    gpsTrackerId: "GPS-TRK-811",
    trackerStatus: TrackerStatus.Active,
    lastGpsLocation: { lat: 8.472, lng: -13.220, address: "East Gate Depot" },
    lastGpsUpdateTime: "2026-07-11T03:50:00-07:00",
    monthlyFuelLimit: 400,
    currentMonthFuelUsed: 220
  },
  {
    id: "v3",
    registrationNumber: "SL-701-XX",
    make: "Mitsubishi",
    model: "L200 Pickup",
    year: 2020,
    type: "Pickup",
    fuelType: "Diesel",
    tankCapacity: 75,
    expectedFuelConsumption: 11.5, // 11.5 km per liter
    currentOdometer: 112400,
    status: VehicleStatus.UnderMaintenance,
    assignedDriverId: "d3",
    assignedDepartment: "Logistics & Field Ops",
    insuranceExpiry: "2026-06-10", // EXPIRED alert potential
    roadworthinessExpiry: "2026-06-30",
    gpsTrackerId: "GPS-TRK-302",
    trackerStatus: TrackerStatus.Tampered, // TAMPER ALERT potential
    lastGpsLocation: { lat: 8.455, lng: -13.210, address: "Freetown Mechanical Hub (Unapproved Garage)" },
    lastGpsUpdateTime: "2026-07-11T02:15:00-07:00",
    monthlyFuelLimit: 350,
    currentMonthFuelUsed: 310
  },
  {
    id: "v4",
    registrationNumber: "SL-112-AMB",
    make: "Toyota",
    model: "Hiace Ambulance",
    year: 2023,
    type: "Ambulance",
    fuelType: "Petrol",
    tankCapacity: 70,
    expectedFuelConsumption: 9.0,
    currentOdometer: 23100,
    status: VehicleStatus.Active,
    assignedDriverId: "d4",
    assignedDepartment: "Emergency & Medical",
    insuranceExpiry: "2027-01-10",
    roadworthinessExpiry: "2027-01-10",
    gpsTrackerId: "GPS-TRK-112",
    trackerStatus: TrackerStatus.Active,
    lastGpsLocation: { lat: 8.489, lng: -13.230, address: "Community Health Clinic, Freetown" },
    lastGpsUpdateTime: "2026-07-11T03:53:00-07:00",
    monthlyFuelLimit: 500,
    currentMonthFuelUsed: 95
  },
  {
    id: "v5",
    registrationNumber: "SL-515-FG",
    make: "Isuzu",
    model: "FSR Cargo Truck",
    year: 2019,
    type: "Truck",
    fuelType: "Diesel",
    tankCapacity: 150,
    expectedFuelConsumption: 6.2,
    currentOdometer: 145800,
    status: VehicleStatus.Grounded,
    assignedDriverId: "",
    assignedDepartment: "Supply Chain Logistics",
    insuranceExpiry: "2026-05-01",
    roadworthinessExpiry: "2026-05-15",
    gpsTrackerId: "GPS-TRK-515",
    trackerStatus: TrackerStatus.Offline,
    lastGpsLocation: { lat: 8.460, lng: -13.250, address: "West Depot Quarantine" },
    lastGpsUpdateTime: "2026-07-09T18:30:00-07:00",
    monthlyFuelLimit: 600,
    currentMonthFuelUsed: 0
  }
];

export const defaultDrivers: Driver[] = [
  {
    id: "d1",
    staffNumber: "STF-DRV-101",
    name: "Alhaji Kamara",
    phone: "+232-77-542109",
    email: "alhaji.kamara@fleet-org.com",
    photoUrl: "https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&q=80&w=200",
    licenseNumber: "LIC-77218-AA",
    licenseClass: "Class C (Heavy Vehicles)",
    licenseExpiry: "2028-04-12",
    status: DriverStatus.Active,
    performanceScore: 94,
    riskScore: 8 // Low risk
  },
  {
    id: "d2",
    staffNumber: "STF-DRV-102",
    name: "Sorie Ibrahim Turay",
    phone: "+232-76-881234",
    email: "sorie.turay@fleet-org.com",
    photoUrl: "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&q=80&w=200",
    licenseNumber: "LIC-81192-BB",
    licenseClass: "Class B (Light Commercial)",
    licenseExpiry: "2027-09-18",
    status: DriverStatus.Active,
    performanceScore: 88,
    riskScore: 18 // Low risk
  },
  {
    id: "d3",
    staffNumber: "STF-DRV-103",
    name: "Musa 'Buster' Conteh",
    phone: "+232-78-456990",
    email: "musa.conteh@fleet-org.com",
    photoUrl: "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&q=80&w=200",
    licenseNumber: "LIC-30211-XX",
    licenseClass: "Class B (Light Commercial)",
    licenseExpiry: "2026-05-30", // EXPIRED!
    status: DriverStatus.Active,
    performanceScore: 54,
    riskScore: 78 // High risk due to mileage claims and unapproved refueling
  },
  {
    id: "d4",
    staffNumber: "STF-DRV-104",
    name: "Fatmata Sesay",
    phone: "+232-33-219875",
    email: "fatmata.sesay@fleet-org.com",
    photoUrl: "https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&q=80&w=200",
    licenseNumber: "LIC-44122-YY",
    licenseClass: "Class A (Emergency Vehicles)",
    licenseExpiry: "2029-01-10",
    status: DriverStatus.Active,
    performanceScore: 96,
    riskScore: 12 // Good rating
  }
];

export const defaultTrips: Trip[] = [
  {
    id: "t1",
    tripRequestNumber: "TRIP-2026-0015",
    vehicleId: "v1",
    driverId: "d1",
    department: "Executive Transport",
    passengers: ["Dr. Elizabeth Pratt (Director of Operations)", "Prof. David Johnson (Visiting Consultant)"],
    purpose: "Transporting official guests to the Regional Development Summit",
    pickupPoint: "Central Admin Block, Freetown",
    destination: "Radisson Blu Conference Centre",
    status: TripStatus.Active,
    requestedAt: "2026-07-11T02:00:00-07:00",
    approvedAt: "2026-07-11T02:15:00-07:00",
    startedAt: "2026-07-11T03:00:00-07:00",
    signOutOdometer: 45150,
    signOutFuelLevel: 80, // %
    signOutOfficerName: "Sgt. Joseph Bundu",
    signOutTime: "2026-07-11T03:05:00-07:00",
    gpsDistanceKm: 12.4
  },
  {
    id: "t2",
    tripRequestNumber: "TRIP-2026-0012",
    vehicleId: "v2",
    driverId: "d2",
    department: "Staff Shuttle",
    passengers: ["Staff Shuttle Service - Shift B (15 staff members)"],
    purpose: "Evening shift employee drop-off",
    pickupPoint: "Freetown Headquarters Office",
    destination: "West End Suburbs (Standard Route)",
    status: TripStatus.Completed,
    requestedAt: "2026-07-10T17:00:00-07:00",
    approvedAt: "2026-07-10T17:30:00-07:00",
    startedAt: "2026-07-10T18:00:00-07:00",
    endedAt: "2026-07-10T19:45:00-07:00",
    signOutOdometer: 68100,
    signOutFuelLevel: 65,
    signOutOfficerName: "Sgt. Joseph Bundu",
    signOutTime: "2026-07-10T18:02:00-07:00",
    signInOdometer: 68150,
    signInFuelLevel: 55,
    signInOfficerName: "Officer Marie Kargbo",
    signInTime: "2026-07-10T19:50:00-07:00",
    gpsDistanceKm: 48.2,
    routeDeviationFlagged: false
  },
  {
    id: "t3",
    tripRequestNumber: "TRIP-2026-0014",
    vehicleId: "v3",
    driverId: "d3",
    department: "Logistics & Field Ops",
    passengers: ["Unlisted Passenger (Flagged Exception)"],
    cargoNotes: "3 crates of field survey instruments",
    purpose: "Field sample retrieval from Lungi Depot",
    pickupPoint: "HQ Logistics Bay",
    destination: "Lungi Depot & Return",
    status: TripStatus.Flagged, // Flagged due to unapproved routing and odometer mismatch
    requestedAt: "2026-07-10T08:00:00-07:00",
    approvedAt: "2026-07-10T08:15:00-07:00",
    startedAt: "2026-07-10T09:00:00-07:00",
    endedAt: "2026-07-10T15:30:00-07:00",
    signOutOdometer: 112200,
    signOutFuelLevel: 75,
    signOutOfficerName: "Sgt. Joseph Bundu",
    signOutTime: "2026-07-10T09:05:00-07:00",
    signInOdometer: 112400, // 200km reported, but actual route is 120km
    signInFuelLevel: 30,
    signInOfficerName: "Officer Marie Kargbo",
    signInTime: "2026-07-10T15:35:00-07:00",
    gpsDistanceKm: 122.5, // Tracker shows 122.5km but driver reported 200km on odometer!
    routeDeviationFlagged: true
  }
];

export const defaultFuelRequests: FuelRequest[] = [
  {
    id: "f1",
    vehicleId: "v1",
    driverId: "d1",
    odometer: 45150,
    requestedLiters: 45,
    estimatedCost: 90,
    stationName: "TotalEnergies Wilberforce",
    timestamp: "2026-07-11T01:30:00-07:00",
    status: "Completed",
    approvedLiters: 45,
    voucherCode: "F-VOUCH-10928",
    receiptPhotoUrl: "https://images.unsplash.com/photo-1554224155-8d04cb21cd6c?auto=format&fit=crop&q=80&w=300",
    pumpPhotoUrl: "https://images.unsplash.com/photo-1527018601619-a508a2be00cd?auto=format&fit=crop&q=80&w=300",
    actualCost: 90,
    actualLiters: 45,
    varianceFlagged: false
  },
  {
    id: "f2",
    vehicleId: "v3",
    driverId: "d3",
    odometer: 112400,
    requestedLiters: 65,
    estimatedCost: 130,
    stationName: "NP Aberdeen Station",
    timestamp: "2026-07-10T16:00:00-07:00",
    status: "Completed",
    approvedLiters: 65,
    voucherCode: "F-VOUCH-81109",
    receiptPhotoUrl: "https://images.unsplash.com/photo-1554224155-8d04cb21cd6c?auto=format&fit=crop&q=80&w=300",
    pumpPhotoUrl: "https://images.unsplash.com/photo-1527018601619-a508a2be00cd?auto=format&fit=crop&q=80&w=300",
    actualCost: 130,
    actualLiters: 65,
    varianceFlagged: true, // FLAG! He traveled 120km, consumed 65 liters of diesel. Tank capacity only matches 11km/l, meaning consumption was expected to be ~11 liters!
    varianceReason: "Calculated consumption is 1.8 km/l. Expected consumption is 11.5 km/l. Huge variance indicates potential fuel siphoning or card misuse."
  },
  {
    id: "f3",
    vehicleId: "v2",
    driverId: "d2",
    odometer: 68150,
    requestedLiters: 35,
    estimatedCost: 70,
    stationName: "Shell East End",
    timestamp: "2026-07-11T03:30:00-07:00",
    status: "Approved",
    approvedLiters: 35,
    voucherCode: "F-VOUCH-33291"
  }
];

export const defaultMaintenanceRequests: MaintenanceRequest[] = [
  {
    id: "m1",
    vehicleId: "v3",
    driverId: "d3",
    category: "Corrective",
    description: "Strange metallic grinding sound from front wheels when braking. Suspension feels unstable.",
    severity: "High",
    odometer: 112400,
    timestamp: "2026-07-10T16:30:00-07:00",
    status: MaintenanceStatus.InGarage,
    garageName: "Freetown Mechanical Hub (Unapproved Garage)",
    quotationAmount: 780,
    beforePhotoUrl: "https://images.unsplash.com/photo-1486006920555-c77dce18193b?auto=format&fit=crop&q=80&w=300",
    completionNotes: "Diagnosis submitted: front brake pads completely worn out, caliper damaged. Rotors need machining."
  },
  {
    id: "m2",
    vehicleId: "v1",
    driverId: "d1",
    category: "Routine",
    description: "Scheduled 45,000 KM Engine Oil & Filter Service.",
    severity: "Low",
    odometer: 45050,
    timestamp: "2026-07-08T09:00:00-07:00",
    status: MaintenanceStatus.Verified,
    garageName: "Toyota Official Country Garage",
    quotationAmount: 180,
    approvedAmount: 180,
    invoiceAmount: 180,
    invoicePhotoUrl: "https://images.unsplash.com/photo-1554224155-8d04cb21cd6c?auto=format&fit=crop&q=80&w=300",
    partsReplaced: [
      { partName: "Premium Synthetic Engine Oil (5L)", partNumber: "TOY-OIL-SYN5", cost: 120, serialInstalled: "OIL-11029" },
      { partName: "Toyota OEM Oil Filter", partNumber: "TOY-FIL-092", cost: 30, serialInstalled: "FIL-90281" },
      { partName: "Sump Plug Gasket", partNumber: "TOY-GAS-881", cost: 10, serialInstalled: "GAS-55219" }
    ],
    beforePhotoUrl: "https://images.unsplash.com/photo-1486006920555-c77dce18193b?auto=format&fit=crop&q=80&w=300",
    afterPhotoUrl: "https://images.unsplash.com/photo-1507136566006-cfc505b114fc?auto=format&fit=crop&q=80&w=300",
    completionNotes: "Routine service performed perfectly. Invoice matches quotation. Odometer verified.",
    testDrivePassed: true
  }
];

export const defaultSpareParts: SparePart[] = [
  { id: "s1", partName: "Premium Synthetic Engine Oil (5L)", partNumber: "TOY-OIL-SYN5", category: "Fluids", compatibleVehicleModel: "Toyota Prado / Hiace", unitCost: 120, stockQty: 18, reorderLevel: 5 },
  { id: "s2", partName: "Toyota OEM Oil Filter", partNumber: "TOY-FIL-092", category: "Filters", compatibleVehicleModel: "Toyota Prado / Hiace", unitCost: 30, stockQty: 24, reorderLevel: 8 },
  { id: "s3", partName: "Heavy Duty Front Brake Pads (Set)", partNumber: "PAD-FR-HD880", category: "Brakes", compatibleVehicleModel: "Toyota Prado / Nissan NV350", unitCost: 85, stockQty: 12, reorderLevel: 4 },
  { id: "s4", partName: "Superpower 12V 75AH Battery", partNumber: "BAT-12V-75AH", category: "Electrical", compatibleVehicleModel: "Universal SUV / Bus", unitCost: 150, stockQty: 3, reorderLevel: 2 },
  { id: "s5", partName: "All-Terrain Tyre (265/65R17)", partNumber: "TYR-AT-17", category: "Tyres", compatibleVehicleModel: "Toyota Prado / Isuzu Truck", unitCost: 180, stockQty: 8, reorderLevel: 4 }
];

export const defaultTyres: Tyre[] = [
  { id: "ty1", vehicleId: "v1", brand: "Michelin", size: "265/65R17", serialNumber: "MICH-881029-A", position: "Front-Left", installedAtOdometer: 40000, installationDate: "2025-11-10", condition: "Good" },
  { id: "ty2", vehicleId: "v1", brand: "Michelin", size: "265/65R17", serialNumber: "MICH-881029-B", position: "Front-Right", installedAtOdometer: 40000, installationDate: "2025-11-10", condition: "Good" },
  { id: "ty3", vehicleId: "v1", brand: "Michelin", size: "265/65R17", serialNumber: "MICH-881029-C", position: "Rear-Left", installedAtOdometer: 40000, installationDate: "2025-11-10", condition: "Good" },
  { id: "ty4", vehicleId: "v1", brand: "Michelin", size: "265/65R17", serialNumber: "MICH-881029-D", position: "Rear-Right", installedAtOdometer: 40000, installationDate: "2025-11-10", condition: "Good" },
  { id: "ty5", vehicleId: "v3", brand: "CheapRoad", size: "205/75R15", serialNumber: "CR-441209-Z", position: "Front-Left", installedAtOdometer: 111500, installationDate: "2026-06-01", condition: "Worn" } // Tyres swapped by driver/garage?
];

export const defaultExceptions: Exception[] = [
  {
    id: "e1",
    type: "Fuel",
    severity: ExceptionSeverity.Critical,
    title: "Extreme Fuel Variance / Suspected Siphoning",
    description: "Vehicle SL-701-XX completed Trip TRIP-2026-0014 reporting 200km distance, but GPS live odometer records indicate only 122.5km traveled. Refueling transaction F2 requested 65L, resulting in a consumption rate of 1.8km per liter against expected 11.5km per liter.",
    vehicleId: "v3",
    driverId: "d3",
    timestamp: "2026-07-10T16:05:00-07:00",
    status: "Open"
  },
  {
    id: "e2",
    type: "Maintenance",
    severity: ExceptionSeverity.High,
    title: "Unapproved Mechanical Garage Dispatch",
    description: "GPS tracking detected Vehicle SL-701-XX remaining stationary for over 4 hours at 'Freetown Mechanical Hub' (unapproved/blacklisted garage) without an authorized fleet manager work order dispatch.",
    vehicleId: "v3",
    driverId: "d3",
    timestamp: "2026-07-10T14:30:00-07:00",
    status: "In Investigation"
  },
  {
    id: "e3",
    type: "Tamper",
    severity: ExceptionSeverity.High,
    title: "GPS Tracker Disconnection Event",
    description: "The GPS module on Vehicle SL-515-FG failed to respond to liveness signals and is marked Offline. Anti-tamper logs show a voltage interruption at the harness connector.",
    vehicleId: "v5",
    timestamp: "2026-07-09T18:30:00-07:00",
    status: "Open"
  }
];

export const defaultIncidents: Incident[] = [
  {
    id: "in1",
    category: "Breakdown",
    timestamp: "2026-07-09T14:15:00-07:00",
    vehicleId: "v3",
    driverId: "d3",
    description: "Radiator hose burst during field transit. Coolant completely drained, engine overheated. Vehicle towed to local yard.",
    location: "Kambia Highway, Mile 34",
    status: "Resolved"
  },
  {
    id: "in2",
    category: "Passenger Complaint",
    timestamp: "2026-07-10T15:00:00-07:00",
    vehicleId: "v3",
    driverId: "d3",
    description: "Passenger reported driver Musa Conteh carried unlisted local commuters along the highway for cash payment, in violation of strict staff transport rules.",
    location: "Lungi Road Terminal",
    status: "Under Investigation"
  }
];

export const defaultAuditLogs: AuditLog[] = [
  {
    id: "l1",
    timestamp: "2026-07-11T01:30:00-07:00",
    userId: "M. Bangura (Fleet Mgr)",
    userRole: "Fleet Manager",
    action: "Approved Fuel Request",
    entityType: "FuelRequest",
    entityId: "f1",
    details: "Approved 45L fuel voucher code F-VOUCH-10928 for driver Alhaji Kamara after confirming route mileage requirements."
  },
  {
    id: "l2",
    timestamp: "2026-07-10T17:30:00-07:00",
    userId: "M. Bangura (Fleet Mgr)",
    userRole: "Fleet Manager",
    action: "Dispatched Work Order",
    entityType: "MaintenanceRequest",
    entityId: "m1",
    details: "Dispatched brake pads replacement to Freetown Mechanical Hub due to high emergency feedback."
  },
  {
    id: "l3",
    timestamp: "2026-07-09T08:00:00-07:00",
    userId: "Admin (System)",
    userRole: "System Admin",
    action: "Rule Change",
    entityType: "PolicyRule",
    entityId: "p2",
    details: "Updated Fuel Variance Tolerance value from 15% to 10% to combat increasing local depot discrepancies."
  }
];
