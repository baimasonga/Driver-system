import React, { useState } from "react";
import {
  Smartphone,
  Wifi,
  WifiOff,
  User,
  Car,
  RotateCw,
  TrendingUp,
  MapPin,
  ClipboardCheck,
  AlertTriangle,
  Flame,
  CheckCircle,
  Clock,
  Navigation,
  FileText,
  DollarSign,
  Plus,
  Compass,
  Check,
  X,
  ScanQrCode,
  Lock,
  ArrowRight
} from "lucide-react";
import {
  Vehicle,
  Driver,
  Trip,
  TripStatus,
  Inspection,
  FuelRequest,
  MaintenanceRequest,
  MaintenanceStatus,
  Exception,
  ExceptionSeverity,
  AuditLog,
  Incident,
  VehicleStatus
} from "../types";

interface MobileSimulatorProps {
  vehicles: Vehicle[];
  drivers: Driver[];
  trips: Trip[];
  fuelRequests: FuelRequest[];
  maintenanceRequests: MaintenanceRequest[];
  exceptions: Exception[];
  incidents: Incident[];
  auditLogs: AuditLog[];
  currentDriver: Driver;
  onUpdateVehicles: (v: Vehicle[]) => void;
  onUpdateTrips: (t: Trip[]) => void;
  onUpdateFuelRequests: (f: FuelRequest[]) => void;
  onUpdateMaintenanceRequests: (m: MaintenanceRequest[]) => void;
  onUpdateExceptions: (e: Exception[]) => void;
  onUpdateIncidents: (i: Incident[]) => void;
  onAddAuditLog: (action: string, entityType: string, entityId: string, details: string) => void;
}

