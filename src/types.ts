export enum VehicleStatus {
  Active = "Active",
  Parked = "Parked",
  UnderMaintenance = "Under Maintenance",
  Grounded = "Grounded",
  Retired = "Retired"
}

export enum TrackerStatus {
  Active = "Active",
  Offline = "Offline",
  Tampered = "Tampered",
  Removed = "Removed"
}

export enum TripStatus {
  Requested = "Requested",
  Approved = "Approved",
  Active = "Active",
  Completed = "Completed",
  Overdue = "Overdue",
  Flagged = "Flagged"
}

export enum DriverStatus {
  Active = "Active",
  Suspended = "Suspended",
  OnLeave = "On Leave",
  Exited = "Exited"
}

export enum MaintenanceStatus {
  Pending = "Pending Approval",
  Approved = "Approved",
  InGarage = "In Garage",
  Completed = "Completed",
  Verified = "Verified"
}

export enum ExceptionSeverity {
  Low = "Low",
  Medium = "Medium",
  High = "High",
  Critical = "Critical"
}

export interface Vehicle {
  id: string;
  registrationNumber: string;
  make: string;
  model: string;
  year: number;
  type: string; // Saloon, SUV, Truck, Bus
  fuelType: "Petrol" | "Diesel";
  tankCapacity: number; // in liters
  expectedFuelConsumption: number; // km per liter
  currentOdometer: number;
  status: VehicleStatus;
  assignedDriverId: string;
  assignedDepartment: string;
  insuranceExpiry: string;
  roadworthinessExpiry: string;
  gpsTrackerId: string;
  trackerStatus: TrackerStatus;
  lastGpsLocation: { lat: number; lng: number; address: string };
  lastGpsUpdateTime: string;
  monthlyFuelLimit: number; // in liters
  currentMonthFuelUsed: number;
}

export interface Driver {
  id: string;
  staffNumber: string;
  name: string;
  phone: string;
  email: string;
  photoUrl: string;
  licenseNumber: string;
  licenseClass: string;
  licenseExpiry: string;
  status: DriverStatus;
  performanceScore: number; // 0 - 100
  riskScore: number; // 0 - 100
}

export interface Trip {
  id: string;
  tripRequestNumber: string;
  vehicleId: string;
  driverId: string;
  department: string;
  passengers: string[];
  cargoNotes?: string;
  purpose: string;
  pickupPoint: string;
  destination: string;
  status: TripStatus;
  
  // Timestamps
  requestedAt: string;
  approvedAt?: string;
  startedAt?: string;
  endedAt?: string;
  overdueThresholdAt?: string;

  // Sign-Out Records (Gate)
  signOutOdometer?: number;
  signOutFuelLevel?: number;
  signOutOfficerName?: string;
  signOutTime?: string;

  // Sign-In Records (Gate)
  signInOdometer?: number;
  signInFuelLevel?: number;
  signInOfficerName?: string;
  signInTime?: string;

  // GPS Route Details
  gpsDistanceKm?: number;
  routeDeviationFlagged?: boolean;
}

export interface Inspection {
  id: string;
  tripId?: string;
  vehicleId: string;
  driverId: string;
  timestamp: string;
  type: "Pre-Trip" | "Post-Trip";
  
  // Checklist (Pass / Fail)
  fuelLevelOk: boolean;
  oilLevelOk: boolean;
  coolantOk: boolean;
  tyresOk: boolean;
  brakesOk: boolean;
  lightsOk: boolean;
  bodyConditionOk: boolean;
  spareTyreToolsOk: boolean;
  
  notes?: string;
  photoUrl?: string;
}

export interface FuelRequest {
  id: string;
  vehicleId: string;
  driverId: string;
  odometer: number;
  requestedLiters: number;
  estimatedCost: number;
  stationName: string;
  timestamp: string;
  status: "Pending" | "Approved" | "Rejected" | "Completed";
  approvedLiters?: number;
  voucherCode?: string;
  receiptPhotoUrl?: string;
  pumpPhotoUrl?: string;
  actualCost?: number;
  actualLiters?: number;
  varianceFlagged?: boolean;
  varianceReason?: string;
}

export interface MaintenanceRequest {
  id: string;
  vehicleId: string;
  driverId: string;
  category: "Routine" | "Corrective" | "Emergency";
  description: string;
  severity: "Low" | "Medium" | "High";
  odometer: number;
  timestamp: string;
  status: MaintenanceStatus;
  
  // Garage and Quotation
  garageName?: string;
  quotationAmount?: number;
  approvedAmount?: number;
  invoiceAmount?: number;
  invoicePhotoUrl?: string;
  
  // Spare Parts Installed
  partsReplaced?: Array<{
    partName: string;
    partNumber?: string;
    cost: number;
    serialInstalled?: string;
    serialRemoved?: string;
  }>;
  
  beforePhotoUrl?: string;
  afterPhotoUrl?: string;
  completionNotes?: string;
  testDrivePassed?: boolean;
}

export interface SparePart {
  id: string;
  partName: string;
  partNumber: string;
  category: string;
  compatibleVehicleModel: string;
  unitCost: number;
  stockQty: number;
  reorderLevel: number;
}

export interface Tyre {
  id: string;
  vehicleId: string;
  brand: string;
  size: string;
  serialNumber: string;
  position: "Front-Left" | "Front-Right" | "Rear-Left" | "Rear-Right" | "Spare";
  installedAtOdometer: number;
  removedAtOdometer?: number;
  installationDate: string;
  condition: "New" | "Good" | "Worn" | "Replaced";
}

export interface Exception {
  id: string;
  type: "Fuel" | "Maintenance" | "Trip" | "Manifest" | "Tamper" | "Policy";
  severity: ExceptionSeverity;
  title: string;
  description: string;
  vehicleId: string;
  driverId?: string;
  timestamp: string;
  status: "Open" | "In Investigation" | "Resolved";
  resolutionNotes?: string;
  resolvedBy?: string;
}

export interface AuditLog {
  id: string;
  timestamp: string;
  userId: string;
  userRole: string;
  action: string;
  entityType: string;
  entityId: string;
  details: string;
}

export interface PolicyRule {
  id: string;
  name: string;
  category: "Fuel" | "Trip" | "Maintenance" | "Audit";
  value: string;
  description: string;
}

export interface Incident {
  id: string;
  category: "Accident" | "Breakdown" | "Violation" | "Theft" | "Passenger Complaint";
  timestamp: string;
  vehicleId: string;
  driverId: string;
  description: string;
  location: string;
  photoUrl?: string;
  status: "Pending" | "Under Investigation" | "Resolved";
}