export default function MobileSimulator({
  vehicles,
  drivers,
  trips,
  fuelRequests,
  maintenanceRequests,
  exceptions,
  incidents,
  auditLogs,
  currentDriver,
  onUpdateVehicles,
  onUpdateTrips,
  onUpdateFuelRequests,
  onUpdateMaintenanceRequests,
  onUpdateExceptions,
  onUpdateIncidents,
  onAddAuditLog
}: MobileSimulatorProps) {
  // Mobile app tabs: 'home' | 'trips' | 'fuel' | 'maintenance' | 'gate'
  const [activeTab, setActiveTab] = useState<"home" | "trips" | "fuel" | "maintenance" | "gate">("home");
  const [isOnline, setIsOnline] = useState<boolean>(true);
  
  // Local Forms State
  const [offlineQueue, setOfflineQueue] = useState<any[]>([]);
  const [showInspection, setShowInspection] = useState<boolean>(false);
  const [showFuelRequest, setShowFuelRequest] = useState<boolean>(false);
  const [showMaintenanceRequest, setShowMaintenanceRequest] = useState<boolean>(false);
  const [showGateSignOut, setShowGateSignOut] = useState<boolean>(false);
  const [showGateSignIn, setShowGateSignIn] = useState<boolean>(false);
  const [showIncidentForm, setShowIncidentForm] = useState<boolean>(false);

  // Pre-Trip Checklist
  const [checklist, setChecklist] = useState({
    fuelLevelOk: true,
    oilLevelOk: true,
    coolantOk: true,
    tyresOk: true,
    brakesOk: true,
    lightsOk: true,
    bodyConditionOk: true,
    spareTyreToolsOk: true,
    notes: ""
  });

  // Fuel request fields
  const [fuelOdometer, setFuelOdometer] = useState<number>(currentDriver.id === "d3" ? 112450 : 45220);
  const [fuelLiters, setFuelLiters] = useState<number>(40);
  const [fuelCost, setFuelCost] = useState<number>(80);
  const [fuelStation, setFuelStation] = useState<string>("TotalEnergies Wilberforce");
  const [fuelReceiptPhoto, setFuelReceiptPhoto] = useState<string>("https://images.unsplash.com/photo-1554224155-8d04cb21cd6c?auto=format&fit=crop&q=80&w=300");
  const [fuelPumpPhoto, setFuelPumpPhoto] = useState<string>("https://images.unsplash.com/photo-1527018601619-a508a2be00cd?auto=format&fit=crop&q=80&w=300");

  // Maintenance fields
  const [mCategory, setMCategory] = useState<"Routine" | "Corrective" | "Emergency">("Corrective");
  const [mDescription, setMDescription] = useState<string>("");
  const [mSeverity, setMSeverity] = useState<"Low" | "Medium" | "High">("Medium");
  const [mOdometer, setMOdometer] = useState<number>(45250);

  // Incident fields
  const [incidentCategory, setIncidentCategory] = useState<"Accident" | "Breakdown" | "Violation" | "Theft" | "Passenger Complaint">("Breakdown");
  const [incidentDescription, setIncidentDescription] = useState<string>("");
  const [incidentLocation, setIncidentLocation] = useState<string>("");

  // Gate Scan state
  const [scannedVehicleId, setScannedVehicleId] = useState<string>("v1");
  const [scannedDriverId, setScannedDriverId] = useState<string>("d1");
  const [gateOdometer, setGateOdometer] = useState<number>(45200);
  const [gateFuel, setGateFuel] = useState<number>(80);
  const [passengerCount, setPassengerCount] = useState<number>(2);

  const assignedVehicle = vehicles.find(v => v.assignedDriverId === currentDriver.id) || vehicles[0];
  const activeTrip = trips.find(t => t.driverId === currentDriver.id && t.status === TripStatus.Active);
  const pendingTrip = trips.find(t => t.driverId === currentDriver.id && t.status === TripStatus.Approved);

  // Sync Offline Queue
  const triggerSync = () => {
    if (offlineQueue.length === 0) return;
    
    let updatedTrips = [...trips];
    let updatedFuel = [...fuelRequests];
    let updatedMaint = [...maintenanceRequests];
    let updatedExceptions = [...exceptions];
    let updatedVehicles = [...vehicles];
    let updatedIncidents = [...incidents];

    offlineQueue.forEach(item => {
      onAddAuditLog(
        `Offline Sync: ${item.type}`,
        item.type,
        item.data.id || "N/A",
        `Synced offline capture created at ${new Date(item.timestamp).toLocaleTimeString()}`
      );

      if (item.type === "TripStart") {
        const tripIdx = updatedTrips.findIndex(t => t.id === item.data.tripId);
        if (tripIdx !== -1) {
          updatedTrips[tripIdx].status = TripStatus.Active;
          updatedTrips[tripIdx].startedAt = item.data.time;
          updatedTrips[tripIdx].signOutOdometer = item.data.odometer;
        }
      } else if (item.type === "TripEnd") {
        const tripIdx = updatedTrips.findIndex(t => t.id === item.data.tripId);
        if (tripIdx !== -1) {
          const trip = updatedTrips[tripIdx];
          trip.status = TripStatus.Completed;
          trip.endedAt = item.data.time;
          trip.signInOdometer = item.data.odometer;
          trip.signInFuelLevel = item.data.fuelLevel;

          // FRAUD CHECK: Odometer / Fuel discrepancy
          const startOdo = trip.signOutOdometer || 0;
          const reportedDist = item.data.odometer - startOdo;
          const actualGpsDist = trip.gpsDistanceKm || reportedDist;
          
          if (reportedDist > actualGpsDist * 1.5 && trip.driverId === "d3") {
            // Musa's discrepancy
            trip.status = TripStatus.Flagged;
            const excId = "exc-" + Math.random().toString(36).substr(2, 9);
            updatedExceptions.push({
              id: excId,
              type: "Trip",
              severity: ExceptionSeverity.High,
              title: "Odometer Inflation / Route Falsification",
              description: `Trip ${trip.tripRequestNumber} reported ${reportedDist}km by odometer, but GPS tracking reports only ${actualGpsDist}km. Discrepancy of ${reportedDist - actualGpsDist}km detected.`,
              vehicleId: trip.vehicleId,
              driverId: trip.driverId,
              timestamp: new Date().toISOString(),
              status: "Open"
            });
          }
        }
      } else if (item.type === "Fuel") {
        updatedFuel.unshift(item.data);
        
        // FRAUD CHECK: Fuel volume exceeds tank capacity or suspicious variance
        const veh = updatedVehicles.find(v => v.id === item.data.vehicleId);
        if (veh) {
          if (item.data.requestedLiters > veh.tankCapacity) {
            const excId = "exc-" + Math.random().toString(36).substr(2, 9);
            updatedExceptions.push({
              id: excId,
              type: "Fuel",
              severity: ExceptionSeverity.Critical,
              title: "Fuel Purchase Exceeds Tank Capacity",
              description: `Refuel request of ${item.data.requestedLiters}L for vehicle ${veh.registrationNumber} exceeds total tank capacity of ${veh.tankCapacity}L.`,
              vehicleId: veh.id,
              driverId: item.data.driverId,
              timestamp: new Date().toISOString(),
              status: "Open"
            });
          }
          // Update monthly fuel used
          veh.currentMonthFuelUsed += item.data.requestedLiters;
        }
      } else if (item.type === "Maintenance") {
        updatedMaint.unshift(item.data);
      } else if (item.type === "Incident") {
        updatedIncidents.unshift(item.data);
      }
    });

    onUpdateTrips(updatedTrips);
    onUpdateFuelRequests(updatedFuel);
    onUpdateMaintenanceRequests(updatedMaint);
    onUpdateExceptions(updatedExceptions);
    onUpdateVehicles(updatedVehicles);
    onUpdateIncidents(updatedIncidents);
    setOfflineQueue([]);
    alert("Offline operations synchronized successfully with Fleet central server!");
  };

  const handleStartTrip = () => {
    if (!pendingTrip) return;
    
    const startData = {
      tripId: pendingTrip.id,
      odometer: assignedVehicle.currentOdometer,
      time: new Date().toISOString()
    };

    if (!isOnline) {
      setOfflineQueue([...offlineQueue, { type: "TripStart", timestamp: Date.now(), data: startData }]);
      // Optimistic offline state update
      const updated = trips.map(t => t.id === pendingTrip.id ? { ...t, status: TripStatus.Active } : t);
      onUpdateTrips(updated);
      onAddAuditLog(currentDriver.name, "Trip", pendingTrip.id, "Started trip in offline mode.");
      setShowInspection(false);
      return;
    }

    // Online
    const updated = trips.map(t => t.id === pendingTrip.id ? {
      ...t,
      status: TripStatus.Active,
      startedAt: new Date().toISOString(),
      signOutOdometer: assignedVehicle.currentOdometer,
      signOutTime: new Date().toISOString()
    } : t);

    // Update vehicle status to Active/Moving
    const updatedVehicles = vehicles.map(v => v.id === assignedVehicle.id ? { ...v, status: VehicleStatus.Active } : v);
    onUpdateVehicles(updatedVehicles);

    onUpdateTrips(updated);
    onAddAuditLog(currentDriver.name, "Trip", pendingTrip.id, "Started trip officially. GPS live feed online.");
    setShowInspection(false);
  };

  const handleEndTrip = (endOdometer: number, endFuelLevel: number) => {
    if (!activeTrip) return;

    const endData = {
      tripId: activeTrip.id,
      odometer: endOdometer,
      fuelLevel: endFuelLevel,
      time: new Date().toISOString()
    };

    if (!isOnline) {
      setOfflineQueue([...offlineQueue, { type: "TripEnd", timestamp: Date.now(), data: endData }]);
      const updated = trips.map(t => t.id === activeTrip.id ? { ...t, status: TripStatus.Completed } : t);
      onUpdateTrips(updated);
      onAddAuditLog(currentDriver.name, "Trip", activeTrip.id, "Completed trip in offline mode.");
      return;
    }

    // Online complete
    let updatedTrips = [...trips];
    const tripIdx = updatedTrips.findIndex(t => t.id === activeTrip.id);
    if (tripIdx !== -1) {
      const trip = updatedTrips[tripIdx];
      trip.status = TripStatus.Completed;
      trip.endedAt = new Date().toISOString();
      trip.signInOdometer = endOdometer;
      trip.signInFuelLevel = endFuelLevel;

      // FRAUD ENGINE: Compare odometer reporting with expected distance
      const startOdo = trip.signOutOdometer || assignedVehicle.currentOdometer - 30;
      const reportedDist = endOdometer - startOdo;
      const gpsExpectedDist = trip.gpsDistanceKm || 15;

      // Update vehicle's current odometer
      const updatedVehicles = vehicles.map(v => {
        if (v.id === trip.vehicleId) {
          return {
            ...v,
            currentOdometer: endOdometer,
            status: VehicleStatus.Parked
          };
        }
        return v;
      });
      onUpdateVehicles(updatedVehicles);

      // Trigger anomaly alerts
      if (reportedDist > gpsExpectedDist * 1.4 && currentDriver.id === "d3") {
        // High discrepancy mock
        trip.status = TripStatus.Flagged;
        const excId = "exc-" + Math.random().toString(36).substr(2, 9);
        const newExceptions = [
          {
            id: excId,
            type: "Trip" as const,
            severity: ExceptionSeverity.High,
            title: "Odometer Inflation / Trip Tampering",
            description: `Driver ${currentDriver.name} completed trip ${trip.tripRequestNumber} with final odometer ${endOdometer} (+${reportedDist}km), but GPS trackers recorded only ${gpsExpectedDist.toFixed(1)}km traveled. Discrepancy suggests manual odometer spin or unauthorized sideline trips.`,
            vehicleId: trip.vehicleId,
            driverId: trip.driverId,
            timestamp: new Date().toISOString(),
            status: "Open" as const
          },
          ...exceptions
        ];
        onUpdateExceptions(newExceptions);
        onAddAuditLog("System (Fraud Detection)", "Exception", excId, "Odometer discrepancy auto-exception triggered.");
      }

      onUpdateTrips(updatedTrips);
      onAddAuditLog(currentDriver.name, "Trip", trip.id, "Ended trip. Odometer photo submitted, route checked.");
    }
  };

  const handleSubmitFuelRequest = () => {
    const reqId = "req-" + Math.random().toString(36).substr(2, 9);
    const newReq: FuelRequest = {
      id: reqId,
      vehicleId: assignedVehicle.id,
      driverId: currentDriver.id,
      odometer: fuelOdometer,
      requestedLiters: fuelLiters,
      estimatedCost: fuelCost,
      stationName: fuelStation,
      timestamp: new Date().toISOString(),
      status: "Pending",
      voucherCode: "F-VOUCH-" + Math.floor(Math.random() * 90000 + 10000)
    };

    // Auto-complete fuel requests in simulator for easy demo
    newReq.status = "Completed";
    newReq.receiptPhotoUrl = fuelReceiptPhoto;
    newReq.pumpPhotoUrl = fuelPumpPhoto;
    newReq.actualCost = fuelCost;
    newReq.actualLiters = fuelLiters;

    // Check for high fuel consumption anomaly
    // E.g., if Musa is refilling 65L after only traveling 120km
    const expectedConsump = assignedVehicle.expectedFuelConsumption; // km/liter
    const distanceTraveled = 120; // assumed since last fill for demo
    const calculatedConsumption = distanceTraveled / fuelLiters;

    if (calculatedConsumption < expectedConsump * 0.4 && currentDriver.id === "d3") {
      newReq.varianceFlagged = true;
      newReq.varianceReason = `Calculated consumption is ${calculatedConsumption.toFixed(1)} km/l, which is way below the expected ${expectedConsump} km/l. Highly indicative of fuel siphoning or receipts inflation.`;
    }

    if (!isOnline) {
      setOfflineQueue([...offlineQueue, { type: "Fuel", timestamp: Date.now(), data: newReq }]);
      alert("Fuel request saved offline. It will synchronize when connection is restored.");
      setShowFuelRequest(false);
      return;
    }

    // Add request
    onUpdateFuelRequests([newReq, ...fuelRequests]);

    // Update vehicle's fuel count
    const updatedVehicles = vehicles.map(v => {
      if (v.id === assignedVehicle.id) {
        return {
          ...v,
          currentMonthFuelUsed: v.currentMonthFuelUsed + fuelLiters
        };
      }
      return v;
    });
    onUpdateVehicles(updatedVehicles);

    // If flagged, append exception
    if (newReq.varianceFlagged) {
      const excId = "exc-" + Math.random().toString(36).substr(2, 9);
      const newExc: Exception = {
        id: excId,
        type: "Fuel",
        severity: ExceptionSeverity.Critical,
        title: "Extreme Fuel Consumption Variance",
        description: `Refuel transaction for Vehicle ${assignedVehicle.registrationNumber} reported ${fuelLiters}L filled at ${fuelStation}. Calculated mileage consumption is ${calculatedConsumption.toFixed(1)} km/l, deviating drastically from expected ${expectedConsump} km/l.`,
        vehicleId: assignedVehicle.id,
        driverId: currentDriver.id,
        timestamp: new Date().toISOString(),
        status: "Open"
      };
      onUpdateExceptions([newExc, ...exceptions]);
      onAddAuditLog("System (Fraud Detection)", "Exception", excId, "Extreme fuel variance alert triggered on Musa Conteh.");
    }

    onAddAuditLog(currentDriver.name, "FuelRequest", reqId, `Submitted fuel claim of ${fuelLiters}L at ${fuelStation}. Odometer: ${fuelOdometer}`);
    setShowFuelRequest(false);
    alert("Fuel claim submitted successfully. Gas voucher reconciled!");
  };

  const handleSubmitMaintenance = () => {
    const reqId = "maint-" + Math.random().toString(36).substr(2, 9);
    const newMaint: MaintenanceRequest = {
      id: reqId,
      vehicleId: assignedVehicle.id,
      driverId: currentDriver.id,
      category: mCategory,
      description: mDescription,
      severity: mSeverity,
      odometer: mOdometer,
      timestamp: new Date().toISOString(),
      status: MaintenanceStatus.Pending,
      beforePhotoUrl: "https://images.unsplash.com/photo-1486006920555-c77dce18193b?auto=format&fit=crop&q=80&w=300"
    };

    if (!isOnline) {
      setOfflineQueue([...offlineQueue, { type: "Maintenance", timestamp: Date.now(), data: newMaint }]);
      alert("Maintenance request saved offline.");
      setShowMaintenanceRequest(false);
      return;
    }

    onUpdateMaintenanceRequests([newMaint, ...maintenanceRequests]);
    onAddAuditLog(currentDriver.name, "MaintenanceRequest", reqId, `Reported vehicle defect: ${mDescription.substring(0, 40)}...`);
    setShowMaintenanceRequest(false);
    alert("Maintenance defect logged. Fleet Manager notified for diagnostic dispatch.");
  };

  const handleSubmitIncident = () => {
    const incId = "inc-" + Math.random().toString(36).substr(2, 9);
    const newInc: Incident = {
      id: incId,
      category: incidentCategory,
      timestamp: new Date().toISOString(),
      vehicleId: assignedVehicle.id,
      driverId: currentDriver.id,
      description: incidentDescription,
      location: incidentLocation,
      status: "Pending"
    };

    if (!isOnline) {
      setOfflineQueue([...offlineQueue, { type: "Incident", timestamp: Date.now(), data: newInc }]);
      alert("Incident saved offline.");
      setShowIncidentForm(false);
      return;
    }

    onUpdateIncidents([newInc, ...incidents]);
    onAddAuditLog(currentDriver.name, "Incident", incId, `Reported ${incidentCategory}: ${incidentDescription.substring(0, 40)}`);
    setShowIncidentForm(false);
    alert("Incident successfully reported. Security and Insurance divisions notified.");
  };

  // Gate actions
  const handleGateSignOutSubmit = () => {
    // Look up active trip or create one
    const trip = trips.find(t => t.driverId === scannedDriverId && t.vehicleId === scannedVehicleId && t.status === TripStatus.Approved);
    let updatedTrips = [...trips];
    
    if (trip) {
      const idx = updatedTrips.findIndex(t => t.id === trip.id);
      updatedTrips[idx] = {
        ...updatedTrips[idx],
        status: TripStatus.Active,
        startedAt: new Date().toISOString(),
        signOutOdometer: gateOdometer,
        signOutFuelLevel: gateFuel,
        signOutOfficerName: "Gate Sergeant Joseph",
        signOutTime: new Date().toISOString()
      };
    } else {
      // Emergency or unapproved sign-out
      const newTripId = "trip-" + Math.random().toString(36).substr(2, 9);
      const emergencyTrip: Trip = {
        id: newTripId,
        tripRequestNumber: "TRIP-EMERG-" + Math.floor(Math.random() * 9000 + 1000),
        vehicleId: scannedVehicleId,
        driverId: scannedDriverId,
        department: "Operations Gate Override",
        passengers: [`Unscheduled trip - ${passengerCount} passengers`],
        purpose: "Emergency off-duty sign-out / No pre-approved trip order",
        pickupPoint: "HQ East Gate Depot",
        destination: "External dispatch destination",
        status: TripStatus.Flagged,
        requestedAt: new Date().toISOString(),
        signOutOdometer: gateOdometer,
        signOutFuelLevel: gateFuel,
        signOutOfficerName: "Gate Sergeant Joseph",
        signOutTime: new Date().toISOString()
      };
      updatedTrips.unshift(emergencyTrip);

      // Trigger exception: Gate Pass movement without approved order
      const excId = "exc-" + Math.random().toString(36).substr(2, 9);
      const newExc: Exception = {
        id: excId,
        type: "Policy",
        severity: ExceptionSeverity.High,
        title: "Unauthorized Vehicle Gate Sign-Out",
        description: `Vehicle Registration Number ${vehicles.find(v => v.id === scannedVehicleId)?.registrationNumber} left the depot gate with driver ${drivers.find(d => d.id === scannedDriverId)?.name} without a pre-approved digital movement slip or trip order.`,
        vehicleId: scannedVehicleId,
        driverId: scannedDriverId,
        timestamp: new Date().toISOString(),
        status: "Open"
      };
      onUpdateExceptions([newExc, ...exceptions]);
    }

    // Set vehicle status to Active
    const updatedVehs = vehicles.map(v => v.id === scannedVehicleId ? { ...v, currentOdometer: gateOdometer, status: VehicleStatus.Active } : v);
    onUpdateVehicles(updatedVehs);
    onUpdateTrips(updatedTrips);
    onAddAuditLog("Gate Sgt. Joseph", "VehicleSignOut", scannedVehicleId, `Signed out vehicle with driver. Gate Pass recorded.`);
    setShowGateSignOut(false);
    alert("Gate Sign-out Authorized. Movement monitoring started.");
  };

  const handleGateSignInSubmit = () => {
    const trip = trips.find(t => t.vehicleId === scannedVehicleId && t.status === TripStatus.Active);
    let updatedTrips = [...trips];

    if (trip) {
      const idx = updatedTrips.findIndex(t => t.id === trip.id);
      updatedTrips[idx] = {
        ...updatedTrips[idx],
        status: TripStatus.Completed,
        endedAt: new Date().toISOString(),
        signInOdometer: gateOdometer,
        signInFuelLevel: gateFuel,
        signInOfficerName: "Gate Sergeant Joseph",
        signInTime: new Date().toISOString()
      };

      // Verify odometer delta against tracker gps data
      const odoDelta = gateOdometer - (updatedTrips[idx].signOutOdometer || 0);
      const gpsDistance = updatedTrips[idx].gpsDistanceKm || odoDelta;

      if (odoDelta > gpsDistance * 1.5 && scannedDriverId === "d3") {
        updatedTrips[idx].status = TripStatus.Flagged;
        const excId = "exc-" + Math.random().toString(36).substr(2, 9);
        onUpdateExceptions([
          {
            id: excId,
            type: "Trip",
            severity: ExceptionSeverity.High,
            title: "Odometer Fraud Warning at Gate Pass",
            description: `Vehicle odometer delta is ${odoDelta}km but GPS logger records ${gpsDistance.toFixed(1)}km. 80km variance detected at gate sign-in.`,
            vehicleId: scannedVehicleId,
            driverId: scannedDriverId,
            timestamp: new Date().toISOString(),
            status: "Open"
          },
          ...exceptions
        ]);
      }
    }

    const updatedVehs = vehicles.map(v => v.id === scannedVehicleId ? { ...v, currentOdometer: gateOdometer, status: VehicleStatus.Parked } : v);
    onUpdateVehicles(updatedVehs);
    onUpdateTrips(updatedTrips);
    onAddAuditLog("Gate Sgt. Joseph", "VehicleSignIn", scannedVehicleId, `Signed in vehicle. Odometer: ${gateOdometer}, Fuel level: ${gateFuel}%`);
    setShowGateSignIn(false);
    alert("Gate Sign-in Complete. Keys and logbook returned.");
  };

  return (
    <div className="flex flex-col items-center justify-center p-4">
      {/* Smartphone Outer Container */}
      <div className="relative w-[345px] h-[710px] bg-neutral-900 rounded-[42px] border-[10px] border-neutral-800 shadow-[0_25px_60px_-15px_rgba(0,0,0,0.6)] flex flex-col overflow-hidden">
        
        {/* Notch Area */}
        <div className="absolute top-0 left-1/2 -translate-x-1/2 w-40 h-5 bg-neutral-800 rounded-b-2xl z-50 flex items-center justify-center">
          <div className="w-12 h-1 bg-neutral-900 rounded-full mb-1"></div>
        </div>

        {/* Status Bar */}
        <div className="h-11 bg-neutral-900 text-white flex justify-between items-end px-6 pb-1.5 text-[11px] font-medium z-40">
          <span>03:55 AM</span>
          <div className="flex items-center space-x-2">
            <button
              onClick={() => {
                setIsOnline(!isOnline);
                if (!isOnline) {
                  // Trigger automatic sync trigger when turning online
                  setTimeout(() => triggerSync(), 200);
                }
              }}
              className="flex items-center focus:outline-none"
              title="Toggle network connectivity"
            >
              {isOnline ? (
                <Wifi className="w-3.5 h-3.5 text-emerald-400" />
              ) : (
                <WifiOff className="w-3.5 h-3.5 text-rose-500" />
              )}
            </button>
            <span className="bg-emerald-500/20 text-emerald-400 text-[9px] px-1.5 py-0.2 rounded font-mono">
              {isOnline ? "Online" : "Offline"}
            </span>
          </div>
        </div>

        {/* Main Content Area */}
        <div className="flex-1 bg-neutral-950 text-neutral-100 flex flex-col relative overflow-y-auto">
          
          {/* Offline Sync Floating Alert */}
          {offlineQueue.length > 0 && (
            <div className="bg-amber-600 text-neutral-900 text-xs py-1.5 px-3 flex justify-between items-center font-semibold">
              <span className="flex items-center">
                <AlertTriangle className="w-3.5 h-3.5 mr-1" /> {offlineQueue.length} unsynced reports
              </span>
              {isOnline ? (
                <button
                  onClick={triggerSync}
                  className="bg-neutral-900 text-amber-400 px-2 py-0.5 rounded text-[10px] hover:bg-neutral-800 font-mono"
                >
                  Sync Now
                </button>
              ) : (
                <span className="text-[10px] opacity-75">Waiting for wifi</span>
              )}
            </div>
          )}

          {/* Core Content Switching */}
          {activeTab === "home" && (
            <div className="p-4 flex flex-col space-y-4">
              {/* Profile Bar */}
              <div className="flex items-center justify-between bg-neutral-900/50 p-3 rounded-2xl border border-neutral-800">
                <div className="flex items-center space-x-3">
                  <img
                    src={currentDriver.photoUrl}
                    alt={currentDriver.name}
                    className="w-10 h-10 rounded-full object-cover border-2 border-amber-500"
                  />
                  <div>
                    <h4 className="text-sm font-bold text-neutral-100">{currentDriver.name}</h4>
                    <p className="text-[11px] text-neutral-400 font-mono">{currentDriver.staffNumber}</p>
                  </div>
                </div>
                <div className="text-right">
                  <span className={`text-[10px] px-2 py-0.5 rounded-full ${
                    currentDriver.riskScore > 50 ? "bg-rose-500/20 text-rose-400" : "bg-emerald-500/20 text-emerald-400"
                  } font-mono font-bold`}>
                    Risk: {currentDriver.riskScore}
                  </span>
                </div>
              </div>

              {/* Duty Vehicle Widget */}
              <div className="bg-neutral-900 p-3 rounded-2xl border border-neutral-800">
                <div className="flex justify-between items-start mb-2">
                  <span className="text-xs text-neutral-400 uppercase font-bold tracking-wider flex items-center">
                    <Car className="w-3.5 h-3.5 mr-1 text-amber-500" /> Assigned Vehicle
                  </span>
                  <span className="text-xs font-mono text-emerald-400 font-bold">{assignedVehicle.registrationNumber}</span>
                </div>
                <h3 className="text-sm font-extrabold">{assignedVehicle.make} {assignedVehicle.model}</h3>
                <div className="grid grid-cols-2 gap-2 mt-3 text-[11px] text-neutral-400 font-mono">
                  <div className="bg-neutral-950 p-1.5 rounded">
                    <span>Odometer</span>
                    <p className="text-white font-bold text-xs">{assignedVehicle.currentOdometer.toLocaleString()} KM</p>
                  </div>
                  <div className="bg-neutral-950 p-1.5 rounded">
                    <span>Fuel Tank</span>
                    <p className="text-white font-bold text-xs">{assignedVehicle.tankCapacity}L (Cap)</p>
                  </div>
                </div>
              </div>

              {/* Trip Control Box */}
              {activeTrip ? (
                <div className="bg-emerald-950/40 border border-emerald-500/30 p-4 rounded-2xl flex flex-col space-y-3">
                  <div className="flex justify-between items-center">
                    <span className="text-emerald-400 text-[11px] font-bold font-mono flex items-center animate-pulse">
                      <Navigation className="w-3 h-3 mr-1 text-emerald-400" /> TRIP IN PROGRESS
                    </span>
                    <span className="text-neutral-400 text-[10px] font-mono">{activeTrip.tripRequestNumber}</span>
                  </div>
                  <div>
                    <p className="text-[11px] text-neutral-400">Destination</p>
                    <h4 className="text-sm font-bold text-neutral-100 flex items-center">
                      <MapPin className="w-3.5 h-3.5 mr-1 text-rose-500" /> {activeTrip.destination}
                    </h4>
                  </div>
                  
                  {/* End Trip Odometer Prompt */}
                  <div className="bg-neutral-950/80 p-2 rounded-xl border border-neutral-800 text-[11px]">
                    <div className="flex justify-between items-center mb-1 text-neutral-400 font-mono">
                      <span>Enter Final Odometer:</span>
                      <span className="text-white font-bold">{assignedVehicle.currentOdometer + (currentDriver.id === "d3" ? 200 : 15)} KM</span>
                    </div>
                    <p className="text-[9px] text-amber-400 italic">Odometer photo evidence matches vehicle dashboard tracker.</p>
                  </div>

                  <button
                    onClick={() => {
                      // Musa Conteh 'd3' reports 200km instead of actual 120km to demonstrate mileage padding fraud detection!
                      const calculatedEndOdo = assignedVehicle.currentOdometer + (currentDriver.id === "d3" ? 200 : 15);
                      handleEndTrip(calculatedEndOdo, 45);
                    }}
                    className="w-full py-2.5 bg-rose-600 hover:bg-rose-700 active:scale-95 transition text-white font-extrabold text-xs rounded-xl shadow-lg flex items-center justify-center space-x-1"
                  >
                    <span>Complete Trip & Submit Photos</span>
                  </button>
                </div>
              ) : pendingTrip ? (
                <div className="bg-amber-950/30 border border-amber-500/30 p-4 rounded-2xl flex flex-col space-y-3">
                  <div className="flex justify-between items-center">
                    <span className="text-amber-400 text-[11px] font-bold font-mono flex items-center">
                      <Clock className="w-3 h-3 mr-1" /> TRIP ASSIGNED (APPROVED)
                    </span>
                    <span className="text-neutral-400 text-[10px]">{pendingTrip.tripRequestNumber}</span>
                  </div>
                  <div>
                    <p className="text-[11px] text-neutral-400">Target Destination</p>
                    <h4 className="text-sm font-bold text-neutral-100 flex items-center">
                      <MapPin className="w-3.5 h-3.5 mr-1 text-amber-500" /> {pendingTrip.destination}
                    </h4>
                  </div>
                  <button
                    onClick={() => setShowInspection(true)}
                    className="w-full py-2.5 bg-amber-500 hover:bg-amber-600 text-neutral-900 font-extrabold text-xs rounded-xl shadow-lg flex items-center justify-center space-x-1"
                  >
                    <ClipboardCheck className="w-4 h-4" />
                    <span>Run Pre-Trip Digital Check</span>
                  </button>
                </div>
              ) : (
                <div className="bg-neutral-900/60 p-4 rounded-2xl border border-neutral-800 text-center py-6">
                  <Compass className="w-8 h-8 text-neutral-500 mx-auto mb-2" />
                  <h4 className="text-sm font-bold text-neutral-300">No active or pending trip assignment</h4>
                  <p className="text-[11px] text-neutral-500 mt-1">Contact dispatch supervisor to assign a new movement order.</p>
                </div>
              )}

              {/* Quick Actions Panel */}
              <div className="grid grid-cols-2 gap-3">
                <button
                  onClick={() => setShowFuelRequest(true)}
                  className="bg-neutral-900 hover:bg-neutral-800 p-3 rounded-xl border border-neutral-800 flex flex-col items-center justify-center space-y-1.5 text-center active:scale-95 transition"
                >
                  <div className="w-8 h-8 rounded-lg bg-amber-500/10 flex items-center justify-center text-amber-500">
                    <Flame className="w-4 h-4" />
                  </div>
                  <span className="text-[11px] font-bold">Request Fuel</span>
                </button>

                <button
                  onClick={() => setShowMaintenanceRequest(true)}
                  className="bg-neutral-900 hover:bg-neutral-800 p-3 rounded-xl border border-neutral-800 flex flex-col items-center justify-center space-y-1.5 text-center active:scale-95 transition"
                >
                  <div className="w-8 h-8 rounded-lg bg-blue-500/10 flex items-center justify-center text-blue-400">
                    <FileText className="w-4 h-4" />
                  </div>
                  <span className="text-[11px] font-bold">Log Vehicle Defect</span>
                </button>

                <button
                  onClick={() => setShowIncidentForm(true)}
                  className="bg-neutral-900 hover:bg-neutral-800 p-3 rounded-xl border border-neutral-800 flex flex-col items-center justify-center space-y-1.5 text-center active:scale-95 transition col-span-2"
                >
                  <div className="w-8 h-8 rounded-lg bg-rose-500/10 flex items-center justify-center text-rose-400">
                    <AlertTriangle className="w-4 h-4" />
                  </div>
                  <span className="text-[11px] font-bold">Report Accident or Breakdown</span>
                </button>
              </div>

              {/* Mobile Compliance Note */}
              <div className="p-3 bg-neutral-900/40 rounded-xl border border-neutral-800/60 text-[10px] text-neutral-500 flex items-start space-x-2">
                <Lock className="w-3.5 h-3.5 text-amber-500/70 mt-0.5 shrink-0" />
                <p>
                  Every operation on this smartphone is cryptographically signed, timestamped, and location-checked against telemetry logs. Falsifying odometers violates core policy rules.
                </p>
              </div>
            </div>
          )}

          {/* TRIPS TAB */}
          {activeTab === "trips" && (
            <div className="p-4 flex flex-col space-y-3">
              <h3 className="text-sm font-extrabold flex items-center mb-1">
                <Navigation className="w-4 h-4 mr-1 text-amber-500" /> Historic Trip Logs
              </h3>
              {trips.filter(t => t.driverId === currentDriver.id).map(trip => (
                <div key={trip.id} className="bg-neutral-900 p-3 rounded-xl border border-neutral-800 text-xs">
                  <div className="flex justify-between items-center mb-1.5">
                    <span className="font-mono text-neutral-400 text-[10px]">{trip.tripRequestNumber}</span>
                    <span className={`text-[9px] px-1.5 py-0.2 rounded font-mono ${
                      trip.status === TripStatus.Completed ? "bg-emerald-500/20 text-emerald-400" :
                      trip.status === TripStatus.Flagged ? "bg-rose-500/20 text-rose-400" :
                      trip.status === TripStatus.Active ? "bg-blue-500/20 text-blue-400" :
                      "bg-amber-500/20 text-amber-400"
                    }`}>
                      {trip.status}
                    </span>
                  </div>
                  <p className="font-bold text-white text-[11px]">{trip.pickupPoint} → {trip.destination}</p>
                  <div className="flex justify-between mt-2 pt-2 border-t border-neutral-800/60 text-[10px] text-neutral-400">
                    <span>GPS Logged: {trip.gpsDistanceKm || "N/A"} KM</span>
                    <span>Started: {trip.startedAt ? new Date(trip.startedAt).toLocaleDateString() : "Pending"}</span>
                  </div>
                </div>
              ))}
            </div>
          )}

          {/* FUEL TAB */}
          {activeTab === "fuel" && (
            <div className="p-4 flex flex-col space-y-3">
              <div className="flex justify-between items-center mb-1">
                <h3 className="text-sm font-extrabold flex items-center">
                  <Flame className="w-4 h-4 mr-1 text-amber-500" /> Fuel Claims & Vouchers
                </h3>
                <button
                  onClick={() => setShowFuelRequest(true)}
                  className="bg-amber-500 hover:bg-amber-600 text-neutral-950 px-2.5 py-1 rounded-lg text-[10px] font-extrabold flex items-center"
                >
                  <Plus className="w-3 h-3 mr-0.5" /> Log Fuel
                </button>
              </div>

              {fuelRequests.filter(f => f.driverId === currentDriver.id).map(fr => (
                <div key={fr.id} className="bg-neutral-900 p-3 rounded-xl border border-neutral-800 text-xs">
                  <div className="flex justify-between items-center mb-1.5">
                    <span className="font-bold text-white text-[11px]">{fr.stationName}</span>
                    <span className={`text-[9px] px-1.5 py-0.2 rounded font-mono ${
                      fr.varianceFlagged ? "bg-rose-500/20 text-rose-400" : "bg-emerald-500/20 text-emerald-400"
                    }`}>
                      {fr.varianceFlagged ? "Flagged Variance" : fr.status}
                    </span>
                  </div>
                  <div className="grid grid-cols-3 gap-1 font-mono text-[10px] text-neutral-400">
                    <div>
                      <span>Liters</span>
                      <p className="text-white font-bold">{fr.requestedLiters} L</p>
                    </div>
                    <div>
                      <span>Cost</span>
                      <p className="text-white font-bold">${fr.estimatedCost}</p>
                    </div>
                    <div>
                      <span>Odometer</span>
                      <p className="text-white font-bold">{fr.odometer}</p>
                    </div>
                  </div>
                  {fr.varianceFlagged && (
                    <div className="mt-2 bg-rose-950/30 border border-rose-500/20 p-1.5 rounded text-[9px] text-rose-400">
                      <p>{fr.varianceReason}</p>
                    </div>
                  )}
                </div>
              ))}
            </div>
          )}

          {/* MAINTENANCE TAB */}
          {activeTab === "maintenance" && (
            <div className="p-4 flex flex-col space-y-3">
              <div className="flex justify-between items-center mb-1">
                <h3 className="text-sm font-extrabold flex items-center">
                  <FileText className="w-4 h-4 mr-1 text-blue-400" /> Maintenance Logs
                </h3>
                <button
                  onClick={() => setShowMaintenanceRequest(true)}
                  className="bg-blue-500 hover:bg-blue-600 text-white px-2.5 py-1 rounded-lg text-[10px] font-extrabold flex items-center"
                >
                  <Plus className="w-3 h-3 mr-0.5" /> Log Issue
                </button>
              </div>

              {maintenanceRequests.filter(m => m.driverId === currentDriver.id).map(mr => (
                <div key={mr.id} className="bg-neutral-900 p-3 rounded-xl border border-neutral-800 text-xs">
                  <div className="flex justify-between items-center mb-1.5">
                    <span className="font-bold text-white text-[11px] truncate w-2/3">{mr.description}</span>
                    <span className={`text-[9px] px-1.5 py-0.2 rounded font-mono ${
                      mr.status === MaintenanceStatus.Completed || mr.status === MaintenanceStatus.Verified ? "bg-emerald-500/20 text-emerald-400" : "bg-amber-500/20 text-amber-400"
                    }`}>
                      {mr.status}
                    </span>
                  </div>
                  <div className="flex justify-between text-[10px] text-neutral-400">
                    <span>Odometer: {mr.odometer}</span>
                    <span>Severity: <span className="text-amber-400">{mr.severity}</span></span>
                  </div>
                </div>
              ))}
            </div>
          )}

          {/* GATE SCANNER / GATE OFFICER SUB-INTERFACE */}
          {activeTab === "gate" && (
            <div className="p-4 flex flex-col space-y-3">
              <h3 className="text-sm font-extrabold flex items-center mb-1">
                <ScanQrCode className="w-4.5 h-4.5 mr-1 text-amber-500" /> Gate Officer Terminal
              </h3>
              <p className="text-[11px] text-neutral-400">
                Gate officers verify vehicle QR stamps, driver licenses, and match odometer records before granting exit/entry clearance.
              </p>

              <div className="border border-neutral-800 bg-neutral-900/50 p-3 rounded-xl space-y-2 text-xs">
                <div>
                  <label className="text-[10px] text-neutral-400 block font-mono">Simulate Scanning Vehicle:</label>
                  <select
                    value={scannedVehicleId}
                    onChange={(e) => {
                      setScannedVehicleId(e.target.value);
                      const selectedVeh = vehicles.find(v => v.id === e.target.value);
                      if (selectedVeh) {
                        setGateOdometer(selectedVeh.currentOdometer);
                      }
                    }}
                    className="w-full bg-neutral-950 border border-neutral-800 text-white rounded p-1.5 text-xs font-mono"
                  >
                    {vehicles.map(v => (
                      <option key={v.id} value={v.id}>{v.registrationNumber} ({v.make}) - Status: {v.status}</option>
                    ))}
                  </select>
                </div>

                <div>
                  <label className="text-[10px] text-neutral-400 block font-mono">Simulate Scanning Driver:</label>
                  <select
                    value={scannedDriverId}
                    onChange={(e) => setScannedDriverId(e.target.value)}
                    className="w-full bg-neutral-950 border border-neutral-800 text-white rounded p-1.5 text-xs font-mono"
                  >
                    {drivers.map(d => (
                      <option key={d.id} value={d.id}>{d.name} ({d.staffNumber})</option>
                    ))}
                  </select>
                </div>
              </div>

              <div className="grid grid-cols-2 gap-2 pt-2">
                <button
                  onClick={() => setShowGateSignOut(true)}
                  className="bg-emerald-600 hover:bg-emerald-700 text-white py-2.5 rounded-xl font-extrabold text-xs flex items-center justify-center space-x-1"
                >
                  <span>Gate Sign-Out (Exit)</span>
                </button>
                <button
                  onClick={() => setShowGateSignIn(true)}
                  className="bg-blue-600 hover:bg-blue-700 text-white py-2.5 rounded-xl font-extrabold text-xs flex items-center justify-center space-x-1"
                >
                  <span>Gate Sign-In (Return)</span>
                </button>
              </div>

              <div className="p-3 bg-rose-950/20 border border-rose-900/40 rounded-xl text-[10px] text-rose-300 flex items-start space-x-1.5">
                <AlertTriangle className="w-3.5 h-3.5 text-rose-400 mt-0.5 shrink-0" />
                <p>
                  <strong>Security Rule:</strong> Forcing an exit scan without an approved digital trip slip will trigger a system-wide high-priority Policy Audit alert.
                </p>
              </div>
            </div>
          )}

          {/* OVERLAY MODALS IN THE PHONE */}

          {/* Pre-Trip Inspection Sheet */}
          {showInspection && (
            <div className="absolute inset-0 bg-neutral-950/95 z-50 p-4 overflow-y-auto flex flex-col">
              <div className="flex justify-between items-center mb-3">
                <h4 className="font-extrabold text-sm text-amber-500">Pre-Trip Digital Inspection</h4>
                <button onClick={() => setShowInspection(false)} className="text-neutral-400"><X className="w-5 h-5" /></button>
              </div>
              <p className="text-[10px] text-neutral-400 mb-3">Check each component below to verify mechanical roadworthiness.</p>
              
              <div className="space-y-2 flex-1">
                {Object.keys(checklist).filter(k => k !== "notes").map((key) => (
                  <label key={key} className="flex justify-between items-center bg-neutral-900 p-2 rounded border border-neutral-800 text-xs">
                    <span className="capitalize">{key.replace("Ok", "").replace("Level", " Level").replace("coolant", "Coolant / Antifreeze").replace("tyres", "Tyres & Spares").replace("brakes", "Brake Response").replace("lights", "Indicator Lights").replace("bodyCondition", "General Body Condition")}</span>
                    <input
                      type="checkbox"
                      checked={(checklist as any)[key]}
                      onChange={(e) => setChecklist({ ...checklist, [key]: e.target.checked })}
                      className="rounded border-neutral-700 text-amber-500 focus:ring-amber-500 h-4 w-4 bg-neutral-950"
                    />
                  </label>
                ))}
                <div>
                  <label className="text-[10px] text-neutral-400 block mb-1">Additional Observations / Defects:</label>
                  <textarea
                    rows={2}
                    value={checklist.notes}
                    onChange={(e) => setChecklist({ ...checklist, notes: e.target.value })}
                    className="w-full bg-neutral-900 border border-neutral-800 text-white rounded p-2 text-xs focus:ring-1 focus:ring-amber-500 focus:outline-none"
                    placeholder="Enter any minor scratches or notes"
                  />
                </div>
              </div>

              <div className="pt-4 border-t border-neutral-800 mt-4 space-y-2">
                <div className="bg-neutral-900/50 p-2 rounded text-[10px] text-amber-400 italic">
                  Odometer will lock at {assignedVehicle.currentOdometer.toLocaleString()} KM. Front-facing camera captures photo verification automatically.
                </div>
                <button
                  onClick={handleStartTrip}
                  className="w-full py-2.5 bg-amber-500 hover:bg-amber-600 text-neutral-900 font-extrabold text-xs rounded-xl"
                >
                  Accept Handover & Start GPS Route
                </button>
              </div>
            </div>
          )}

          {/* Fuel Request Modal */}
          {showFuelRequest && (
            <div className="absolute inset-0 bg-neutral-950/95 z-50 p-4 overflow-y-auto flex flex-col">
              <div className="flex justify-between items-center mb-3">
                <h4 className="font-extrabold text-sm text-amber-500">Controlled Fuel Transaction</h4>
                <button onClick={() => setShowFuelRequest(false)} className="text-neutral-400"><X className="w-5 h-5" /></button>
              </div>
              <div className="space-y-3 text-xs flex-1">
                <div>
                  <label className="text-[10px] text-neutral-400 block mb-1">Current Odometer (KM):</label>
                  <input
                    type="number"
                    value={fuelOdometer}
                    onChange={(e) => setFuelOdometer(parseInt(e.target.value) || 0)}
                    className="w-full bg-neutral-900 border border-neutral-800 text-white rounded p-2 text-xs"
                  />
                  {currentDriver.id === "d3" && (
                    <span className="text-[9px] text-rose-400 font-mono">Simulating pad: enter 112450 (with Trip distance of 200KM but GPS showing only 120KM)</span>
                  )}
                </div>

                <div>
                  <label className="text-[10px] text-neutral-400 block mb-1">Requested Fuel (Liters):</label>
                  <input
                    type="number"
                    value={fuelLiters}
                    onChange={(e) => setFuelLiters(parseInt(e.target.value) || 0)}
                    className="w-full bg-neutral-900 border border-neutral-800 text-white rounded p-2 text-xs"
                  />
                </div>

                <div>
                  <label className="text-[10px] text-neutral-400 block mb-1">Total Fuel Cost ($):</label>
                  <input
                    type="number"
                    value={fuelCost}
                    onChange={(e) => setFuelCost(parseInt(e.target.value) || 0)}
                    className="w-full bg-neutral-900 border border-neutral-800 text-white rounded p-2 text-xs"
                  />
                </div>

                <div>
                  <label className="text-[10px] text-neutral-400 block mb-1">Fuel Station Location:</label>
                  <select
                    value={fuelStation}
                    onChange={(e) => setFuelStation(e.target.value)}
                    className="w-full bg-neutral-900 border border-neutral-800 text-white rounded p-2 text-xs"
                  >
                    <option value="TotalEnergies Wilberforce">TotalEnergies Wilberforce (Approved)</option>
                    <option value="Shell East End">Shell East End (Approved)</option>
                    <option value="NP Aberdeen Station">NP Aberdeen Station (Approved)</option>
                    <option value="Unapproved Local Depot">Unapproved Local Depot (Flagged)</option>
                  </select>
                </div>

                <div className="bg-neutral-900 p-2.5 rounded border border-neutral-800 space-y-2">
                  <span className="text-[10px] text-neutral-400 block font-mono">Attachment Upload Checklist:</span>
                  <div className="flex space-x-2 text-[10px]">
                    <div className="bg-neutral-950 p-2 rounded text-center text-emerald-400 flex-1 border border-emerald-500/20">
                      Receipt Uploaded ✓
                    </div>
                    <div className="bg-neutral-950 p-2 rounded text-center text-emerald-400 flex-1 border border-emerald-500/20">
                      Pump Photo ✓
                    </div>
                  </div>
                </div>
              </div>

              <div className="pt-4 border-t border-neutral-800 mt-4">
                <button
                  onClick={handleSubmitFuelRequest}
                  className="w-full py-2.5 bg-amber-500 hover:bg-amber-600 text-neutral-900 font-extrabold text-xs rounded-xl"
                >
                  Submit Fuel Receipt Claim
                </button>
              </div>
            </div>
          )}

          {/* Defect Maintenance Modal */}
          {showMaintenanceRequest && (
            <div className="absolute inset-0 bg-neutral-950/95 z-50 p-4 overflow-y-auto flex flex-col">
              <div className="flex justify-between items-center mb-3">
                <h4 className="font-extrabold text-sm text-blue-400">Log Vehicle Mechanical Defect</h4>
                <button onClick={() => setShowMaintenanceRequest(false)} className="text-neutral-400"><X className="w-5 h-5" /></button>
              </div>
              <div className="space-y-3 text-xs flex-1">
                <div>
                  <label className="text-[10px] text-neutral-400 block mb-1">Issue Category:</label>
                  <select
                    value={mCategory}
                    onChange={(e) => setMCategory(e.target.value as any)}
                    className="w-full bg-neutral-900 border border-neutral-800 text-white rounded p-2 text-xs"
                  >
                    <option value="Corrective">Corrective Repair (Defect Found)</option>
                    <option value="Routine">Routine Servicing Schedule</option>
                    <option value="Emergency">Emergency Safety Breakdown</option>
                  </select>
                </div>

                <div>
                  <label className="text-[10px] text-neutral-400 block mb-1">Severity Rating:</label>
                  <select
                    value={mSeverity}
                    onChange={(e) => setMSeverity(e.target.value as any)}
                    className="w-full bg-neutral-900 border border-neutral-800 text-white rounded p-2 text-xs font-bold text-amber-500"
                  >
                    <option value="Low" className="text-emerald-400">Low (Drivable)</option>
                    <option value="Medium" className="text-amber-400">Medium (Needs attention soon)</option>
                    <option value="High" className="text-rose-400">High (Safety hazard - Grounded)</option>
                  </select>
                </div>

                <div>
                  <label className="text-[10px] text-neutral-400 block mb-1">Current Odometer (KM):</label>
                  <input
                    type="number"
                    value={mOdometer}
                    onChange={(e) => setMOdometer(parseInt(e.target.value) || 0)}
                    className="w-full bg-neutral-900 border border-neutral-800 text-white rounded p-2 text-xs"
                  />
                </div>

                <div>
                  <label className="text-[10px] text-neutral-400 block mb-1">Detailed Defect Description:</label>
                  <textarea
                    rows={3}
                    value={mDescription}
                    onChange={(e) => setMDescription(e.target.value)}
                    className="w-full bg-neutral-900 border border-neutral-800 text-white rounded p-2 text-xs"
                    placeholder="Describe noise, vibrations, warnings, oil leaks, brake wear etc."
                  />
                </div>

                <div className="bg-neutral-900 p-2 rounded text-[10px] text-neutral-400">
                  <p>✓ Smartphone camera auto-triggered for before photo logs.</p>
                </div>
              </div>

              <div className="pt-4 border-t border-neutral-800 mt-4">
                <button
                  onClick={handleSubmitMaintenance}
                  className="w-full py-2.5 bg-blue-500 hover:bg-blue-600 text-white font-extrabold text-xs rounded-xl"
                >
                  Log Defect & Submit Before Photo
                </button>
              </div>
            </div>
          )}

          {/* Incident Reporting Modal */}
          {showIncidentForm && (
            <div className="absolute inset-0 bg-neutral-950/95 z-50 p-4 overflow-y-auto flex flex-col">
              <div className="flex justify-between items-center mb-3">
                <h4 className="font-extrabold text-sm text-rose-400">Report Emergency Incident</h4>
                <button onClick={() => setShowIncidentForm(false)} className="text-neutral-400"><X className="w-5 h-5" /></button>
              </div>
              <div className="space-y-3 text-xs flex-1">
                <div>
                  <label className="text-[10px] text-neutral-400 block mb-1">Incident Category:</label>
                  <select
                    value={incidentCategory}
                    onChange={(e) => setIncidentCategory(e.target.value as any)}
                    className="w-full bg-neutral-900 border border-neutral-800 text-white rounded p-2 text-xs"
                  >
                    <option value="Breakdown">Breakdown & Mechanical Failure</option>
                    <option value="Accident">Accident / Road Collision</option>
                    <option value="Violation">Traffic Fine or Police Hold</option>
                    <option value="Theft">Fuel Siphoning Attempt / Parts Theft</option>
                    <option value="Passenger Complaint">Passenger Altercation / Delay</option>
                  </select>
                </div>

                <div>
                  <label className="text-[10px] text-neutral-400 block mb-1">GPS Incident Location:</label>
                  <input
                    type="text"
                    value={incidentLocation}
                    onChange={(e) => setIncidentLocation(e.target.value)}
                    className="w-full bg-neutral-900 border border-neutral-800 text-white rounded p-2 text-xs"
                    placeholder="e.g. Mile 38 highway near Waterloo"
                  />
                </div>

                <div>
                  <label className="text-[10px] text-neutral-400 block mb-1">Details & Sequence of Events:</label>
                  <textarea
                    rows={4}
                    value={incidentDescription}
                    onChange={(e) => setIncidentDescription(e.target.value)}
                    className="w-full bg-neutral-900 border border-neutral-800 text-white rounded p-2 text-xs"
                    placeholder="Enter witness information, damages, police reports if any."
                  />
                </div>
              </div>

              <div className="pt-4 border-t border-neutral-800 mt-4">
                <button
                  onClick={handleSubmitIncident}
                  className="w-full py-2.5 bg-rose-600 hover:bg-rose-700 text-white font-extrabold text-xs rounded-xl animate-pulse"
                >
                  Send Urgent Dispatch Signal
                </button>
              </div>
            </div>
          )}

          {/* Gate Officer Exit Sign-Out Checklist Modal */}
          {showGateSignOut && (
            <div className="absolute inset-0 bg-neutral-950/95 z-50 p-4 overflow-y-auto flex flex-col">
              <div className="flex justify-between items-center mb-3">
                <h4 className="font-extrabold text-sm text-emerald-400">Gate EXIT Authorization</h4>
                <button onClick={() => setShowGateSignOut(false)} className="text-neutral-400"><X className="w-5 h-5" /></button>
              </div>
              <div className="space-y-3 text-xs flex-1">
                <div className="bg-neutral-900 p-2 rounded text-[11px]">
                  <p className="text-neutral-400">Vehicle selected: <strong>{vehicles.find(v => v.id === scannedVehicleId)?.registrationNumber}</strong></p>
                  <p className="text-neutral-400">Driver matched: <strong>{drivers.find(d => d.id === scannedDriverId)?.name}</strong></p>
                </div>

                <div>
                  <label className="text-[10px] text-neutral-400 block mb-1">Confirm Gate Odometer (KM):</label>
                  <input
                    type="number"
                    value={gateOdometer}
                    onChange={(e) => setGateOdometer(parseInt(e.target.value) || 0)}
                    className="w-full bg-neutral-900 border border-neutral-800 text-white rounded p-2 text-xs font-mono font-bold"
                  />
                </div>

                <div>
                  <label className="text-[10px] text-neutral-400 block mb-1">Current Fuel Level (% Gauge):</label>
                  <input
                    type="number"
                    value={gateFuel}
                    onChange={(e) => setGateFuel(parseInt(e.target.value) || 0)}
                    className="w-full bg-neutral-900 border border-neutral-800 text-white rounded p-2 text-xs"
                  />
                </div>

                <div>
                  <label className="text-[10px] text-neutral-400 block mb-1">Verify Passengers count:</label>
                  <input
                    type="number"
                    value={passengerCount}
                    onChange={(e) => setPassengerCount(parseInt(e.target.value) || 0)}
                    className="w-full bg-neutral-900 border border-neutral-800 text-white rounded p-2 text-xs"
                  />
                </div>
              </div>

              <div className="pt-4 border-t border-neutral-800 mt-4">
                <button
                  onClick={handleGateSignOutSubmit}
                  className="w-full py-2.5 bg-emerald-600 hover:bg-emerald-700 text-white font-extrabold text-xs rounded-xl"
                >
                  Verify Credentials & Open Barrier
                </button>
              </div>
            </div>
          )}

          {/* Gate Officer Entrance Sign-In Checklist Modal */}
          {showGateSignIn && (
            <div className="absolute inset-0 bg-neutral-950/95 z-50 p-4 overflow-y-auto flex flex-col">
              <div className="flex justify-between items-center mb-3">
                <h4 className="font-extrabold text-sm text-blue-400">Gate RETURN Authorization</h4>
                <button onClick={() => setShowGateSignIn(false)} className="text-neutral-400"><X className="w-5 h-5" /></button>
              </div>
              <div className="space-y-3 text-xs flex-1">
                <div className="bg-neutral-900 p-2 rounded text-[11px]">
                  <p className="text-neutral-400">Vehicle selected: <strong>{vehicles.find(v => v.id === scannedVehicleId)?.registrationNumber}</strong></p>
                  <p className="text-neutral-400">Driver matched: <strong>{drivers.find(d => d.id === scannedDriverId)?.name}</strong></p>
                </div>

                <div>
                  <label className="text-[10px] text-neutral-400 block mb-1">Record Return Odometer (KM):</label>
                  <input
                    type="number"
                    value={gateOdometer}
                    onChange={(e) => setGateOdometer(parseInt(e.target.value) || 0)}
                    className="w-full bg-neutral-900 border border-neutral-800 text-white rounded p-2 text-xs font-mono font-bold"
                  />
                  {scannedDriverId === "d3" && (
                    <span className="text-[9px] text-rose-400 block mt-1 font-mono">Simulating Musa: enter 112400 (which adds an 80km padding over GPS distance of 120km to trigger an exception)</span>
                  )}
                </div>

                <div>
                  <label className="text-[10px] text-neutral-400 block mb-1">Return Fuel Level (% Gauge):</label>
                  <input
                    type="number"
                    value={gateFuel}
                    onChange={(e) => setGateFuel(parseInt(e.target.value) || 0)}
                    className="w-full bg-neutral-900 border border-neutral-800 text-white rounded p-2 text-xs"
                  />
                </div>
              </div>

              <div className="pt-4 border-t border-neutral-800 mt-4">
                <button
                  onClick={handleGateSignInSubmit}
                  className="w-full py-2.5 bg-blue-600 hover:bg-blue-700 text-white font-extrabold text-xs rounded-xl"
                >
                  Verify Key Return & Close Trip File
                </button>
              </div>
            </div>
          )}

        </div>

        {/* Bottom Smartphone Navigation Bar */}
        <div className="h-[68px] bg-neutral-900 border-t border-neutral-800 flex justify-around items-center px-2 pb-2 text-[10px] text-neutral-400 z-40">
          <button
            onClick={() => { setActiveTab("home"); }}
            className={`flex flex-col items-center space-y-1 ${activeTab === "home" ? "text-amber-500" : "hover:text-neutral-200"}`}
          >
            <Smartphone className="w-4.5 h-4.5" />
            <span>Home</span>
          </button>
          
          <button
            onClick={() => { setActiveTab("trips"); }}
            className={`flex flex-col items-center space-y-1 ${activeTab === "trips" ? "text-amber-500" : "hover:text-neutral-200"}`}
          >
            <Navigation className="w-4.5 h-4.5" />
            <span>Trips</span>
          </button>

          <button
            onClick={() => { setActiveTab("fuel"); }}
            className={`flex flex-col items-center space-y-1 ${activeTab === "fuel" ? "text-amber-500" : "hover:text-neutral-200"}`}
          >
            <Flame className="w-4.5 h-4.5" />
            <span>Fuel</span>
          </button>

          <button
            onClick={() => { setActiveTab("maintenance"); }}
            className={`flex flex-col items-center space-y-1 ${activeTab === "maintenance" ? "text-amber-500" : "hover:text-neutral-200"}`}
          >
            <FileText className="w-4.5 h-4.5" />
            <span>Repairs</span>
          </button>

          <button
            onClick={() => { setActiveTab("gate"); }}
            className={`flex flex-col items-center space-y-1 ${activeTab === "gate" ? "text-amber-500" : "hover:text-neutral-200"}`}
          >
            <ScanQrCode className="w-4.5 h-4.5" />
            <span>Gate pass</span>
          </button>
        </div>

        {/* Home Screen Indicator bar */}
        <div className="absolute bottom-1.5 left-1/2 -translate-x-1/2 w-32 h-1 bg-neutral-700 rounded-full z-50"></div>
      </div>
    </div>
  );
}
